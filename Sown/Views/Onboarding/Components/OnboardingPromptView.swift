import SwiftUI

/// Shared journal-style prompt header for onboarding reflection screens
struct OnboardingPromptView: View {
    let question: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question)
                .font(.custom("PatrickHand-Regular", size: 24))
                .foregroundStyle(JournalTheme.Colors.navy)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(.custom("PatrickHand-Regular", size: 15))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
