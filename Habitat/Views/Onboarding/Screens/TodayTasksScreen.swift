import SwiftUI

/// Onboarding screen for one-off today tasks
struct TodayTasksScreen: View {
    @Bindable var data: OnboardingData
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Prompt
                OnboardingPromptView(
                    question: "Anything you need to get done today?",
                    subtitle: "These are one-off tasks, not habits. They disappear once done."
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

                // Task pills
                VStack(alignment: .leading, spacing: 12) {
                    if !data.todayTasks.isEmpty {
                        FlowLayout(spacing: 10) {
                            ForEach(data.todayTasks, id: \.self) { task in
                                OnboardingTaskPill(name: task) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        data.todayTasks.removeAll { $0 == task }
                                        data.selectedTasks.remove(task)
                                    }
                                    HapticFeedback.selection()
                                }
                            }
                        }
                    }

                    // Add task field
                    AddCustomPillField(
                        placeholder: "e.g. Pay electricity bill, Book dentist...",
                        selectedNames: $data.selectedTasks,
                        customPills: $data.todayTasks
                    )
                }
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
                    hasSelections: !data.todayTasks.isEmpty,
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

// MARK: - Task Pill (teal accent, X to remove)

struct OnboardingTaskPill: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 6) {
                Text("\u{1F4CC}")
                    .font(.system(size: 15))
                Text(name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(JournalTheme.Colors.teal)
            )
        }
        .buttonStyle(.plain)
    }
}
