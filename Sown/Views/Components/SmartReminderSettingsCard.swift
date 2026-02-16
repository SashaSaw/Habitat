import SwiftUI

/// Reusable card showing smart reminder settings
/// Used in onboarding ScheduleScreen and in the main app settings
struct SmartReminderSettingsCard: View {
    @State private var schedule = UserSchedule.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "bell.badge")
                    .font(.system(size: 18))
                    .foregroundStyle(JournalTheme.Colors.amber)

                Text("Smart Reminders")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                Spacer()

                Toggle("", isOn: $schedule.smartRemindersEnabled)
                    .tint(JournalTheme.Colors.amber)
                    .labelsHidden()
            }

            if schedule.smartRemindersEnabled {
                // Explanation
                Text("You'll get 5 nudges throughout the day, timed around your habits.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .fixedSize(horizontal: false, vertical: true)

                // Reminder timeline
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(schedule.allReminderSlots.enumerated()), id: \.offset) { index, slot in
                        reminderRow(
                            number: index + 1,
                            time: formatMinutes(slot.minutes),
                            label: slot.label,
                            description: reminderDescription(for: index)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(JournalTheme.Colors.paperLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
        )
        .onChange(of: schedule.smartRemindersEnabled) { _, newValue in
            if !newValue {
                Task {
                    await SmartReminderService.shared.cancelAllSmartReminders()
                }
            }
        }
    }

    // MARK: - Row

    private func reminderRow(number: Int, time: String, label: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Time badge
            Text(time)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(JournalTheme.Colors.amber)
                .frame(width: 68, alignment: .trailing)

            // Dot connector
            Circle()
                .fill(JournalTheme.Colors.amber)
                .frame(width: 8, height: 8)
                .padding(.top, 4)

            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                Text(description)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Helpers

    private func reminderDescription(for index: Int) -> String {
        switch index {
        case 0: return "Write any tasks and start morning habits"
        case 1: return "Reminder to complete morning habits"
        case 2: return "Check-in on daytime habits"
        case 3: return "Finish hobbies and evening habits"
        case 4: return "Final habits before winding down"
        default: return ""
        }
    }

    private func formatMinutes(_ totalMinutes: Int) -> String {
        let hour = totalMinutes / 60
        let minute = totalMinutes % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}
