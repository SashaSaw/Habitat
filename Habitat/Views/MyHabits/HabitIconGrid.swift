import SwiftUI

/// Represents either a standalone habit or a group in the grid
enum GridItem: Identifiable {
    case habit(Habit)
    case group(HabitGroup)

    var id: UUID {
        switch self {
        case .habit(let habit): return habit.id
        case .group(let group): return group.id
        }
    }
}

/// Grid layout for habit and group icons with drag-drop to create groups
struct HabitIconGrid: View {
    @Bindable var store: HabitStore
    let habits: [Habit]
    let groups: [HabitGroup]
    let isArchived: Bool
    let onSelectHabit: (Habit) -> Void
    let onSelectGroup: (HabitGroup) -> Void
    let onArchive: ((Habit) -> Void)?
    let onUnarchive: ((Habit) -> Void)?
    let onDelete: (Habit) -> Void
    let onDeleteGroup: (HabitGroup) -> Void
    var onAddHabit: (() -> Void)? = nil

    @State private var dropTargetId: UUID? = nil

    private let columns = [
        SwiftUI.GridItem(.adaptive(minimum: 90, maximum: 100), spacing: 16)
    ]

    /// Standalone habits (not in any group)
    private var standaloneHabits: [Habit] {
        let groupedHabitIds = Set(groups.flatMap { $0.habitIds })
        return habits.filter { !groupedHabitIds.contains($0.id) }
    }

    /// Combined list of items to display
    private var gridItems: [GridItem] {
        var items: [GridItem] = []

        // Add groups first
        for group in groups {
            items.append(.group(group))
        }

        // Add standalone habits
        for habit in standaloneHabits {
            items.append(.habit(habit))
        }

        return items
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(gridItems) { item in
                switch item {
                case .habit(let habit):
                    habitIconWithDragDrop(habit: habit)

                case .group(let group):
                    groupIconWithDragDrop(group: group)
                }
            }

            // Add Habit button at the end (only for non-archived section)
            if !isArchived, let onAddHabit = onAddHabit {
                AddHabitIconView(onTap: onAddHabit)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Habit Icon with Drag/Drop

    @ViewBuilder
    private func habitIconWithDragDrop(habit: Habit) -> some View {
        HabitIconView(
            habit: habit,
            isArchived: isArchived,
            onTap: { onSelectHabit(habit) }
        )
        .scaleEffect(dropTargetId == habit.id ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: dropTargetId)
        .contextMenu {
            if isArchived {
                Button {
                    onUnarchive?(habit)
                } label: {
                    Label("Unarchive", systemImage: "arrow.up.bin")
                }
            } else {
                Button {
                    onArchive?(habit)
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            }

            Divider()

            Button(role: .destructive) {
                onDelete(habit)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .draggable(habit.id.uuidString) {
            HabitIconView(habit: habit, isArchived: isArchived, onTap: {})
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                )
                .opacity(0.9)
        }
        .dropDestination(for: String.self) { items, _ in
            dropTargetId = nil
            guard let droppedId = items.first,
                  let droppedUUID = UUID(uuidString: droppedId),
                  droppedUUID != habit.id,
                  let droppedHabit = habits.first(where: { $0.id == droppedUUID }) else {
                return false
            }

            // Create a new group from these two habits
            _ = store.createGroupFromHabits(droppedHabit, habit)
            return true
        } isTargeted: { isTargeted in
            dropTargetId = isTargeted ? habit.id : nil
        }
    }

    // MARK: - Group Icon with Drag/Drop

    @ViewBuilder
    private func groupIconWithDragDrop(group: HabitGroup) -> some View {
        GroupIconView(
            group: group,
            habits: store.allHabits,
            onTap: { onSelectGroup(group) }
        )
        .scaleEffect(dropTargetId == group.id ? 1.15 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: dropTargetId)
        .contextMenu {
            Button(role: .destructive) {
                onDeleteGroup(group)
            } label: {
                Label("Delete Group", systemImage: "trash")
            }
        }
        .dropDestination(for: String.self) { items, _ in
            dropTargetId = nil
            guard let droppedId = items.first,
                  let droppedUUID = UUID(uuidString: droppedId),
                  let droppedHabit = habits.first(where: { $0.id == droppedUUID }),
                  !group.habitIds.contains(droppedUUID) else {
                return false
            }

            // Add habit to this group
            store.addHabitToGroup(droppedHabit, group: group)
            return true
        } isTargeted: { isTargeted in
            dropTargetId = isTargeted ? group.id : nil
        }
    }
}

/// Horizontal scroll layout for landscape mode
struct HabitIconHStack: View {
    @Bindable var store: HabitStore
    let habits: [Habit]
    let groups: [HabitGroup]
    let isArchived: Bool
    let onSelectHabit: (Habit) -> Void
    let onSelectGroup: (HabitGroup) -> Void
    let onArchive: ((Habit) -> Void)?
    let onUnarchive: ((Habit) -> Void)?
    let onDelete: (Habit) -> Void
    let onDeleteGroup: (HabitGroup) -> Void
    var onAddHabit: (() -> Void)? = nil

    /// Standalone habits (not in any group)
    private var standaloneHabits: [Habit] {
        let groupedHabitIds = Set(groups.flatMap { $0.habitIds })
        return habits.filter { !groupedHabitIds.contains($0.id) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                // Groups first
                ForEach(groups) { group in
                    GroupIconView(
                        group: group,
                        habits: store.allHabits,
                        onTap: { onSelectGroup(group) }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            onDeleteGroup(group)
                        } label: {
                            Label("Delete Group", systemImage: "trash")
                        }
                    }
                }

                // Standalone habits
                ForEach(standaloneHabits) { habit in
                    HabitIconView(
                        habit: habit,
                        isArchived: isArchived,
                        onTap: { onSelectHabit(habit) }
                    )
                    .contextMenu {
                        if isArchived {
                            Button {
                                onUnarchive?(habit)
                            } label: {
                                Label("Unarchive", systemImage: "arrow.up.bin")
                            }
                        } else {
                            Button {
                                onArchive?(habit)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            onDelete(habit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                // Add Habit button at the end (only for non-archived section)
                if !isArchived, let onAddHabit = onAddHabit {
                    AddHabitIconView(onTap: onAddHabit)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
