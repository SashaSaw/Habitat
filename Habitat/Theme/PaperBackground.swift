import SwiftUI

/// Lined paper background for Today View
struct LinedPaperBackground: View {
    let lineSpacing: CGFloat

    init(lineSpacing: CGFloat = JournalTheme.Dimensions.lineSpacing) {
        self.lineSpacing = lineSpacing
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base paper color
                JournalTheme.Colors.paper

                // Horizontal lines
                Canvas { context, size in
                    let lineColor = JournalTheme.Colors.lineLight.resolve(in: .init())

                    var y = lineSpacing
                    while y < size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))

                        context.stroke(
                            path,
                            with: .color(Color(lineColor)),
                            lineWidth: 0.5
                        )
                        y += lineSpacing
                    }
                }

                // Left margin line (optional, for more authentic look)
                Canvas { context, size in
                    let marginColor = JournalTheme.Colors.negativeRedDark.opacity(0.3).resolve(in: .init())

                    var path = Path()
                    path.move(to: CGPoint(x: 40, y: 0))
                    path.addLine(to: CGPoint(x: 40, y: size.height))

                    context.stroke(
                        path,
                        with: .color(Color(marginColor)),
                        lineWidth: 0.5
                    )
                }

                // Paper texture overlay (subtle noise)
                PaperTexture()
                    .opacity(0.03)
            }
        }
        .ignoresSafeArea()
    }
}

/// Graph/squared paper background for Month Grid View
struct GraphPaperBackground: View {
    let cellSize: CGFloat

    init(cellSize: CGFloat = JournalTheme.Dimensions.gridCellSize) {
        self.cellSize = cellSize
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base paper color
                JournalTheme.Colors.paper

                // Grid lines
                Canvas { context, size in
                    let lineColor = JournalTheme.Colors.lineLight.resolve(in: .init())

                    // Vertical lines
                    var x: CGFloat = 0
                    while x < size.width {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))

                        context.stroke(
                            path,
                            with: .color(Color(lineColor)),
                            lineWidth: 0.5
                        )
                        x += cellSize
                    }

                    // Horizontal lines
                    var y: CGFloat = 0
                    while y < size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))

                        context.stroke(
                            path,
                            with: .color(Color(lineColor)),
                            lineWidth: 0.5
                        )
                        y += cellSize
                    }
                }

                // Paper texture overlay
                PaperTexture()
                    .opacity(0.03)
            }
        }
        .ignoresSafeArea()
    }
}

/// Subtle paper texture - simplified for performance
/// Using a simple gradient overlay instead of random dots
struct PaperTexture: View {
    var body: some View {
        // Simple subtle texture using a gradient - much more performant
        LinearGradient(
            colors: [
                Color.black.opacity(0.02),
                Color.clear,
                Color.black.opacity(0.01)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Modifier for Paper Backgrounds

struct LinedPaperModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(LinedPaperBackground())
    }
}

struct GraphPaperModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(GraphPaperBackground())
    }
}

extension View {
    func linedPaperBackground() -> some View {
        modifier(LinedPaperModifier())
    }

    func graphPaperBackground() -> some View {
        modifier(GraphPaperModifier())
    }
}

#Preview("Lined Paper") {
    LinedPaperBackground()
}

#Preview("Graph Paper") {
    GraphPaperBackground()
}
