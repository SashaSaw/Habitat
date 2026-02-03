import SwiftUI
import UIKit

/// Theme constants for the journal aesthetic
enum JournalTheme {
    // MARK: - Colors

    enum Colors {
        static let paper = Color(hex: "FDF8E7")
        static let paperDark = Color(hex: "F5EED6")
        static let lineLight = Color(hex: "D4D4D4")
        static let lineMedium = Color(hex: "B8C4CE")
        static let inkBlue = Color(hex: "1A365D")
        static let inkBlack = Color(hex: "2D2D2D")
        static let goodDayGreen = Color(hex: "C6F6D5")
        static let goodDayGreenDark = Color(hex: "68D391")
        static let negativeRed = Color(hex: "FED7D7")
        static let negativeRedDark = Color(hex: "FC8181")
        static let completedGray = Color(hex: "A0AEC0")
        static let sectionHeader = Color(hex: "4A5568")
    }

    // MARK: - Fonts

    enum Fonts {
        static func handwritten(size: CGFloat) -> Font {
            .system(size: size, weight: .medium, design: .rounded)
        }

        static func typewriter(size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }

        static func title() -> Font {
            .system(size: 28, weight: .bold, design: .rounded)
        }

        static func dateHeader() -> Font {
            .system(size: 22, weight: .bold, design: .rounded)
        }

        static func sectionHeader() -> Font {
            .system(size: 13, weight: .bold, design: .monospaced)
        }

        static func habitName() -> Font {
            .system(size: 17, weight: .regular, design: .rounded)
        }

        static func habitCriteria() -> Font {
            .system(size: 14, weight: .light, design: .rounded)
        }

        static func streakCount() -> Font {
            .system(size: 12, weight: .medium, design: .rounded)
        }
    }

    // MARK: - Dimensions

    enum Dimensions {
        static let lineSpacing: CGFloat = 32
        static let marginLeft: CGFloat = 48
        static let gridCellSize: CGFloat = 32
        static let cornerRadius: CGFloat = 8
        static let strokeWidth: CGFloat = 2
        static let checkmarkSize: CGFloat = 24
    }

    // MARK: - Animations

    enum Animations {
        static let strikethrough = Animation.easeOut(duration: 0.3)
        static let completion = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let fade = Animation.easeInOut(duration: 0.2)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    static func completion() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Haptic for crossing the completion threshold during swipe
    static func thresholdCrossed() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Stronger haptic for final completion confirmation
    static func completionConfirmed() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
