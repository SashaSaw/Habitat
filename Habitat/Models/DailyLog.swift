import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    var completed: Bool
    var value: Double?

    // Relationship to habit
    var habit: Habit?

    init(
        id: UUID = UUID(),
        date: Date,
        completed: Bool = false,
        value: Double? = nil,
        habit: Habit? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.completed = completed
        self.value = value
        self.habit = habit
    }
}

// MARK: - DailyLog Extensions

extension DailyLog {
    /// Creates or updates a log for a habit on a specific date
    static func createOrUpdate(
        for habit: Habit,
        on date: Date,
        completed: Bool,
        value: Double? = nil,
        context: ModelContext
    ) -> DailyLog {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Check if log already exists
        if let existingLog = habit.log(for: date) {
            existingLog.completed = completed
            existingLog.value = value
            return existingLog
        }

        // Create new log
        let newLog = DailyLog(
            date: startOfDay,
            completed: completed,
            value: value,
            habit: habit
        )
        context.insert(newLog)
        habit.dailyLogs.append(newLog)
        return newLog
    }
}
