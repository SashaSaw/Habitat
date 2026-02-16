import SwiftUI

/// Sheet for creating or editing an end-of-day reflection note
struct EndOfDayNoteView: View {
    @Bindable var store: HabitStore
    let date: Date
    let onDismiss: () -> Void

    @State private var noteText: String = ""
    @State private var score: Int = 5
    @State private var isEditing: Bool = false
    @State private var existingNote: EndOfDayNote? = nil

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }

    private var isLocked: Bool {
        existingNote?.isLocked == true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Date header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(JournalTheme.Colors.inkBlack)

                        if store.isGoodDay(for: date) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(JournalTheme.Colors.goodDayGreenDark)
                                    .frame(width: 8, height: 8)
                                Text("Good Day")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(JournalTheme.Colors.goodDayGreenDark)
                            }
                        }
                    }

                    // Fulfillment score
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HOW FULFILLED DO YOU FEEL?")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)

                        if isLocked {
                            // Read-only score display
                            HStack(spacing: 4) {
                                ForEach(1...10, id: \.self) { value in
                                    Circle()
                                        .fill(value <= score ? scoreColor(for: score) : JournalTheme.Colors.lineLight)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Text("\(value)")
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundStyle(value <= score ? .white : JournalTheme.Colors.completedGray)
                                        )
                                }
                            }
                        } else {
                            // Interactive score selector
                            HStack(spacing: 4) {
                                ForEach(1...10, id: \.self) { value in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            score = value
                                        }
                                        Feedback.selection()
                                    } label: {
                                        Circle()
                                            .fill(value <= score ? scoreColor(for: score) : JournalTheme.Colors.lineLight)
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Text("\(value)")
                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                    .foregroundStyle(value <= score ? .white : JournalTheme.Colors.completedGray)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Text(scoreLabel(for: score))
                            .font(JournalTheme.Fonts.habitCriteria())
                            .foregroundStyle(scoreColor(for: score))
                    }

                    // Reflection note
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REFLECTION")
                            .font(JournalTheme.Fonts.sectionHeader())
                            .foregroundStyle(JournalTheme.Colors.sectionHeader)
                            .tracking(2)

                        if isLocked {
                            // Read-only note display
                            Text(noteText.isEmpty ? "No reflection recorded" : noteText)
                                .font(JournalTheme.Fonts.habitName())
                                .foregroundStyle(noteText.isEmpty ? JournalTheme.Colors.completedGray : JournalTheme.Colors.inkBlack)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.7))
                                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                )
                        } else {
                            TextEditor(text: $noteText)
                                .font(JournalTheme.Fonts.habitName())
                                .foregroundStyle(JournalTheme.Colors.inkBlack)
                                .frame(minHeight: 150)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(JournalTheme.Colors.lineLight, lineWidth: 1)
                                )
                                .overlay(alignment: .topLeading) {
                                    if noteText.isEmpty {
                                        Text("How was your day? What went well? What could be better?")
                                            .font(JournalTheme.Fonts.habitName())
                                            .foregroundStyle(JournalTheme.Colors.completedGray.opacity(0.5))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 20)
                                            .allowsHitTesting(false)
                                    }
                                }
                        }
                    }

                    // Lock indicator
                    if isLocked {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                            Text("This entry is now locked and can no longer be edited")
                                .font(JournalTheme.Fonts.habitCriteria())
                        }
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(JournalTheme.Colors.lineLight.opacity(0.5))
                        )
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .linedPaperBackground()
            .navigationTitle("Daily Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Feedback.buttonPress()
                        onDismiss()
                    }
                }

                if !isLocked {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Feedback.buttonPress()
                            store.saveEndOfDayNote(for: date, note: noteText, fulfillmentScore: score)
                            onDismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            loadExisting()
        }
    }

    // MARK: - Helpers

    private func loadExisting() {
        if let existing = store.endOfDayNote(for: date) {
            existingNote = existing
            noteText = existing.note
            score = existing.fulfillmentScore
            isEditing = true
        }
    }

    private func scoreColor(for value: Int) -> Color {
        switch value {
        case 1...3: return JournalTheme.Colors.negativeRedDark
        case 4...5: return JournalTheme.Colors.amber
        case 6...7: return JournalTheme.Colors.teal
        case 8...10: return JournalTheme.Colors.goodDayGreenDark
        default: return JournalTheme.Colors.completedGray
        }
    }

    private func scoreLabel(for value: Int) -> String {
        switch value {
        case 1: return "Very unfulfilled"
        case 2: return "Unfulfilled"
        case 3: return "Somewhat unfulfilled"
        case 4: return "Slightly below average"
        case 5: return "Neutral"
        case 6: return "Somewhat fulfilled"
        case 7: return "Fulfilled"
        case 8: return "Very fulfilled"
        case 9: return "Extremely fulfilled"
        case 10: return "Peak fulfillment"
        default: return ""
        }
    }
}
