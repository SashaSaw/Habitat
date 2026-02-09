# Implementation Brief: App Redesign

## Overview
This document describes a set of UX and feature changes to the habit tracker app. The goal is to simplify the user experience, reduce cognitive load, add support for one-off tasks, redesign the day view, replace groups with a simpler "options" concept, and implement the app blocking feature — the core differentiator that turns the app from a habit tracker into a phone addiction solution. The app has a paper journal aesthetic (cream backgrounds, ruled lines, serif fonts, navy accents) — all changes must preserve this.

Read through this entire document before making any changes. Then implement each section in order, testing as you go.

---

## 1. Simplified Add Flow (Priority: High)

### Problem
The current add-habit flow asks the user to make too many decisions upfront: name, description, positive/negative, must-do/nice-to-do, hobby or not, frequency type, frequency details, notification schedule. That's ~8 decisions per item. The target user is someone who's overwhelmed — they won't fill all this in.

### New Design: Two-Tier Progressive Disclosure

**Tier 1 (what the user sees by default):**
- A text input for the habit name (placeholder: "e.g. Read for 30 min, Buy butter...")
- A set of quick-pick suggestions shown when the input is empty (Read, Exercise, Meditate, Journal, No scrolling, Drink water, Cook a meal, Call family — each with an emoji and a preset frequency)
- A frequency selector with four options as pill buttons: **"Just today"** | **"Every day"** | **"Weekly"** | **"Monthly"**
  - "Just today" is for one-off tasks (see Section 2 below). When selected, hide ALL advanced options — tasks don't need them. Change the submit button text to "Add to today" and show a small info note: "One-off task · won't affect your streak"
  - "Every day" = daily, no further config needed
  - "Weekly" = expands to show either day-of-week selector circles (M T W T F S S) OR a simple "X times a week" counter. Both options visible at once with an "Or just" separator
  - "Monthly" = expands to show an "X times a month" counter
- A submit button ("Add habit" for recurring, "Add to today" for one-off tasks)

**Tier 2 (collapsed under "More options", hidden by default, hidden entirely for "Just today" tasks):**
- Priority: "Must do" (default) or "Nice to do" — pill selector
- Type: "Build a habit" (default) or "Quit a habit" — pill selector
- Reminders toggle with description "Get notified to do this"
- Notes & photos toggle with description "Journal about this when done"

**Smart defaults (applied automatically, user can change in Tier 2):**
- Priority: Must do
- Type: Build a habit  
- Reminders: Off
- Notes & photos: Off

**Key principle:** A user should be able to go from opening the add screen to having a trackable habit in 2 taps (type name → tap "Add habit"). Quick picks make it possible in 2 taps with zero typing.

### What to remove from the current add flow
- Remove the "description" field from the initial add flow (can be added later from the habit detail page)
- Remove the "hobby" toggle entirely — instead, make notes & photos available on everything as an optional toggle
- Remove the "positive/negative" toggle — replace with the simpler "Build a habit / Quit a habit" framing, and move it to the collapsed advanced section
- Remove notification scheduling from the add flow — move it to the habit's detail page, accessible after creation

---

## 2. One-Off Tasks ("Just Today")

### Concept
Users need to add things like "Buy butter" or "Call dentist" that are specific to today and don't repeat. These are NOT habits — they're tasks. They should appear on the day list alongside habits but be visually distinct and not affect the good-day streak.

### Implementation

**Data model:**
- Tasks use the same underlying model as habits but with a frequency of "once" or equivalent
- Tasks have: name, done/not done, creation date
- Tasks do NOT have: priority (never count as must-do), options, reminders, notes/photos
- Tasks should be cleaned up after the day ends (either deleted or archived). If not completed, you can decide whether to roll them over to the next day or discard them — rolling over is probably better UX

**On the day view:**
- Tasks appear in their own section labelled "Today Only" with a teal accent colour
- Tasks use a **square checkbox with rounded corners** (border-radius ~6px) to visually distinguish from habits which use **round checkboxes** (fully circular)
- Tasks display a small "TODAY" badge in teal
- When completed, tasks move to the "Done" section at the bottom like everything else
- Tasks do NOT count toward the good-day streak or must-do completion

**On the add flow:**
- "Just today" is a frequency option alongside daily/weekly/monthly
- When selected: hide the "More options" section entirely, change button to "Add to today", show info text explaining it won't affect the streak

---

## 3. Redesigned Day View (Priority: High)

### New Section Structure (top to bottom)

1. **Header:** "Today" title + day/date subtitle (matches current design)

2. **Streak tracker bar:** A coloured banner showing:
   - "X/Y must-dos complete" with a fire emoji — amber/gold background when incomplete
   - "🔥 Good day! All must-dos done" — green background when all must-dos are complete
   - Current streak count and "keep it going!" text
   - This replaces needing to go to the stats page to see streak status

3. **"★ Must Do" section:** All must-do habits for today, with amber/gold section label

4. **"Nice To Do" section:** Non-must-do habits, with default muted section label

5. **"◇ Today Only" section:** One-off tasks, with teal section label and a count badge

6. **"Done ✓" section:** All completed items (both habits and tasks) at reduced opacity with strikethrough. Must-do items that are completed should show inline in the must-do section (struck through) rather than moving down, so the user can see their must-do progress at a glance. Non-must-do completed items move to this bottom section.

7. **Quick add bar:** A dashed-border "Add a habit or task..." prompt at the bottom that opens the add flow

### Interaction
- Tapping a habit toggles its done state (or opens the options picker if it has options — see Section 4)
- The swipe-to-cross-off mechanic should be preserved for completing items
- The strikethrough line style should match the existing journal aesthetic
- The streak tracker bar should update in real-time as items are checked off

### Colour System for the Day View
- **Amber/gold** (#D4A028 area): Must-do labels, streak bar when incomplete
- **Teal** (#4A9B8E area): Today-only task labels, badges, and checkboxes
- **Green** (#5B9A5F area): Streak bar when all must-dos complete
- **Navy** (#1E2A4A): Completed checkmarks, primary text, core UI elements
- These colours should feel natural on the cream paper background — keep them muted, not saturated

---

## 4. Groups — Improved Day View Behaviour (Priority: High)

### What groups are (keeping the existing concept)
Groups stay as they are: a parent habit (typically must-do) that contains sub-habits (nice-to-dos). The parent represents something like "Exercise" and the sub-habits are the different ways to do it: Gym, Swim, Run. Completing any ONE sub-habit satisfies the parent group for that day.

Groups also support a "hobby" mode where sub-habits can have notes and photos attached — this is valuable for things like creative hobbies where the user might want to journal about what they did (e.g. a "Creative" group with sub-habits "Draw", "Paint", "Write" where each supports photo capture).

### Problem with current day view
Currently, when a group appears on the day view, the relationship between the parent and sub-habits isn't clear enough. It's not obvious that completing one sub-habit satisfies the parent, and the list gets visually cluttered with expanded sub-habits that are no longer relevant once one is done.

### New Day View Behaviour for Groups

**Default (uncompleted) state:**
- The parent group habit shows on the day list in its normal position (e.g. under "★ Must Do" if it's a must-do)
- Below the parent, the sub-habits are shown indented slightly (left padding/margin to indicate nesting) with their own checkboxes
- The parent itself does NOT have a checkbox — it's a header for the sub-habits. It shows a small badge indicating how many sub-options exist (e.g. "3 options")
- Sub-habits are visually lighter/secondary compared to standalone habits — slightly smaller text or muted styling to show they belong to the parent

**When a sub-habit is completed (the key interaction):**
- The completed sub-habit gets the strikethrough/cross-off treatment (same swipe mechanic as other habits)
- The parent group COLLAPSES — all the other uncompleted sub-habits animate closed/hidden
- The parent now shows as completed (struck through) with the chosen sub-habit noted in italic after the name: e.g. "Exercise — Gym" with strikethrough
- The parent's checkbox (which now appears since it's resolved) shows as checked
- This collapse should be animated — a smooth height transition so the sub-habits fold up into the parent. This is the satisfying moment: you did one thing, and a whole block of your list resolves

**Uncollapsing / changing your mind:**
- Tapping a collapsed, completed group should expand it again and un-mark it — letting the user change which sub-habit they did, or undo the completion entirely
- This follows the same undo pattern as tapping any completed habit to un-complete it

**Data tracking:**
- When a sub-habit is completed, record both the parent group completion AND which specific sub-habit was chosen
- Stats should track each sub-habit's completions separately (e.g. "you did Gym 12 times, Swim 5 times, Run 3 times this month")
- The parent group's completion counts toward the good-day streak and must-do tracking as normal

### Introducing the concept to new users

Groups are more complex than regular habits, so new users need a gentle introduction. Add an explanatory callout in two places:

**On the My Habits page (near the group tiles or as a first-time tooltip):**
- A card/callout with a lightbulb icon: "💡 **Habit groups** — Some habits have multiple ways to do them. 'Exercise' might be gym, swimming, or a run. Create a group and add your options as sub-habits. Complete any one to tick off the group for the day."
- This should show the first time the user visits the My Habits page (or until dismissed). After that, it can be hidden but accessible from a "?" or info icon.

**When creating a group (in the add flow or group creation):**
- A brief inline explanation: "Add the different ways you can do this habit. Completing any one counts as doing the whole thing."
- Keep it to one sentence — don't over-explain.

**On the day view (first time a group appears):**
- A subtle one-time tooltip or hint on the first group the user sees: "Complete any one of these to tick off [Group Name]" — dismissable, shown once.

---

## 5. My Habits Page Changes (Priority: Medium)

### Keep
- The icon grid layout (tiles with emoji/abbreviation, colour, and name)
- The "Add Habit" tile with dashed border
- The "Archived" section at the bottom
- **Group tiles** — groups remain as a concept. The group tile on the grid should continue to show the sub-habit letter badges (e.g. G, S, R stacked in the corner) so users can see at a glance which habits are groups with sub-options

### Change
- **Improved group tile appearance:** Group tiles should be visually distinguishable from regular habit tiles. Keep the existing stacked letter badges for sub-habits. Consider a subtle visual cue on the tile itself — e.g. a small corner fold, a slightly different border, or the word "group" in tiny text — so users learn to recognise them. Don't overdo this; the letter badges may be enough.

- **Group detail/edit page:** When tapping a group tile, show a detail page with:
  - Group header: icon, group name, priority badge, frequency badge
  - **Sub-habits list:** Each sub-habit shown as a row with its name. Each row is tappable to edit the sub-habit's name. Rows can be reordered or deleted.
  - **"+ Add sub-habit" button** (dashed border style) to add new options to the group
  - **Explanatory callout:** "Complete any one of these sub-habits to tick off [Group Name] for the day. Stats track each one separately."
  - **Hobby toggle:** A toggle for "Enable notes & photos" — when on, completing a sub-habit from this group prompts the user to optionally add notes/photos about what they did. This is the hobby mode.
  - Settings list: Priority, Frequency, Reminders — each as a tappable row showing current value
  - "Archive this group" action at the bottom
  - Back button to return to the grid

- **Regular habit detail page:** When tapping a non-group habit tile, show a simpler detail page:
  - Habit header: icon, name, priority badge, frequency badge
  - Settings list: Priority, Frequency, Reminders, Notes & photos — each as a tappable row showing current value
  - "Archive this habit" action at the bottom
  - Back button to return to the grid

- **Creating a new group:** The add flow should support creating groups. This could be:
  - A toggle or option during habit creation: after entering the habit name, an option like "This has sub-options" or "Add variations" that expands to let you add sub-habit names
  - OR a separate "Create group" path from the My Habits page (a second add button or a choice when tapping the main add button: "Add habit" vs "Add group")
  - Either way, the group creation should include the explanatory text: "Add the different ways you can do this habit. Completing any one counts as doing the whole thing."

---

## 6. App Blocking — Block Setup (Priority: High)

### Concept
The app's core differentiator is the connection between blocking distracting apps and surfacing habits. When a user tries to open a blocked app (Instagram, TikTok, etc.), instead of a generic "this app is blocked" wall, they see their habit list for today. This is the feature that ties the whole product together — the blocker IS the habit tracker's front door.

### Block Setup Screen

Add a new screen accessible from settings or onboarding (not a main tab — it's a configure-once-and-forget screen).

**Layout:**
1. **Header:** "Block apps" title + subtitle "Choose apps to block during focus hours"

2. **Block schedule card:** A card showing the current block window (e.g. "9:00 AM → 9:00 PM") with an "Edit" button. Tapping edit should open a time range picker where the user sets start and end times. Default to 9:00 AM → 9:00 PM as a sensible starting point.

3. **App selection list:** A scrollable list of common social/distraction apps. Each row shows:
   - App icon (use the app's brand colour as background with an emoji placeholder, or load the actual app icon if possible on the platform)
   - App name
   - A toggle/checkbox on the right — coral/red background with ✕ when blocked, empty outline when not blocked
   - Tapping a row toggles its blocked state
   
   **Default app list to include:**
   - Instagram, TikTok, Twitter/X, YouTube, Reddit, Facebook, Snapchat, Pinterest
   - Ideally also allow the user to add any other installed app (platform-dependent — on iOS this may require Screen Time API, on Android UsageStats)

4. **Info callout at bottom:** "💡 When you try to open a blocked app, you'll see your habits for today instead — a nudge to do something meaningful."

**Data model:**
- Store a list of blocked app identifiers (bundle IDs on iOS, package names on Android)
- Store the block schedule as start time + end time + active days (default: every day)
- Store a boolean for whether blocking is enabled globally

**Visual style:**
- Same journal aesthetic as the rest of the app
- Blocked apps use coral/red colouring (matches the ✕ crosses on the month view — red = things you're saying no to)
- The schedule card uses the standard paper-light card style

---

## 7. App Blocking — Intercept Screen (Priority: High)

### Concept
This is THE key screen of the entire app. When the user tries to open a blocked app during the block schedule, the OS redirects them to this screen instead. It should feel like a gentle nudge, not a punishment. The tone is: "You've got better things to do — here they are."

### Layout (top to bottom)

1. **Blocked app indicator:** A row showing the blocked app's icon + "Instagram is blocked" + "Until [end time] · Xh Xm left". This acknowledges what happened without being preachy.

2. **Motivation banner:** An amber/gold card showing:
   - "You've got X things left today" (count of all undone habits + tasks)
   - "Complete your must-dos to keep your [N]-day streak 🔥"
   - This creates urgency around the streak without being aggressive

3. **"★ Must Do" section:** Undone must-do habits, each as a tappable card/row. Tapping a habit navigates to a **focus mode** (see below). These are the primary action — the thing we most want the user to do instead of scrolling.

4. **"◇ Today's tasks" section:** Undone one-off tasks shown in their teal style. These are NOT tappable into focus mode (tasks are quick actions, not focus sessions) but are visible as a reminder. The user can tick them off directly from this screen.

5. **"Done ✓" section:** Completed items at reduced opacity, same as the day view.

6. **Override button (intentionally de-emphasised):** At the very bottom, small muted text: "Use Instagram anyway →". This is deliberately understated — small font, low contrast, no button styling. When tapped, it does NOT immediately open the app. Instead it changes to: "Are you sure? Tap again to use for 5 min." Requiring a double-tap adds just enough friction to make the user reconsider without feeling like a prison. If tapped again, grant a 5-minute temporary unlock for that specific app, after which the block resumes.

### Focus Mode (launched from intercept)

When the user taps a habit from the intercept screen, they enter a focus mode:

1. **Habit display:** Large emoji + habit name centred on screen
2. **Message:** "Instead of scrolling, spend some time on this."
3. **Optional focus timer:** A timer selector (default 25 min, adjustable in 5-min increments with +/- buttons) with a "Start focusing" button. When running, the timer shows a large countdown display.
4. **Skip timer option:** "Mark as done (no timer)" button below the timer — for habits that don't need timed focus (like "Floss")
5. **During timer:** Show "Phone is locked to other apps" message + a "Done — I did it" button (green/success styling) and a small "End session early" link
6. **On completion:** Show a celebration screen — "Nice work!" + habit name + "X things left today" + streak status. Then a "Back to habits" button that returns to the intercept screen.

If the habit has options (see Section 4), the option picker should appear before/during the completion flow — ask "Which one did you do?" before marking done.

### Technical Implementation Notes

**Platform considerations:**
- **iOS:** This likely requires integration with the Screen Time API (FamilyControls / ManagedSettings frameworks) to block apps and present a custom shield view. The intercept screen would be implemented as a ShieldConfigurationExtension. Research the latest iOS APIs for app blocking — the DeviceActivityMonitor and ShieldAction protocols are relevant. Note: Apple restricts what UI you can show in shield views, so the full intercept layout may need to be a deep link back into the main app.
- **Android:** Use UsageStatsManager to detect app launches and an accessibility service or overlay to intercept. The intercept screen can be a full activity launched over the blocked app.
- **Both platforms:** The block schedule should run as a background process/extension. The temporary 5-minute unlock needs a timer that re-engages the block automatically.

**The intercept screen should reuse the day view's data.** It's showing the same habits and tasks as the Today tab, just in a different context. Don't duplicate the data source — read from the same store.

**Focus timer state:** The timer should continue running even if the user backgrounds the app. Use a background timer/notification. When the timer completes, send a local notification congratulating them and asking if they completed the habit.

---

## 8. App Blocking — Integration with Day View (Priority: Medium)

### How blocking connects to the rest of the app

The intercept screen is essentially a filtered, contextual version of the day view. To keep things connected:

- **Completing a habit from the intercept screen should update the day view.** Same data, same state. If the user marks "Exercise — Gym" as done from the intercept, it should show as done on the Today tab too.
- **The streak tracker on the intercept should show the same data** as the day view's streak bar. Same must-do count, same streak number.
- **After completing all habits from the intercept**, the motivation banner should update to something celebratory: "🔥 All done! Your streak is safe." The override button could also change to allow freer access since the user has earned it.
- **On the day view**, consider showing a small indicator of blocked apps status — something subtle like "🔒 3 apps blocked until 9 PM" at the top, tappable to go to block setup. This reinforces the connection without cluttering the view.

### Block status in the app

Add a way to access the block setup from within the app. Options:
- A settings/gear icon somewhere accessible (e.g. on the My Habits page or as a settings tab)
- Or a small "🔒 Blocking active" banner on the Today view that links to setup
- Don't add it as a main tab — blocking is a set-and-forget feature, not something you interact with daily

## 9. What NOT to Change
- The Month view (grid of days × habits with ticks and crosses) — leave as-is
- The Stats page — leave as-is, but one-off tasks should NOT appear in stats
- The overall journal aesthetic (cream paper, ruled lines, red margin line, serif fonts, navy accents)
- The tab bar structure (Today, My Habits, Month, Stats)
- The app's existing navigation patterns

---

## Implementation Order
1. Update the data model to support one-off tasks (frequency: "once"), sub-habit completion tracking on groups (which sub-habit was chosen + timestamp), and blocked apps configuration (app identifiers, schedule, enabled state)
2. Implement the new add flow with progressive disclosure and "Just today" support
3. Implement the new day view with sections, streak tracker, and the group collapsing behaviour (completing a sub-habit collapses the group and marks the parent done)
4. Update the My Habits page — improved group tiles, group detail/edit page with sub-habit management and hobby toggle, regular habit detail page
5. Add the "introducing groups" explanatory callouts (My Habits page, group creation, first-time day view tooltip)
6. Implement the block setup screen (app selection, schedule configuration)
7. Implement the app intercept screen (blocked app view, habit list, override flow)
8. Implement focus mode (timer, habit completion from intercept, celebration screen)
9. Wire up platform-level app blocking (Screen Time API on iOS / UsageStats on Android) to trigger the intercept screen
10. Ensure intercept screen shares state with day view — completing habits from either location updates both
11. Test the full flow end-to-end: add a group with sub-habits → see it on day view with sub-habits expanded → complete a sub-habit → verify group collapses with "Exercise — Gym" strikethrough → verify streak updates → tap collapsed group to uncollapse and undo → block an app → try to open blocked app → see intercept → tap habit → focus timer → complete → verify 5-min override works → verify stats track sub-habit separately

---

## Summary of Colour Language (for reference)
| Colour | Hex | Usage |
|--------|-----|-------|
| Amber/Gold | #D4A028 | Must-do labels, streak bar (incomplete), ★ star, intercept motivation banner |
| Teal | #4A9B8E | Today-only tasks, "TODAY" badges, task checkboxes |
| Green | #5B9A5F | Streak bar (all must-dos complete), success states, focus timer completion |
| Navy | #1E2A4A | Core UI, checkmarks, primary text, buttons, focus timer display |
| Coral | #D4836A | Crosses on month view, "quit a habit" type, blocked app indicators, archive/delete |
| Paper | #F5EDDA | Background |
| Paper Light | #FAF6EC | Card backgrounds, input backgrounds |
