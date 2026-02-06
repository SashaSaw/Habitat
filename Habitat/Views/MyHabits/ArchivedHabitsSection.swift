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
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        Text("Archived")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        Text("(\(habits.count))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(JournalTheme.Colors.lineLight.opacity(0.5))
                            )

                        Spacer()
                    }
                    .padding(.horizontal)
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
