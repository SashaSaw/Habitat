import SwiftUI

/// Settings card for enabling HealthKit integration
struct HealthKitSettingsCard: View {
    @State private var healthKitManager = HealthKitManager.shared
    @State private var isEnabled: Bool = false
    @State private var showingAuthError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with toggle
            HStack {
                Image(systemName: "heart.fill")
                    .font(.custom("PatrickHand-Regular", size: 18))
                    .foregroundStyle(.red)

                Text("Apple Health")
                    .font(.custom("PatrickHand-Regular", size: 17))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                Spacer()

                if healthKitManager.isAvailable {
                    Toggle("", isOn: $isEnabled)
                        .tint(.red)
                        .labelsHidden()
                        .onChange(of: isEnabled) { _, newValue in
                            handleToggleChange(newValue)
                        }
                } else {
                    Text("Not Available")
                        .font(.custom("PatrickHand-Regular", size: 13))
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                }
            }

            if healthKitManager.isAvailable {
                if isEnabled && healthKitManager.isAuthorized {
                    // Enabled state
                    Text("Link habits to Apple Health metrics for automatic tracking when you reach your goals.")
                        .font(.custom("PatrickHand-Regular", size: 13))
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                        .fixedSize(horizontal: false, vertical: true)

                    // Supported metrics list
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SUPPORTED METRICS")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                            .tracking(1.5)

                        FlowLayout(spacing: 8) {
                            ForEach(HealthKitMetricType.allCases, id: \.self) { metric in
                                HStack(spacing: 4) {
                                    Image(systemName: metric.icon)
                                        .font(.custom("PatrickHand-Regular", size: 11))
                                    Text(metric.displayName)
                                        .font(.custom("PatrickHand-Regular", size: 11))
                                }
                                .foregroundStyle(JournalTheme.Colors.inkBlack)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(JournalTheme.Colors.lineLight.opacity(0.5))
                                )
                            }
                        }
                    }
                } else if !isEnabled {
                    // Disabled state
                    Text("Enable to auto-complete habits when you hit step goals, exercise minutes, and more.")
                        .font(.custom("PatrickHand-Regular", size: 13))
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                // Not available (iPad, etc.)
                Text("Apple Health is not available on this device.")
                    .font(.custom("PatrickHand-Regular", size: 13))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(JournalTheme.Colors.paperLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
        )
        .onAppear {
            isEnabled = healthKitManager.isAuthorized
        }
        .alert("Health Access Required", isPresented: $showingAuthError) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                isEnabled = false
            }
        } message: {
            Text("Please enable Health access for Sown in Settings to use this feature.")
        }
    }

    private func handleToggleChange(_ newValue: Bool) {
        Feedback.selection()

        if newValue {
            // Request authorization
            Task {
                let authorized = await healthKitManager.requestAuthorization()
                await MainActor.run {
                    if authorized {
                        isEnabled = true
                    } else {
                        // Authorization request failed (e.g., HealthKit unavailable)
                        isEnabled = false
                        showingAuthError = true
                    }
                }
            }
        } else {
            // User disabled - just turn off (we can't revoke HealthKit permissions)
            isEnabled = false
        }
    }
}

#Preview {
    VStack {
        HealthKitSettingsCard()
            .padding()
    }
    .linedPaperBackground()
}
