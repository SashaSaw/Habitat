import SwiftUI

/// Main settings view — shown as a tab
struct SettingsView: View {
    @Bindable var store: HabitStore
    @State private var schedule = UserSchedule.shared
    @State private var showingBlockSetup = false
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Smart Reminders section
                    SmartReminderSettingsCard()

                    // Schedule section (wake/bed times)
                    scheduleCard

                    // Sound Effects toggle
                    HStack {
                        Image(systemName: soundEffectsEnabled ? "speaker.wave.2" : "speaker.slash")
                            .font(.system(size: 18))
                            .foregroundStyle(JournalTheme.Colors.teal)
                            .frame(width: 24)

                        Text("Sound Effects")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.inkBlack)

                        Spacer()

                        Toggle("", isOn: $soundEffectsEnabled)
                            .tint(JournalTheme.Colors.teal)
                            .labelsHidden()
                            .onChange(of: soundEffectsEnabled) { _, _ in
                                Feedback.selection()
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

                    // App Blocking button
                    Button {
                        Feedback.buttonPress()
                        showingBlockSetup = true
                    } label: {
                        HStack {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 18))
                                .foregroundStyle(JournalTheme.Colors.amber)

                            Text("App Blocking")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(JournalTheme.Colors.inkBlack)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(JournalTheme.Colors.completedGray)
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
                    }
                    .buttonStyle(.plain)

                    // Archived Habits
                    NavigationLink {
                        ArchivedHabitsListView(store: store)
                            .onAppear { Feedback.sheetOpen() }
                    } label: {
                        HStack {
                            Image(systemName: "archivebox")
                                .font(.system(size: 18))
                                .foregroundStyle(JournalTheme.Colors.completedGray)

                            Text("Archived Habits")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(JournalTheme.Colors.inkBlack)

                            Spacer()

                            if !store.archivedHabits.isEmpty {
                                Text("\(store.archivedHabits.count)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(JournalTheme.Colors.completedGray)
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
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .linedPaperBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBlockSetup) {
                BlockSetupView()
                    .onAppear { Feedback.sheetOpen() }
            }
            .onChange(of: schedule.wakeTimeMinutes) { _, _ in
                store.refreshSmartReminders()
            }
            .onChange(of: schedule.bedTimeMinutes) { _, _ in
                store.refreshSmartReminders()
            }
            .onChange(of: schedule.smartRemindersEnabled) { _, newValue in
                if newValue {
                    store.refreshSmartReminders()
                }
            }
        }
    }

    // MARK: - Schedule Card

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 18))
                    .foregroundStyle(JournalTheme.Colors.teal)

                Text("My Schedule")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
            }

            VStack(spacing: 12) {
                scheduleRow(label: "I wake up around", time: schedule.wakeTimeString, emoji: "🌅")
                scheduleRow(label: "I go to bed around", time: schedule.bedTimeString, emoji: "😴")
            }

            Text("Change your times to adjust reminder schedule.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.completedGray)

            // Time adjustment pickers
            VStack(spacing: 8) {
                HStack {
                    Text("Wake time")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack)
                    Spacer()
                    DatePicker("", selection: Binding(
                        get: { schedule.wakeTimeDate },
                        set: { newDate in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            schedule.wakeTimeMinutes = (comps.hour ?? 7) * 60 + (comps.minute ?? 0)
                        }
                    ), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(JournalTheme.Colors.navy)
                }

                HStack {
                    Text("Bed time")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack)
                    Spacer()
                    DatePicker("", selection: Binding(
                        get: { schedule.bedTimeDate },
                        set: { newDate in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            schedule.bedTimeMinutes = (comps.hour ?? 23) * 60 + (comps.minute ?? 0)
                        }
                    ), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(JournalTheme.Colors.navy)
                }
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
    }

    private func scheduleRow(label: String, time: String, emoji: String) -> some View {
        HStack {
            Text(emoji)
                .font(.system(size: 14))
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(JournalTheme.Colors.inkBlack)
            Spacer()
            Text(time)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(JournalTheme.Colors.amber)
        }
    }
}
