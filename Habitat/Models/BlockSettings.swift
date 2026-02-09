import Foundation
import FamilyControls
import SwiftUI

/// Manages app blocking settings persisted via UserDefaults
@Observable
final class BlockSettings {
    static let shared = BlockSettings()

    /// Whether blocking is enabled globally
    var isEnabled: Bool {
        didSet { save() }
    }

    /// Block schedule start time (minutes from midnight)
    var scheduleStartMinutes: Int {
        didSet { save() }
    }

    /// Block schedule end time (minutes from midnight)
    var scheduleEndMinutes: Int {
        didSet { save() }
    }

    /// Which days of the week blocking is active (1=Sun, 7=Sat)
    var activeDays: Set<Int> {
        didSet { save() }
    }

    /// Temporary unlock: app name → expiry date
    var temporaryUnlocks: [String: Date] {
        didSet { save() }
    }

    // MARK: - Computed Properties

    /// Number of selected apps + categories from Screen Time selection
    var selectedCount: Int {
        let stm = ScreenTimeManager.shared
        return stm.activitySelection.applicationTokens.count
            + stm.activitySelection.categoryTokens.count
    }

    /// Formatted start time string
    var startTimeString: String {
        formatMinutes(scheduleStartMinutes)
    }

    /// Formatted end time string
    var endTimeString: String {
        formatMinutes(scheduleEndMinutes)
    }

    /// Start time as Date (today)
    var startTime: Date {
        get {
            Calendar.current.date(bySettingHour: scheduleStartMinutes / 60, minute: scheduleStartMinutes % 60, second: 0, of: Date()) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            scheduleStartMinutes = (components.hour ?? 9) * 60 + (components.minute ?? 0)
        }
    }

    /// End time as Date (today)
    var endTime: Date {
        get {
            Calendar.current.date(bySettingHour: scheduleEndMinutes / 60, minute: scheduleEndMinutes % 60, second: 0, of: Date()) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            scheduleEndMinutes = (components.hour ?? 21) * 60 + (components.minute ?? 0)
        }
    }

    /// Whether blocking is currently active (within schedule and has selections)
    var isCurrentlyActive: Bool {
        guard isEnabled, selectedCount > 0 else { return false }

        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)

        guard activeDays.contains(weekday) else { return false }

        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        if scheduleStartMinutes <= scheduleEndMinutes {
            return currentMinutes >= scheduleStartMinutes && currentMinutes < scheduleEndMinutes
        } else {
            // Wraps midnight
            return currentMinutes >= scheduleStartMinutes || currentMinutes < scheduleEndMinutes
        }
    }

    /// Time remaining in current block window
    var timeRemainingString: String? {
        guard isCurrentlyActive else { return nil }

        let now = Date()
        let calendar = Calendar.current
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        let remaining: Int
        if scheduleStartMinutes <= scheduleEndMinutes {
            remaining = scheduleEndMinutes - currentMinutes
        } else {
            if currentMinutes >= scheduleStartMinutes {
                remaining = (24 * 60 - currentMinutes) + scheduleEndMinutes
            } else {
                remaining = scheduleEndMinutes - currentMinutes
            }
        }

        let hours = remaining / 60
        let minutes = remaining % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }

    /// Check if a specific app is temporarily unlocked
    func isTemporarilyUnlocked(_ appName: String) -> Bool {
        guard let expiry = temporaryUnlocks[appName] else { return false }
        return Date() < expiry
    }

    /// Grant a 5-minute temporary unlock for an app
    func grantTemporaryUnlock(for appName: String) {
        temporaryUnlocks[appName] = Date().addingTimeInterval(5 * 60)
    }

    // MARK: - Persistence

    private static let settingsKey = "blockSettings_v2"

    private init() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: Self.settingsKey),
           let saved = try? JSONDecoder().decode(SavedBlockSettings.self, from: data) {
            self.isEnabled = saved.isEnabled
            self.scheduleStartMinutes = saved.scheduleStartMinutes
            self.scheduleEndMinutes = saved.scheduleEndMinutes
            self.activeDays = Set(saved.activeDays)
            self.temporaryUnlocks = saved.temporaryUnlocks
        } else {
            // Defaults
            self.isEnabled = false
            self.scheduleStartMinutes = 9 * 60 // 9:00 AM
            self.scheduleEndMinutes = 21 * 60 // 9:00 PM
            self.activeDays = Set(1...7) // Every day
            self.temporaryUnlocks = [:]
        }
    }

    private func save() {
        let saved = SavedBlockSettings(
            isEnabled: isEnabled,
            scheduleStartMinutes: scheduleStartMinutes,
            scheduleEndMinutes: scheduleEndMinutes,
            activeDays: Array(activeDays),
            temporaryUnlocks: temporaryUnlocks
        )
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.settingsKey)
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hour = minutes / 60
        let min = minutes % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, min, period)
    }
}

/// Codable wrapper for persistence
private struct SavedBlockSettings: Codable {
    let isEnabled: Bool
    let scheduleStartMinutes: Int
    let scheduleEndMinutes: Int
    let activeDays: [Int]
    let temporaryUnlocks: [String: Date]
}
