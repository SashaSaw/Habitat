import SwiftUI

struct NameScreen: View {
    let onContinue: () -> Void

    @AppStorage("userName") private var userName = ""
    @State private var nameInput = ""
    @FocusState private var nameFieldFocused: Bool

    @State private var showContent = false
    @State private var showButton = false

    private var hasName: Bool { !nameInput.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("What\u{2019}s your name?")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(JournalTheme.Colors.navy)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)

                Text("We\u{2019}ll use this to personalise your experience.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                TextField("Your name", text: $nameInput)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(JournalTheme.Colors.paperLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 48)
                    .focused($nameFieldFocused)
                    .submitLabel(.continue)
                    .onSubmit { if hasName { saveName(); onContinue() } }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
            }

            Spacer()

            // Button — only visible once name is entered
            if hasName {
                Button {
                    saveName()
                    onContinue()
                } label: {
                    Text("Continue")
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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hasName)
        .onAppear {
            nameInput = userName
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { showContent = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) { showButton = true }
        }
    }

    private func saveName() {
        userName = nameInput.trimmingCharacters(in: .whitespaces)
    }
}
