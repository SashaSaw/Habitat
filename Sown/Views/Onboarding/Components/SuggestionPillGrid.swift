import SwiftUI

/// Reusable toggle pill grid for onboarding suggestion selection
struct SuggestionPillGrid: View {
    let suggestions: [HabitSuggestion]
    @Binding var selectedNames: Set<String>
    @Binding var customPills: [String]

    var body: some View {
        FlowLayout(spacing: 10) {
            // Template suggestions
            ForEach(suggestions, id: \.name) { suggestion in
                SuggestionPill(
                    emoji: suggestion.emoji,
                    name: suggestion.name,
                    isSelected: selectedNames.contains(suggestion.name),
                    isCustom: false,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedNames.contains(suggestion.name) {
                                selectedNames.remove(suggestion.name)
                            } else {
                                selectedNames.insert(suggestion.name)
                            }
                        }
                        Feedback.selection()
                    }
                )
            }

            // User-added custom pills (always selected, tap to remove)
            ForEach(customPills, id: \.self) { name in
                SuggestionPill(
                    emoji: "\u{2728}",
                    name: name,
                    isSelected: true,
                    isCustom: true,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            customPills.removeAll { $0 == name }
                            selectedNames.remove(name)
                        }
                        Feedback.selection()
                    }
                )
            }
        }
    }
}

// MARK: - Add Custom Pill Field

struct AddCustomPillField: View {
    let placeholder: String
    @Binding var selectedNames: Set<String>
    @Binding var customPills: [String]

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Something else?")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.completedGray)

            HStack(spacing: 10) {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                    .focused($isFocused)
                    .onSubmit { addPill() }

                Button(action: addPill) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(trimmedText.isEmpty ? JournalTheme.Colors.lineLight : JournalTheme.Colors.navy)
                }
                .disabled(trimmedText.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(JournalTheme.Colors.paperLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isFocused ? JournalTheme.Colors.navy.opacity(0.4) : JournalTheme.Colors.lineLight, lineWidth: 1)
            )
        }
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespaces)
    }

    private func addPill() {
        guard !trimmedText.isEmpty else { return }
        let name = trimmedText

        // Don't add duplicates
        guard !selectedNames.contains(name) && !customPills.contains(name) else {
            text = ""
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            customPills.append(name)
            selectedNames.insert(name)
        }
        text = ""
        Feedback.selection()
    }
}

// MARK: - Individual Pill

private struct SuggestionPill: View {
    let emoji: String
    let name: String
    let isSelected: Bool
    let isCustom: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 15))
                Text(name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isSelected ? Color.white : JournalTheme.Colors.inkBlack)

                // Show X on custom pills to hint they can be removed
                if isCustom {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    isSelected ? JournalTheme.Colors.navy : Color.white.opacity(0.85)
                )
            )
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.clear : JournalTheme.Colors.lineLight,
                    lineWidth: 1
                )
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
