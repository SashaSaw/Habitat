import Foundation
import UserNotifications

/// Service for managing habit reminder notifications
final class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission Handling

    /// Requests notification permission from the user
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    /// Checks the current notification permission status
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Notification Scheduling

    /// Schedules all notifications for a habit based on its frequency type
    func scheduleNotifications(for habit: Habit) async {
        // First, cancel existing notifications for this habit
        await cancelNotifications(for: habit)

        guard habit.notificationsEnabled else { return }

        switch habit.frequencyType {
        case .once:
            // Tasks don't have notifications
            break
        case .daily:
            await scheduleDailyNotifications(for: habit)
        case .weekly:
            await scheduleWeeklyNotifications(for: habit)
        case .monthly:
            // Future implementation
            break
        }
    }

    private func scheduleDailyNotifications(for habit: Habit) async {
        for (index, minutes) in habit.dailyNotificationMinutes.enumerated() {
            let identifier = notificationIdentifier(for: habit, index: index)

            var dateComponents = DateComponents()
            dateComponents.hour = minutes / 60
            dateComponents.minute = minutes % 60

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let content = UNMutableNotificationContent()
            content.title = "Habit Reminder"
            content.body = "Time to: \(habit.name)"
            content.sound = .default
            content.categoryIdentifier = "HABIT_REMINDER"
            content.userInfo = ["habitId": habit.id.uuidString]

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to schedule daily notification: \(error)")
            }
        }
    }

    private func scheduleWeeklyNotifications(for habit: Habit) async {
        let notificationTime = habit.weeklyNotificationTime
        let hour = notificationTime / 60
        let minute = notificationTime % 60

        for (index, weekday) in habit.weeklyNotificationDays.enumerated() {
            let identifier = notificationIdentifier(for: habit, index: index)

            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let content = UNMutableNotificationContent()
            content.title = "Habit Reminder"
            content.body = "Don't forget: \(habit.name)"
            content.sound = .default
            content.categoryIdentifier = "HABIT_REMINDER"
            content.userInfo = ["habitId": habit.id.uuidString]

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to schedule weekly notification: \(error)")
            }
        }
    }

    // MARK: - Notification Cancellation

    /// Cancels all notifications for a specific habit
    func cancelNotifications(for habit: Habit) async {
        // Cancel up to max possible notifications (5 for daily, 7 for weekly)
        let maxNotifications = 10
        let identifiers = (0..<maxNotifications).map { index in
            notificationIdentifier(for: habit, index: index)
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancels all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func notificationIdentifier(for habit: Habit, index: Int) -> String {
        "habit_\(habit.id.uuidString)_\(index)"
    }

    /// Returns all pending notification requests (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}
