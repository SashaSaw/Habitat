import SwiftUI
import SwiftData

/// Redesigned detail view for a single habit — settings-row layout
struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore
    let habit: Habit

    @State private var showingDeleteConfirmation = false
    @State private var editingName = false
    @State private var editedName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                VStack(alignment: .center, spacing: 12) {
                    // Icon
                    habitIcon

                    // Editable name
                    if editingName {
                        HStack {
                            TextField("Habit name", text: $editedName)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(JournalTheme.Colors.inkBlack)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.plain)

                            Button("Save") {
                                habit.name = editedName.trimmingCharacters(in: .whitespaces)
                                store.updateHabit(habit)
                                editingName = false
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.teal)
                        }
                        .padding(.horizontal)
                    } else {
                        Text(habit.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.inkBlack)
                            .onTapGesture {
                                editedName = habit.name
                                editingName = true
                            }
                    }

                    // Badges
                    HStack(spacing: 8) {
                        Text(habit.tier.displayName.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(habit.tier == .mustDo ? JournalTheme.Colors.amber : JournalTheme.Colors.completedGray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(habit.tier == .mustDo ? JournalTheme.Colors.amber.opacity(0.12) : JournalTheme.Colors.lineLight.opacity(0.5))
                            )

                        Text(habit.frequencyDisplayName.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(JournalTheme.Colors.lineLight.opacity(0.5))
                            )

                        if habit.type == .negative {
                            Text("QUIT")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(JournalTheme.Colors.coral)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(JournalTheme.Colors.coral.opacity(0.12))
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                // MARK: - Stats Cards
                HabitStatsSection(habit: habit, store: store)

                // MARK: - Recent Activity
                RecentActivitySection(habit: habit)

                // MARK: - Hobby Logs
                if habit.isHobby || habit.enableNotesPhotos {
                    HobbyLogsSection(habit: habit)
                }

                // MARK: - Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("SETTINGS")
                        .font(JournalTheme.Fonts.sectionHeader())
                        .foregroundStyle(JournalTheme.Colors.sectionHeader)
                        .tracking(2)

                    VStack(spacing: 0) {
                        // Priority
                        settingsRow(
                            icon: "star.fill",
                            iconColor: JournalTheme.Colors.amber,
                            label: "Priority",
                            value: habit.tier.displayName
                        ) {
                            habit.tier = habit.tier == .mustDo ? .niceToDo : .mustDo
                            store.updateHabit(habit)
                        }

                        Divider().padding(.leading, 48)

                        // Frequency
                        settingsRow(
                            icon: "repeat",
                            iconColor: JournalTheme.Colors.teal,
                            label: "Frequency",
                            value: habit.frequencyDisplayName
                        ) {
                            // Would navigate to frequency editor — for now just cycles
                        }

                        Divider().padding(.leading, 48)

                        // Reminders
                        settingsRow(
                            icon: "bell.fill",
                            iconColor: JournalTheme.Colors.amber,
                            label: "Reminders",
                            value: habit.notificationsEnabled ? "On" : "Off"
                        ) {
                            habit.notificationsEnabled.toggle()
                            store.updateHabit(habit)
                        }

                        Divider().padding(.leading, 48)

                        // Notes & Photos toggle
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(JournalTheme.Colors.teal)
                                .frame(width: 24)

                            Text("Notes & photos")
                                .font(JournalTheme.Fonts.habitName())
                                .foregroundStyle(JournalTheme.Colors.inkBlack)

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { habit.enableNotesPhotos },
                                set: { newValue in
                                    habit.enableNotesPhotos = newValue
                                    habit.isHobby = newValue
                                    store.updateHabit(habit)
                                }
                            ))
                            .labelsHidden()
                            .tint(JournalTheme.Colors.teal)
                        }
                        .padding(14)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    )
                }

                // MARK: - Actions
                VStack(spacing: 12) {
                    Button {
                        if habit.isActive {
                            store.archiveHabit(habit)
                        } else {
                            store.unarchiveHabit(habit)
                        }
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: habit.isActive ? "archivebox" : "arrow.up.bin")
                            Text(habit.isActive ? "Archive habit" : "Unarchive habit")
                        }
                        .font(JournalTheme.Fonts.habitName())
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(JournalTheme.Colors.completedGray.opacity(0.5), lineWidth: 1.5)
                        )
                    }

                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete habit")
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

                Spacer(minLength: 100)
            }
            .padding()
        }
        .linedPaperBackground()
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Habit Icon

    @ViewBuilder
    private var habitIcon: some View {
        let iconSize: CGFloat = 72
        let emoji: String? = {
            for char in habit.name {
                if char.isEmoji { return String(char) }
            }
            return nil
        }()
        let initials: String = {
            let words = habit.name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if words.count >= 2 {
                return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
            }
            return String(habit.name.prefix(2)).uppercased()
        }()
        let bgColor: Color = habit.tier == .mustDo ? JournalTheme.Colors.inkBlue : JournalTheme.Colors.goodDayGreenDark

        ZStack {
            if let data = habit.iconImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(bgColor)
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 36))
                } else {
                    Text(initials)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Settings Row

    private func settingsRow(icon: String, iconColor: Color, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .frame(width: 24)

                Text(label)
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                Spacer()

                Text(value)
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}

/// Stats cards section
struct HabitStatsSection: View {
    let habit: Habit
    let store: HabitStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATISTICS")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.sectionHeader)
                .tracking(2)

            HStack(spacing: 16) {
                StatCard(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(habit.currentStreak)",
                    label: "Current Streak"
                )

                StatCard(
                    icon: "trophy.fill",
                    iconColor: .yellow,
                    value: "\(habit.bestStreak)",
                    label: "Best Streak"
                )
            }

            HStack(spacing: 16) {
                StatCard(
                    icon: "chart.pie.fill",
                    iconColor: JournalTheme.Colors.inkBlue,
                    value: "\(Int(store.completionRate(for: habit) * 100))%",
                    label: "30-Day Rate"
                )

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
            Text("LAST 7 DAYS")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.sectionHeader)
                .tracking(2)

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
            Text("HOBBY LOGS")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.sectionHeader)
                .tracking(2)

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
