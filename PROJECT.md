# Habitat - Habit Tracker App

Created: February 2, 2026
Effort: 2 Weeks
Excitement: High
LinkedIn-ready?: No
Status: In Progress
Tech: Swift, SwiftUI, SwiftData, iOS

## Project Proposal - Habitat

### One-liner:

A journal-style habit tracker with a paper aesthetic that helps you build streaks, track "good days," and achieve your daily goals through satisfying swipe-to-complete interactions.

### Problem:

Existing habit trackers are either too complex or too boring:

- Overwhelming feature sets that distract from building habits
- Generic UI with no personality or delight
- No clear definition of what makes a "successful day"
- Habit groups (do X of Y options) are rarely supported

### Solution:

Habitat - an iOS app that:

1. **Journal aesthetic** - Lined paper background, hand-drawn checkmarks, pen-style strikethroughs that feel satisfying
2. **Smart habit tiers** - "Must-do" habits define your good day, "Nice-to-do" are bonus
3. **Flexible groups** - "Do something creative" = guitar OR drawing OR painting (pick 1 of 3)
4. **Swipe-to-complete** - Draw the strikethrough with your finger, feel the haptic feedback
5. **Good Day tracking** - See your month at a glance on graph paper

### Target User:

- People building daily routines
- Minimalists who want a focused, aesthetic tool

### MVP Features:

| Feature | Description |
| --- | --- |
| Today View | Lined paper with habits, swipe right to strikethrough, tap to undo |
| Habit Tiers | Must-do (required for good day) vs Nice-to-do (bonus) |
| Habit Types | Positive (do this) vs Negative (avoid this) |
| Habit Groups | Bundle habits with "complete X of Y" logic |
| Frequencies | Daily, X times per week, X times per month |
| Month Grid | Graph paper calendar showing good days at a glance |
| Streaks | Current streak and best streak per habit |
| Stats View | Completion rates, good day percentage, streaks |

### Future Features:

| Feature | Description |
| --- | --- |
| **Habit Agent (Conversational Onboarding)** | Chat-based habit creation instead of boring forms. "I've been meaning to go running but never get round to it" → Agent: "Let's add that! How often - once a week to start?" Feels like talking to a coach, not filling out a form. |
| **Habit Agent (Add New Habits)** | Same conversational flow anytime you want to add habits. Agent remembers your existing groups and suggests where new habits fit. No forms, just chat. |
| **Smart Scheduling** | Agent learns your routines from conversation. "I want to sleep by 11pm" → sets bedtime routine reminder. "I work 9-5" → schedules habits around work hours. |
| **Personalised Tips** | Agent analyses your goals and gives actionable advice. Like asking ChatGPT about dieting, but you also get the tracker, streaks, and visualisation all in one place. |
| **App Blocking** | "I want to use Instagram less" → Habitat blocks distracting apps during work hours or before bed. Integrates with Screen Time API. |
| Widgets | iOS home screen widgets showing today's progress |
| Apple Watch | Quick habit completion from your wrist |
| Notifications | Nudges at custom times |
| Data Export | Export habit data as CSV/JSON |
| Themes | Different paper styles (grid, dot grid, cream, white) |
| Habit Templates | Pre-built habit sets (Morning Routine, Fitness, etc.) |
| Notes | Add notes to completed habits ("ran 5k today!") |
| Skip Day | Mark a day as intentionally skipped (vacation, sick) |
| Habit Archive | Hide old habits without losing streak history |
| iCloud Sync | Sync across iPhone and iPad |
| Negative Habit Counters | "Days since last cigarette" style tracking |
| Weekly/Monthly Reviews | Reflection prompts on your progress |

### Habit Agent - Deep Dive

The core insight: **Forms are boring. People already struggle with habits - making them fill out forms to track them just adds friction.**

#### Onboarding Flow (First Launch)

Instead of empty state + "Add Habit" button:

```
Agent: "Hey! I'm here to help you build better habits.
        What's something you've been meaning to do but
        keep putting off?"

User:  "I want to go running but I never get round to it"

Agent: "Running! Great choice. How often would feel
        achievable? Once a week is a solid start."

User:  "Yeah once a week sounds good"

Agent: "Perfect. I've added 'Go running' - 1x per week.
        What else have you been meaning to start?"

User:  "I should probably read more instead of scrolling"

Agent: "I feel that. Let's add 'Read' - daily or a few
        times a week?"

[continues until user says they're done]
```

#### Adding Habits Later

Same conversational flow via a chat button. Agent remembers context:

```
Agent: "I see you've got an Exercise group with running
        and gym. Should I add swimming there too?"
```

#### Smart Future Features

1. **Schedule Detection**
   - "I work 9-5" → knows not to schedule habits during work
   - "I want to sleep by 11" → sets 10pm "wind down" reminder
   - "I'm a night owl" → adjusts "morning routine" expectations

2. **Tip Generation**
   - Analyses habits and conversation history
   - "You mentioned you scroll instead of reading - try keeping your book by your bed and phone in another room"
   - Like ChatGPT advice, but integrated with your tracker

3. **App Blocking Integration**
   - "I waste hours on TikTok" → offers to block during focus times
   - Uses iOS Screen Time API
   - Agent can suggest blocking schedules based on your goals

### Tech Stack:

- Framework: SwiftUI (iOS 17+)
- Persistence: SwiftData
- Architecture: MVVM with @Observable
- Animations: Custom Canvas drawings, spring animations
- Haptics: UIKit haptic feedback

### Screens:

1. Today View (lined paper, swipeable habits, groups)
2. Month Grid (graph paper calendar, good day indicators)
3. Stats (completion rates, streaks, charts)
4. Add/Edit Habit (name, tier, type, frequency, criteria)
5. Add/Edit Group (name, habits, require count)
6. Habit Detail (history, stats, edit/delete)

### LinkedIn Angle:

*"I wanted a habit tracker that felt like writing in a journal. So I built one with SwiftUI - complete with hand-drawn checkmarks and satisfying swipe-to-strikethrough. Here's what I learned about delightful UX in a weekend."*

---

## Current Implementation Status

### Completed:
- [x] Data models (Habit, HabitGroup, DailyLog)
- [x] SwiftData persistence
- [x] HabitStore view model
- [x] Today View with lined paper background
- [x] Swipe-to-complete gesture with real-time strikethrough
- [x] Tap-to-undo for completed habits
- [x] Habit groups with require count
- [x] Hand-drawn checkmarks and crosses
- [x] Haptic feedback on completion
- [x] Month Grid View (basic)
- [x] Stats View (basic)
- [x] Add/Edit Habit flow
- [x] Transparent tab bar and navigation

### In Progress:
- [ ] Swipe-to-delete for groups
- [ ] Empty group deletion prompt

### To Do:
- [ ] Good day celebration animation
- [ ] Streak display on Today View
- [ ] Polish Month Grid View
- [ ] Polish Stats View
- [ ] App icon
- [ ] Launch screen
