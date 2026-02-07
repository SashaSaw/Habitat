import SwiftUI

/// Horizontal day-of-week selector for weekly habit notifications
struct DaySelectorView: View {
    @Binding var selectedDays: Set<Int>  // 1=Sunday, 2=Monday, ..., 7=Saturday

    // Days ordered Mon-Sun for display
    private let days: [(Int, String)] = [
        (2, "M"),   // Monday
        (3, "T"),   // Tuesday
        (4, "W"),   // Wednesday
        (5, "T"),   // Thursday
        (6, "F"),   // Friday
        (7, "S"),   // Saturday
        (1, "S")    // Sunday
    ]

    private let dayNames: [Int: String] = [
        1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days, id: \.0) { day in
                DayButton(
                    letter: day.1,
                    fullName: dayNames[day.0] ?? "",
                    isSelected: selectedDays.contains(day.0),
                    onTap: { toggleDay(day.0) }
                )
            }
        }
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

/// Individual day button
struct DayButton: View {
    let letter: String
    let fullName: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            Text(letter)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? JournalTheme.Colors.inkBlue : Color.clear)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.clear : JournalTheme.Colors.lineLight,
                            lineWidth: 1.5
                        )
                )
                .foregroundStyle(isSelected ? .white : JournalTheme.Colors.inkBlack)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(fullName), \(isSelected ? "selected" : "not selected")")
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var selectedDays: Set<Int> = [2, 4, 6] // Mon, Wed, Fri

        var body: some View {
            VStack {
                DaySelectorView(selectedDays: $selectedDays)
                Text("Selected: \(selectedDays.sorted().map { String($0) }.joined(separator: ", "))")
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
