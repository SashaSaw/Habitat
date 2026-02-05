import SwiftUI

/// Helper struct for hobby log sheet presentation (used by both MonthGridView and HabitDetailView)
struct HobbyLogSelection: Identifiable {
    let id = UUID()
    let habit: Habit
    let date: Date
}

/// Sheet to view notes and photos from a hobby log in the month grid
struct HobbyLogDetailSheet: View {
    let habit: Habit
    let date: Date
    let onDismiss: () -> Void

    @State private var loadedImage: UIImage? = nil
    @State private var currentLog: DailyLog? = nil

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(habit.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.inkBlack)

                        Text(dateFormatter.string(from: date))
                            .font(JournalTheme.Fonts.habitCriteria())
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    }
                    .padding(.bottom, 8)

                    // Photo section
                    if let image = loadedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo")
                                .font(JournalTheme.Fonts.sectionHeader())
                                .foregroundStyle(JournalTheme.Colors.inkBlue)

                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        }
                    }

                    // Note section
                    if let log = currentLog, let note = log.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(JournalTheme.Fonts.sectionHeader())
                                .foregroundStyle(JournalTheme.Colors.inkBlue)

                            Text(note)
                                .font(JournalTheme.Fonts.habitName())
                                .foregroundStyle(JournalTheme.Colors.inkBlack)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.7))
                                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                )
                        }
                    }

                    // Empty state
                    if loadedImage == nil && (currentLog?.note == nil || currentLog?.note?.isEmpty == true) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundStyle(JournalTheme.Colors.completedGray)

                            Text("No photo or notes recorded")
                                .font(JournalTheme.Fonts.habitName())
                                .foregroundStyle(JournalTheme.Colors.completedGray)

                            Text("Photos and notes are added when completing a hobby")
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .linedPaperBackground()
            .navigationTitle("Hobby Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        // Find the log for this date
        currentLog = habit.dailyLogs.first { log in
            Calendar.current.isDate(log.date, inSameDayAs: date) && log.completed
        }

        // Load photo if available
        if let photoPath = currentLog?.photoPath {
            loadedImage = PhotoStorageService.shared.loadPhoto(from: photoPath)
        }
    }
}
