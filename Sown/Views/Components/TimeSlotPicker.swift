import SwiftUI

/// Reusable picker for selecting which time-of-day slots a habit belongs to.
/// Displays the 5 schedule slots as tappable pills — multiple can be selected.
struct TimeSlotPicker: View {
    @Binding var selectedSlots: Set<String>

    /// The 5 schedule time slots (matches DraftHabit.TimeOfDay raw values)
    private static let slots: [(rawValue: String, label: String, emoji: String)] = [
        ("After Wake", "After Wake", "🌅"),
        ("Morning", "Morning", "☀️"),
        ("During the Day", "Daytime", "📋"),
        ("Evening", "Evening", "🌙"),
        ("Before Bed", "Before Bed", "😴"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Wrap pills in a flow layout
            FlowLayout(spacing: 8) {
                ForEach(Self.slots, id: \.rawValue) { slot in
                    slotPill(slot)
                }
            }
        }
    }

    private func slotPill(_ slot: (rawValue: String, label: String, emoji: String)) -> some View {
        let isSelected = selectedSlots.contains(slot.rawValue)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isSelected {
                    selectedSlots.remove(slot.rawValue)
                } else {
                    selectedSlots.insert(slot.rawValue)
                }
            }
            Feedback.selection()
        } label: {
            HStack(spacing: 5) {
                Text(slot.emoji)
                    .font(.custom("PatrickHand-Regular", size: 13))
                Text(slot.label)
                    .font(.custom("PatrickHand-Regular", size: 13))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected
                        ? JournalTheme.Colors.navy.opacity(0.1)
                        : JournalTheme.Colors.paperLight)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected
                            ? JournalTheme.Colors.navy.opacity(0.4)
                            : JournalTheme.Colors.lineLight,
                        lineWidth: 1
                    )
            )
            .foregroundStyle(isSelected
                ? JournalTheme.Colors.navy
                : JournalTheme.Colors.completedGray)
        }
        .buttonStyle(.plain)
    }
}
