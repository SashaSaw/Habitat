import SwiftUI

/// Screen 1: Physiological needs (Maslow Level 1)
struct BasicsScreen: View {
    @Bindable var data: OnboardingData
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Prompt
                OnboardingPromptView(
                    question: "What do you need every day to feel okay?",
                    subtitle: "The non-negotiables. The stuff that keeps you running."
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

                // Suggestion pills
                SuggestionPillGrid(
                    suggestions: HabitSuggestion.basics,
                    selectedNames: $data.selectedBasics,
                    customPills: $data.customBasics
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

                // Add custom pill
                AddCustomPillField(
                    placeholder: "e.g. Stretch, Skincare routine...",
                    selectedNames: $data.selectedBasics,
                    customPills: $data.customBasics
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                OnboardingContinueButton(
                    hasSelections: !data.selectedBasics.isEmpty,
                    action: onContinue
                )
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
            .background(
                LinearGradient(
                    colors: [JournalTheme.Colors.paper.opacity(0), JournalTheme.Colors.paper],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .allowsHitTesting(false)
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                appeared = true
            }
        }
    }
}
