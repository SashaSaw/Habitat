import SwiftUI
import SwiftData

/// Detailed view for a single habit
struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore
    let habit: Habit

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HabitDetailHeader(habit: habit)

                // Stats Cards
                HabitStatsSection(habit: habit, store: store)

                // Recent Activity
                RecentActivitySection(habit: habit)

                // Hobby Logs Section (only for hobbies with content)
                if habit.isHobby {
                    HobbyLogsSection(habit: habit)
                }

                // Actions
                ActionsSection(
                    onEdit: { showingEditSheet = true },
                    onDelete: { showingDeleteConfirmation = true }
                )

                Spacer(minLength: 100)
            }
            .padding()
        }
        .linedPaperBackground()
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(store: store, habit: habit)
        }
        .alert("Delete Habit?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteHabit(habit)
                dismiss()
            }
        } message: {
            Text("This will permanently delete '\(habit.name)' and all its history.")
        }
    }
}

/// Header showing habit name and basic info
struct HabitDetailHeader: View {
    let habit: Habit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Type badge
            HStack {
                Text(habit.tier.displayName.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(habit.tier == .mustDo ? JournalTheme.Colors.inkBlue : JournalTheme.Colors.completedGray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(habit.tier == .mustDo ? JournalTheme.Colors.inkBlue.opacity(0.1) : JournalTheme.Colors.lineLight.opacity(0.5))
                    )

                Text(habit.type.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(habit.type == .positive ? JournalTheme.Colors.goodDayGreenDark : JournalTheme.Colors.negativeRedDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(habit.type == .positive ? JournalTheme.Colors.goodDayGreen.opacity(0.3) : JournalTheme.Colors.negativeRed.opacity(0.3))
                    )

                Spacer()
            }

            // Name and criteria
            Text(habit.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack)

            if let criteria = habit.successCriteria, !criteria.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 14))
                    Text("Target: \(criteria)")
                        .font(JournalTheme.Fonts.habitName())
                }
                .foregroundStyle(JournalTheme.Colors.completedGray)
            }

            if !habit.habitDescription.isEmpty {
                Text(habit.habitDescription)
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }

            // Frequency
            HStack(spacing: 4) {
                Image(systemName: "repeat")
                    .font(.system(size: 14))
                Text(habit.frequencyDisplayName)
                    .font(JournalTheme.Fonts.habitCriteria())
            }
            .foregroundStyle(JournalTheme.Colors.completedGray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

/// Stats cards section
struct HabitStatsSection: View {
    let habit: Habit
    let store: HabitStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.inkBlue)

            HStack(spacing: 16) {
                // Current streak
                StatCard(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(habit.currentStreak)",
                    label: "Current Streak"
                )

                // Best streak
                StatCard(
                    icon: "trophy.fill",
                    iconColor: .yellow,
                    value: "\(habit.bestStreak)",
                    label: "Best Streak"
                )
            }

            HStack(spacing: 16) {
                // Completion rate
                StatCard(
                    icon: "chart.pie.fill",
                    iconColor: JournalTheme.Colors.inkBlue,
                    value: "\(Int(store.completionRate(for: habit) * 100))%",
                    label: "30-Day Rate"
                )

                // Total completions
                let totalCompletions = habit.dailyLogs.filter { $0.completed }.count
                StatCard(
                    icon: "checkmark.circle.fill",
                    iconColor: JournalTheme.Colors.goodDayGreenDark,
                    value: "\(totalCompletions)",
                    label: "Total Done"
                )
            }
        }
    }
}

/// Individual stat card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack)

            Text(label)
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

/// Recent activity section showing last 7 days
struct RecentActivitySection: View {
    let habit: Habit

    private var last7Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.inkBlue)

            HStack(spacing: 8) {
                ForEach(last7Days, id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(dayFormatter.string(from: date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        if habit.isCompleted(for: date) {
                            HandDrawnCheckmark(size: 24, color: JournalTheme.Colors.inkBlue)
                        } else {
                            Circle()
                                .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1.5)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .frame(maxWidth: .infinity)
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
}

/// Actions section with edit and delete buttons
struct ActionsSection: View {
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button {
                onEdit()
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Habit")
                }
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(JournalTheme.Colors.inkBlue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(JournalTheme.Colors.inkBlue, lineWidth: 1.5)
                )
            }

            Button {
                onDelete()
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
        }
    }
}

/// Section showing hobby logs with photos and notes
struct HobbyLogsSection: View {
    let habit: Habit

    @State private var selectedLogDate: HobbyLogSelection? = nil

    private var logsWithContent: [DailyLog] {
        habit.dailyLogs
            .filter { $0.completed && $0.hasContent }
            .sorted { $0.date > $1.date }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hobby Logs")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.inkBlue)

            if logsWithContent.isEmpty {
                Text("No photos or notes recorded yet")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    )
            } else {
                VStack(spacing: 8) {
                    ForEach(logsWithContent.prefix(5)) { log in
                        HobbyLogRow(log: log, dateFormatter: dateFormatter)
                            .onTapGesture {
                                selectedLogDate = HobbyLogSelection(habit: habit, date: log.date)
                            }
                    }

                    if logsWithContent.count > 5 {
                        Text("+ \(logsWithContent.count - 5) more entries")
                            .font(JournalTheme.Fonts.habitCriteria())
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .sheet(item: $selectedLogDate) { selection in
            HobbyLogDetailSheet(
                habit: selection.habit,
                date: selection.date,
                onDismiss: {
                    selectedLogDate = nil
                }
            )
        }
    }
}

/// A single row showing a hobby log entry
struct HobbyLogRow: View {
    let log: DailyLog
    let dateFormatter: DateFormatter

    @State private var loadedImage: UIImage? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or placeholder
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if log.photoPath != nil {
                RoundedRectangle(cornerRadius: 8)
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "note.text")
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(dateFormatter.string(from: log.date))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                if let note = log.note, !note.isEmpty {
                    Text(note)
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(JournalTheme.Colors.completedGray)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
        .onAppear {
            loadPhoto()
        }
    }

    private func loadPhoto() {
        if let photoPath = log.photoPath {
            loadedImage = PhotoStorageService.shared.loadPhoto(from: photoPath)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: config)
    let store = HabitStore(modelContext: container.mainContext)

    let habit = Habit(
        name: "Drink water",
        habitDescription: "Stay hydrated throughout the day",
        tier: .mustDo,
        type: .positive,
        successCriteria: "3L",
        currentStreak: 7,
        bestStreak: 14
    )
    container.mainContext.insert(habit)

    return NavigationStack {
        HabitDetailView(store: store, habit: habit)
    }
}
