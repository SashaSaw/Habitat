# Claude Code Guidelines for Sown

## Xcode Instructions

When providing Xcode instructions:

- **Keep steps atomic and simple** - one action per step
- **Explain core concepts first** - before diving into implementation, explain what we're doing and why
- **Describe the overall flow** - how changes affect the app's behavior
- **Assume beginner level** - this is the user's first time using Xcode
- **Use exact menu paths** - e.g., "Click File > New > File" not "create a new file"
- **Reference UI elements clearly** - describe where things are located on screen
- **Verify UI for Xcode 16+** - UI has changed significantly; always use keyboard shortcuts as fallback

### Common Xcode Operations (Xcode 16+)

| Action | How to do it |
|--------|--------------|
| Open Library (UI elements) | Press **Cmd+Shift+L** |
| Add constraints | Select view, then **Editor > Resolve Auto Layout Issues** or click constraints icon at bottom of canvas |
| Show/hide sidebars | **Cmd+0** (left), **Cmd+Option+0** (right) |
| Show Attributes Inspector | **Cmd+Option+4** |
| Show Size Inspector | **Cmd+Option+5** |
| Clean Build | **Cmd+Shift+K** |
| Build & Run | **Cmd+R** |

## App Architecture

- **SwiftUI** app using **SwiftData** for persistence
- **@Observable** pattern for state management via `HabitStore`
- Custom **PatrickHand** handwritten font throughout
- Journal/paper aesthetic with lined backgrounds

## Key Files

- `HabitStore.swift` - Central state management
- `JournalTheme.swift` - Colors, fonts, dimensions, Feedback enum
- `SoundEffectService.swift` - Audio playback
- Models in `/Models` - Habit, DailyLog, HabitGroup, etc.
