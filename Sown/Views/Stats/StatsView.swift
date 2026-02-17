import SwiftUI
import SwiftData
import Charts

/// Statistics and summary view
struct StatsView: View {
    @Bindable var store: HabitStore

    var body: some View {
        NavigationStack {
            StatsContentView(store: store)
                .navigationTitle("Statistics")
        }
    }
}

/// The actual content of the Stats View
struct StatsContentView: View {
    @Bindable var store: HabitStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall Stats Card
                OverallStatsCard(store: store)

                // Good Day Streak
                GoodDayStreakCard(store: store)

                // Fulfillment Chart
                FulfillmentChartCard(store: store)

                // Habit Completion Rates
                HabitCompletionSection(store: store)

                Spacer(minLength: 100)
            }
            .padding()
        }
        .linedPaperBackground()
    }
}

/// Card showing overall statistics
struct OverallStatsCard: View {
    let store: HabitStore
    @State private var goodDayPercentage: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 30 Days")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.inkBlue)

            HStack(spacing: 24) {
                StatItem(
                    value: "\(goodDayPercentage)%",
                    label: "Good Days",
                    icon: "star.fill",
                    color: .yellow
                )

                StatItem(
                    value: "\(store.mustDoHabits.count)",
                    label: "Must-Dos",
                    icon: "checkmark.circle.fill",
                    color: JournalTheme.Colors.inkBlue
                )

                StatItem(
                    value: "\(store.niceToDoHabits.count)",
                    label: "Nice-to-Dos",
                    icon: "plus.circle.fill",
                    color: JournalTheme.Colors.completedGray
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
        .onAppear {
            goodDayPercentage = Int(store.goodDayRate(days: 30) * 100)
        }
    }
}

/// Individual stat item
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.custom("PatrickHand-Regular", size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(.custom("PatrickHand-Regular", size: 24))
                .foregroundStyle(JournalTheme.Colors.inkBlack)

            Text(label)
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Card showing good day streak
struct GoodDayStreakCard: View {
    let store: HabitStore
    @State private var currentStreak: Int = 0

    private func calculateStreak() -> Int {
        var streak = 0
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: Date())

        // Check if today is a good day
        if store.isGoodDay(for: date) {
            streak = 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        } else {
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }

        // Count backwards (limit to 365 days max to prevent infinite loops)
        var daysChecked = 0
        while store.isGoodDay(for: date) && daysChecked < 365 {
            streak += 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
            daysChecked += 1
        }

        return streak
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.custom("PatrickHand-Regular", size: 20))
                    .foregroundStyle(.orange)

                Text("Good Day Streak")
                    .font(JournalTheme.Fonts.sectionHeader())
                    .foregroundStyle(JournalTheme.Colors.inkBlue)

                Spacer()
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(currentStreak)")
                    .font(.custom("PatrickHand-Regular", size: 48))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                Text("days")
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .padding(.bottom, 8)
            }

            if currentStreak > 0 {
                Text("Keep it up! Every good day counts.")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            } else {
                Text("Complete all must-dos today to start a streak!")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
        .onAppear {
            currentStreak = calculateStreak()
        }
    }
}

/// Section showing individual habit completion rates
struct HabitCompletionSection: View {
    let store: HabitStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habit Completion (30 days)")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.inkBlue)

            if store.recurringHabits.isEmpty {
                Text("No habits yet")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            } else {
                ForEach(store.recurringHabits) { habit in
                    HabitCompletionRow(habit: habit, store: store)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

/// Single habit completion row with progress bar
struct HabitCompletionRow: View {
    let habit: Habit
    let store: HabitStore

    private var completionRate: Double {
        store.completionRate(for: habit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(habit.name)
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                Spacer()

                Text("\(Int(completionRate * 100))%")
                    .font(JournalTheme.Fonts.streakCount())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(JournalTheme.Colors.lineLight)
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * completionRate, height: 8)
                }
            }
            .frame(height: 8)

            // Streak info
            if habit.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.custom("PatrickHand-Regular", size: 10))
                        .foregroundStyle(.orange)
                    Text("\(habit.currentStreak) day streak")
                        .font(JournalTheme.Fonts.streakCount())
                        .foregroundStyle(JournalTheme.Colors.completedGray)

                    if habit.bestStreak > habit.currentStreak {
                        Text("(best: \(habit.bestStreak))")
                            .font(JournalTheme.Fonts.streakCount())
                            .foregroundStyle(JournalTheme.Colors.completedGray.opacity(0.7))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var progressColor: Color {
        if completionRate >= 0.8 {
            return JournalTheme.Colors.goodDayGreenDark
        } else if completionRate >= 0.5 {
            return .yellow
        } else {
            return JournalTheme.Colors.negativeRedDark.opacity(0.7)
        }
    }
}

/// Data point for the fulfillment chart
struct FulfillmentDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}

/// Card showing fulfillment scores over time as a line chart
struct FulfillmentChartCard: View {
    let store: HabitStore

    private var dataPoints: [FulfillmentDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let notes = store.recentEndOfDayNotes(days: 30)

        return notes.map { note in
            FulfillmentDataPoint(date: note.date, score: note.fulfillmentScore)
        }.sorted { $0.date < $1.date }
    }

    private var averageScore: Double {
        guard !dataPoints.isEmpty else { return 0 }
        let sum = dataPoints.reduce(0) { $0 + $1.score }
        return Double(sum) / Double(dataPoints.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.custom("PatrickHand-Regular", size: 20))
                    .foregroundStyle(JournalTheme.Colors.teal)

                Text("Fulfillment")
                    .font(JournalTheme.Fonts.sectionHeader())
                    .foregroundStyle(JournalTheme.Colors.inkBlue)

                Spacer()

                if !dataPoints.isEmpty {
                    Text("avg \(String(format: "%.1f", averageScore))")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                }
            }

            if dataPoints.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.custom("PatrickHand-Regular", size: 32))
                        .foregroundStyle(JournalTheme.Colors.completedGray)

                    Text("No reflections yet")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.completedGray)

                    Text("Write daily reflections in the Journal tab to see your fulfillment trend")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.completedGray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Line chart
                Chart {
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Score", point.score)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [JournalTheme.Colors.negativeRedDark, JournalTheme.Colors.amber, JournalTheme.Colors.goodDayGreenDark],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Score", point.score)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [JournalTheme.Colors.teal.opacity(0.2), JournalTheme.Colors.teal.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Score", point.score)
                        )
                        .foregroundStyle(chartPointColor(for: point.score))
                        .symbolSize(30)
                    }

                    // Average line
                    RuleMark(y: .value("Average", averageScore))
                        .foregroundStyle(JournalTheme.Colors.completedGray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }
                .chartYScale(domain: 1...10)
                .chartYAxis {
                    AxisMarks(values: [1, 5, 10]) { value in
                        AxisValueLabel()
                            .font(.custom("PatrickHand-Regular", size: 10))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                            .foregroundStyle(JournalTheme.Colors.lineLight)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(.custom("PatrickHand-Regular", size: 10))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                            .foregroundStyle(JournalTheme.Colors.lineLight)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }

    private func chartPointColor(for score: Int) -> Color {
        switch score {
        case 1...3: return JournalTheme.Colors.negativeRedDark
        case 4...5: return JournalTheme.Colors.amber
        case 6...7: return JournalTheme.Colors.teal
        case 8...10: return JournalTheme.Colors.goodDayGreenDark
        default: return JournalTheme.Colors.completedGray
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitGroup.self, DailyLog.self, DayRecord.self, EndOfDayNote.self], inMemory: true)
}
