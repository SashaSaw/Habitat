import SwiftUI
import Foundation

/// Hand-drawn style checkmark
struct HandDrawnCheckmark: View {
    let size: CGFloat
    let color: Color
    var animated: Bool = false

    @State private var animationProgress: CGFloat = 0

    init(size: CGFloat = 20, color: Color = JournalTheme.Colors.inkBlue, animated: Bool = false) {
        self.size = size
        self.color = color
        self.animated = animated
    }

    var body: some View {
        Canvas { context, canvasSize in
            let progress = animated ? animationProgress : 1.0

            var path = Path()

            let startX = canvasSize.width * 0.15
            let startY = canvasSize.height * 0.55
            let midX = canvasSize.width * 0.4
            let midY = canvasSize.height * 0.8
            let endX = canvasSize.width * 0.9
            let endY = canvasSize.height * 0.2

            path.move(to: CGPoint(x: startX, y: startY))

            let wobble1 = CGPoint(
                x: (startX + midX) / 2 + CGFloat.random(in: -2...2),
                y: (startY + midY) / 2 + CGFloat.random(in: -2...2)
            )
            path.addQuadCurve(
                to: CGPoint(x: midX, y: midY),
                control: wobble1
            )

            let wobble2 = CGPoint(
                x: (midX + endX) / 2 + CGFloat.random(in: -2...2),
                y: (midY + endY) / 2 + CGFloat.random(in: -2...2)
            )
            path.addQuadCurve(
                to: CGPoint(x: endX, y: endY),
                control: wobble2
            )

            let trimmedPath = path.trimmedPath(from: 0, to: progress)

            context.stroke(
                trimmedPath,
                with: .color(color),
                style: StrokeStyle(
                    lineWidth: 2.5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.3)) {
                    animationProgress = 1.0
                }
            }
        }
    }
}

/// Hand-drawn style cross/X mark
struct HandDrawnCross: View {
    let size: CGFloat
    let color: Color
    var animated: Bool = false

    @State private var animationProgress: CGFloat = 0

    init(size: CGFloat = 20, color: Color = JournalTheme.Colors.negativeRedDark, animated: Bool = false) {
        self.size = size
        self.color = color
        self.animated = animated
    }

    var body: some View {
        Canvas { context, canvasSize in
            let progress = animated ? animationProgress : 1.0

            var path1 = Path()
            path1.move(to: CGPoint(x: canvasSize.width * 0.2, y: canvasSize.height * 0.2))
            path1.addQuadCurve(
                to: CGPoint(x: canvasSize.width * 0.8, y: canvasSize.height * 0.8),
                control: CGPoint(
                    x: canvasSize.width * 0.5 + CGFloat.random(in: -3...3),
                    y: canvasSize.height * 0.5 + CGFloat.random(in: -3...3)
                )
            )

            var path2 = Path()
            path2.move(to: CGPoint(x: canvasSize.width * 0.8, y: canvasSize.height * 0.2))
            path2.addQuadCurve(
                to: CGPoint(x: canvasSize.width * 0.2, y: canvasSize.height * 0.8),
                control: CGPoint(
                    x: canvasSize.width * 0.5 + CGFloat.random(in: -3...3),
                    y: canvasSize.height * 0.5 + CGFloat.random(in: -3...3)
                )
            )

            let trimmedPath1 = path1.trimmedPath(from: 0, to: min(progress * 2, 1))
            let trimmedPath2 = path2.trimmedPath(from: 0, to: max(0, progress * 2 - 1))

            context.stroke(
                trimmedPath1,
                with: .color(color),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )

            context.stroke(
                trimmedPath2,
                with: .color(color),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.4)) {
                    animationProgress = 1.0
                }
            }
        }
    }
}

/// Hand-drawn strikethrough line shape
struct StrikethroughShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard progress > 0 else { return path }

        let startY = rect.midY
        let actualWidth = rect.width

        // Simple slightly wavy line
        path.move(to: CGPoint(x: 0, y: startY))

        // Create a hand-drawn looking line with slight wave
        let midPoint = actualWidth / 2
        path.addQuadCurve(
            to: CGPoint(x: midPoint, y: startY - 1),
            control: CGPoint(x: midPoint / 2, y: startY + 1)
        )
        path.addQuadCurve(
            to: CGPoint(x: actualWidth, y: startY),
            control: CGPoint(x: midPoint + midPoint / 2, y: startY - 1)
        )

        return path.trimmedPath(from: 0, to: progress)
    }
}

/// Hand-drawn strikethrough line for completed habits
/// Now accepts external progress binding for swipe gesture control
struct StrikethroughLine: View {
    let width: CGFloat
    let color: Color
    @Binding var progress: CGFloat

    init(width: CGFloat, color: Color = JournalTheme.Colors.inkBlue, progress: Binding<CGFloat>) {
        self.width = width
        self.color = color
        self._progress = progress
    }

    var body: some View {
        StrikethroughShape(progress: progress)
            .stroke(color, style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                lineJoin: .round
            ))
            .frame(width: width, height: 4)
    }
}

/// Empty checkbox circle
struct EmptyCheckbox: View {
    let size: CGFloat
    let color: Color

    init(size: CGFloat = 22, color: Color = JournalTheme.Colors.inkBlue.opacity(0.4)) {
        self.size = size
        self.color = color
    }

    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: 1.5)
            .frame(width: size, height: size)
    }
}

/// Completion indicator that shows either checkbox, checkmark, or cross
struct CompletionIndicator: View {
    let isCompleted: Bool
    let habitType: HabitType
    var animated: Bool = false

    var body: some View {
        Group {
            if isCompleted {
                if habitType == .positive {
                    HandDrawnCheckmark(animated: animated)
                } else {
                    HandDrawnCross(animated: animated)
                }
            } else {
                EmptyCheckbox()
            }
        }
    }
}

#Preview("Checkmark") {
    VStack(spacing: 20) {
        HandDrawnCheckmark(size: 30, animated: false)
        HandDrawnCheckmark(size: 30, color: .green, animated: true)
    }
    .padding()
}

#Preview("Cross") {
    VStack(spacing: 20) {
        HandDrawnCross(size: 30, animated: false)
        HandDrawnCross(size: 30, animated: true)
    }
    .padding()
}

#Preview("Strikethrough") {
    struct PreviewWrapper: View {
        @State private var progress: CGFloat = 1.0
        var body: some View {
            VStack(spacing: 20) {
                Text("Complete this task")
                    .overlay(alignment: .leading) {
                        StrikethroughLine(width: 150, progress: $progress)
                    }
                Slider(value: $progress, in: 0...1)
                    .padding()
                Button("Toggle") {
                    withAnimation {
                        progress = progress == 1.0 ? 0.0 : 1.0
                    }
                }
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
