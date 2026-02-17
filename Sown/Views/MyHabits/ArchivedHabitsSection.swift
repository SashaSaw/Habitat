import SwiftUI

/// Collapsible section showing archived habits
struct ArchivedHabitsSection: View {
    @Bindable var store: HabitStore
    let habits: [Habit]
    let isLandscape: Bool
    let onSelectHabit: (Habit) -> Void
    let onUnarchive: (Habit) -> Void
    let onDelete: (Habit) -> Void

    @State private var isExpanded: Bool = false

    var body: some View {
        if !habits.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header with expand/collapse
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.custom("PatrickHand-Regular", size: 12))
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        Text("Archived")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        Text("(\(habits.count))")
                            .font(.custom("PatrickHand-Regular", size: 12))
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(JournalTheme.Colors.lineLight.opacity(0.5))
                            )

                        Spacer()
                    }
                    .padding(.leading, JournalTheme.Dimensions.marginLeft + 8)
                    .padding(.trailing, 16)
                }
                .buttonStyle(.plain)

                // Archived habits grid/hstack
                if isExpanded {
                    if isLandscape {
                        HabitIconHStack(
                            store: store,
                            habits: habits,
                            groups: [],
                            isArchived: true,
                            onSelectHabit: onSelectHabit,
                            onSelectGroup: { _ in },
                            onArchive: nil,
                            onUnarchive: onUnarchive,
                            onDelete: onDelete,
                            onDeleteGroup: { _ in }
                        )
                    } else {
                        HabitIconGrid(
                            store: store,
                            habits: habits,
                            groups: [],
                            isArchived: true,
                            onSelectHabit: onSelectHabit,
                            onSelectGroup: { _ in },
                            onArchive: nil,
                            onUnarchive: onUnarchive,
                            onDelete: onDelete,
                            onDeleteGroup: { _ in }
                        )
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}
