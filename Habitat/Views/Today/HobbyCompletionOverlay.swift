import SwiftUI

/// Overlay shown when completing a hobby, allowing photo/note capture
struct HobbyCompletionOverlay: View {
    let habit: Habit
    let onSave: (String?, UIImage?) -> Void
    let onDismiss: () -> Void

    @State private var note: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showingImageSourcePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false

    var body: some View {
        ZStack {
            // Semi-transparent background - tap to dismiss
            Color.white.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Content card
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.inkBlack)

                    Text("Completed!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(JournalTheme.Colors.goodDayGreenDark)
                }

                // Photo section
                Button {
                    showingImageSourcePicker = true
                } label: {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(JournalTheme.Colors.inkBlue, lineWidth: 2)
                            )
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.system(size: 32))
                                .foregroundStyle(JournalTheme.Colors.completedGray)

                            Text("Add Photo")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                        }
                        .frame(width: 120, height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                        )
                    }
                }
                .confirmationDialog("Add Photo", isPresented: $showingImageSourcePicker) {
                    if ImagePicker.isCameraAvailable {
                        Button("Take Photo") {
                            showingCamera = true
                        }
                    }
                    Button("Choose from Library") {
                        showingPhotoLibrary = true
                    }
                    if selectedImage != nil {
                        Button("Remove Photo", role: .destructive) {
                            selectedImage = nil
                        }
                    }
                }

                // Note section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JournalTheme.Colors.completedGray)

                    TextEditor(text: $note)
                        .font(JournalTheme.Fonts.habitName())
                        .frame(height: 80)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(JournalTheme.Colors.lineLight, lineWidth: 1)
                        )
                }

                // Buttons
                HStack(spacing: 16) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(JournalTheme.Colors.completedGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(JournalTheme.Colors.lineLight, lineWidth: 1)
                            )
                    }

                    Button {
                        let noteToSave = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
                        onSave(noteToSave, selectedImage)
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(JournalTheme.Colors.inkBlue)
                            )
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            )
            .padding(.horizontal, 32)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                selectedImage = image
            }
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary) { image in
                selectedImage = image
            }
        }
    }
}
