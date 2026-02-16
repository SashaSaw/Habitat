import SwiftUI

/// Main onboarding container — manages paged navigation through all screens
struct OnboardingView: View {
    let store: HabitStore
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var highestPageReached = 0
    @State private var data = OnboardingData()

    // 0=Welcome, 1=Name, 2=Basics, 3=Responsibilities, 4=TodayTasks, 5=Fulfilment, 6=Schedule, 7=Refinement, 8=Complete
    private let totalPages = 9
    /// Index of the Schedule screen (draft habits generated when leaving it)
    private let schedulePageIndex = 6

    var body: some View {
        ZStack {
            // Paper background
            LinedPaperBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar (visible on screens 2-7, not welcome/name or complete)
                if currentPage > 1 && currentPage < totalPages - 1 {
                    OnboardingProgressBar(current: currentPage - 1, total: totalPages - 3)
                        .padding(.horizontal, 28)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }

                // Page content
                TabView(selection: $currentPage) {
                    WelcomeScreen(onContinue: { advance() })
                        .tag(0)

                    NameScreen(onContinue: { advance() })
                        .tag(1)

                    BasicsScreen(data: data, onContinue: { advance() })
                        .tag(2)

                    ResponsibilitiesScreen(data: data, onContinue: { advance() })
                        .tag(3)

                    TodayTasksScreen(data: data, onContinue: { advance() })
                        .tag(4)

                    FulfilmentScreen(data: data, onContinue: { advance() })
                        .tag(5)

                    ScheduleScreen(data: data, onContinue: { advance() })
                        .tag(6)

                    RefinementScreen(
                        data: data,
                        onContinue: { advance() },
                        onGoBack: { goBack(to: 2) }
                    )
                    .tag(7)

                    CompleteScreen(
                        data: data,
                        store: store,
                        onFinish: onComplete
                    )
                    .tag(8)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)
            }
        }
        .onChange(of: currentPage) { oldPage, newPage in
            // When user swipes forward past a page they haven't visited, treat it like continue/skip
            if newPage > highestPageReached {
                // Generate draft habits when swiping past the schedule screen
                if oldPage == schedulePageIndex {
                    data.draftHabits = HabitGenerator.generate(from: data)
                }
                highestPageReached = newPage
                Feedback.selection()
            }
        }
    }

    // MARK: - Navigation

    private func advance() {
        // Generate draft habits before showing the refinement screen
        if currentPage == schedulePageIndex {
            data.draftHabits = HabitGenerator.generate(from: data)
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
        highestPageReached = max(highestPageReached, currentPage)
        Feedback.selection()
    }

    private func goBack(to page: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentPage = max(page, 0)
        }
    }
}
