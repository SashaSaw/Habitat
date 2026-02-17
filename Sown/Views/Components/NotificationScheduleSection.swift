import SwiftUI

/// FormCard wrapper that shows the appropriate scheduler based on frequency type
struct NotificationScheduleSection: View {
    let frequencyType: FrequencyType
    @Binding var notificationsEnabled: Bool
    @Binding var dailyNotificationMinutes: [Int]
    @Binding var weeklyNotificationDays: Set<Int>

    var body: some View {
        FormCard(
            header: "Reminders",
            footer: footerText
        ) {
            CardToggle(label: "Enable notifications", isOn: $notificationsEnabled)

            if notificationsEnabled {
                Divider()
                    .padding(.vertical, 8)

                switch frequencyType {
                case .once:
                    EmptyView()

                case .daily:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tap timeline to add reminders")
                            .font(JournalTheme.Fonts.habitCriteria())
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        TimelineSchedulerView(notificationMinutes: $dailyNotificationMinutes)
                    }

                case .weekly:
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Remind me on")
                            .font(JournalTheme.Fonts.habitCriteria())
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        DaySelectorView(selectedDays: $weeklyNotificationDays)

                        Text("Notifications will be sent at 9:00 AM")
                            .font(.custom("PatrickHand-Regular", size: 11))
                            .foregroundStyle(JournalTheme.Colors.completedGray.opacity(0.7))
                    }

                case .monthly:
                    Text("Monthly notifications coming soon")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                }
            }
        }
    }

    private var footerText: String {
        if !notificationsEnabled {
            return "Get reminded to complete this habit"
        }
        switch frequencyType {
        case .once:
            return ""
        case .daily:
            return "Drag points to adjust times, tap to remove"
        case .weekly:
            return "You'll be notified at 9:00 AM on selected days"
        case .monthly:
            return ""
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var enabled = true
        @State var dailyMinutes: [Int] = [540, 720]
        @State var weeklyDays: Set<Int> = [2, 4, 6]

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    NotificationScheduleSection(
                        frequencyType: .daily,
                        notificationsEnabled: $enabled,
                        dailyNotificationMinutes: $dailyMinutes,
                        weeklyNotificationDays: $weeklyDays
                    )

                    NotificationScheduleSection(
                        frequencyType: .weekly,
                        notificationsEnabled: $enabled,
                        dailyNotificationMinutes: $dailyMinutes,
                        weeklyNotificationDays: $weeklyDays
                    )
                }
                .padding()
            }
            .background(JournalTheme.Colors.paper)
        }
    }

    return PreviewWrapper()
}
