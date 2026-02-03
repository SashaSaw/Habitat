import SwiftUI
import SwiftData

/// View for adding a new habit group
struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore

    @State private var name = ""
    @State private var tier: HabitTier = .mustDo
    @State private var requireCount = 1
    @State private var selectedHabitIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    TextField("Group name", text: $name)
                        .font(JournalTheme.Fonts.habitName())
                } header: {
                    Text("Group Name")
                } footer: {
                    Text("e.g., 'Do something creative', 'Exercise'")
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
                } footer: {
                    Text(tier == .mustDo
                        ? "This group must be satisfied for a 'good day'"
                        : "This group is optional")
                }

                // Requirement Section
                Section {
                    Stepper("Require \(requireCount) habit\(requireCount == 1 ? "" : "s")", value: $requireCount, in: 1...max(1, selectedHabitIds.count))
                } header: {
                    Text("Requirement")
                } footer: {
                    Text("How many habits in this group need to be completed to satisfy the requirement")
                }

                // Habit Selection Section
                Section {
                    if store.habits.isEmpty {
                        Text("No habits available. Create some habits first.")
                            .font(JournalTheme.Fonts.habitCriteria())
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    } else {
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
                                // Adjust require count if needed
                                if requireCount > selectedHabitIds.count && !selectedHabitIds.isEmpty {
                                    requireCount = selectedHabitIds.count
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Habits (\(selectedHabitIds.count) selected)")
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addGroup()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedHabitIds.isEmpty)
                }
            }
        }
    }

    private func addGroup() {
        store.addGroup(
            name: name.trimmingCharacters(in: .whitespaces),
            tier: tier,
            requireCount: requireCount,
            habitIds: Array(selectedHabitIds)
        )
        dismiss()
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

    return AddGroupView(store: store)
}
