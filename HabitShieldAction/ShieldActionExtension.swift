import ManagedSettings
import UserNotifications

/// Handles button taps on the shield screen
/// NOTE: Class name must match NSExtensionPrincipalClass in Info.plist
class ShieldActionExtension: ShieldActionDelegate {

    private static let appGroupID = "group.com.incept5.SeedBed"

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // "Open SeedBed" — fire a notification to open the app, then close shield
            sendOpenSeedBedNotification()
            completionHandler(.close)
        case .secondaryButtonPressed:
            // "Close" — defer to keep the shield in place
            completionHandler(.defer)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            sendOpenSeedBedNotification()
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            sendOpenSeedBedNotification()
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.close)
        }
    }

    // MARK: - Open SeedBed via Local Notification

    /// Sends an immediate local notification that, when tapped, opens SeedBed
    private func sendOpenSeedBedNotification() {
        // Also write a flag so the app knows to show InterceptView
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        defaults?.set(Date().timeIntervalSince1970, forKey: "interceptRequested")

        let content = UNMutableNotificationContent()
        content.title = "Open SeedBed"
        content.body = "Tap to choose the person you want to be."
        content.sound = nil
        content.categoryIdentifier = "OPEN_SEEDBED"

        // Fire immediately (1 second delay — minimum for a trigger)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "seedbed.open.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[ShieldAction] Failed to send notification: \(error)")
            }
        }
    }
}
