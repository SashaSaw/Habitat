import SwiftUI

/// Thin ink-style progress line for onboarding screens
struct OnboardingProgressBar: View {
    let current: Int
    let total: Int

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(current) / CGFloat(total)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(JournalTheme.Colors.lineLight)
                    .frame(height: 3)

                // Fill
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(JournalTheme.Colors.navy)
                    .frame(width: geo.size.width * progress, height: 3)
                    .animation(.easeInOut(duration: 0.35), value: progress)
            }
        }
        .frame(height: 3)
    }
}
