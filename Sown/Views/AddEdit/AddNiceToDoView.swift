import SwiftUI
import SwiftData

/// Streamlined nice-to-do habit creation with progressive disclosure
struct AddNiceToDoView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore

    // Step 1: Name
    @State private var name = ""

    // Step 2: Frequency
    @State private var frequencyType: FrequencyType = .weekly
    @State private var frequencyTarget: Int = 3
    @State private var hasSetFrequency: Bool = false

    // Step 3: Success Criteria
    @State private var criteria: [CriterionEntry] = [CriterionEntry()]
    @State private var hasSetCriteria: Bool = false

    // Step 4: Habit Prompt
    @State private var habitPrompt: String = ""
    @State private var hasSetPrompt: Bool = false

    // Step 5: Reminders
    @State private var enableReminders: Bool = false
    @State private var hasSetReminders: Bool = false
    @State private var selectedTimeSlots: Set<String> = []

    // Confirmation
    @State private var showConfirmation = false
    @State private var addedHabitName = ""

    @FocusState private var nameFieldFocused: Bool

    private var hasName: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var showStep2: Bool { hasName }
    private var showStep3: Bool { hasSetFrequency }
    private var showStep4: Bool { hasSetCriteria }
    private var showStep5: Bool { hasSetPrompt }
    private var showSubmit: Bool { hasSetReminders }

    /// Quick-pick suggestions appropriate for nice-to-do habits
    private let niceToDoSuggestions: [(emoji: String, name: String)] = [
        ("📖", "Read"),
        ("💪", "Exercise"),
        ("🧘", "Meditate"),
        ("✏️", "Journal"),
        ("🎸", "Practice music"),
        ("🎨", "Draw or paint"),
        ("🍳", "Cook a meal"),
        ("📞", "Call family"),
        ("🌱", "Garden"),
        ("📸", "Photography"),
        ("🧠", "Learn something new"),
    ]

    var body: some View {
        if showConfirmation {
            AddHabitConfirmationView(habitName: addedHabitName) { dismiss() }
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

                    if !hasName {
                        quickPicksSection
                    }

                    if showStep2 {
                        frequencySection
                    }

                    if showStep3 {
                        successCriteriaSection
                    }

                    if showStep4 {
                        habitPromptSection
                    }

                    if showStep5 {
                        remindersSection
                    }

                    if showSubmit {
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
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(JournalTheme.Colors.inkBlue)
                }
            }
        }
        .onAppear { nameFieldFocused = true }
    }

    // MARK: - Step 1: Header & Name

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("New nice-to-do")
                .font(JournalTheme.Fonts.title())
                .foregroundStyle(JournalTheme.Colors.navy)

            Text("A habit you'd like to build over time")
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .italic()
        }
    }

    private var nameInputField: some View {
        TextField("What's the habit?", text: $name)
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
    }

    private var quickPicksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK PICKS")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .tracking(1.5)

            FlowLayout(spacing: 10) {
                ForEach(niceToDoSuggestions, id: \.name) { suggestion in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            name = suggestion.emoji + " " + suggestion.name
                        }
                        HapticFeedback.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Text(suggestion.emoji)
                                .font(.system(size: 15))
                            Text(suggestion.name)
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.inkBlack)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.85))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Step 2: Frequency

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW OFTEN?")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .tracking(1.5)

            VStack(spacing: 14) {
                // Weekly / Monthly toggle
                HStack(spacing: 10) {
                    frequencyTypePill(type: .weekly, label: "Weekly")
                    frequencyTypePill(type: .monthly, label: "Monthly")
                }

                // Target stepper
                HStack {
                    Text(frequencyType == .weekly
                        ? "\(frequencyTarget) time\(frequencyTarget == 1 ? "" : "s") per week"
                        : "\(frequencyTarget) time\(frequencyTarget == 1 ? "" : "s") per month"
                    )
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                    Spacer()

                    HStack(spacing: 0) {
                        Button {
                            if frequencyTarget > 1 {
                                frequencyTarget -= 1
                                markFrequencySet()
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(JournalTheme.Colors.navy)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(JournalTheme.Colors.paperLight))
                        }
                        .buttonStyle(.plain)

                        Button {
                            let max = frequencyType == .weekly ? 7 : 31
                            if frequencyTarget < max {
                                frequencyTarget += 1
                                markFrequencySet()
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(JournalTheme.Colors.navy)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(JournalTheme.Colors.paperLight))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func frequencyTypePill(type: FrequencyType, label: String) -> some View {
        let isSelected = frequencyType == type

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                frequencyType = type
                // Reset target to sensible default when switching
                if type == .weekly && frequencyTarget > 7 {
                    frequencyTarget = 3
                }
                markFrequencySet()
            }
            HapticFeedback.selection()
        } label: {
            Text(label)
                .font(JournalTheme.Fonts.habitCriteria())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : JournalTheme.Colors.inkBlack)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? JournalTheme.Colors.navy : Color.clear)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : JournalTheme.Colors.lineLight,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func markFrequencySet() {
        if !hasSetFrequency {
            withAnimation(.easeInOut(duration: 0.25)) {
                hasSetFrequency = true
            }
        }
    }

    // MARK: - Step 3: Success Criteria

    private var successCriteriaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW WILL YOU MEASURE IT?")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .tracking(1.5)

            CriteriaEditorView(criteria: $criteria, onChanged: {
                checkCriteriaCompletion()
            })

            // Skip link
            if !hasSetCriteria {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        hasSetCriteria = true
                    }
                } label: {
                    Text("Skip")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.inkBlue)
                        .underline()
                }
                .padding(.leading, 4)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func checkCriteriaCompletion() {
        if CriteriaEditorView.hasValidCriteria(criteria) && !hasSetCriteria {
            withAnimation(.easeInOut(duration: 0.25)) {
                hasSetCriteria = true
            }
        }
    }

    // MARK: - Step 4: Habit Prompt

    private var habitPromptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT SMALL FIRST STEP GETS YOU STARTED?")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .tracking(1.5)

            Text("Think of a tiny action to begin this habit")
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .italic()

            TextField("e.g. Put on your trainers and step outside", text: $habitPrompt)
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(JournalTheme.Colors.inkBlack)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                        )
                )
                .onChange(of: habitPrompt) { _, newVal in
                    if !newVal.trimmingCharacters(in: .whitespaces).isEmpty && !hasSetPrompt {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            hasSetPrompt = true
                        }
                    }
                }

            if !hasSetPrompt {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        hasSetPrompt = true
                    }
                } label: {
                    Text("Skip")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.inkBlue)
                        .underline()
                }
                .padding(.leading, 4)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Step 5: Reminders

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REMINDERS")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .tracking(1.5)

            HStack {
                Text("Enable reminders")
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { enableReminders },
                    set: { newVal in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            enableReminders = newVal
                            if !hasSetReminders {
                                hasSetReminders = true
                            }
                        }
                    }
                ))
                .tint(JournalTheme.Colors.inkBlue)
                .labelsHidden()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )
            .onAppear {
                if !hasSetReminders {
                    withAnimation(.easeInOut(duration: 0.25).delay(0.1)) {
                        hasSetReminders = true
                    }
                }
            }

            if enableReminders {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When should we remind you?")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.completedGray)

                    TimeSlotPicker(selectedSlots: $selectedTimeSlots)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button { addNiceToDo() } label: {
            Text("Add Nice-to-do")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(JournalTheme.Colors.navy)
                )
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Add Habit Logic

    private func addNiceToDo() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        // Build success criteria string from valid entries
        let criteriaString = buildCriteriaString()

        // Strip emoji for display name
        var displayName = trimmedName
        if let first = displayName.first, first.isEmoji {
            displayName = String(displayName.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        addedHabitName = displayName.isEmpty ? trimmedName : displayName

        let _ = store.addHabit(
            name: trimmedName,
            tier: .niceToDo,
            type: .positive,
            frequencyType: frequencyType,
            frequencyTarget: frequencyTarget,
            successCriteria: criteriaString.isEmpty ? nil : criteriaString,
            isHobby: false,
            notificationsEnabled: enableReminders,
            enableNotesPhotos: false,
            habitPrompt: habitPrompt.trimmingCharacters(in: .whitespaces),
            scheduleTimes: Array(selectedTimeSlots)
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            showConfirmation = true
        }
    }

    private func buildCriteriaString() -> String {
        CriteriaEditorView.buildCriteriaString(from: criteria)
    }
}

#Preview("Add Nice-to-Do") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: config)
    let store = HabitStore(modelContext: container.mainContext)

    return AddNiceToDoView(store: store)
}
