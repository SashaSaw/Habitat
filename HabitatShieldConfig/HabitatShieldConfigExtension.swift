import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Customizes the shield UI shown when a user tries to open a blocked app
class HabitatShieldConfigExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 253/255, green: 248/255, blue: 231/255, alpha: 1.0), // paper color
            icon: UIImage(systemName: "leaf.fill"),
            title: ShieldConfiguration.Label(
                text: "Time to focus",
                color: UIColor(red: 30/255, green: 42/255, blue: 74/255, alpha: 1.0) // inkBlack
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Open Habitat to see your habits for today",
                color: UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Habitat",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 212/255, green: 160/255, blue: 40/255, alpha: 1.0), // amber
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0)
            )
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Use the same configuration for category-based shields
        return configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 253/255, green: 248/255, blue: 231/255, alpha: 1.0),
            icon: UIImage(systemName: "leaf.fill"),
            title: ShieldConfiguration.Label(
                text: "Time to focus",
                color: UIColor(red: 30/255, green: 42/255, blue: 74/255, alpha: 1.0)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Open Habitat to see your habits for today",
                color: UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Habitat",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 212/255, green: 160/255, blue: 40/255, alpha: 1.0),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0)
            )
        )
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: webDomain)
    }
}
