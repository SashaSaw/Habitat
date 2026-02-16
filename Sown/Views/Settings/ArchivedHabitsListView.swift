import SwiftUI

/// Shows all archived habits with options to unarchive or delete
struct ArchivedHabitsListView: View {
    @Bindable var store: HabitStore
    @State private var habitToDelete: Habit?
    @State private var showDeleteConfirmation = false
    @AppStorage("hasSeenArchiveHint") private var hasSeenArchiveHint = false
    @State private var showHint = false

    var body: some View {
        Group {
            if store.archivedHabits.isEmpty {
                ScrollView {
                    VStack(spacing: 8) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 36))
                            .foregroundStyle(JournalTheme.Colors.completedGray.opacity(0.5))

                        Text("No archived habits")
                            .font(JournalTheme.Fonts.habitName())
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        Text("Habits you archive will appear here")
                            .font(JournalTheme.Fonts.habitCriteria())
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
                .linedPaperBackground()
            } else {
                List {
                    if showHint {
                        HStack(alignment: .top, spacing: 10) {
                            Text("💡")
                                .font(.system(size: 16))

                            Text("Swipe left to delete a habit, or swipe right to restore it.")
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.sectionHeader)

                            Spacer()

                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showHint = false
                                    hasSeenArchiveHint = true
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }
                        }
                        .padding(12)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(JournalTheme.Colors.amber.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(JournalTheme.Colors.amber.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.horizontal, 16)
                        )
                        .listRowSeparator(.hidden)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    ForEach(store.archivedHabits) { habit in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.name)
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                                Text(habit.tier.displayName)
                                    .font(JournalTheme.Fonts.habitCriteria())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }

                            Spacer()

                            Button {
                                store.unarchiveHabit(habit)
                            } label: {
                                Text("Restore")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(JournalTheme.Colors.inkBlue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .strokeBorder(JournalTheme.Colors.inkBlue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(JournalTheme.Colors.paper)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                habitToDelete = habit
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                store.unarchiveHabit(habit)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(JournalTheme.Colors.inkBlue)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .linedPaperBackground()
                .onAppear {
                    if !hasSeenArchiveHint {
                        withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
                            showHint = true
                        }
                    }
                }
            }
        }
        .navigationTitle("Archived Habits")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Habit?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                habitToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let habit = habitToDelete {
                    store.deleteHabit(habit)
                }
                habitToDelete = nil
            }
        } message: {
            Text("This will permanently delete '\(habitToDelete?.name ?? "")' and all its history.")
        }
    }
}
