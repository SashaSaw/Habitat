import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitDescription: String
    var tier: HabitTier
    var type: HabitType
    var frequencyType: FrequencyType
    var frequencyTarget: Int
    var successCriteria: String?
    var groupId: UUID?
    var currentStreak: Int
    var bestStreak: Int
    var isActive: Bool
    var createdAt: Date
    var sortOrder: Int
    var isHobby: Bool = false
    @Attribute(.externalStorage) var iconImageData: Data? = nil

    // Options: different ways to complete this habit (e.g. ["Gym", "Swim", "Run"] for "Exercise")
    var options: [String] = []

    // Whether notes & photos are enabled for this habit (replaces isHobby concept)
    var enableNotesPhotos: Bool = false

    // Notification scheduling
    var notificationsEnabled: Bool = false
    var dailyNotificationMinutes: [Int] = []      // Minutes from midnight (0-1440), up to 5
    var weeklyNotificationDays: [Int] = []        // Weekday indices (1=Sun, 2=Mon, ..., 7=Sat)
    var weeklyNotificationTime: Int = 540         // Default 9:00 AM

    // Relationship to daily logs
    @Relationship(deleteRule: .cascade, inverse: \DailyLog.habit)
    var dailyLogs: [DailyLog] = []

    init(
        id: UUID = UUID(),
        name: String,
        habitDescription: String = "",
        tier: HabitTier = .mustDo,
        type: HabitType = .positive,
        frequencyType: FrequencyType = .daily,
        frequencyTarget: Int = 1,
        successCriteria: String? = nil,
        groupId: UUID? = nil,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        isActive: Bool = true,
        createdAt: Date = Date(),
        sortOrder: Int = 0,
        isHobby: Bool = false
    ) {
        self.id = id
        self.name = name
        self.habitDescription = habitDescription
        self.tier = tier
        self.type = type
        self.frequencyType = frequencyType
        self.frequencyTarget = frequencyTarget
        self.successCriteria = successCriteria
        self.groupId = groupId
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.isActive = isActive
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.isHobby = isHobby
    }

    /// Returns the display text for the habit (name + criteria if applicable)
    var displayText: String {
        if let criteria = successCriteria, !criteria.isEmpty {
            return "\(name) - \(criteria)"
        }
        return name
    }

    /// Checks if this habit belongs to a group
    var isInGroup: Bool {
        groupId != nil
    }

    /// Whether this is a one-off task (not a recurring habit)
    var isTask: Bool {
        frequencyType == .once
    }

    /// Whether this habit has options (multiple ways to complete)
    var hasOptions: Bool {
        !options.isEmpty
    }

    /// Returns the frequency display name
    var frequencyDisplayName: String {
        switch frequencyType {
        case .once:
            return "Today only"
        case .daily:
            return "Daily"
        case .weekly:
            return "\(frequencyTarget)x per week"
        case .monthly:
            return "\(frequencyTarget)x per month"
        }
    }
}

// MARK: - Habit Extensions for Completion Checking

extension Habit {
    /// Gets the log for a specific date
    func log(for date: Date) -> DailyLog? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return dailyLogs.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }
    }

    /// Checks if the habit is completed for a specific date
    func isCompleted(for date: Date) -> Bool {
        guard let log = log(for: date) else { return false }
        return log.completed
    }

    /// Gets the completion value for a specific date (for measurable habits)
    func completionValue(for date: Date) -> Double? {
        guard let log = log(for: date) else { return nil }
        return log.value
    }

    /// Counts completions within a date range
    func completionCount(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        return dailyLogs.filter { log in
            log.completed &&
            calendar.compare(log.date, to: startDate, toGranularity: .day) != .orderedAscending &&
            calendar.compare(log.date, to: endDate, toGranularity: .day) != .orderedDescending
        }.count
    }
}
