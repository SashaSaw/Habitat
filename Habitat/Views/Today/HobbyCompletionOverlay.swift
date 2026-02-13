import SwiftUI
import UIKit

/// Wrapper to give UIImage a stable identity for ForEach
private struct IdentifiablePhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Overlay shown when completing a hobby, allowing photo/note capture (up to 3 photos)
struct HobbyCompletionOverlay: View {
    let habit: Habit
    let onSave: (String?, [UIImage]) -> Void
    let onDismiss: () -> Void

    @State private var note: String = ""
    @State private var selectedImages: [IdentifiablePhoto] = []
    @State private var showingImageSourcePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false

    private let maxPhotos = 3

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

                // Photo section — horizontal row of up to 3
                HStack(spacing: 12) {
                    ForEach(selectedImages) { item in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: item.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(JournalTheme.Colors.inkBlue, lineWidth: 1.5)
                                )

                            // Remove button
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedImages.removeAll { $0.id == item.id }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)).frame(width: 16, height: 16))
                            }
                            .offset(x: 4, y: -4)
                        }
                    }

                    // Add photo button (if under max)
                    if selectedImages.count < maxPhotos {
                        Button {
                            showingImageSourcePicker = true
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "camera")
                                    .font(.system(size: 24))
                                    .foregroundStyle(JournalTheme.Colors.completedGray)

                                Text(selectedImages.isEmpty ? "Add Photo" : "+")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            )
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
                        .foregroundStyle(JournalTheme.Colors.inkBlack)
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
                        onSave(noteToSave, selectedImages.map(\.image))
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
                if selectedImages.count < maxPhotos {
                    selectedImages.append(IdentifiablePhoto(image: image))
                }
            }
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary) { image in
                if selectedImages.count < maxPhotos {
                    selectedImages.append(IdentifiablePhoto(image: image))
                }
            }
        }
    }
}
