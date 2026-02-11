# Habitat — Feature Implementation Plan

This document covers all requested features broken into manageable phases. Each phase builds on the previous one.

---

## Phase 1: Onboarding Overhaul — Grouping Logic, Pills & Schedule Times

### 1A. Replace "Exercise" with specific activities + add auto-grouping rules

**Files:** `OnboardingData.swift`, `HabitGenerator.swift`, `CompleteScreen.swift`

**Changes to `OnboardingData.swift`:**
- Remove the generic "Exercise" pill from `HabitSuggestion.fulfilment`
- Add `Gym` (💪, "30 min", niceToDo, daily, isHobby: true) and `Cycle` (🚴, "30 min", niceToDo, weekly x3, isHobby: true) alongside existing `Run`
- Keep all other fulfilment pills the same: Read, Meditate, Journal, Play music, Draw or paint, Photography, Practice a language, Write, Run, Cook something new, Craft
- Existing pills like "Play music" stay as "Play music" (they map to the creative group below)

**Auto-grouping rules in `HabitGenerator.swift`:**

Define a new struct `AutoGroupRule`:
```swift
struct AutoGroupRule {
    let groupName: String
    let groupEmoji: String
    let memberNames: Set<String>   // pill names that belong to this group
    let minimumMembers: Int        // need at least this many selected to form a group (2)
}
```

Three rules:
1. **"Be Mindful"** 🧘 — members: `["Journal", "Meditate"]`
2. **"Exercise"** 💪 — members: `["Gym", "Run", "Cycle"]`
3. **"Be Creative"** 🎨 — members: `["Draw or paint", "Play music", "Write", "Craft", "Photography", "Cook something new"]`

Logic: After generating all `DraftHabit`s, check each rule. If ≥2 members are selected, mark those drafts as belonging to a group. Add a new `DraftGroup` struct to hold group info alongside `draftHabits`.

**New structs in `OnboardingData.swift`:**
```swift
struct DraftGroup: Identifiable {
    let id = UUID()
    var name: String
    var emoji: String
    var tier: HabitTier  // always .mustDo for groups
    var memberDraftIds: [UUID]
    var requireCount: Int  // default 1
}
```

Add `var draftGroups: [DraftGroup] = []` to `OnboardingData`.

**Changes to `CompleteScreen.swift` → `createHabits()`:**
- After creating all individual habits, iterate `data.draftGroups`
- For each group, find the created `Habit` objects by matching draft names
- Call `store.addGroup(name:, tier: .mustDo, requireCount: 1, habitIds:)`
- Groups are **always mustDo** — this is their purpose: a less strict must-do that lets you pick any one from a set of nice-to-do hobbies

### 1B. One-off tasks → pill-based (same as other sections)

**Files:** `OnboardingData.swift`, `ResponsibilitiesScreen.swift`, `HabitGenerator.swift`

**Changes to `OnboardingData.swift`:**
- Remove `todayTasksText: String`
- Add `todayTasks: [String] = []` (array of pill strings, same pattern as `customBasics`)
- Add `selectedTasks: Set<String> = []`
- Update `hasAnySelections` to check `!todayTasks.isEmpty` instead of `todayTasksText`

**Changes to `ResponsibilitiesScreen.swift`:**
- Replace the one-off tasks `TextField` with the same `AddCustomPillField` + pill display pattern
- Show pills for each task added, with ✕ to remove
- No pre-defined suggestion pills for tasks — only the add field
- Tasks auto-select when added (add to both `todayTasks` and `selectedTasks`)

**Changes to `HabitGenerator.swift`:**
- Replace `parseTaskText()` with a loop over `data.todayTasks` creating `DraftHabit` entries with `.once` frequency

### 1C. Time-of-day schedule system (5 time slots)

**Files:** `OnboardingData.swift`, `DraftHabit.swift` (inside OnboardingData), `Habit.swift`, `HabitGenerator.swift`

**Expand `DraftHabit.TimeOfDay`** to 5 schedule slots:
```swift
enum TimeOfDay: String, CaseIterable {
    case afterWake = "After Wake"       // user's wake time
    case morning = "Morning"             // wake time → 12pm
    case duringTheDay = "During the Day" // 12pm → 5pm
    case evening = "Evening"             // 5pm → 1hr before bed
    case beforeBed = "Before Bed"        // 1hr before bed → bed time
    case task = "Today's Tasks"          // one-off tasks (unchanged)
}
```

**Add `scheduleTimes: [TimeOfDay]` to `Habit` model:**
- New persisted property: `var scheduleTimes: [String] = []` (stored as raw values)
- Each habit can have 1–5 schedule times selected
- Computed property to convert to/from `[TimeOfDay]`

**Map existing suggestions to new time slots:**
- "Wake up on time" → `.afterWake`
- "Take vitamins" → `.afterWake`
- "Make bed" → `.afterWake`
- "Drink enough water" → `.duringTheDay`
- "Eat proper meals" → `.duringTheDay`
- "Move your body" → `.duringTheDay`
- "Brush & floss" → `.afterWake`
- "Walk the dog" → `.afterWake`
- "No scrolling" → `.duringTheDay`
- "Tidy up" → `.evening`
- "Call family" → `.evening`
- "Review budget" → `.evening`
- "Wind-down routine" → `.beforeBed`
- "Sleep on time" → `.beforeBed`
- "Read" → `.beforeBed`
- "Meditate" → `.afterWake`
- "Journal" → `.beforeBed`
- Hobbies (Run, Gym, Cycle, Draw, Music, etc.) → `.duringTheDay`
- "Practice a language" → `.morning`

**Store wake/bed times on `Habit` or `BlockSettings` or a new `UserSchedule` singleton:**
- Create `UserSchedule` observable singleton persisted to UserDefaults
- Properties: `wakeTimeMinutes: Int`, `bedTimeMinutes: Int`
- Populated during onboarding from `OnboardingData.wakeUpTime` / `.bedTime`
- Used by notification system to calculate actual notification times

### 1D. "Habit prompt" for nice-to-do hobbies

**Files:** `OnboardingData.swift`, `HabitSuggestion`, `DraftHabit`, `Habit.swift`

Nice-to-do hobbies should have a motivational "micro-habit" prompt — a small first step to get the user started.

**Add `habitPrompt: String` to `HabitSuggestion`:**
```swift
// Pre-defined prompts for known hobbies:
"Run"              → "Put on your trainers and step outside"
"Gym"              → "Take a water bottle and walk to the gym"
"Cycle"            → "Pump the tyres and get on the saddle"
"Play music"       → "Pick up the guitar and strum a few strings"
"Draw or paint"    → "Open the sketchbook and draw one line"
"Photography"      → "Grab your camera and take one photo"
"Write"            → "Open a blank page and write one sentence"
"Cook something new" → "Pick a recipe and lay out the ingredients"
"Craft"            → "Get your materials out on the table"
"Journal"          → "Open your journal and write today's date"
"Meditate"         → "Sit down, close your eyes, take one breath"
"Read"             → "Pick up your book and read one page"
"Practice a language" → "Open the app and do one lesson"
```

**Add `habitPrompt: String` to `Habit` model** (persisted, default empty)

**For custom hobbies** added during onboarding — the user won't have a prompt yet. This will be set later via the edit screen (see Phase 5).

---

## Phase 2: Notification / Reminder System

### 2A. Smart reminder schedule (5 daily reminders)

**Files:** New `ReminderService.swift`, `NotificationService.swift` (existing), `UserSchedule.swift` (from 1C), `Habit.swift`

When reminders are enabled globally, the app sends 5 timed notifications per day:

| # | Time | Content |
|---|------|---------|
| 1 | **Wake time** | "Good morning! Write any tasks for today and start your morning habits." Lists afterWake habits. |
| 2 | **11:00 AM** (1hr before morning ends) | "Morning reminder: you still have X morning habits left." Lists uncompleted morning habits with reminders on. Shows must-do progress (e.g. "3/7 must-dos done"). |
| 3 | **5:00 PM** (end of daytime) | "Afternoon check-in: get your daytime habits done." Lists uncompleted duringTheDay habits. Shows progress. |
| 4 | **2 hours before bed** | "Evening wind-down: you have X habits left today." Lists uncompleted evening habits + any remaining hobbies. Shows progress. |
| 5 | **1 hour before bed** | "Last call: finish up these final habits before bed." Lists uncompleted beforeBed habits. |

**Reminder content rules:**
- Only include **must-dos** and **standalone nice-to-dos** (not group members)
- For nice-to-dos show the `habitPrompt` instead of just the name (motivational framing)
- Show `X/Y must-dos complete` progress in each reminder
- Each reminder names the actual habits relevant to that time slot

**Per-habit schedule assignment:**
- Each habit stores which of the 5 time slots it belongs to (1 or more)
- When user enables reminders for a habit, they can pick which time slots
- This is shown in settings / habit edit screen

**Implementation:**
- Extend existing `NotificationService` with a `scheduleSmartReminders()` method
- Called whenever habits change, completion state changes, or at midnight rollover
- Uses `UNUserNotificationCenter` with unique identifiers per time slot
- Recalculates content each time based on current completion state

### 2B. Reminder settings UI

**Files:** New section in `HabitDetailView.swift` or a new `ReminderSettingsView.swift`

- Global toggle: "Smart Reminders" on/off
- Per-habit: which time slots this habit appears in (multi-select of the 5 slots)
- Show the actual computed times based on wake/bed settings
- Preview of what the reminder will say

---

## Phase 3: App Blocker Screen Redesign — Identity-Based Choice

### 3A. Replace `InterceptView` with identity-based two-screen flow

**Files:** `InterceptView.swift` (major rewrite)

**Screen 1: "How will you cast your vote?"**

Two large buttons on paper background:

```
How will you cast your vote?

[ I am the kind of person who         ]
[ is controlled by their phone         ]

         — or —

[ I am the kind of person who          ]
[ I promised myself I would be         ]
```

**If user taps "controlled by phone" → Screen 2:**

Title: "Fine, just write this to scroll:"

Quote displayed: *"I would rather scroll right now than become the person I want to be"*

- TextEditor where user must type that exact sentence
- Compare input (case-insensitive, trimmed) to the target string
- Once it matches, show a "Continue to [app name]" button
- Button grants 5-min temporary unlock (same as current override)

**If user taps "person I promised" → Screen 3 (habit view):**

- Show the user's uncompleted habits for the current time slot
- For **must-dos**: show name + criteria (same as current)
- For **nice-to-dos / hobbies**: show the `habitPrompt` text instead (the micro-habit)
  - e.g. "🎸 Pick up the guitar and strum a few strings" instead of "Play music"
- Completing habits from here works the same as today
- Close button returns to home (blocked app stays blocked)

### 3B. Update `InterceptHabitRow` for hobby prompts

- When displaying a nice-to-do habit that has a `habitPrompt`, show the prompt as the subtitle
- Show the actual habit name smaller above or below

---

## Phase 4: Good Day Logic, Month Grid & Hobby Logs

### 4A. Lock "Good Day" status once achieved

**Files:** `HabitStore.swift`, possibly `DailyLog.swift`

**New model: `DayRecord`** (SwiftData)
```swift
@Model final class DayRecord {
    var id: UUID
    var date: Date          // startOfDay
    var isGoodDay: Bool
    var lockedAt: Date?     // when good day was locked in
}
```

**Logic change in `HabitStore`:**
- When `isGoodDay(for: today)` becomes true for the first time, create/update a `DayRecord` with `isGoodDay = true` and `lockedAt = Date()`
- Once locked, adding new habits that day does NOT un-lock the good day
- `isGoodDay(for date)` checks: if `DayRecord` exists and `isGoodDay == true`, return true (regardless of current habit state)
- For dates without a locked record, fall back to current live calculation

### 4B. Month Grid — pre-creation "-" symbol for habits

**Files:** `MonthGridView.swift` → `GridCellView`

For dates **before a habit's `createdAt`** date, show a hand-drawn dash "—" symbol:
- Dark, visible, fits the aesthetic
- Use a custom drawn dash (like `HandDrawnDash` view) — a slightly wavy horizontal line rendered with a `Path`
- Color: `JournalTheme.Colors.inkBlack.opacity(0.3)`

**Changes to `GridCellView`:**
- Add `habitCreatedAt: Date?` parameter
- If `date < habitCreatedAt` → show `HandDrawnDash` instead of empty/checkmark/cross
- Create new `HandDrawnDash` view similar to `HandDrawnCheckmark`/`HandDrawnCross`

**Changes to `DayRowView`:**
- Pass each habit's `createdAt` to the cell view

### 4C. Month Grid — Good Day green highlight uses locked records

- Update `isGoodDay` parameter in `DayRowView` to use the new `DayRecord` lookup
- Green highlight shows for any day that was locked as a good day

### 4D. Hobby Logs — support up to 3 photos

**Files:** `DailyLog.swift`, `HobbyCompletionOverlay.swift`, `HobbyLogDetailSheet.swift`, `PhotoStorageService.swift`

**Changes to `DailyLog`:**
- Replace `photoPath: String?` with `photoPaths: [String]` (up to 3)
- Migration: wrap existing `photoPath` into single-element array
- Keep backward compatibility

**Changes to `HobbyCompletionOverlay`:**
- Show up to 3 photo picker slots
- Display selected photos in a horizontal row
- User can add/remove individual photos

**Changes to `HobbyLogDetailSheet`:**
- Display up to 3 photos in a scrollable gallery or grid
- Tap to enlarge

### 4E. Group hobby logs — parent groups clickable in month grid

**Files:** `MonthGridView.swift`, `HobbyLogDetailSheet.swift`

- In the month grid, group columns are already shown
- Make group cells tappable when one or more sub-habits have hobby log content for that date
- On tap, open a `GroupHobbyLogSheet` that shows all sub-habit hobby logs for that date
- Show each sub-habit's name, note, and photos in a scrollable list

### 4F. Hobby logs editable from edit screen

**Files:** `HabitDetailView.swift` or new `HobbyLogEditView.swift`

- In the habit edit/detail screen, add a section showing recent hobby logs
- Each log entry shows date, note preview, photo thumbnails
- Tapping opens an editor where the user can modify the note and swap/remove/add photos
- Use same `HobbyCompletionOverlay` components for editing

---

## Phase 5: Frequency Editing & Habit Settings

### 5A. Change frequency in edit screen (daily/weekly/monthly)

**Files:** `HabitDetailView.swift` or `AddHabitView.swift`

- Add frequency picker: Daily / Weekly / Monthly
- **If Weekly selected:** show number picker (1-7x per week) + day selector (which days)
- **If Monthly selected:** show number picker (1-30x per month)
- **If Must Do tier:** frequency is locked to Daily (auto-set, grayed out)
- **If user changes to Daily:** they can optionally make it Must Do
- Vice versa: setting tier to mustDo auto-sets frequency to daily

### 5B. Custom hobby prompt for user-created hobbies

**Files:** `AddHabitView.swift`, `HabitDetailView.swift`

- When creating or editing a nice-to-do hobby, show a text field: "What's a small first step to get you started?"
- Placeholder: "e.g. Put on your trainers and step outside"
- This is stored as `Habit.habitPrompt`
- Used in reminders and the app blocker intercept screen

---

## Phase 6: Celebration Overlay Timing Fix

### 6A. Congratulations overlay waits for notes overlay

**Files:** `TodayView.swift` (or wherever `CelebrationOverlay` + `HobbyCompletionOverlay` are triggered)

**Current bug:** When crossing out the last must-do that has `enableNotesPhotos`, both the hobby notes overlay AND the congratulations overlay can appear simultaneously.

**Fix:**
- Add a state flag: `waitingForHobbyNote: Bool`
- When the last must-do is completed and it triggers a hobby note overlay, set `waitingForHobbyNote = true`
- Do NOT show `CelebrationOverlay` while `waitingForHobbyNote` is true
- When the hobby note overlay is dismissed, set `waitingForHobbyNote = false` → then trigger the celebration overlay
- Use `onDismiss` callback from `HobbyCompletionOverlay`

---

## Phase 7: End-of-Day Note & Fulfillment Score

### 7A. New model: `EndOfDayNote`

**Files:** New `EndOfDayNote.swift` in Models/

```swift
@Model final class EndOfDayNote {
    var id: UUID
    var date: Date              // startOfDay
    var note: String
    var fulfillmentScore: Int   // 1-10 scale
    var createdAt: Date
    var isLocked: Bool          // true after the grace period
}
```

**Lifecycle:**
- At end of day (triggered by beforeBed reminder or user manually), prompt user to write a reflection
- User rates their fulfillment 1–10
- The note can be edited **until the end of the NEXT day** (grace period)
- After that, `isLocked = true` and it becomes read-only forever

### 7B. End-of-day note UI

**Files:** New `EndOfDayNoteView.swift`

- Paper-textured card with:
  - Date header
  - Fulfillment score selector (1–10, styled as tappable circles or slider)
  - Multi-line text editor for the reflection note
  - "Save" button
- Triggered from:
  - The "before bed" reminder notification (deep link)
  - A button on `TodayView` that appears in the evening
  - The journal view (for editing past notes within grace period)

### 7C. Fulfillment graph in Stats

**Files:** `StatsView.swift`

- New card: **"Fulfillment"**
- Line graph plotting fulfillment scores over time (last 30 days)
- X-axis: dates, Y-axis: 1–10 score
- Use SwiftUI `Chart` framework (iOS 16+)
- Color: gradient from red (low) → amber (mid) → green (high)
- Show average score as a horizontal reference line

### 7D. Journal view — browse end-of-day notes

**Files:** New `JournalView.swift` (new tab or accessible from Stats)

- Scrollable list of past end-of-day notes, newest first
- Each entry shows:
  - Date
  - Fulfillment score (visual indicator)
  - Note preview (first 2 lines)
  - Whether it was a good day (green dot)
- Tapping opens full note view
- If within grace period (next day), show "Edit" button
- After grace period, read-only with a lock icon
- If a note was never written for a past day, show a faded entry: "No reflection recorded"
  - If it's within grace period, allow creating it still

---

## Phase 8: Groups Default to Must-Do

### 8A. Ensure all group creation flows default to mustDo

**Files:** `AddGroupView.swift`, `HabitStore.swift`, `HabitGroup.swift`

- When creating a group (both from onboarding auto-grouping and manual creation), tier defaults to `.mustDo`
- The purpose of groups: a less strict must-do that lets you pick any 1 from a set of hobbies
- In `AddGroupView`, pre-select "Must Do" as the tier
- Sub-habits within a group can be nice-to-do individually, but the group obligation is must-do
- This is already partly the case — just ensure consistency everywhere

---

## Implementation Order (Recommended)

| Order | Phase | Complexity | Dependencies |
|-------|-------|-----------|--------------|
| 1 | **1B** One-off tasks as pills | Small | None |
| 2 | **1A** Exercise removal + auto-grouping | Medium | None |
| 3 | **8A** Groups default mustDo | Small | 1A |
| 4 | **1C** 5 time-slot schedule system | Medium | None |
| 5 | **1D** Hobby prompts | Small | None |
| 6 | **6A** Celebration overlay fix | Small | None |
| 7 | **4B** Month grid pre-creation dash | Small | None |
| 8 | **4A** Lock good day status | Medium | None |
| 9 | **4C** Month grid green highlight fix | Small | 4A |
| 10 | **4D** Hobby logs 3 photos | Medium | None |
| 11 | **4E** Group hobby logs clickable | Small | 4D |
| 12 | **4F** Hobby logs editable | Medium | 4D |
| 13 | **5A** Frequency editing | Medium | None |
| 14 | **5B** Custom hobby prompt setting | Small | 1D |
| 15 | **3A** App blocker identity redesign | Large | 1D |
| 16 | **3B** Intercept hobby prompts | Small | 3A, 1D |
| 17 | **2A** Smart reminder system | Large | 1C, 1D |
| 18 | **2B** Reminder settings UI | Medium | 2A |
| 19 | **7A** End-of-day note model | Small | None |
| 20 | **7B** End-of-day note UI | Medium | 7A |
| 21 | **7C** Fulfillment graph | Medium | 7A |
| 22 | **7D** Journal view | Medium | 7A, 7B |

---

## Files Changed Summary

### New Files
- `Models/DayRecord.swift` — locked good day records
- `Models/EndOfDayNote.swift` — end-of-day reflections
- `Services/ReminderService.swift` — smart reminder scheduling
- `Services/UserSchedule.swift` — wake/bed time singleton
- `Views/Journal/JournalView.swift` — journal browser
- `Views/Journal/EndOfDayNoteView.swift` — note editor
- `Views/MonthGrid/HandDrawnDash.swift` — pre-creation dash symbol
- `Views/MonthGrid/GroupHobbyLogSheet.swift` — group hobby logs viewer

### Modified Files
- `Models/Habit.swift` — add `scheduleTimes`, `habitPrompt`
- `Models/DailyLog.swift` — `photoPaths: [String]` replaces `photoPath`
- `Models/HabitGroup.swift` — ensure mustDo default
- `Views/Onboarding/OnboardingData.swift` — DraftGroup, task pills, TimeOfDay expansion, remove Exercise
- `Views/Onboarding/HabitGenerator.swift` — auto-grouping logic, task pill generation
- `Views/Onboarding/Screens/ResponsibilitiesScreen.swift` — pill-based tasks
- `Views/Onboarding/Screens/CompleteScreen.swift` — create groups from onboarding
- `Views/Blocking/InterceptView.swift` — complete redesign (identity choice)
- `Views/MonthGrid/MonthGridView.swift` — pre-creation dash, group tap, locked good days
- `Views/Stats/StatsView.swift` — fulfillment graph
- `Views/Today/TodayView.swift` — celebration overlay timing
- `Views/Today/HobbyCompletionOverlay.swift` — 3 photo support
- `Views/MonthGrid/HobbyLogDetailSheet.swift` — 3 photos, edit support
- `Views/Detail/HabitDetailView.swift` — frequency edit, hobby prompt, hobby log edit
- `Views/MyHabits/AddGroupView.swift` — mustDo default
- `Services/NotificationService.swift` — smart reminders integration
- `ContentView.swift` — add Journal tab or entry point
