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

// MARK: - Quick Pick Suggestion

/// A preset habit suggestion for quick adding
struct QuickPickSuggestion: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let frequency: FrequencyType
    var type: HabitType = .positive
    var triggersAppBlockSlip: Bool = false

    static let defaults: [QuickPickSuggestion] = [
        QuickPickSuggestion(emoji: "📖", name: "Read", frequency: .daily),
        QuickPickSuggestion(emoji: "💪", name: "Exercise", frequency: .daily),
        QuickPickSuggestion(emoji: "🧘", name: "Meditate", frequency: .daily),
        QuickPickSuggestion(emoji: "✏️", name: "Journal", frequency: .daily),
        QuickPickSuggestion(emoji: "📵", name: "No scrolling", frequency: .daily, type: .negative, triggersAppBlockSlip: true),
        QuickPickSuggestion(emoji: "💧", name: "Drink water", frequency: .daily),
        QuickPickSuggestion(emoji: "🍳", name: "Cook a meal", frequency: .daily),
        QuickPickSuggestion(emoji: "📞", name: "Call family", frequency: .weekly),
    ]
}

// MARK: - Flowing Tag Layout for Quick Picks

/// A flowing horizontal wrap layout for quick pick tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Frequency Pill Picker

/// Horizontal wrapping pill buttons for selecting frequency
struct FrequencyPillPicker: View {
    @Binding var selection: FrequencyType

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(FrequencyType.addFlowCases, id: \.self) { freq in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = freq
                    }
                } label: {
                    Text(freq.displayName)
                        .font(JournalTheme.Fonts.habitCriteria())
                        .fontWeight(selection == freq ? .semibold : .regular)
                        .foregroundStyle(selection == freq ? .white : JournalTheme.Colors.inkBlack)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(pillColor(for: freq, selected: selection == freq))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    pillBorderColor(for: freq, selected: selection == freq),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func pillColor(for freq: FrequencyType, selected: Bool) -> Color {
        guard selected else { return Color.clear }
        if freq == .once {
            return JournalTheme.Colors.teal
        }
        return JournalTheme.Colors.navy
    }

    private func pillBorderColor(for freq: FrequencyType, selected: Bool) -> Color {
        if selected {
            if freq == .once { return JournalTheme.Colors.teal }
            return JournalTheme.Colors.navy
        }
        return JournalTheme.Colors.lineLight
    }
}

// MARK: - Day of Week Selector

/// Circular day-of-week selectors (M T W T F S S)
struct DayOfWeekSelector: View {
    @Binding var selectedDays: Set<Int>

    private let days = [
        (index: 2, label: "M"),
        (index: 3, label: "T"),
        (index: 4, label: "W"),
        (index: 5, label: "T"),
        (index: 6, label: "F"),
        (index: 7, label: "S"),
        (index: 1, label: "S"),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.index) { day in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if selectedDays.contains(day.index) {
                            selectedDays.remove(day.index)
                        } else {
                            selectedDays.insert(day.index)
                        }
                    }
                } label: {
                    Text(day.label)
                        .font(.custom("PatrickHand-Regular", size: 13))
                        .foregroundStyle(selectedDays.contains(day.index) ? .white : JournalTheme.Colors.inkBlack)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(selectedDays.contains(day.index) ? JournalTheme.Colors.navy : Color.clear)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    selectedDays.contains(day.index) ? Color.clear : JournalTheme.Colors.lineLight,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Add Habit Confirmation Overlay

/// Shown after successfully adding a habit
struct AddHabitConfirmationView: View {
    let habitName: String
    let onDismiss: () -> Void

    @State private var showCheck = false
    @State private var showText = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Checkmark circle
            ZStack {
                Circle()
                    .fill(JournalTheme.Colors.successGreen.opacity(0.15))
                    .frame(width: 80, height: 80)

                Circle()
                    .strokeBorder(JournalTheme.Colors.successGreen, lineWidth: 2)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.custom("PatrickHand-Regular", size: 32))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
            }
            .scaleEffect(showCheck ? 1.0 : 0.5)
            .opacity(showCheck ? 1.0 : 0.0)

            // Title
            Text("Added to your day")
                .font(JournalTheme.Fonts.dateHeader())
                .foregroundStyle(JournalTheme.Colors.inkBlack)
                .opacity(showText ? 1.0 : 0.0)

            // Subtitle
            Text("\(habitName) is ready to track")
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .italic()
                .opacity(showText ? 1.0 : 0.0)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .linedPaperBackground()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showCheck = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showText = true
            }
            Feedback.success()
            // Auto-dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }
}

// MARK: - More Options Panel

/// The expanded "More options" content for the add habit flow
struct AddHabitMoreOptionsPanel: View {
    @Binding var tier: HabitTier
    @Binding var type: HabitType

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Priority
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                HStack(spacing: 10) {
                    mustDoPill
                    niceToDoPill
                }
            }

            Divider()

            // Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Type")
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                HStack(spacing: 10) {
                    ForEach(HabitType.allCases, id: \.self) { typeOption in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { type = typeOption }
                        } label: {
                            Text(typeOption.displayName)
                                .font(JournalTheme.Fonts.habitCriteria())
                                .fontWeight(type == typeOption ? .semibold : .regular)
                                .foregroundStyle(type == typeOption ? .white : JournalTheme.Colors.inkBlack)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(type == typeOption ? JournalTheme.Colors.navy : Color.clear))
                                .overlay(Capsule().strokeBorder(type == typeOption ? Color.clear : JournalTheme.Colors.lineLight, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            Text("Reminders & notes available after adding")
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        )
    }

    private var mustDoPill: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { tier = .mustDo }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "star.fill").font(.custom("PatrickHand-Regular", size: 11))
                Text("Must do")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .fontWeight(tier == .mustDo ? .semibold : .regular)
            }
            .foregroundStyle(tier == .mustDo ? JournalTheme.Colors.amber : JournalTheme.Colors.inkBlack)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(tier == .mustDo ? JournalTheme.Colors.amber.opacity(0.15) : Color.clear))
            .overlay(Capsule().strokeBorder(tier == .mustDo ? JournalTheme.Colors.amber : JournalTheme.Colors.lineLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var niceToDoPill: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { tier = .niceToDo }
        } label: {
            Text("Nice to do")
                .font(JournalTheme.Fonts.habitCriteria())
                .fontWeight(tier == .niceToDo ? .semibold : .regular)
                .foregroundStyle(tier == .niceToDo ? JournalTheme.Colors.navy : JournalTheme.Colors.inkBlack)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(tier == .niceToDo ? JournalTheme.Colors.navy.opacity(0.1) : Color.clear))
                .overlay(Capsule().strokeBorder(tier == .niceToDo ? JournalTheme.Colors.navy : JournalTheme.Colors.lineLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Frequency Detail Section

/// The expanded weekly/monthly frequency detail controls
struct FrequencyDetailSection: View {
    let frequencyType: FrequencyType
    @Binding var frequencyTarget: Int
    @Binding var selectedWeekDays: Set<Int>

    var body: some View {
        VStack(spacing: 0) {
            if frequencyType == .weekly {
                weeklySection
            }
            if frequencyType == .monthly {
                monthlySection
            }
            if frequencyType == .once {
                taskInfoNote
            }
        }
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("On specific days")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                DayOfWeekSelector(selectedDays: $selectedWeekDays)
            }

            HStack {
                Rectangle().fill(JournalTheme.Colors.lineLight).frame(height: 1)
                Text("Or just")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                Rectangle().fill(JournalTheme.Colors.lineLight).frame(height: 1)
            }

            counterRow(label: "\(frequencyTarget) times a week", min: 1, max: 7)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.85)).shadow(color: .black.opacity(0.04), radius: 4, y: 2))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var monthlySection: some View {
        counterRow(label: "\(frequencyTarget) times a month", min: 1, max: 31)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.85)).shadow(color: .black.opacity(0.04), radius: 4, y: 2))
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var taskInfoNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle").font(.custom("PatrickHand-Regular", size: 14)).foregroundStyle(JournalTheme.Colors.teal)
            Text("One-off task \u{00B7} won't affect your streak")
                .font(JournalTheme.Fonts.habitCriteria()).foregroundStyle(JournalTheme.Colors.teal)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(JournalTheme.Colors.teal.opacity(0.1)))
        .transition(.opacity)
    }

    private func counterRow(label: String, min: Int, max: Int) -> some View {
        HStack {
            Text(label)
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(JournalTheme.Colors.inkBlack)
            Spacer()
            HStack(spacing: 0) {
                Button {
                    if frequencyTarget > min { frequencyTarget -= 1; selectedWeekDays.removeAll() }
                } label: {
                    Image(systemName: "minus").font(.custom("PatrickHand-Regular", size: 14)).foregroundStyle(JournalTheme.Colors.navy)
                        .frame(width: 36, height: 36).background(Circle().fill(JournalTheme.Colors.paperLight))
                }.buttonStyle(.plain)
                Button {
                    if frequencyTarget < max { frequencyTarget += 1; selectedWeekDays.removeAll() }
                } label: {
                    Image(systemName: "plus").font(.custom("PatrickHand-Regular", size: 14)).foregroundStyle(JournalTheme.Colors.navy)
                        .frame(width: 36, height: 36).background(Circle().fill(JournalTheme.Colors.paperLight))
                }.buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Add Habit View

/// View for adding a new habit with stepped progressive disclosure
struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore
    /// Optional group to auto-add the new habit into
    var addToGroup: HabitGroup? = nil

    @State private var name = ""
    @State private var frequencyType: FrequencyType = .daily
    @State private var frequencyTarget: Int = 3
    @State private var selectedWeekDays: Set<Int> = []
    @State private var showMoreOptions = false
    @State private var tier: HabitTier = .mustDo
    @State private var type: HabitType = .positive
    @State private var enableReminders: Bool = false
    @State private var enableNotesPhotos: Bool = false
    @State private var showConfirmation = false
    @State private var addedHabitName = ""
    @State private var triggersAppBlockSlip: Bool = false

    @FocusState private var nameFieldFocused: Bool

    private var hasName: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isTask: Bool { frequencyType == .once }
    private var submitButtonText: String { isTask ? "Add to today" : "Add habit" }

    private var cleanName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        var result = trimmed
        if let first = result.first, first.isEmoji {
            result = String(result.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return result.isEmpty ? trimmed : result
    }

    var body: some View {
        if showConfirmation {
            AddHabitConfirmationView(habitName: addedHabitName) { dismiss() }
        } else {
            formContent
        }
    }

    private var formContent: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    nameInputField
                    if !hasName { quickPicksSection }
                    if hasName { stepTwoSection }
                    Spacer(minLength: 60)
                }
                .padding(20)
            }
            .linedPaperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JournalTheme.Colors.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { Feedback.buttonPress(); dismiss() }.foregroundStyle(JournalTheme.Colors.inkBlue)
                }
            }
        }
        .onAppear { nameFieldFocused = true }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(addToGroup != nil ? "New sub-habit" : "New habit")
                .font(JournalTheme.Fonts.title())
                .foregroundStyle(JournalTheme.Colors.navy)
            if let group = addToGroup {
                Text("Adding to \(group.name)")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.teal)
                    .italic()
            } else {
                Text("What do you want to start doing?")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .italic()
            }
        }
    }

    private var nameInputField: some View {
        TextField("e.g. Read for 30 min, Buy butter...", text: $name)
            .font(JournalTheme.Fonts.habitName())
            .foregroundStyle(JournalTheme.Colors.inkBlack)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(JournalTheme.Colors.paperLight)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1))
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
                ForEach(QuickPickSuggestion.defaults) { suggestion in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            name = suggestion.emoji + " " + suggestion.name
                            frequencyType = suggestion.frequency
                            type = suggestion.type
                            triggersAppBlockSlip = suggestion.triggersAppBlockSlip
                        }
                        Feedback.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Text(suggestion.emoji).font(.custom("PatrickHand-Regular", size: 15))
                            Text(suggestion.name)
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.inkBlack)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(Color.white.opacity(0.85))
                                .overlay(Capsule().strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var stepTwoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Frequency picker
            VStack(alignment: .leading, spacing: 10) {
                Text("HOW OFTEN?")
                    .font(JournalTheme.Fonts.sectionHeader())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .tracking(1.5)

                FrequencyPillPicker(selection: $frequencyType)
                FrequencyDetailSection(frequencyType: frequencyType, frequencyTarget: $frequencyTarget, selectedWeekDays: $selectedWeekDays)
            }

            // More options (hidden for tasks)
            if !isTask {
                moreOptionsSection
            }

            // Submit button
            Button { addHabit() } label: {
                Text(submitButtonText)
                    .font(.custom("PatrickHand-Regular", size: 17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(isTask ? JournalTheme.Colors.teal : JournalTheme.Colors.navy))
            }
            .buttonStyle(.plain)

            // Defaults hint
            if !isTask {
                Text("Defaults: must-do \u{00B7} \(frequencyType.displayName.lowercased()) \u{00B7} no reminders")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var moreOptionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { showMoreOptions.toggle() }
            } label: {
                HStack {
                    Text("More options")
                        .font(JournalTheme.Fonts.habitName())
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                    Spacer()
                    Image(systemName: showMoreOptions ? "chevron.up" : "chevron.down")
                        .font(.custom("PatrickHand-Regular", size: 12))
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(showMoreOptions ? JournalTheme.Colors.amber : JournalTheme.Colors.lineLight, lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 10).fill(JournalTheme.Colors.paperLight))
                )
            }
            .buttonStyle(.plain)
            .zIndex(1)

            if showMoreOptions {
                AddHabitMoreOptionsPanel(tier: $tier, type: $type)
                    .padding(.top, 8)
                    .transition(.asymmetric(
                        insertion: .push(from: .top),
                        removal: .push(from: .bottom)
                    ))
            }
        }
        .clipped()
    }

    private func addHabit() {
        let target: Int
        if frequencyType == .daily || frequencyType == .once {
            target = 1
        } else if frequencyType == .weekly && !selectedWeekDays.isEmpty {
            target = selectedWeekDays.count
        } else {
            target = frequencyTarget
        }

        addedHabitName = cleanName

        store.addHabit(
            name: name.trimmingCharacters(in: .whitespaces),
            tier: tier,
            type: type,
            frequencyType: frequencyType,
            frequencyTarget: target,
            groupId: addToGroup?.id,
            isHobby: enableNotesPhotos,
            notificationsEnabled: enableReminders,
            weeklyNotificationDays: Array(selectedWeekDays),
            enableNotesPhotos: enableNotesPhotos,
            triggersAppBlockSlip: triggersAppBlockSlip
        )

        // If adding to a group, also add the new habit to the group's habitIds
        if let group = addToGroup,
           let newHabit = store.habits.first(where: {
               $0.name == name.trimmingCharacters(in: .whitespaces) && $0.groupId == group.id
           }) {
            store.addHabitToGroup(newHabit, group: group)
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            showConfirmation = true
        }
    }
}

#Preview("Add Habit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: config)
    let store = HabitStore(modelContext: container.mainContext)

    return AddHabitView(store: store)
}
