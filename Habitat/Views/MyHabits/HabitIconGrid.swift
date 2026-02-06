import SwiftUI

/// Grid layout for habit icons with drag-drop reordering
struct HabitIconGrid: View {
    @Bindable var store: HabitStore
    let habits: [Habit]
    let isArchived: Bool
    let onSelectHabit: (Habit) -> Void
    let onArchive: ((Habit) -> Void)?
    let onUnarchive: ((Habit) -> Void)?
    let onDelete: (Habit) -> Void

    @State private var draggingHabit: Habit?

    private let columns = [
        GridItem(.adaptive(minimum: 90, maximum: 100), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(habits) { habit in
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
                .draggable(habit.id.uuidString) {
                    HabitIconView(habit: habit, isArchived: isArchived, onTap: {})
                        .opacity(0.8)
                }
                .dropDestination(for: String.self) { items, _ in
                    guard let droppedId = items.first,
                          let droppedUUID = UUID(uuidString: droppedId),
                          let sourceIndex = habits.firstIndex(where: { $0.id == droppedUUID }),
                          let destIndex = habits.firstIndex(where: { $0.id == habit.id }),
                          sourceIndex != destIndex else {
                        return false
                    }

                    var reorderedHabits = habits
                    let movedHabit = reorderedHabits.remove(at: sourceIndex)
                    reorderedHabits.insert(movedHabit, at: destIndex)
                    store.reorderHabits(reorderedHabits)
                    return true
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Horizontal scroll layout for landscape mode
struct HabitIconHStack: View {
    @Bindable var store: HabitStore
    let habits: [Habit]
    let isArchived: Bool
    let onSelectHabit: (Habit) -> Void
    let onArchive: ((Habit) -> Void)?
    let onUnarchive: ((Habit) -> Void)?
    let onDelete: (Habit) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(habits) { habit in
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
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
