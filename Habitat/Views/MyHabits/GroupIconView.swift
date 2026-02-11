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
                // Background with subtle border to distinguish from regular habits
                RoundedRectangle(cornerRadius: 16)
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(JournalTheme.Colors.completedGray.opacity(0.3), lineWidth: 1)
                    .frame(width: iconSize, height: iconSize)

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
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.clear)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(8)
            }

            // Group name with "group" label — same fixed height as HabitIconView
            VStack(spacing: 2) {
                Text(group.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)

                Text("group")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
            .frame(width: iconSize + 16, height: 32, alignment: .top)
        }
        .onTapGesture {
            onTap()
        }
    }
}

/// Mini habit icon for group preview
struct MiniHabitIcon: View {
    let habit: Habit

    /// Custom image from data if available
    private var customImage: UIImage? {
        guard let data = habit.iconImageData else { return nil }
        return UIImage(data: data)
    }

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
            if let customImage = customImage {
                Image(uiImage: customImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
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
}

/// Redesigned group detail/edit sheet with sub-habit management
struct GroupDetailSheet: View {
    let group: HabitGroup
    @Bindable var store: HabitStore
    let onDismiss: () -> Void

    @State private var groupName: String
    @State private var selectedHabit: Habit?
    @State private var showingDeleteConfirmation = false
    @State private var showingAddSubHabit = false
    @State private var showingAddHabitSheet = false
    @State private var editingHabitId: UUID? = nil
    @State private var editingHabitName: String = ""

    init(group: HabitGroup, store: HabitStore, onDismiss: @escaping () -> Void) {
        self.group = group
        self.store = store
        self.onDismiss = onDismiss
        self._groupName = State(initialValue: group.name)
    }

    private var groupHabits: [Habit] {
        store.allHabits.filter { group.habitIds.contains($0.id) }
    }

    /// Existing habits not in any group that can be added as sub-habits
    private var availableHabits: [Habit] {
        let allGroupedIds = Set(store.groups.flatMap { $0.habitIds })
        return store.liveHabits.filter { !allGroupedIds.contains($0.id) && !$0.isTask }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Group Header
                    VStack(alignment: .center, spacing: 12) {
                        // Group icon preview
                        GroupIconView(
                            group: group,
                            habits: store.allHabits,
                            onTap: {}
                        )
                        .allowsHitTesting(false)

                        // Inline name editor
                        TextField("Group name", text: $groupName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.inkBlack)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .onChange(of: groupName) { _, newValue in
                                group.name = newValue
                                store.updateGroup(group)
                            }

                        // Badges
                        HStack(spacing: 8) {
                            Text(group.tier.displayName.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(group.tier == .mustDo ? JournalTheme.Colors.amber : JournalTheme.Colors.completedGray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(group.tier == .mustDo ? JournalTheme.Colors.amber.opacity(0.12) : JournalTheme.Colors.lineLight.opacity(0.5))
                                )

                            Text("Complete \(group.requireCount) of \(group.habitIds.count)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(JournalTheme.Colors.lineLight.opacity(0.5))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // MARK: - Sub-habits List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SUB-HABITS")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(groupHabits) { habit in
                                subHabitRow(habit)

                                if habit.id != groupHabits.last?.id {
                                    Divider()
                                        .padding(.leading, 48)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.7))
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        )
                        .padding(.horizontal)

                        // + Add sub-habit button / picker
                        if showingAddSubHabit {
                            VStack(alignment: .leading, spacing: 0) {
                                // Existing habits to choose from
                                if !availableHabits.isEmpty {
                                    Text("ADD EXISTING HABIT")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(JournalTheme.Colors.sectionHeader)
                                        .tracking(1.5)
                                        .padding(.horizontal, 14)
                                        .padding(.top, 12)
                                        .padding(.bottom, 8)

                                    ForEach(availableHabits) { habit in
                                        Button {
                                            store.addHabitToGroup(habit, group: group)
                                            habit.groupId = group.id
                                            store.updateHabit(habit)
                                            withAnimation {
                                                showingAddSubHabit = false
                                            }
                                        } label: {
                                            HStack(spacing: 12) {
                                                // Habit icon/letter badge
                                                ZStack {
                                                    Circle()
                                                        .fill(JournalTheme.Colors.inkBlue.opacity(0.12))
                                                        .frame(width: 28, height: 28)

                                                    Text(String(habit.name.prefix(1)).uppercased())
                                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                                        .foregroundStyle(JournalTheme.Colors.inkBlue)
                                                }

                                                Text(habit.name)
                                                    .font(JournalTheme.Fonts.habitName())
                                                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                                                Spacer()

                                                Image(systemName: "plus.circle")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(JournalTheme.Colors.teal)
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                        }
                                        .buttonStyle(.plain)

                                        if habit.id != availableHabits.last?.id {
                                            Divider()
                                                .padding(.leading, 54)
                                        }
                                    }

                                    Divider()
                                        .padding(.vertical, 4)
                                }

                                // Create new option — opens AddHabitView sheet
                                Button {
                                    withAnimation {
                                        showingAddSubHabit = false
                                    }
                                    showingAddHabitSheet = true
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 18))
                                            .foregroundStyle(JournalTheme.Colors.teal)

                                        Text("Create new sub-habit")
                                            .font(JournalTheme.Fonts.habitName())
                                            .foregroundStyle(JournalTheme.Colors.teal)

                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)

                                // Cancel button
                                HStack {
                                    Spacer()
                                    Button {
                                        withAnimation {
                                            showingAddSubHabit = false
                                        }
                                    } label: {
                                        Text("Cancel")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(JournalTheme.Colors.completedGray)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .padding(.bottom, 4)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JournalTheme.Colors.paperLight)
                                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                            )
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        } else {
                            Button {
                                withAnimation {
                                    showingAddSubHabit = true
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(JournalTheme.Colors.completedGray)

                                    Text("Add sub-habit...")
                                        .font(JournalTheme.Fonts.habitCriteria())
                                        .foregroundStyle(JournalTheme.Colors.completedGray)

                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            JournalTheme.Colors.completedGray.opacity(0.35),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }

                    // MARK: - Explanatory Callout
                    HStack(spacing: 10) {
                        Text("Complete any one of these sub-habits to tick off \(group.name) for the day. Stats track each one separately.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.6))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(JournalTheme.Colors.amber.opacity(0.06))
                            .strokeBorder(JournalTheme.Colors.amber.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // MARK: - Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SETTINGS")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            // Priority
                            settingsRow(
                                icon: "star.fill",
                                iconColor: JournalTheme.Colors.amber,
                                label: "Priority",
                                value: group.tier.displayName
                            ) {
                                group.tier = group.tier == .mustDo ? .niceToDo : .mustDo
                                store.updateGroup(group)
                            }

                            Divider().padding(.leading, 48)

                            // Hobby toggle
                            HStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(JournalTheme.Colors.teal)
                                    .frame(width: 24)

                                Text("Enable notes & photos")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { groupHabits.first?.enableNotesPhotos ?? false },
                                    set: { newValue in
                                        for habit in groupHabits {
                                            habit.enableNotesPhotos = newValue
                                            habit.isHobby = newValue
                                            store.updateHabit(habit)
                                        }
                                    }
                                ))
                                .labelsHidden()
                                .tint(JournalTheme.Colors.teal)
                            }
                            .padding(14)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.7))
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        )
                        .padding(.horizontal)
                    }

                    // MARK: - Archive/Delete
                    VStack(spacing: 12) {
                        Button {
                            // Archive all habits in the group
                            for habit in groupHabits {
                                store.archiveHabit(habit)
                            }
                            store.deleteGroup(group)
                            onDismiss()
                        } label: {
                            HStack {
                                Image(systemName: "archivebox")
                                Text("Archive this group")
                            }
                            .font(JournalTheme.Fonts.habitName())
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(JournalTheme.Colors.completedGray.opacity(0.5), lineWidth: 1.5)
                            )
                        }

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
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

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
            .sheet(isPresented: $showingAddHabitSheet) {
                AddHabitView(store: store, addToGroup: group)
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

    // MARK: - Sub-habit Row

    @ViewBuilder
    private func subHabitRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            // Letter badge
            ZStack {
                Circle()
                    .fill(JournalTheme.Colors.inkBlue.opacity(0.12))
                    .frame(width: 28, height: 28)

                Text(String(habit.name.prefix(1)).uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlue)
            }

            if editingHabitId == habit.id {
                // Inline editing
                TextField("Sub-habit name", text: $editingHabitName)
                    .font(JournalTheme.Fonts.habitName())
                    .textFieldStyle(.plain)
                    .onSubmit {
                        habit.name = editingHabitName.trimmingCharacters(in: .whitespaces)
                        store.updateHabit(habit)
                        editingHabitId = nil
                    }

                Button {
                    habit.name = editingHabitName.trimmingCharacters(in: .whitespaces)
                    store.updateHabit(habit)
                    editingHabitId = nil
                } label: {
                    Text("Save")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.teal)
                }
            } else {
                // Display mode
                Text(habit.name)
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
        }
        .padding(14)
        .contentShape(Rectangle())
        .onTapGesture {
            editingHabitId = habit.id
            editingHabitName = habit.name
        }
        .contextMenu {
            Button {
                editingHabitId = habit.id
                editingHabitName = habit.name
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                store.removeHabitFromGroup(habit, group: group)
                store.deleteHabit(habit)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                store.removeHabitFromGroup(habit, group: group)
            } label: {
                Label("Remove from Group", systemImage: "folder.badge.minus")
            }
        }
    }

    // MARK: - Settings Row

    private func settingsRow(icon: String, iconColor: Color, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .frame(width: 24)

                Text(label)
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                Spacer()

                Text(value)
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}
