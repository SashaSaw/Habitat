import SwiftUI
import SwiftData

/// Main view displaying habits as app-like icons
struct MyHabitsView: View {
    @Bindable var store: HabitStore
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var selectedGroup: HabitGroup?
    @State private var habitToDelete: Habit?
    @State private var groupToDelete: HabitGroup?
    @State private var showDeleteHabitConfirmation = false
    @State private var showDeleteGroupConfirmation = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Paper background
                    LinedPaperBackground(lineSpacing: JournalTheme.Dimensions.lineSpacing)

                    if isLandscape {
                        // Landscape: horizontal scroll
                        landscapeLayout
                    } else {
                        // Portrait: vertical scroll with grid
                        portraitLayout
                    }
                }
            }
            .navigationTitle("My Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            store.createSampleData()
                        } label: {
                            Label("Load Sample Data", systemImage: "tray.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(JournalTheme.Colors.inkBlue)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(store: store)
            }
            .sheet(item: $selectedHabit) { habit in
                NavigationStack {
                    HabitDetailView(store: store, habit: habit)
                }
            }
            .sheet(item: $selectedGroup) { group in
                GroupDetailSheet(
                    group: group,
                    store: store,
                    onDismiss: { selectedGroup = nil }
                )
            }
            .alert("Delete Habit?", isPresented: $showDeleteHabitConfirmation) {
                Button("Cancel", role: .cancel) {
                    habitToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let habit = habitToDelete {
                        store.deleteHabit(habit)
                    }
                    habitToDelete = nil
                }
            } message: {
                Text("This will permanently delete '\(habitToDelete?.name ?? "")' and all its history.")
            }
            .alert("Delete Group?", isPresented: $showDeleteGroupConfirmation) {
                Button("Cancel", role: .cancel) {
                    groupToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let group = groupToDelete {
                        store.deleteGroup(group)
                    }
                    groupToDelete = nil
                }
            } message: {
                Text("This will delete the group '\(groupToDelete?.name ?? "")'. The habits inside will not be deleted.")
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title section
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Habits")
                        .font(JournalTheme.Fonts.title())
                        .foregroundStyle(JournalTheme.Colors.inkBlack)

                    Text("\(store.liveHabits.count) active habits")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                }
                .padding(.horizontal)
                .padding(.top, 16)

                // Live habits section (always show to include Add button)
                VStack(alignment: .leading, spacing: 12) {
                    if !store.liveHabits.isEmpty || !store.groups.isEmpty {
                        Text("ACTIVE")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)
                            .padding(.horizontal)
                    }

                    HabitIconGrid(
                        store: store,
                        habits: store.liveHabits,
                        groups: store.groups,
                        isArchived: false,
                        onSelectHabit: { selectedHabit = $0 },
                        onSelectGroup: { selectedGroup = $0 },
                        onArchive: { store.archiveHabit($0) },
                        onUnarchive: nil,
                        onDelete: { habit in
                            habitToDelete = habit
                            showDeleteHabitConfirmation = true
                        },
                        onDeleteGroup: { group in
                            groupToDelete = group
                            showDeleteGroupConfirmation = true
                        },
                        onAddHabit: { showingAddHabit = true }
                    )
                }

                // Archived habits section
                ArchivedHabitsSection(
                    store: store,
                    habits: store.archivedHabits,
                    isLandscape: false,
                    onSelectHabit: { selectedHabit = $0 },
                    onUnarchive: { store.unarchiveHabit($0) },
                    onDelete: { habit in
                        habitToDelete = habit
                        showDeleteHabitConfirmation = true
                    }
                )

                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Live habits - horizontal scroll (always show to include Add button)
                VStack(alignment: .leading, spacing: 8) {
                    if !store.liveHabits.isEmpty || !store.groups.isEmpty {
                        Text("ACTIVE")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)
                            .padding(.horizontal)
                    }

                    HabitIconHStack(
                        store: store,
                        habits: store.liveHabits,
                        groups: store.groups,
                        isArchived: false,
                        onSelectHabit: { selectedHabit = $0 },
                        onSelectGroup: { selectedGroup = $0 },
                        onArchive: { store.archiveHabit($0) },
                        onUnarchive: nil,
                        onDelete: { habit in
                            habitToDelete = habit
                            showDeleteHabitConfirmation = true
                        },
                        onDeleteGroup: { group in
                            groupToDelete = group
                            showDeleteGroupConfirmation = true
                        },
                        onAddHabit: { showingAddHabit = true }
                    )
                }

                // Archived habits
                ArchivedHabitsSection(
                    store: store,
                    habits: store.archivedHabits,
                    isLandscape: true,
                    onSelectHabit: { selectedHabit = $0 },
                    onUnarchive: { store.unarchiveHabit($0) },
                    onDelete: { habit in
                        habitToDelete = habit
                        showDeleteHabitConfirmation = true
                    }
                )
            }
            .padding(.vertical)
        }
    }

}

#Preview {
    MyHabitsView(store: HabitStore(modelContext: try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
}
