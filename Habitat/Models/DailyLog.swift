import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    var completed: Bool
    var value: Double?
    var note: String?
    var photoPath: String?
    var selectedOption: String?

    // Relationship to habit
    var habit: Habit?

    init(
        id: UUID = UUID(),
        date: Date,
        completed: Bool = false,
        value: Double? = nil,
        note: String? = nil,
        photoPath: String? = nil,
        selectedOption: String? = nil,
        habit: Habit? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.completed = completed
        self.value = value
        self.note = note
        self.photoPath = photoPath
        self.selectedOption = selectedOption
        self.habit = habit
    }
}

// MARK: - DailyLog Extensions

extension DailyLog {
    /// Returns true if this log has any hobby content (note or photo)
    var hasContent: Bool {
        (note != nil && !note!.isEmpty) || (photoPath != nil && !photoPath!.isEmpty)
    }

    /// Creates or updates a log for a habit on a specific date
    static func createOrUpdate(
        for habit: Habit,
        on date: Date,
        completed: Bool,
        value: Double? = nil,
        note: String? = nil,
        photoPath: String? = nil,
        context: ModelContext
    ) -> DailyLog {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Check if log already exists
        if let existingLog = habit.log(for: date) {
            existingLog.completed = completed
            existingLog.value = value
            // Always update note and photoPath when explicitly provided
            if note != nil {
                existingLog.note = note
            }
            if photoPath != nil {
                existingLog.photoPath = photoPath
            }
            return existingLog
        }

        // Create new log
        let newLog = DailyLog(
            date: startOfDay,
            completed: completed,
            value: value,
            note: note,
            photoPath: photoPath,
            habit: habit
        )
        context.insert(newLog)
        habit.dailyLogs.append(newLog)
        return newLog
    }
}
