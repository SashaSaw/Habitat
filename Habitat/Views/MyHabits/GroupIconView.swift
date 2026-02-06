import SwiftUI

/// Group icon displayed like an iOS folder with mini habit previews
struct GroupIconView: View {
    let group: HabitGroup
    let habits: [Habit]
    let onTap: () -> Void

    private let iconSize: CGFloat = 72

    /// Get habits that belong to this group
    private var groupHabits: [Habit] {
        habits.filter { group.habitIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Folder-style icon with mini habit previews
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                // Mini habit grid (2x2)
                let previewHabits = Array(groupHabits.prefix(4))
                LazyVGrid(columns: [
                    SwiftUI.GridItem(.fixed(24), spacing: 4),
                    SwiftUI.GridItem(.fixed(24), spacing: 4)
                ], spacing: 4) {
                    ForEach(previewHabits) { habit in
                        MiniHabitIcon(habit: habit)
                    }

                    // Fill empty slots
                    ForEach(0..<max(0, 4 - previewHabits.count), id: \.self) { _ in
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(8)
            }

            // Group name
            Text(group.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(JournalTheme.Colors.inkBlack)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: iconSize + 16)
        }
        .onTapGesture {
            onTap()
        }
    }
}

/// Mini habit icon for group preview
struct MiniHabitIcon: View {
    let habit: Habit

    /// Extracts the first emoji from the habit name
    private var emoji: String? {
        for char in habit.name {
            if char.isEmoji {
                return String(char)
            }
        }
        return nil
    }

    /// Returns first letter initial
    private var initial: String {
        String(habit.name.prefix(1)).uppercased()
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
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 24, height: 24)

            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: 12))
            } else {
                Text(initial)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

/// Sheet to view and manage habits within a group
struct GroupDetailSheet: View {
    let group: HabitGroup
    @Bindable var store: HabitStore
    let onDismiss: () -> Void

    @State private var groupName: String
    @State private var selectedHabit: Habit?
    @State private var showingDeleteConfirmation = false

    init(group: HabitGroup, store: HabitStore, onDismiss: @escaping () -> Void) {
        self.group = group
        self.store = store
        self.onDismiss = onDismiss
        self._groupName = State(initialValue: group.name)
    }

    private var groupHabits: [Habit] {
        store.allHabits.filter { group.habitIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Group name editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GROUP NAME")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)

                        TextField("Group name", text: $groupName)
                            .font(JournalTheme.Fonts.habitName())
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.7))
                                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                            )
                            .onChange(of: groupName) { _, newValue in
                                group.name = newValue
                                store.updateGroup(group)
                            }
                    }
                    .padding(.horizontal)

                    // Habits in group
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HABITS IN GROUP")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)
                            .padding(.horizontal)

                        if groupHabits.isEmpty {
                            Text("No habits in this group")
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                                .padding()
                        } else {
                            LazyVGrid(columns: [
                                SwiftUI.GridItem(.adaptive(minimum: 90, maximum: 100), spacing: 16)
                            ], spacing: 20) {
                                ForEach(groupHabits) { habit in
                                    HabitIconView(
                                        habit: habit,
                                        isArchived: false,
                                        onTap: { selectedHabit = habit }
                                    )
                                    .contextMenu {
                                        Button {
                                            store.removeHabitFromGroup(habit, group: group)
                                        } label: {
                                            Label("Remove from Group", systemImage: "folder.badge.minus")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Delete group button
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Group")
                        }
                        .font(JournalTheme.Fonts.habitName())
                        .foregroundStyle(JournalTheme.Colors.negativeRedDark)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(JournalTheme.Colors.negativeRedDark.opacity(0.5), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .linedPaperBackground()
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .sheet(item: $selectedHabit) { habit in
                NavigationStack {
                    HabitDetailView(store: store, habit: habit)
                }
            }
            .alert("Delete Group?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    store.deleteGroup(group)
                    onDismiss()
                }
            } message: {
                Text("This will delete the group '\(group.name)'. The habits inside will not be deleted.")
            }
        }
    }
}
