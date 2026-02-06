import SwiftUI
import SwiftData

// MARK: - Reusable Form Card Component

/// A white card container for form sections
struct FormCard<Content: View>: View {
    let header: String?
    let footer: String?
    @ViewBuilder let content: () -> Content

    init(header: String? = nil, footer: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let header = header {
                Text(header.uppercased())
                    .font(JournalTheme.Fonts.sectionHeader())
                    .foregroundStyle(JournalTheme.Colors.inkBlue)
                    .tracking(1.5)
                    .padding(.horizontal, 4)
            }

            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )

            if let footer = footer {
                Text(footer)
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// Styled text field for the card-based form
struct CardTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(label)
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                if isRequired {
                    Text("*")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.negativeRedDark)
                }
            }

            TextField(placeholder, text: $text)
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(JournalTheme.Colors.inkBlack)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(JournalTheme.Colors.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                        )
                )
        }
    }
}

/// Styled segmented picker for the card-based form
struct CardSegmentedPicker<T: Hashable & CaseIterable & RawRepresentable>: View where T.AllCases: RandomAccessCollection, T.RawValue == String {
    let label: String
    @Binding var selection: T
    let displayName: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)

            HStack(spacing: 0) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = option
                        }
                    } label: {
                        Text(displayName(option))
                            .font(JournalTheme.Fonts.habitName())
                            .foregroundStyle(selection == option ? .white : JournalTheme.Colors.inkBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selection == option ? JournalTheme.Colors.inkBlue : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(JournalTheme.Colors.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                    )
            )
        }
    }
}

/// Styled toggle for the card-based form
struct CardToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(JournalTheme.Colors.inkBlack)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(JournalTheme.Colors.inkBlue)
                .labelsHidden()
        }
    }
}

// MARK: - Add Habit View

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
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Info Section
                    FormCard(header: "Basic Info") {
                        CardTextField(
                            label: "Name",
                            placeholder: "Enter habit name",
                            text: $name,
                            isRequired: true
                        )

                        CardTextField(
                            label: "Description",
                            placeholder: "Optional description",
                            text: $habitDescription
                        )
                    }

                    // Type Section
                    FormCard(
                        header: "Habit Type",
                        footer: type == .positive
                            ? "Something you want to do"
                            : "Something you want to avoid"
                    ) {
                        CardSegmentedPicker(
                            label: "Type",
                            selection: $type,
                            displayName: { $0.displayName }
                        )
                    }

                    // Hobby Section (only for positive habits)
                    if type == .positive {
                        FormCard(
                            footer: isHobby
                                ? "You'll be prompted to add photos and notes when completing"
                                : "Enable to track photos and notes for this activity"
                        ) {
                            CardToggle(label: "This is a hobby", isOn: $isHobby)
                        }

                        // Priority Section
                        FormCard(
                            header: "Priority",
                            footer: tier == .mustDo
                                ? "Must-do habits are required for a 'good day'"
                                : "Nice-to-do habits are bonus and tracked separately"
                        ) {
                            CardSegmentedPicker(
                                label: "Priority Level",
                                selection: $tier,
                                displayName: { $0.displayName }
                            )
                        }
                    }

                    // Frequency Section
                    FormCard(header: "Frequency") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How often?")
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.completedGray)

                            Picker("Frequency", selection: $frequencyType) {
                                ForEach(FrequencyType.allCases, id: \.self) { freq in
                                    Text(freq.displayName).tag(freq)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(JournalTheme.Colors.inkBlue)

                            if frequencyType == .weekly {
                                Stepper("Target: \(frequencyTarget)x per week", value: $frequencyTarget, in: 1...7)
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                            } else if frequencyType == .monthly {
                                Stepper("Target: \(frequencyTarget)x per month", value: $frequencyTarget, in: 1...31)
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                            }
                        }
                    }

                    // Success Criteria Section
                    FormCard(
                        header: "Success Criteria",
                        footer: "Define what counts as completing this habit. Leave empty for simple yes/no tracking."
                    ) {
                        CardTextField(
                            label: "Target",
                            placeholder: "e.g., 3L, 15 mins, 5000 steps",
                            text: $successCriteria
                        )
                    }

                    // Group Assignment Section
                    if !store.groups.isEmpty {
                        FormCard(
                            header: "Group",
                            footer: "Add this habit to a group where completing any habit satisfies the requirement."
                        ) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Assign to group")
                                    .font(JournalTheme.Fonts.habitCriteria())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)

                                Picker("Group", selection: $selectedGroupId) {
                                    Text("None").tag(nil as UUID?)
                                    ForEach(store.groups) { group in
                                        Text(group.name).tag(group.id as UUID?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(JournalTheme.Colors.inkBlue)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .linedPaperBackground()
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JournalTheme.Colors.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(JournalTheme.Colors.inkBlue)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addHabit()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty
                        ? JournalTheme.Colors.completedGray
                        : JournalTheme.Colors.inkBlue)
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
            isHobby: type == .positive && isHobby
        )

        if let groupId = selectedGroupId,
           let group = store.groups.first(where: { $0.id == groupId }),
           let habit = store.habits.last {
            store.addHabitToGroup(habit, group: group)
        }

        dismiss()
    }
}

// MARK: - Edit Habit View

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
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Info Section
                    FormCard(header: "Basic Info") {
                        CardTextField(
                            label: "Name",
                            placeholder: "Enter habit name",
                            text: $name,
                            isRequired: true
                        )

                        CardTextField(
                            label: "Description",
                            placeholder: "Optional description",
                            text: $habitDescription
                        )
                    }

                    // Stats Section
                    FormCard(header: "Statistics") {
                        VStack(spacing: 12) {
                            HStack {
                                Label("Current Streak", systemImage: "flame.fill")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                                Spacer()
                                Text("\(habit.currentStreak) days")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }

                            Divider()

                            HStack {
                                Label("Best Streak", systemImage: "trophy.fill")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                                Spacer()
                                Text("\(habit.bestStreak) days")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }

                            Divider()

                            HStack {
                                Label("Completion Rate", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                                Spacer()
                                Text("\(Int(store.completionRate(for: habit) * 100))%")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }
                        }
                    }

                    // Type Section
                    FormCard(header: "Habit Type") {
                        CardSegmentedPicker(
                            label: "Type",
                            selection: $type,
                            displayName: { $0.displayName }
                        )
                    }

                    // Priority & Hobby (only for positive)
                    if type == .positive {
                        FormCard(header: "Priority") {
                            CardSegmentedPicker(
                                label: "Priority Level",
                                selection: $tier,
                                displayName: { $0.displayName }
                            )
                        }

                        FormCard(
                            footer: isHobby
                                ? "You'll be prompted to add photos and notes when completing"
                                : "Enable to track photos and notes for this activity"
                        ) {
                            CardToggle(label: "This is a hobby", isOn: $isHobby)
                        }
                    }

                    // Frequency Section
                    FormCard(header: "Frequency") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Frequency", selection: $frequencyType) {
                                ForEach(FrequencyType.allCases, id: \.self) { freq in
                                    Text(freq.displayName).tag(freq)
                                }
                            }
                            .pickerStyle(.segmented)

                            if frequencyType == .weekly {
                                Stepper("Target: \(frequencyTarget)x per week", value: $frequencyTarget, in: 1...7)
                                    .font(JournalTheme.Fonts.habitName())
                            } else if frequencyType == .monthly {
                                Stepper("Target: \(frequencyTarget)x per month", value: $frequencyTarget, in: 1...31)
                                    .font(JournalTheme.Fonts.habitName())
                            }
                        }
                    }

                    // Success Criteria
                    FormCard(header: "Success Criteria") {
                        CardTextField(
                            label: "Target",
                            placeholder: "e.g., 3L, 15 mins, 5000 steps",
                            text: $successCriteria
                        )
                    }

                    // Delete Button
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Habit")
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

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .linedPaperBackground()
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JournalTheme.Colors.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(JournalTheme.Colors.inkBlue)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty
                        ? JournalTheme.Colors.completedGray
                        : JournalTheme.Colors.inkBlue)
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
        habit.isHobby = type == .positive && isHobby

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
