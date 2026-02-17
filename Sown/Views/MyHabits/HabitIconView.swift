import SwiftUI

/// Individual habit icon displayed in the My Habits grid
struct HabitIconView: View {
    let habit: Habit
    let isArchived: Bool
    let onTap: () -> Void

    private let iconSize: CGFloat = 72

    /// Custom image from data if available
    private var customImage: UIImage? {
        guard let data = habit.iconImageData else { return nil }
        return UIImage(data: data)
    }

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
            // Icon rounded square
            ZStack {
                if let customImage = customImage {
                    // Custom image icon
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(isArchived ? 0.4 : 1.0)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                } else {
                    // Default icon with emoji or initials
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundColor.opacity(isArchived ? 0.4 : 1.0))
                        .frame(width: iconSize, height: iconSize)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                    if let emoji = emoji {
                        Text(emoji)
                            .font(.custom("PatrickHand-Regular", size: 36))
                    } else {
                        Text(initials)
                            .font(.custom("PatrickHand-Regular", size: 24))
                            .foregroundStyle(.white)
                    }
                }
            }

            // Habit name — fixed height so icons stay aligned across the grid
            Text(displayName)
                .font(.custom("PatrickHand-Regular", size: 12))
                .foregroundStyle(isArchived ? JournalTheme.Colors.completedGray : JournalTheme.Colors.inkBlack)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(width: iconSize + 16, height: 32, alignment: .top)
        }
        .opacity(isArchived ? 0.6 : 1.0)
        .onTapGesture {
            onTap()
        }
    }

    /// Display name with emoji stripped (emoji is shown in the icon)
    private var displayName: String {
        habit.name.replacingOccurrences(of: emoji ?? "", with: "").trimmingCharacters(in: .whitespaces)
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
            // Icon rounded square with plus
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(JournalTheme.Colors.completedGray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: "plus")
                    .font(.custom("PatrickHand-Regular", size: 28))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }

            // Label — same fixed height as HabitIconView for alignment
            Text("Add Habit")
                .font(.custom("PatrickHand-Regular", size: 12))
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: iconSize + 16, height: 32, alignment: .top)
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
