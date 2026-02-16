import SwiftUI
import SwiftData

/// Focus mode launched when tapping a habit from the intercept screen
/// Provides a timer-based focus session as an alternative to scrolling
struct FocusModeView: View {
    @Bindable var store: HabitStore
    let habit: Habit
    @Environment(\.dismiss) private var dismiss

    // Timer state
    @State private var timerMinutes: Int = 25
    @State private var timerRunning = false
    @State private var timerEndDate: Date? = nil
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer? = nil

    // Completion state
    @State private var showCompletion = false

    // Option selection (for habits with options)
    @State private var selectedOption: String? = nil
    @State private var showingOptions = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                JournalTheme.Colors.paper
                    .ignoresSafeArea()

                if showCompletion {
                    completionScreen
                } else if timerRunning {
                    timerRunningScreen
                } else {
                    timerSetupScreen
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !showCompletion {
                        Button {
                            stopTimer()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Timer Setup Screen

    private var timerSetupScreen: some View {
        VStack(spacing: 32) {
            Spacer()

            // Habit display
            habitDisplay

            // Message
            Text("Instead of scrolling,\nspend some time on this.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Timer selector
            timerSelector

            // Start focusing button
            Button {
                startTimer()
            } label: {
                Text("Start focusing")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(JournalTheme.Colors.amber)
                    )
            }
            .padding(.horizontal, 40)

            // Skip timer option
            Button {
                completeHabit()
            } label: {
                Text("Mark as done (no timer)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Timer Running Screen

    private var timerRunningScreen: some View {
        VStack(spacing: 32) {
            Spacer()

            // Habit display (smaller)
            VStack(spacing: 8) {
                habitIcon
                    .scaleEffect(0.8)

                Text(habit.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
            }

            // Large countdown
            Text(timerString)
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(JournalTheme.Colors.amber)
                .contentTransition(.numericText())

            // Progress ring
            ZStack {
                Circle()
                    .stroke(JournalTheme.Colors.lineMedium, lineWidth: 4)

                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(JournalTheme.Colors.amber, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerProgress)
            }
            .frame(width: 120, height: 120)

            // Lock message
            Text("Phone is locked to other apps")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.completedGray)

            Spacer()

            // Done button
            Button {
                completeHabit()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Done — I did it")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(JournalTheme.Colors.successGreen)
                )
            }
            .padding(.horizontal, 40)

            // End early link
            Button {
                stopTimer()
            } label: {
                Text("End session early")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Completion Screen

    private var completionScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            // Celebration
            Text("🎉")
                .font(.system(size: 64))

            Text("Nice work!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack)

            Text(habit.name)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.amber)

            // Status
            VStack(spacing: 8) {
                let undoneCount = store.standalonePositiveMustDoHabits.filter { !$0.isCompleted(for: Date()) }.count
                    + store.mustDoGroups.filter { !$0.isSatisfied(habits: store.habits, for: Date()) }.count

                if undoneCount > 0 {
                    Text("\(undoneCount) thing\(undoneCount == 1 ? "" : "s") left today")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.7))
                } else {
                    Text("All must-dos complete! 🔥")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.successGreen)
                }

                let streak = store.currentGoodDayStreak()
                if streak > 0 {
                    Text("\(streak)-day streak")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(JournalTheme.Colors.successGreen.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(JournalTheme.Colors.successGreen.opacity(0.2), lineWidth: 1)
                    )
            )

            Spacer()

            // Back button
            Button {
                dismiss()
            } label: {
                Text("Back to habits")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(JournalTheme.Colors.amber)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Components

    private var habitDisplay: some View {
        VStack(spacing: 12) {
            habitIcon

            Text(habit.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack)

            if let criteria = habit.successCriteria, !criteria.isEmpty {
                Text(criteria)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
        }
    }

    private var habitIcon: some View {
        Group {
            if let imageData = habit.iconImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(JournalTheme.Colors.amber.opacity(0.12))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(String(habit.name.prefix(1)))
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.amber)
                    )
            }
        }
    }

    private var timerSelector: some View {
        HStack(spacing: 20) {
            // Decrease button
            Button {
                if timerMinutes > 5 {
                    timerMinutes -= 5
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(timerMinutes > 5 ? JournalTheme.Colors.inkBlack : JournalTheme.Colors.completedGray)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(JournalTheme.Colors.paperLight)
                            .overlay(
                                Circle()
                                    .strokeBorder(JournalTheme.Colors.lineMedium, lineWidth: 1)
                            )
                    )
            }
            .disabled(timerMinutes <= 5)

            // Timer display
            VStack(spacing: 2) {
                Text("\(timerMinutes)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                Text("minutes")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
            .frame(width: 100)

            // Increase button
            Button {
                if timerMinutes < 120 {
                    timerMinutes += 5
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(timerMinutes < 120 ? JournalTheme.Colors.inkBlack : JournalTheme.Colors.completedGray)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(JournalTheme.Colors.paperLight)
                            .overlay(
                                Circle()
                                    .strokeBorder(JournalTheme.Colors.lineMedium, lineWidth: 1)
                            )
                    )
            }
            .disabled(timerMinutes >= 120)
        }
    }

    // MARK: - Timer Logic

    private var timerString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var timerProgress: CGFloat {
        let total = timerMinutes * 60
        guard total > 0 else { return 0 }
        return CGFloat(total - remainingSeconds) / CGFloat(total)
    }

    private func startTimer() {
        remainingSeconds = timerMinutes * 60
        timerEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        timerRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let endDate = timerEndDate {
                let remaining = Int(endDate.timeIntervalSince(Date()))
                if remaining <= 0 {
                    // Timer complete
                    completeHabit()
                } else {
                    withAnimation(.linear(duration: 0.1)) {
                        remainingSeconds = remaining
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerRunning = false
        timerEndDate = nil
    }

    private func completeHabit() {
        stopTimer()

        // Handle options
        if habit.hasOptions, !habit.options.isEmpty {
            // For habits with options, mark as done with first option
            store.setCompletion(for: habit, completed: true, on: Date())
            if let firstOption = habit.options.first {
                store.recordSelectedOption(for: habit, option: firstOption, on: Date())
            }
        } else {
            store.setCompletion(for: habit, completed: true, on: Date())
        }

        Feedback.completionConfirmed()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showCompletion = true
        }
    }
}

#Preview {
    FocusModeView(
        store: HabitStore(modelContext: try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext),
        habit: {
            let h = Habit(name: "Exercise", tier: .mustDo, type: .positive)
            h.successCriteria = "30 minutes of activity"
            return h
        }()
    )
}
