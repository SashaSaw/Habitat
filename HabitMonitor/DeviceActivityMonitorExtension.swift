import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

/// DeviceActivityMonitor extension that applies/removes shields when the blocking schedule begins/ends
/// NOTE: Class name must match NSExtensionPrincipalClass in Info.plist
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()
    private static let selectionKey = "screenTimeSelection"
    private static let appGroupID = "group.com.incept5.Habitat"

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load the saved selection and apply shields
        guard let selection = loadSelection() else { return }

        let applications = selection.applicationTokens
        let categories = selection.categoryTokens

        if !applications.isEmpty {
            store.shield.applications = applications
        }
        if !categories.isEmpty {
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(categories)
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Remove all shields when the schedule ends
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
    }

    // MARK: - Load Selection

    /// Load FamilyActivitySelection from the shared App Group UserDefaults
    private func loadSelection() -> FamilyActivitySelection? {
        let defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        guard let data = defaults.data(forKey: Self.selectionKey) else { return nil }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}
