import SwiftUI

/// Individual habit icon displayed in the My Habits grid
struct HabitIconView: View {
    let habit: Habit
    let isArchived: Bool
    let onTap: () -> Void

    private let iconSize: CGFloat = 72

    /// Extracts the first emoji from the habit name, or returns nil
    private var emoji: String? {
        for scalar in habit.name.unicodeScalars {
            if scalar.properties.isEmoji && scalar.properties.isEmojiPresentation {
                return String(scalar)
            }
            // Check for emoji with variation selector
            if scalar.properties.isEmoji {
                let char = Character(scalar)
                if char.isEmoji {
                    return String(char)
                }
            }
        }
        // Check for multi-scalar emojis
        for char in habit.name {
            if char.isEmoji {
                return String(char)
            }
        }
        return nil
    }

    /// Returns 1-2 letter initials from the habit name
    private var initials: String {
        let words = habit.name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count >= 2 {
            let first = words[0].prefix(1)
            let second = words[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    /// Background color based on habit tier
    private var backgroundColor: Color {
        switch habit.tier {
        case .mustDo:
            return JournalTheme.Colors.inkBlue
        case .niceToDo:
            return JournalTheme.Colors.goodDayGreenDark
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(backgroundColor.opacity(isArchived ? 0.4 : 1.0))
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 36))
                } else {
                    Text(initials)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            // Habit name
            Text(habit.name.replacingOccurrences(of: emoji ?? "", with: "").trimmingCharacters(in: .whitespaces))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isArchived ? JournalTheme.Colors.completedGray : JournalTheme.Colors.inkBlack)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: iconSize + 16)
        }
        .opacity(isArchived ? 0.6 : 1.0)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Character Extension for Emoji Detection

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

/// Add Habit button styled like a habit icon
struct AddHabitIconView: View {
    let onTap: () -> Void

    private let iconSize: CGFloat = 72

    var body: some View {
        VStack(spacing: 8) {
            // Icon circle with plus
            ZStack {
                Circle()
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                Circle()
                    .strokeBorder(JournalTheme.Colors.completedGray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }

            // Label
            Text("Add Habit")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: iconSize + 16)
        }
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    let habit = Habit(name: "Guitar", tier: .mustDo)
    return HabitIconView(habit: habit, isArchived: false, onTap: {})
}
