import SwiftUI
import SwiftData

/// Streamlined group creation — name input with pre-selected habits.
/// Selected must-dos are auto-converted to nice-to-dos (weekly, 1×).
struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore
    let selectedHabitIds: Set<UUID>
    var onComplete: () -> Void = {}

    @State private var groupName = ""
    @State private var showConfirmation = false

    @FocusState private var nameFieldFocused: Bool

    private var hasName: Bool { !groupName.trimmingCharacters(in: .whitespaces).isEmpty }

    /// The actual habits that were selected
    private var selectedHabits: [Habit] {
        store.habits.filter { selectedHabitIds.contains($0.id) }
    }

    /// How many of the selected habits are currently must-dos (will be converted)
    private var mustDoCount: Int {
        selectedHabits.filter { $0.tier == .mustDo }.count
    }

    var body: some View {
        if showConfirmation {
            AddHabitConfirmationView(habitName: groupName.trimmingCharacters(in: .whitespaces)) {
                onComplete()
                dismiss()
            }
        } else {
            formContent
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    nameInputField
                    selectedHabitsList

                    if mustDoCount > 0 {
                        conversionNotice
                    }

                    if hasName {
                        submitButton
                    }

                    Spacer(minLength: 60)
                }
                .padding(20)
            }
            .linedPaperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JournalTheme.Colors.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete()
                        dismiss()
                    }
                    .foregroundStyle(JournalTheme.Colors.inkBlue)
                }
            }
        }
        .onAppear { nameFieldFocused = true }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("New group")
                .font(JournalTheme.Fonts.title())
                .foregroundStyle(JournalTheme.Colors.inkBlue)

            Text("Complete any one to tick off the group")
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .italic()
        }
    }

    // MARK: - Name Input

    private var nameInputField: some View {
        TextField("Group name", text: $groupName)
            .font(JournalTheme.Fonts.habitName())
            .foregroundStyle(JournalTheme.Colors.inkBlack)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(JournalTheme.Colors.paperLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                    )
            )
            .focused($nameFieldFocused)
            .submitLabel(.done)
            .onSubmit { if hasName { createGroup() } }
    }

    // MARK: - Selected Habits Preview

    private var selectedHabitsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(selectedHabits.count) HABITS IN GROUP")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .tracking(1.5)

            VStack(spacing: 0) {
                ForEach(selectedHabits) { habit in
                    HStack(spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(JournalTheme.Colors.inkBlue)

                        Text(habit.name)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.inkBlack)

                        Spacer()

                        if habit.tier == .mustDo {
                            Text("Must-do → Nice-to-do")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(JournalTheme.Colors.amber)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)

                    if habit.id != selectedHabits.last?.id {
                        Divider()
                            .padding(.leading, 29)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )
        }
    }

    // MARK: - Conversion Notice

    private var conversionNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundStyle(JournalTheme.Colors.amber)

            Text("Must-dos will become nice-to-dos (1× per week) when added to a group.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.7))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(JournalTheme.Colors.amber.opacity(0.08))
                .strokeBorder(JournalTheme.Colors.amber.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button { createGroup() } label: {
            Text("Create Group")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(JournalTheme.Colors.inkBlue)
                )
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Create Group Logic

    private func createGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        // Convert any must-do habits to nice-to-do (weekly, 1×)
        for habit in selectedHabits {
            if habit.tier == .mustDo {
                habit.tier = .niceToDo
                habit.frequencyType = .weekly
                habit.frequencyTarget = 1
            }
        }

        // Create the group as must-do with requireCount 1
        store.addGroup(
            name: trimmedName,
            tier: .mustDo,
            requireCount: 1,
            habitIds: Array(selectedHabitIds)
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            showConfirmation = true
        }
    }
}

/// View for editing an existing group
struct EditGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore
    let group: HabitGroup

    @State private var name: String
    @State private var tier: HabitTier
    @State private var requireCount: Int
    @State private var selectedHabitIds: Set<UUID>
    @State private var showingDeleteConfirmation = false

    init(store: HabitStore, group: HabitGroup) {
        self.store = store
        self.group = group
        _name = State(initialValue: group.name)
        _tier = State(initialValue: group.tier)
        _requireCount = State(initialValue: group.requireCount)
        _selectedHabitIds = State(initialValue: Set(group.habitIds))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    TextField("Group name", text: $name)
                        .font(JournalTheme.Fonts.habitName())
                } header: {
                    Text("Group Name")
                }

                // Tier Section
                Section {
                    Picker("Tier", selection: $tier) {
                        ForEach(HabitTier.allCases, id: \.self) { tier in
                            Text(tier.displayName).tag(tier)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Priority")
                }

                // Requirement Section
                Section {
                    Stepper("Require \(requireCount) habit\(requireCount == 1 ? "" : "s")", value: $requireCount, in: 1...max(1, selectedHabitIds.count))
                } header: {
                    Text("Requirement")
                }

                // Habit Selection Section
                Section {
                    ForEach(store.habits) { habit in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.name)
                                    .font(JournalTheme.Fonts.habitName())

                                Text(habit.tier.displayName)
                                    .font(JournalTheme.Fonts.habitCriteria())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }

                            Spacer()

                            if selectedHabitIds.contains(habit.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(JournalTheme.Colors.inkBlue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(JournalTheme.Colors.lineLight)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedHabitIds.contains(habit.id) {
                                selectedHabitIds.remove(habit.id)
                            } else {
                                selectedHabitIds.insert(habit.id)
                            }
                            if requireCount > selectedHabitIds.count && !selectedHabitIds.isEmpty {
                                requireCount = selectedHabitIds.count
                            }
                        }
                    }
                } header: {
                    Text("Select Habits (\(selectedHabitIds.count) selected)")
                }

                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Group", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedHabitIds.isEmpty)
                }
            }
            .alert("Delete Group?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    store.deleteGroup(group)
                    dismiss()
                }
            } message: {
                Text("This will delete the group '\(group.name)'. The habits inside will remain.")
            }
        }
    }

    private func saveChanges() {
        group.name = name.trimmingCharacters(in: .whitespaces)
        group.tier = tier
        group.requireCount = requireCount
        group.habitIds = Array(selectedHabitIds)
        store.updateGroup(group)
        dismiss()
    }
}

#Preview("Add Group") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: config)
    let store = HabitStore(modelContext: container.mainContext)

    return AddGroupView(store: store, selectedHabitIds: []) { }
}
