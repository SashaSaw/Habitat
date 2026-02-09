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
    @AppStorage("hasSeenGroupCallout") private var hasSeenGroupCallout = false
    @State private var showGroupCallout = false

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
            .navigationBarHidden(true)
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
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // First-time group explanatory callout
                if showGroupCallout && !store.groups.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        Text("💡")
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Habit groups")
                                .font(JournalTheme.Fonts.handwritten(size: 15))
                                .fontWeight(.semibold)
                                .foregroundStyle(JournalTheme.Colors.inkBlack)

                            Text("Some habits have multiple ways to do them. \"Exercise\" might be gym, swimming, or a run. Create a group and add your options as sub-habits. Complete any one to tick off the group for the day.")
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.sectionHeader)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showGroupCallout = false
                                hasSeenGroupCallout = true
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(JournalTheme.Colors.amber.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(JournalTheme.Colors.amber.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Live habits section (always show to include Add button)
                VStack(alignment: .leading, spacing: 12) {
                    if !store.liveHabits.isEmpty || !store.groups.isEmpty {
                        Text("ACTIVE")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)
                            .padding(.leading, 24)
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
            .onAppear {
                if !hasSeenGroupCallout && !store.groups.isEmpty {
                    withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                        showGroupCallout = true
                    }
                }
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
