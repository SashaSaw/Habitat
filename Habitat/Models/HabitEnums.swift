import Foundation

/// Represents the tier/priority level of a habit
enum HabitTier: String, Codable, CaseIterable, Sendable {
    case mustDo = "must_do"
    case niceToDo = "nice_to_do"

    var displayName: String {
        switch self {
        case .mustDo: return "Must Do"
        case .niceToDo: return "Nice To Do"
        }
    }
}

/// Represents whether a habit is positive (to do) or negative (to avoid)
enum HabitType: String, Codable, CaseIterable, Sendable {
    case positive
    case negative

    var displayName: String {
        switch self {
        case .positive: return "Positive"
        case .negative: return "Negative"
        }
    }

    var description: String {
        switch self {
        case .positive: return "Something to do"
        case .negative: return "Something to avoid"
        }
    }
}

/// Represents the frequency type without associated values (for SwiftData compatibility)
enum FrequencyType: String, Codable, CaseIterable, Sendable {
    case daily
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
