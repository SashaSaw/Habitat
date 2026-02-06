import SwiftUI
import SwiftData

/// Main view displaying habits as app-like icons
struct MyHabitsView: View {
    @Bindable var store: HabitStore
    @State private var showingAddHabit = false
    @State private var showingAddGroup = false
    @State private var selectedHabit: Habit?
    @State private var habitToDelete: Habit?
    @State private var showDeleteConfirmation = false

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
                            showingAddHabit = true
                        } label: {
                            Label("Add Habit", systemImage: "plus.circle")
                        }

                        Button {
                            showingAddGroup = true
                        } label: {
                            Label("Add Group", systemImage: "folder.badge.plus")
                        }

                        Divider()

                        Button {
                            store.createSampleData()
                        } label: {
                            Label("Load Sample Data", systemImage: "tray.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(JournalTheme.Colors.inkBlue)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(store: store)
            }
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView(store: store)
            }
            .sheet(item: $selectedHabit) { habit in
                NavigationStack {
                    HabitDetailView(store: store, habit: habit)
                }
            }
            .alert("Delete Habit?", isPresented: $showDeleteConfirmation) {
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

                // Empty state
                if store.liveHabits.isEmpty && store.archivedHabits.isEmpty {
                    emptyState
                } else {
                    // Live habits section
                    if !store.liveHabits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACTIVE")
                                .font(JournalTheme.Fonts.sectionHeader())
                                .foregroundStyle(JournalTheme.Colors.sectionHeader)
                                .tracking(2)
                                .padding(.horizontal)

                            HabitIconGrid(
                                store: store,
                                habits: store.liveHabits,
                                isArchived: false,
                                onSelectHabit: { selectedHabit = $0 },
                                onArchive: { store.archiveHabit($0) },
                                onUnarchive: nil,
                                onDelete: { habit in
                                    habitToDelete = habit
                                    showDeleteConfirmation = true
                                }
                            )
                        }
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
                            showDeleteConfirmation = true
                        }
                    )
                }

                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Live habits - horizontal scroll
                if !store.liveHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACTIVE")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)
                            .padding(.horizontal)

                        HabitIconHStack(
                            store: store,
                            habits: store.liveHabits,
                            isArchived: false,
                            onSelectHabit: { selectedHabit = $0 },
                            onArchive: { store.archiveHabit($0) },
                            onUnarchive: nil,
                            onDelete: { habit in
                                habitToDelete = habit
                                showDeleteConfirmation = true
                            }
                        )
                    }
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
                        showDeleteConfirmation = true
                    }
                )
            }
            .padding(.vertical)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundStyle(JournalTheme.Colors.completedGray)

            Text("No habits yet")
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(JournalTheme.Colors.completedGray)

            Text("Tap + to add your first habit")
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    MyHabitsView(store: HabitStore(modelContext: try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
}
