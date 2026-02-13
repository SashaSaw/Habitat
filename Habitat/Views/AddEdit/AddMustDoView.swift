import SwiftUI
import SwiftData

/// A single success criterion entry (number + unit)
private struct CriterionEntry: Identifiable {
    let id = UUID()
    var value: String = ""
    var unit: String = ""
    var isCustomUnit: Bool = false
    var customUnit: String = ""
}

/// Streamlined must-do habit creation with progressive disclosure
struct AddMustDoView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore

    // Step 1: Name
    @State private var name = ""

    // Step 2: Success Criteria
    @State private var criteria: [CriterionEntry] = [CriterionEntry()]
    @State private var hasSetCriteria: Bool = false

    // Step 3: Habit Prompt
    @State private var habitPrompt: String = ""
    @State private var hasSetPrompt: Bool = false

    // Step 4: Reminders
    @State private var enableReminders: Bool = false
    @State private var hasSetReminders: Bool = false
    @State private var selectedTimeSlots: Set<String> = []

    // Confirmation
    @State private var showConfirmation = false
    @State private var addedHabitName = ""

    @FocusState private var nameFieldFocused: Bool

    private var hasName: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var showStep2: Bool { hasName }
    private var showStep3: Bool { hasSetCriteria }
    private var showStep4: Bool { hasSetPrompt }
    private var showSubmit: Bool { hasSetReminders }

    /// Quick-pick suggestions appropriate for must-do habits
    private let mustDoSuggestions: [(emoji: String, name: String)] = [
        ("💧", "Drink water"),
        ("⏰", "Wake up on time"),
        ("😴", "Sleep on time"),
        ("🛏️", "Make bed"),
        ("🪥", "Brush & floss"),
        ("💊", "Take vitamins"),
        ("🏃", "Move your body"),
        ("🧹", "Tidy up"),
        ("🌳", "Go outside"),
    ]

    /// Predefined unit categories
    private static let unitCategories: [(category: String, units: [String])] = [
        ("Time", ["seconds", "minutes", "hours"]),
        ("Distance", ["m", "km", "miles"]),
        ("Weight", ["g", "kg", "lbs"]),
        ("Volume", ["ml", "litres"]),
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
                        successCriteriaSection
                    }

                    if showStep3 {
                        habitPromptSection
                    }

                    if showStep4 {
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
            Text("New must-do")
                .font(JournalTheme.Fonts.title())
                .foregroundStyle(JournalTheme.Colors.amber)

            Text("Build a daily habit you won't skip")
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
                ForEach(mustDoSuggestions, id: \.name) { suggestion in
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

    // MARK: - Step 2: Success Criteria

    private var successCriteriaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW WILL YOU MEASURE IT?")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .tracking(1.5)

            VStack(spacing: 12) {
                ForEach(Array(criteria.enumerated()), id: \.element.id) { index, entry in
                    criterionRow(index: index)
                }

                // Add another button (max 3)
                if criteria.count < 3 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            criteria.append(CriterionEntry())
                        }
                        HapticFeedback.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                            Text("Add another")
                                .font(JournalTheme.Fonts.habitCriteria())
                        }
                        .foregroundStyle(JournalTheme.Colors.inkBlue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .strokeBorder(JournalTheme.Colors.inkBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )

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

    private func criterionRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Number field
                TextField("0", text: Binding(
                    get: { criteria[index].value },
                    set: { newVal in
                        criteria[index].value = newVal
                        checkCriteriaCompletion()
                    }
                ))
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack)
                .keyboardType(.decimalPad)
                .frame(width: 60)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(JournalTheme.Colors.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                        )
                )

                // Unit display
                if !criteria[index].unit.isEmpty {
                    Text(criteria[index].isCustomUnit ? criteria[index].customUnit : criteria[index].unit)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(JournalTheme.Colors.inkBlue.opacity(0.1))
                        )
                }

                Spacer()

                // Remove button (if more than 1 criterion)
                if criteria.count > 1 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            criteria.remove(at: index)
                            checkCriteriaCompletion()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    }
                }
            }

            // Unit picker pills
            unitPicker(index: index)
        }
        .padding(.bottom, index < criteria.count - 1 ? 8 : 0)
        .overlay(alignment: .bottom) {
            if index < criteria.count - 1 {
                Rectangle()
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(height: 1)
                    .padding(.horizontal, -4)
            }
        }
    }

    private func unitPicker(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Predefined units by category
            ForEach(Self.unitCategories, id: \.category) { category in
                HStack(spacing: 6) {
                    Text(category.category)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                        .frame(width: 50, alignment: .trailing)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(category.units, id: \.self) { unit in
                                unitPill(unit: unit, index: index, isCustom: false)
                            }
                        }
                    }
                }
            }

            // Custom unit row
            HStack(spacing: 6) {
                Text("Custom")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .frame(width: 50, alignment: .trailing)

                if criteria[index].isCustomUnit {
                    TextField("e.g. pages, reps", text: Binding(
                        get: { criteria[index].customUnit },
                        set: { newVal in
                            criteria[index].customUnit = newVal
                            criteria[index].unit = newVal
                            checkCriteriaCompletion()
                        }
                    ))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(JournalTheme.Colors.inkBlue.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .strokeBorder(JournalTheme.Colors.inkBlue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .frame(maxWidth: 150)
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            criteria[index].isCustomUnit = true
                            criteria[index].unit = ""
                            criteria[index].customUnit = ""
                        }
                        HapticFeedback.selection()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                            Text("Custom")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.clear)
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

    private func unitPill(unit: String, index: Int, isCustom: Bool) -> some View {
        let isSelected = !criteria[index].isCustomUnit && criteria[index].unit == unit

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                criteria[index].unit = unit
                criteria[index].isCustomUnit = false
                criteria[index].customUnit = ""
                checkCriteriaCompletion()
            }
            HapticFeedback.selection()
        } label: {
            Text(unit)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : JournalTheme.Colors.inkBlack)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? JournalTheme.Colors.inkBlue : Color.clear)
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

    private func checkCriteriaCompletion() {
        // Mark criteria as set if at least one criterion has both a value and a unit
        let hasValid = criteria.contains { entry in
            let hasValue = !entry.value.trimmingCharacters(in: .whitespaces).isEmpty
            let hasUnit: Bool
            if entry.isCustomUnit {
                hasUnit = !entry.customUnit.trimmingCharacters(in: .whitespaces).isEmpty
            } else {
                hasUnit = !entry.unit.isEmpty
            }
            return hasValue && hasUnit
        }
        if hasValid && !hasSetCriteria {
            withAnimation(.easeInOut(duration: 0.25)) {
                hasSetCriteria = true
            }
        }
    }

    // MARK: - Step 3: Habit Prompt

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

    // MARK: - Step 4: Reminders

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
                // Automatically mark as set when section appears
                // (user can just leave it off and submit)
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
        Button { addMustDo() } label: {
            Text("Add Must-do")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(JournalTheme.Colors.amber)
                )
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Add Habit Logic

    private func addMustDo() {
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
            tier: .mustDo,
            type: .positive,
            frequencyType: .daily,
            frequencyTarget: 1,
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
        let validCriteria = criteria.compactMap { entry -> String? in
            let value = entry.value.trimmingCharacters(in: .whitespaces)
            guard !value.isEmpty else { return nil }

            let unitStr: String
            if entry.isCustomUnit {
                let custom = entry.customUnit.trimmingCharacters(in: .whitespaces)
                guard !custom.isEmpty else { return nil }
                unitStr = custom
            } else {
                guard !entry.unit.isEmpty else { return nil }
                unitStr = entry.unit
            }

            return "\(value) \(unitStr)"
        }

        return validCriteria.joined(separator: ", ")
    }
}

#Preview("Add Must-Do") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: config)
    let store = HabitStore(modelContext: container.mainContext)

    return AddMustDoView(store: store)
}
