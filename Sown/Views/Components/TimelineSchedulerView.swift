import SwiftUI

/// Interactive timeline for scheduling daily habit notifications
struct TimelineSchedulerView: View {
    @Binding var notificationMinutes: [Int]  // Minutes from midnight (0-1440)
    let maxPoints: Int = 5

    private let hourMarkers = [0, 6, 12, 18, 24]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Timeline with points
            GeometryReader { geometry in
                let trackWidth = geometry.size.width

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(JournalTheme.Colors.lineLight)
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)

                    // Notification points
                    ForEach(Array(notificationMinutes.enumerated()), id: \.offset) { index, minutes in
                        TimelinePoint(
                            minutes: minutes,
                            trackWidth: trackWidth,
                            onDrag: { newMinutes in
                                updatePoint(at: index, to: newMinutes)
                            },
                            onRemove: {
                                removePoint(at: index)
                            }
                        )
                    }
                }
                .frame(height: 50)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    addPoint(at: location.x, trackWidth: trackWidth)
                }
            }
            .frame(height: 50)

            // Hour markers
            HStack {
                ForEach(hourMarkers, id: \.self) { hour in
                    Text(formatHour(hour))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                    if hour < 24 {
                        Spacer()
                    }
                }
            }

            // Point count and instructions
            HStack {
                Text("\(notificationMinutes.count)/\(maxPoints) reminders")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)

                Spacer()

                if notificationMinutes.count > 0 {
                    Text("Tap point to remove")
                        .font(.system(size: 11))
                        .foregroundStyle(JournalTheme.Colors.completedGray.opacity(0.7))
                }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 || hour == 24 {
            return "00:00"
        }
        return String(format: "%02d:00", hour)
    }

    private func addPoint(at x: CGFloat, trackWidth: CGFloat) {
        guard notificationMinutes.count < maxPoints else { return }

        let minutes = Int((x / trackWidth) * 1440)
        let clampedMinutes = max(0, min(1440, minutes))

        // Snap to 5-minute increments
        let snappedMinutes = (clampedMinutes / 5) * 5

        // Don't add if too close to existing point (within 15 minutes)
        let tooClose = notificationMinutes.contains { abs($0 - snappedMinutes) < 15 }
        guard !tooClose else { return }

        notificationMinutes.append(snappedMinutes)
        notificationMinutes.sort()

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func updatePoint(at index: Int, to minutes: Int) {
        guard index < notificationMinutes.count else { return }

        // Snap to 5-minute increments
        let snappedMinutes = (minutes / 5) * 5
        notificationMinutes[index] = max(0, min(1440, snappedMinutes))
    }

    private func removePoint(at index: Int) {
        guard index < notificationMinutes.count else { return }
        notificationMinutes.remove(at: index)

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

/// Individual draggable point on the timeline
struct TimelinePoint: View {
    let minutes: Int
    let trackWidth: CGFloat
    let onDrag: (Int) -> Void
    let onRemove: () -> Void

    @State private var isDragging = false

    private var xPosition: CGFloat {
        (CGFloat(minutes) / 1440.0) * trackWidth
    }

    private var timeString: String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }

    var body: some View {
        VStack(spacing: 2) {
            // Time label
            Text(timeString)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(JournalTheme.Colors.inkBlue)
                .opacity(isDragging ? 1 : 0.9)

            // Point marker
            Circle()
                .fill(JournalTheme.Colors.inkBlue)
                .frame(width: isDragging ? 18 : 14, height: isDragging ? 18 : 14)
                .shadow(color: .black.opacity(0.2), radius: isDragging ? 4 : 2, y: 1)
        }
        .position(x: xPosition, y: 25)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let newMinutes = Int((value.location.x / trackWidth) * 1440)
                    onDrag(newMinutes)
                }
                .onEnded { _ in
                    isDragging = false
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                }
        )
        .onTapGesture {
            onRemove()
        }
        .animation(.easeOut(duration: 0.15), value: isDragging)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var minutes: [Int] = [540, 720, 1080] // 9am, 12pm, 6pm

        var body: some View {
            VStack {
                TimelineSchedulerView(notificationMinutes: $minutes)
                Text("Times: \(minutes.map { "\($0/60):\(String(format: "%02d", $0%60))" }.joined(separator: ", "))")
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
