import SwiftUI
import SwiftData

/// View for adding a new habit
struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore

    @State private var name = ""
    @State private var habitDescription = ""
    @State private var tier: HabitTier = .mustDo
    @State private var type: HabitType = .positive
    @State private var frequencyType: FrequencyType = .daily
    @State private var frequencyTarget: Int = 4
    @State private var successCriteria = ""
    @State private var selectedGroupId: UUID?
    @State private var isHobby: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    TextField("Habit name", text: $name)
                        .font(JournalTheme.Fonts.habitName())

                    TextField("Description (optional)", text: $habitDescription)
                        .font(JournalTheme.Fonts.habitCriteria())
                } header: {
                    Text("Basic Info")
                }

                // Type Section
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(HabitType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Habit Type")
                } footer: {
                    Text(type == .positive
                        ? "Something you want to do"
                        : "Something you want to avoid - shown in Don't Do section")
                }

                // Hobby Section (only for positive habits)
                if type == .positive {
                    Section {
                        Toggle("This is a hobby", isOn: $isHobby)
                    } footer: {
                        if isHobby {
                            Text("You'll be prompted to add photos and notes when completing")
                        } else {
                            Text("Enable to track photos and notes for this activity")
                        }
                    }
                }

                // Tier Section (only for positive habits)
                if type == .positive {
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
                            ? "Must-do habits are required for a 'good day'"
                            : "Nice-to-do habits are bonus and tracked separately")
                    }
                }

                // Frequency Section
                Section {
                    Picker("Frequency", selection: $frequencyType) {
                        ForEach(FrequencyType.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    if frequencyType == .weekly {
                        Stepper("Target: \(frequencyTarget)x per week", value: $frequencyTarget, in: 1...7)
                    } else if frequencyType == .monthly {
                        Stepper("Target: \(frequencyTarget)x per month", value: $frequencyTarget, in: 1...31)
                    }
                } header: {
                    Text("Frequency")
                }

                // Success Criteria Section
                Section {
                    TextField("e.g., 3L, 15 mins, 5000 steps", text: $successCriteria)
                        .font(JournalTheme.Fonts.habitCriteria())
                } header: {
                    Text("Success Criteria (optional)")
                } footer: {
                    Text("Define what counts as completing this habit. Leave empty for simple yes/no tracking.")
                }

                // Group Assignment Section
                if !store.groups.isEmpty {
                    Section {
                        Picker("Group", selection: $selectedGroupId) {
                            Text("None").tag(nil as UUID?)
                            ForEach(store.groups) { group in
                                Text(group.name).tag(group.id as UUID?)
                            }
                        }
                    } header: {
                        Text("Group (optional)")
                    } footer: {
                        Text("Add this habit to a group where completing any habit satisfies the requirement.")
                    }
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addHabit()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addHabit() {
        let target = frequencyType == .daily ? 1 : frequencyTarget

        store.addHabit(
            name: name.trimmingCharacters(in: .whitespaces),
            description: habitDescription,
            tier: tier,
            type: type,
            frequencyType: frequencyType,
            frequencyTarget: target,
            successCriteria: successCriteria.isEmpty ? nil : successCriteria,
            groupId: selectedGroupId,
            isHobby: type == .positive && isHobby // Only positive habits can be hobbies
        )

        // If assigned to a group, update the group's habit list
        if let groupId = selectedGroupId,
           let group = store.groups.first(where: { $0.id == groupId }),
           let habit = store.habits.last {
            store.addHabitToGroup(habit, group: group)
        }

        dismiss()
    }
}

/// View for editing an existing habit
struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore
    let habit: Habit

    @State private var name: String
    @State private var habitDescription: String
    @State private var tier: HabitTier
    @State private var type: HabitType
    @State private var frequencyType: FrequencyType
    @State private var frequencyTarget: Int
    @State private var successCriteria: String
    @State private var selectedGroupId: UUID?
    @State private var isHobby: Bool
    @State private var showingDeleteConfirmation = false

    init(store: HabitStore, habit: Habit) {
        self.store = store
        self.habit = habit
        _name = State(initialValue: habit.name)
        _habitDescription = State(initialValue: habit.habitDescription)
        _tier = State(initialValue: habit.tier)
        _type = State(initialValue: habit.type)
        _successCriteria = State(initialValue: habit.successCriteria ?? "")
        _selectedGroupId = State(initialValue: habit.groupId)
        _frequencyType = State(initialValue: habit.frequencyType)
        _frequencyTarget = State(initialValue: habit.frequencyTarget)
        _isHobby = State(initialValue: habit.isHobby)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    TextField("Habit name", text: $name)
                        .font(JournalTheme.Fonts.habitName())

                    TextField("Description (optional)", text: $habitDescription)
                        .font(JournalTheme.Fonts.habitCriteria())
                } header: {
                    Text("Basic Info")
                }

                // Stats Section
                Section {
                    HStack {
                        Label("Current Streak", systemImage: "flame.fill")
                        Spacer()
                        Text("\(habit.currentStreak) days")
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    }

                    HStack {
                        Label("Best Streak", systemImage: "trophy.fill")
                        Spacer()
                        Text("\(habit.bestStreak) days")
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    }

                    HStack {
                        Label("Completion Rate", systemImage: "chart.line.uptrend.xyaxis")
                        Spacer()
                        Text("\(Int(store.completionRate(for: habit) * 100))%")
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    }
                } header: {
                    Text("Statistics")
                }

                // Type Section
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(HabitType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Habit Type")
                }

                // Tier Section (only for positive habits)
                if type == .positive {
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

                    // Hobby Section
                    Section {
                        Toggle("This is a hobby", isOn: $isHobby)
                    } footer: {
                        if isHobby {
                            Text("You'll be prompted to add photos and notes when completing")
                        } else {
                            Text("Enable to track photos and notes for this activity")
                        }
                    }
                }

                // Frequency Section
                Section {
                    Picker("Frequency", selection: $frequencyType) {
                        ForEach(FrequencyType.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    if frequencyType == .weekly {
                        Stepper("Target: \(frequencyTarget)x per week", value: $frequencyTarget, in: 1...7)
                    } else if frequencyType == .monthly {
                        Stepper("Target: \(frequencyTarget)x per month", value: $frequencyTarget, in: 1...31)
                    }
                } header: {
                    Text("Frequency")
                }

                // Success Criteria Section
                Section {
                    TextField("e.g., 3L, 15 mins, 5000 steps", text: $successCriteria)
                        .font(JournalTheme.Fonts.habitCriteria())
                } header: {
                    Text("Success Criteria (optional)")
                }

                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Habit", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Habit")
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Delete Habit?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    store.deleteHabit(habit)
                    dismiss()
                }
            } message: {
                Text("This will permanently delete '\(habit.name)' and all its history. This cannot be undone.")
            }
        }
    }

    private func saveChanges() {
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.habitDescription = habitDescription
        habit.tier = tier
        habit.type = type
        habit.successCriteria = successCriteria.isEmpty ? nil : successCriteria
        habit.frequencyType = frequencyType
        habit.frequencyTarget = frequencyType == .daily ? 1 : frequencyTarget
        habit.isHobby = type == .positive && isHobby // Only positive habits can be hobbies

        store.updateHabit(habit)
        dismiss()
    }
}

#Preview("Add Habit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: config)
    let store = HabitStore(modelContext: container.mainContext)

    return AddHabitView(store: store)
}
