import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void

    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showPromise = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // App icon
                VStack(spacing: 4) {
                    Text("\u{1F331}")
                        .font(.system(size: 56))
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 10)
                }

                // Title
                Text("Welcome to Sown")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(JournalTheme.Colors.navy)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 15)

                // Subtitle
                Text("Before we start, let\u{2019}s take a moment\nto think about your day.")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 10)

                // Promise
                Text("You\u{2019}ll be ready in about 60 seconds.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.amber)
                    .italic()
                    .opacity(showPromise ? 1 : 0)
                    .offset(y: showPromise ? 0 : 10)
            }

            Spacer()

            // Button
            Button(action: onContinue) {
                Text("Let\u{2019}s begin")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(JournalTheme.Colors.navy)
                    )
            }
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { showTitle = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) { showSubtitle = true }
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) { showPromise = true }
            withAnimation(.easeOut(duration: 0.5).delay(1.3)) { showButton = true }
        }
    }
}
