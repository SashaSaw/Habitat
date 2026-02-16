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
        case .positive: return "Build a habit"
        case .negative: return "Quit a habit"
        }
    }

    var description: String {
        switch self {
        case .positive: return "Something you want to do"
        case .negative: return "Something you want to stop"
        }
    }
}

/// Represents the frequency type without associated values (for SwiftData compatibility)
enum FrequencyType: String, Codable, CaseIterable, Sendable {
    case once
    case daily
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .once: return "Just today"
        case .daily: return "Every day"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }

    /// Whether this frequency type represents a one-off task
    var isTask: Bool {
        self == .once
    }

    /// Cases shown in the add flow frequency picker (all cases)
    static var addFlowCases: [FrequencyType] {
        [.once, .daily, .weekly, .monthly]
    }

    /// Cases for recurring habits only (excludes once)
    static var recurringCases: [FrequencyType] {
        [.daily, .weekly, .monthly]
    }
}
