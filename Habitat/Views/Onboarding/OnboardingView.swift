import SwiftUI

/// Main onboarding container — manages paged navigation through all screens
struct OnboardingView: View {
    let store: HabitStore
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var data = OnboardingData()

    private let totalPages = 7 // 0=Welcome, 1=Basics, 2=Responsibilities, 3=Fulfilment, 4=Schedule, 5=Refinement, 6=Complete

    var body: some View {
        ZStack {
            // Paper background
            LinedPaperBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar (visible on screens 1-5, not welcome or complete)
                if currentPage > 0 && currentPage < totalPages - 1 {
                    OnboardingProgressBar(current: currentPage, total: totalPages - 2)
                        .padding(.horizontal, 28)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }

                // Page content
                TabView(selection: $currentPage) {
                    WelcomeScreen(onContinue: { advance() })
                        .tag(0)

                    BasicsScreen(data: data, onContinue: { advance() })
                        .tag(1)

                    ResponsibilitiesScreen(data: data, onContinue: { advance() })
                        .tag(2)

                    FulfilmentScreen(data: data, onContinue: { advance() })
                        .tag(3)

                    ScheduleScreen(data: data, onContinue: { advance() })
                        .tag(4)

                    RefinementScreen(
                        data: data,
                        onContinue: { advance() },
                        onGoBack: { goBack(to: 1) }
                    )
                    .tag(5)

                    CompleteScreen(
                        data: data,
                        store: store,
                        onFinish: onComplete
                    )
                    .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)
            }
        }
    }

    // MARK: - Navigation

    private func advance() {
        // Generate draft habits before showing the refinement screen
        if currentPage == 4 {
            data.draftHabits = HabitGenerator.generate(from: data)
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
        HapticFeedback.selection()
    }

    private func goBack(to page: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentPage = max(page, 0)
        }
    }
}
