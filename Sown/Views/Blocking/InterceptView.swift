import SwiftUI
import SwiftData

/// The screen shown when a user tries to open a blocked app
/// Identity-based two-screen flow:
///   Screen 1: "How will you cast your vote?" — two choices
///   Screen 2a (controlled): Type a shame sentence to unlock
///   Screen 2b (promised): Show habits to complete
struct InterceptView: View {
    @Bindable var store: HabitStore
    let blockedAppName: String
    let blockedAppEmoji: String
    let blockedAppColor: Color
    @State private var blockSettings = BlockSettings.shared

    /// Which screen we're on
    @State private var screen: InterceptScreen = .vote

    @Environment(\.dismiss) private var dismiss

    private let selectedDate = Date()
    private let lineHeight = JournalTheme.Dimensions.lineSpacing
    private let contentPadding: CGFloat = 24

    enum InterceptScreen {
        case vote
        case controlled   // shame typing
        case countdown    // 10s countdown before unlock
        case habits       // show habits to do
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinedPaperBackground(lineSpacing: lineHeight)
                    .ignoresSafeArea()

                switch screen {
                case .vote:
                    voteScreen
                case .controlled:
                    controlledScreen
                case .countdown:
                    countdownScreen
                case .habits:
                    habitsScreen
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    }
                }

                if screen != .vote {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if screen == .countdown {
                                    countdownTimer?.invalidate()
                                    countdownTimer = nil
                                    screen = .controlled
                                } else {
                                    screen = .vote
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Screen 1: Vote

    private var voteScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            // Blocked app badge
            blockedAppBadge
                .padding(.bottom, 24)

            // Message
            Text("Every moment of weakness is a chance to choose the right path.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, contentPadding + 8)
                .padding(.bottom, 16)

            // Question
            Text("Choose wisely.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 40)

            // Choice 1: Controlled by phone
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    screen = .controlled
                }
                Feedback.selection()
            } label: {
                VStack(spacing: 6) {
                    Text("I am the kind of person who")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.7))
                    Text("is controlled by their phone")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.negativeRedDark)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(JournalTheme.Colors.negativeRedDark.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(JournalTheme.Colors.negativeRedDark.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, contentPadding)

            // Divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(height: 1)
                Text("or")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                Rectangle()
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(height: 1)
            }
            .padding(.horizontal, contentPadding + 20)
            .padding(.vertical, 16)

            // Choice 2: The person I promised
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    screen = .habits
                }
                Feedback.selection()
            } label: {
                VStack(spacing: 6) {
                    Text("I am the kind of person who")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.7))
                    Text("I promised myself I would be")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.successGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(JournalTheme.Colors.successGreen.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(JournalTheme.Colors.successGreen.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, contentPadding)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Screen 2a: Controlled (Shame Sentence)

    @State private var typedSentence: String = ""
    private let shameSentence = "I know this will not make me feel better but I am choosing it anyway"

    private var sentenceMatches: Bool {
        typedSentence.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == shameSentence.lowercased()
    }

    private var controlledScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("Be honest with yourself first:")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack)
                        .padding(.top, 20)

                    // The sentence to copy
                    Text("\u{201C}\(shameSentence)\u{201D}")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(JournalTheme.Colors.negativeRedDark.opacity(0.8))
                        .italic()
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(JournalTheme.Colors.negativeRedDark.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(JournalTheme.Colors.negativeRedDark.opacity(0.15), lineWidth: 1)
                                )
                        )

                    // Text editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type it here:")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        TextEditor(text: $typedSentence)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.inkBlack)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(sentenceMatches
                                                ? JournalTheme.Colors.successGreen.opacity(0.4)
                                                : JournalTheme.Colors.lineLight,
                                                lineWidth: 1)
                                    )
                            )
                    }

                    // Unlock button (only when sentence matches)
                    if sentenceMatches {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                screen = .countdown
                            }
                            Feedback.selection()
                        } label: {
                            Text("Continue to \(blockedAppName) (5 min)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JournalTheme.Colors.completedGray)
                                )
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Right path escape hatch
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            screen = .habits
                        }
                        Feedback.selection()
                    } label: {
                        Text("You can still choose the right path")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.successGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, contentPadding)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: sentenceMatches)
    }

    // MARK: - Screen 2a.2: Countdown

    @State private var countdownSeconds: Int = 10
    @State private var countdownTimer: Timer? = nil

    private var countdownScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            // Countdown circle
            ZStack {
                Circle()
                    .stroke(JournalTheme.Colors.lineLight, lineWidth: 4)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(countdownSeconds) / 10.0)
                    .stroke(JournalTheme.Colors.completedGray, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: countdownSeconds)

                Text("\(countdownSeconds)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                    .contentTransition(.numericText())
            }
            .padding(.bottom, 32)

            Text("Are you sure?")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack)
                .padding(.bottom, 8)

            Text("You still have time to change your mind.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, contentPadding)
                .padding(.bottom, 40)

            // Right path button (always visible)
            Button {
                countdownTimer?.invalidate()
                countdownTimer = nil
                withAnimation(.easeInOut(duration: 0.25)) {
                    screen = .habits
                }
                Feedback.selection()
            } label: {
                Text("I want to choose the right path")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(JournalTheme.Colors.successGreen)
                    )
            }
            .padding(.horizontal, contentPadding)
            .padding(.bottom, 12)

            // Unlock button (appears when countdown finishes)
            if countdownSeconds <= 0 {
                Button {
                    countdownTimer?.invalidate()
                    countdownTimer = nil
                    // Mark all negative habits as slipped (completed = failed for negative habits)
                    markNegativeHabitsAsSlipped()
                    ScreenTimeManager.shared.grantTemporaryUnlock(minutes: 5)
                    Feedback.selection()
                    dismiss()
                } label: {
                    Text("Continue to \(blockedAppName) (5 min)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(JournalTheme.Colors.completedGray)
                        )
                }
                .padding(.horizontal, contentPadding)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: countdownSeconds)
        .onAppear {
            countdownSeconds = 10
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if countdownSeconds > 0 {
                    countdownSeconds -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
        .onDisappear {
            countdownTimer?.invalidate()
            countdownTimer = nil
        }
    }

    // MARK: - Screen 2b: Habits

    @State private var showingFocusMode: Habit? = nil

    private var habitsScreen: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Motivation banner
                motivationBanner

                // Must Do section
                mustDoSection

                // Nice-to-do / hobby section with prompts
                hobbySection

                // Today's tasks section
                tasksSection

                // Done section
                doneSection

                Spacer(minLength: 80)
            }
            .padding(.top, 16)
        }
        .sheet(item: $showingFocusMode) { habit in
            FocusModeView(store: store, habit: habit)
        }
    }

    // MARK: - Blocked App Badge

    private var blockedAppBadge: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(blockedAppColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Text(blockedAppEmoji)
                    .font(.system(size: 18))
            }

            Text("\(blockedAppName) is blocked")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.completedGray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(JournalTheme.Colors.paperLight)
                .overlay(
                    Capsule()
                        .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                )
        )
    }

    // MARK: - Motivation Banner

    private var motivationBanner: some View {
        let undoneCount = undoneHabitCount + store.todayVisibleTasks.count
        let streak = store.currentGoodDayStreak()
        let allDone = store.isGoodDay(for: selectedDate)

        return VStack(alignment: .leading, spacing: 6) {
            if allDone {
                HStack {
                    Text("🔥 All done! Your streak is safe.")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.successGreen)
                    Spacer()
                }
            } else {
                HStack {
                    Text("You chose to be the person you promised.")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.successGreen)
                    Spacer()
                }

                if undoneCount > 0 {
                    Text("You have \(undoneCount) thing\(undoneCount == 1 ? "" : "s") to do — let's go.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.7))
                }

                if streak > 0 {
                    Text("Keep your \(streak)-day streak alive 🔥")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.5))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(allDone
                    ? JournalTheme.Colors.successGreen.opacity(0.12)
                    : JournalTheme.Colors.successGreen.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(JournalTheme.Colors.successGreen.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, contentPadding)
    }

    // MARK: - Must Do Section

    @ViewBuilder
    private var mustDoSection: some View {
        let undoneStandalone = store.standalonePositiveMustDoHabits.filter { !$0.isCompleted(for: selectedDate) }
        let undoneGrouped = store.mustDoGroups.filter { !$0.isSatisfied(habits: store.habits, for: selectedDate) }

        if !undoneStandalone.isEmpty || !undoneGrouped.isEmpty {
            VStack(spacing: 0) {
                sectionHeader("★ MUST DO", color: JournalTheme.Colors.amber)

                ForEach(undoneStandalone) { habit in
                    InterceptHabitRow(
                        habit: habit,
                        lineHeight: lineHeight,
                        onTap: { showingFocusMode = habit },
                        onComplete: { store.setCompletion(for: habit, completed: true, on: selectedDate) }
                    )
                }

                ForEach(undoneGrouped) { group in
                    let groupHabits = store.habits(for: group).filter { !$0.isCompleted(for: selectedDate) }
                    ForEach(groupHabits) { habit in
                        InterceptHabitRow(
                            habit: habit,
                            lineHeight: lineHeight,
                            groupName: group.name,
                            onTap: { showingFocusMode = habit },
                            onComplete: { store.setCompletion(for: habit, completed: true, on: selectedDate) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Hobby / Nice-to-do Section (with prompts)

    @ViewBuilder
    private var hobbySection: some View {
        let niceHabits = store.niceToDoHabits.filter { $0.isActive && !$0.isTask && !$0.isCompleted(for: selectedDate) }

        if !niceHabits.isEmpty {
            VStack(spacing: 0) {
                sectionHeader("◇ NICE TO DO", color: JournalTheme.Colors.teal)

                ForEach(niceHabits) { habit in
                    InterceptHabitRow(
                        habit: habit,
                        lineHeight: lineHeight,
                        showPrompt: true,
                        onTap: { showingFocusMode = habit },
                        onComplete: { store.setCompletion(for: habit, completed: true, on: selectedDate) }
                    )
                }
            }
        }
    }

    // MARK: - Tasks Section

    @ViewBuilder
    private var tasksSection: some View {
        if !store.todayVisibleTasks.isEmpty {
            VStack(spacing: 0) {
                sectionHeader("◇ TODAY'S TASKS", color: JournalTheme.Colors.teal)

                ForEach(store.todayVisibleTasks) { task in
                    InterceptTaskRow(
                        task: task,
                        lineHeight: lineHeight,
                        onComplete: { store.setCompletion(for: task, completed: true, on: selectedDate) }
                    )
                }
            }
        }
    }

    // MARK: - Done Section

    @ViewBuilder
    private var doneSection: some View {
        let completedMustDo = store.standalonePositiveMustDoHabits.filter { $0.isCompleted(for: selectedDate) }
        let completedTasks = store.todayCompletedTasks

        if !completedMustDo.isEmpty || !completedTasks.isEmpty {
            VStack(spacing: 0) {
                sectionHeader("DONE ✓", color: JournalTheme.Colors.completedGray)

                ForEach(completedMustDo) { habit in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(JournalTheme.Colors.successGreen)

                        Text(habit.name)
                            .font(JournalTheme.Fonts.habitName())
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                            .strikethrough(color: JournalTheme.Colors.completedGray)

                        Spacer()
                    }
                    .padding(.horizontal, contentPadding)
                    .frame(height: lineHeight)
                    .opacity(0.5)
                }

                ForEach(completedTasks) { task in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(JournalTheme.Colors.teal)

                        Text(task.name)
                            .font(JournalTheme.Fonts.habitName())
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                            .strikethrough(color: JournalTheme.Colors.completedGray)

                        Spacer()
                    }
                    .padding(.horizontal, contentPadding)
                    .frame(height: lineHeight)
                    .opacity(0.5)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(color)
                .tracking(2)
            Spacer()
        }
        .padding(.horizontal, contentPadding)
        .padding(.bottom, 4)
    }

    private var undoneHabitCount: Int {
        let undoneStandalone = store.standalonePositiveMustDoHabits.filter { !$0.isCompleted(for: selectedDate) }.count
        let undoneGroups = store.mustDoGroups.filter { !$0.isSatisfied(habits: store.habits, for: selectedDate) }.count
        return undoneStandalone + undoneGroups
    }

    /// Mark scroll-related negative habits as slipped for today (completed = true means they failed).
    /// Only targets habits with triggersAppBlockSlip = true (e.g. "No scrolling").
    /// This loses their good day and cannot be undone until the next day.
    private func markNegativeHabitsAsSlipped() {
        let scrollHabits = store.negativeHabits.filter { $0.triggersAppBlockSlip }
        guard !scrollHabits.isEmpty else { return }

        for habit in scrollHabits {
            if !habit.isCompleted(for: selectedDate) {
                store.setCompletion(for: habit, completed: true, on: selectedDate)
            }
        }
        // Lock these habits so they can't be toggled back today
        BlockSettings.shared.negativeHabitsAutoSlippedDate = Date()
    }
}

// MARK: - Intercept Habit Row

/// A tappable habit row for the intercept screen
/// Shows habitPrompt as subtitle for nice-to-do hobbies when showPrompt is true
struct InterceptHabitRow: View {
    let habit: Habit
    let lineHeight: CGFloat
    var groupName: String? = nil
    var showPrompt: Bool = false
    let onTap: () -> Void
    let onComplete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Habit emoji/icon
                if let imageData = habit.iconImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(habit.tier == .mustDo
                            ? JournalTheme.Colors.amber.opacity(0.12)
                            : JournalTheme.Colors.teal.opacity(0.12))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(habit.name.prefix(1)))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(habit.tier == .mustDo
                                    ? JournalTheme.Colors.amber
                                    : JournalTheme.Colors.teal)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    // Show habit prompt as primary text for hobbies, with name smaller
                    if showPrompt && !habit.habitPrompt.isEmpty {
                        Text(habit.habitPrompt)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.inkBlack)
                            .lineLimit(2)

                        Text(habit.name)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    } else {
                        Text(habit.name)
                            .font(JournalTheme.Fonts.habitName())
                            .foregroundStyle(JournalTheme.Colors.inkBlack)

                        if let group = groupName {
                            Text(group)
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                        } else if let criteria = habit.successCriteria, !criteria.isEmpty {
                            Text(criteria)
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
            .padding(.horizontal, 24)
            .frame(minHeight: lineHeight)
        }
    }
}

// MARK: - Intercept Task Row

/// A task row on the intercept screen (can be ticked off directly)
struct InterceptTaskRow: View {
    let task: Habit
    let lineHeight: CGFloat
    let onComplete: () -> Void

    @State private var isCompleted = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isCompleted = true
                    onComplete()
                    Feedback.completion()
                }
            } label: {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(JournalTheme.Colors.teal, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(JournalTheme.Colors.teal)
                        }
                    }
            }

            Text(task.name)
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(isCompleted ? JournalTheme.Colors.completedGray : JournalTheme.Colors.inkBlack)
                .strikethrough(isCompleted, color: JournalTheme.Colors.completedGray)

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(minHeight: lineHeight)
    }
}

#Preview {
    InterceptView(
        store: HabitStore(modelContext: try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext),
        blockedAppName: "Instagram",
        blockedAppEmoji: "📷",
        blockedAppColor: Color(hex: "#E1306C")
    )
}
