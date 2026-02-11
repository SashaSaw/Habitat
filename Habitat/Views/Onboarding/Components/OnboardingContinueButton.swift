import SwiftUI

/// Adaptive Continue/Skip button for onboarding screens
struct OnboardingContinueButton: View {
    let hasSelections: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(hasSelections ? "Continue" : "Skip")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(hasSelections ? Color.white : JournalTheme.Colors.navy)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(hasSelections ? JournalTheme.Colors.navy : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            hasSelections ? Color.clear : JournalTheme.Colors.lineLight,
                            lineWidth: 1.5
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: hasSelections)
    }
}
