import SwiftUI
import SwiftData

/// The screen shown when a user tries to open a blocked app
/// This is THE key screen — a gentle nudge showing today's habits
struct InterceptView: View {
    @Bindable var store: HabitStore
    let blockedAppName: String
    let blockedAppEmoji: String
    let blockedAppColor: Color
    @State private var blockSettings = BlockSettings.shared

    @State private var overrideTapCount = 0
    @State private var overrideTimer: Timer? = nil
    @State private var showingFocusMode: Habit? = nil

    @Environment(\.dismiss) private var dismiss

    private let selectedDate = Date()
    private let lineHeight = JournalTheme.Dimensions.lineSpacing
    private let contentPadding: CGFloat = 24

    var body: some View {
        NavigationStack {
            ZStack {
                LinedPaperBackground(lineSpacing: lineHeight)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Blocked app indicator
                        blockedAppHeader

                        // Motivation banner
                        motivationBanner

                        // Must Do section
                        mustDoSection

                        // Today's tasks section
                        tasksSection

                        // Done section
                        doneSection

                        // Override button (de-emphasised)
                        overrideButton
                            .padding(.top, 20)

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 16)
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
            }
            .sheet(item: $showingFocusMode) { habit in
                FocusModeView(store: store, habit: habit)
            }
        }
    }

    // MARK: - Blocked App Header

    private var blockedAppHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(blockedAppColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Text(blockedAppEmoji)
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(blockedAppName) is blocked")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                if let timeRemaining = blockSettings.timeRemainingString {
                    Text("Until \(blockSettings.endTimeString) · \(timeRemaining)")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(JournalTheme.Colors.paperLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(JournalTheme.Colors.lineMedium, lineWidth: 1)
                )
        )
        .padding(.horizontal, contentPadding)
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
                    Text("You've got \(undoneCount) thing\(undoneCount == 1 ? "" : "s") left today")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.amber)
                    Spacer()
                }

                if streak > 0 {
                    Text("Complete your must-dos to keep your \(streak)-day streak 🔥")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.7))
                } else {
                    Text("Complete your must-dos to start a streak 🔥")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(allDone
                    ? JournalTheme.Colors.successGreen.opacity(0.12)
                    : JournalTheme.Colors.amber.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(allDone
                            ? JournalTheme.Colors.successGreen.opacity(0.25)
                            : JournalTheme.Colors.amber.opacity(0.25),
                            lineWidth: 1)
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

    // MARK: - Override Button

    private var overrideButton: some View {
        VStack(spacing: 8) {
            Button {
                handleOverrideTap()
            } label: {
                if overrideTapCount == 0 {
                    Text("Use \(blockedAppName) anyway →")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.completedGray.opacity(0.6))
                } else {
                    Text("Are you sure? Tap again to use for 5 min.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.coral.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, contentPadding)
        .padding(.bottom, 40)
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

    private func handleOverrideTap() {
        overrideTimer?.invalidate()

        if overrideTapCount == 0 {
            overrideTapCount = 1
            // Reset after 5 seconds if no second tap
            overrideTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                withAnimation { overrideTapCount = 0 }
            }
        } else {
            // Second tap — grant temporary unlock
            blockSettings.grantTemporaryUnlock(for: blockedAppName.lowercased())
            HapticFeedback.selection()
            dismiss()
        }
    }
}

// MARK: - Intercept Habit Row

/// A tappable habit row for the intercept screen (navigates to focus mode)
struct InterceptHabitRow: View {
    let habit: Habit
    let lineHeight: CGFloat
    var groupName: String? = nil
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
                        .fill(JournalTheme.Colors.amber.opacity(0.12))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(habit.name.prefix(1)))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(JournalTheme.Colors.amber)
                        )
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(habit.name)
                        .font(JournalTheme.Fonts.habitName())
                        .foregroundStyle(JournalTheme.Colors.inkBlack)

                    if let group = groupName {
                        Text(group)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.completedGray)
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
                    HapticFeedback.completion()
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
