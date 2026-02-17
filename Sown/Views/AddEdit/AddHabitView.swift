import SwiftUI
import SwiftData
import PhotosUI

/// Wrapper to make UIImage identifiable for sheet presentation
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Reusable Form Card Component

/// A white card container for form sections
struct FormCard<Content: View>: View {
    let header: String?
    let footer: String?
    @ViewBuilder let content: () -> Content

    init(header: String? = nil, footer: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let header = header {
                Text(header.uppercased())
                    .font(JournalTheme.Fonts.sectionHeader())
                    .foregroundStyle(JournalTheme.Colors.inkBlue)
                    .tracking(1.5)
                    .padding(.horizontal, 4)
            }

            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )

            if let footer = footer {
                Text(footer)
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// Styled text field for the card-based form
struct CardTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(label)
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                if isRequired {
                    Text("*")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.negativeRedDark)
                }
            }

            TextField(placeholder, text: $text)
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(JournalTheme.Colors.inkBlack)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(JournalTheme.Colors.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                        )
                )
        }
    }
}

/// Styled segmented picker for the card-based form
struct CardSegmentedPicker<T: Hashable & CaseIterable & RawRepresentable>: View where T.AllCases: RandomAccessCollection, T.RawValue == String {
    let label: String
    @Binding var selection: T
    let displayName: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)

            HStack(spacing: 0) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = option
                        }
                    } label: {
                        Text(displayName(option))
                            .font(JournalTheme.Fonts.habitName())
                            .foregroundStyle(selection == option ? .white : JournalTheme.Colors.inkBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selection == option ? JournalTheme.Colors.inkBlue : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(JournalTheme.Colors.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1)
                    )
            )
        }
    }
}

/// Styled toggle for the card-based form
struct CardToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(JournalTheme.Colors.inkBlack)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(JournalTheme.Colors.inkBlue)
                .labelsHidden()
        }
    }
}

// MARK: - Icon Picker Component

/// Displays a habit icon that can be tapped to change the image
struct HabitIconPicker: View {
    let name: String
    let tier: HabitTier
    @Binding var iconImageData: Data?

    @State private var showingImageSourcePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageToCrop: IdentifiableImage?

    private let iconSize: CGFloat = 80

    /// Custom image from data if available
    private var customImage: UIImage? {
        guard let data = iconImageData else { return nil }
        return UIImage(data: data)
    }

    /// Extracts the first emoji from the name
    private var emoji: String? {
        for char in name {
            if char.isEmoji {
                return String(char)
            }
        }
        return nil
    }

    /// Returns 1-2 letter initials
    private var initials: String {
        let words = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count >= 2 {
            let first = words[0].prefix(1)
            let second = words[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    /// Background color based on tier
    private var backgroundColor: Color {
        switch tier {
        case .mustDo:
            return JournalTheme.Colors.inkBlue
        case .niceToDo:
            return JournalTheme.Colors.goodDayGreenDark
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Icon preview
            ZStack {
                if let customImage = customImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(backgroundColor)
                        .frame(width: iconSize, height: iconSize)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

                    if let emoji = emoji {
                        Text(emoji)
                            .font(.custom("PatrickHand-Regular", size: 40))
                    } else if !name.isEmpty {
                        Text(initials)
                            .font(.custom("PatrickHand-Regular", size: 28))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "photo")
                            .font(.custom("PatrickHand-Regular", size: 28))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Edit overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "pencil.circle.fill")
                            .font(.custom("PatrickHand-Regular", size: 24))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(JournalTheme.Colors.inkBlue)
                                    .frame(width: 26, height: 26)
                            )
                            .offset(x: 4, y: 4)
                    }
                }
                .frame(width: iconSize, height: iconSize)
            }
            .onTapGesture {
                showingImageSourcePicker = true
            }

            Text("Tap to change icon")
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
        }
        .confirmationDialog("Choose Image Source", isPresented: $showingImageSourcePicker) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingPhotoPicker = true
            }
            if iconImageData != nil {
                Button("Remove Custom Icon", role: .destructive) {
                    iconImageData = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        imageToCrop = IdentifiableImage(image: image)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                if let image = image {
                    imageToCrop = IdentifiableImage(image: image)
                }
            }
        }
        .fullScreenCover(item: $imageToCrop) { identifiableImage in
            ImageCropperView(image: identifiableImage.image) { croppedImage in
                if let croppedImage = croppedImage {
                    saveImage(croppedImage)
                }
                imageToCrop = nil
            }
            .id(identifiableImage.id)
        }
    }

    private func saveImage(_ image: UIImage) {
        // Resize to final size and compress for storage
        let targetSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        iconImageData = resizedImage.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Image Cropper View

/// Full-screen view for cropping an image to a square
struct ImageCropperView: View {
    let image: UIImage
    let onComplete: (UIImage?) -> Void

    @Environment(\.dismiss) private var dismiss

    // The offset of the image relative to the crop area
    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero

    // Scale for pinch-to-zoom
    @State private var imageScale: CGFloat = 1.0
    @State private var lastImageScale: CGFloat = 1.0

    // Computed image size for display
    @State private var displayImageSize: CGSize = .zero

    // Size of the square crop area
    private let cropSize: CGFloat = 280

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                let viewSize = geometry.size

                ZStack {
                    // The image (can be dragged and scaled)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: viewSize.width)
                        .scaleEffect(imageScale)
                        .offset(imageOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    imageOffset = CGSize(
                                        width: lastImageOffset.width + value.translation.width,
                                        height: lastImageOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastImageOffset = imageOffset
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastImageScale * value
                                    imageScale = min(max(newScale, 0.5), 5.0)
                                }
                                .onEnded { _ in
                                    lastImageScale = imageScale
                                }
                        )
                        .onAppear {
                            // Reset state for fresh start
                            imageOffset = .zero
                            lastImageOffset = .zero
                            imageScale = 1.0
                            lastImageScale = 1.0
                            initializeScale(viewWidth: viewSize.width)
                        }

                    // Dark overlay with transparent crop hole
                    CropOverlay(cropSize: cropSize, viewSize: viewSize)
                        .allowsHitTesting(false)

                    // Crop border
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: cropSize, height: cropSize)
                        .allowsHitTesting(false)
                }
            }

            // Header and footer overlay
            VStack(spacing: 0) {
                // Header with background extending into safe area
                HStack {
                    Button("Cancel") {
                        Feedback.buttonPress()
                        onComplete(nil)
                        dismiss()
                    }
                    .font(.body)
                    .foregroundStyle(.white)

                    Spacer()

                    Text("Move and Scale")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Button("Done") {
                        Feedback.buttonPress()
                        let cropped = cropImage(viewWidth: UIScreen.main.bounds.width)
                        onComplete(cropped)
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .padding(.top, 60) // Fixed padding below notch/dynamic island
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.6))

                Spacer()

                // Instructions
                Text("Drag to position, pinch to zoom")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 16)
                    .padding(.bottom, 40) // Fixed padding above home indicator
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.6))
            }
            .ignoresSafeArea()
        }
    }

    private func initializeScale(viewWidth: CGFloat) {
        // Calculate the display size of the image
        let imageAspect = image.size.width / image.size.height

        let displayWidth = viewWidth
        let displayHeight = viewWidth / imageAspect

        // Scale so the smaller dimension fills the crop area
        let scaleToFillWidth = cropSize / displayWidth
        let scaleToFillHeight = cropSize / displayHeight

        // Use the larger scale to ensure crop area is filled
        imageScale = max(scaleToFillWidth, scaleToFillHeight, 1.0)
        lastImageScale = imageScale
    }

    private func cropImage(viewWidth: CGFloat) -> UIImage? {
        let imageSize = image.size
        let imageAspect = imageSize.width / imageSize.height

        // Calculate how the image is displayed
        let displayWidth = viewWidth
        let displayHeight = viewWidth / imageAspect

        // Apply our scale
        let scaledWidth = displayWidth * imageScale
        let scaledHeight = displayHeight * imageScale

        // The ratio to convert from display to image coordinates
        let ratioX = imageSize.width / scaledWidth
        let ratioY = imageSize.height / scaledHeight

        // The crop square is centered in the view
        // The image is offset by imageOffset from center
        // So the crop center in image-relative coordinates is at (-offset)
        let cropCenterInScaledImage = CGPoint(
            x: scaledWidth / 2 - imageOffset.width,
            y: scaledHeight / 2 - imageOffset.height
        )

        // Convert to actual image coordinates
        let cropCenterInImage = CGPoint(
            x: cropCenterInScaledImage.x * ratioX,
            y: cropCenterInScaledImage.y * ratioY
        )

        // Crop size in image coordinates
        let cropSizeInImage = cropSize * ratioX

        // Create crop rect
        var cropRect = CGRect(
            x: cropCenterInImage.x - cropSizeInImage / 2,
            y: cropCenterInImage.y - cropSizeInImage / 2,
            width: cropSizeInImage,
            height: cropSizeInImage
        )

        // Clamp to image bounds
        cropRect.origin.x = max(0, min(cropRect.origin.x, imageSize.width - cropRect.width))
        cropRect.origin.y = max(0, min(cropRect.origin.y, imageSize.height - cropRect.height))
        cropRect.size.width = min(cropRect.width, imageSize.width - cropRect.origin.x)
        cropRect.size.height = min(cropRect.height, imageSize.height - cropRect.origin.y)

        // Perform the crop
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

/// Overlay with a transparent square hole for cropping
struct CropOverlay: View {
    let cropSize: CGFloat
    let viewSize: CGSize

    var body: some View {
        Canvas { context, size in
            // Draw semi-transparent black over everything
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.black.opacity(0.6))
            )

            // Cut out the crop area (clear it)
            let cropRect = CGRect(
                x: (size.width - cropSize) / 2,
                y: (size.height - cropSize) / 2,
                width: cropSize,
                height: cropSize
            )

            context.blendMode = .destinationOut
            context.fill(
                Path(roundedRect: cropRect, cornerRadius: 16),
                with: .color(.white)
            )
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            parent.onImageCaptured(image)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImageCaptured(nil)
            parent.dismiss()
        }
    }
}

// MARK: - Quick Pick Suggestion

/// A preset habit suggestion for quick adding
struct QuickPickSuggestion: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let frequency: FrequencyType
    var type: HabitType = .positive
    var triggersAppBlockSlip: Bool = false

    static let defaults: [QuickPickSuggestion] = [
        QuickPickSuggestion(emoji: "📖", name: "Read", frequency: .daily),
        QuickPickSuggestion(emoji: "💪", name: "Exercise", frequency: .daily),
        QuickPickSuggestion(emoji: "🧘", name: "Meditate", frequency: .daily),
        QuickPickSuggestion(emoji: "✏️", name: "Journal", frequency: .daily),
        QuickPickSuggestion(emoji: "📵", name: "No scrolling", frequency: .daily, type: .negative, triggersAppBlockSlip: true),
        QuickPickSuggestion(emoji: "💧", name: "Drink water", frequency: .daily),
        QuickPickSuggestion(emoji: "🍳", name: "Cook a meal", frequency: .daily),
        QuickPickSuggestion(emoji: "📞", name: "Call family", frequency: .weekly),
    ]
}

// MARK: - Flowing Tag Layout for Quick Picks

/// A flowing horizontal wrap layout for quick pick tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Frequency Pill Picker

/// Horizontal wrapping pill buttons for selecting frequency
struct FrequencyPillPicker: View {
    @Binding var selection: FrequencyType

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(FrequencyType.addFlowCases, id: \.self) { freq in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = freq
                    }
                } label: {
                    Text(freq.displayName)
                        .font(JournalTheme.Fonts.habitCriteria())
                        .fontWeight(selection == freq ? .semibold : .regular)
                        .foregroundStyle(selection == freq ? .white : JournalTheme.Colors.inkBlack)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(pillColor(for: freq, selected: selection == freq))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    pillBorderColor(for: freq, selected: selection == freq),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func pillColor(for freq: FrequencyType, selected: Bool) -> Color {
        guard selected else { return Color.clear }
        if freq == .once {
            return JournalTheme.Colors.teal
        }
        return JournalTheme.Colors.navy
    }

    private func pillBorderColor(for freq: FrequencyType, selected: Bool) -> Color {
        if selected {
            if freq == .once { return JournalTheme.Colors.teal }
            return JournalTheme.Colors.navy
        }
        return JournalTheme.Colors.lineLight
    }
}

// MARK: - Day of Week Selector

/// Circular day-of-week selectors (M T W T F S S)
struct DayOfWeekSelector: View {
    @Binding var selectedDays: Set<Int>

    private let days = [
        (index: 2, label: "M"),
        (index: 3, label: "T"),
        (index: 4, label: "W"),
        (index: 5, label: "T"),
        (index: 6, label: "F"),
        (index: 7, label: "S"),
        (index: 1, label: "S"),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.index) { day in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if selectedDays.contains(day.index) {
                            selectedDays.remove(day.index)
                        } else {
                            selectedDays.insert(day.index)
                        }
                    }
                } label: {
                    Text(day.label)
                        .font(.custom("PatrickHand-Regular", size: 13))
                        .foregroundStyle(selectedDays.contains(day.index) ? .white : JournalTheme.Colors.inkBlack)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(selectedDays.contains(day.index) ? JournalTheme.Colors.navy : Color.clear)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    selectedDays.contains(day.index) ? Color.clear : JournalTheme.Colors.lineLight,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Add Habit Confirmation Overlay

/// Shown after successfully adding a habit
struct AddHabitConfirmationView: View {
    let habitName: String
    let onDismiss: () -> Void

    @State private var showCheck = false
    @State private var showText = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Checkmark circle
            ZStack {
                Circle()
                    .fill(JournalTheme.Colors.successGreen.opacity(0.15))
                    .frame(width: 80, height: 80)

                Circle()
                    .strokeBorder(JournalTheme.Colors.successGreen, lineWidth: 2)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.custom("PatrickHand-Regular", size: 32))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
            }
            .scaleEffect(showCheck ? 1.0 : 0.5)
            .opacity(showCheck ? 1.0 : 0.0)

            // Title
            Text("Added to your day")
                .font(JournalTheme.Fonts.dateHeader())
                .foregroundStyle(JournalTheme.Colors.inkBlack)
                .opacity(showText ? 1.0 : 0.0)

            // Subtitle
            Text("\(habitName) is ready to track")
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .italic()
                .opacity(showText ? 1.0 : 0.0)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .linedPaperBackground()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showCheck = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showText = true
            }
            Feedback.success()
            // Auto-dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }
}

// MARK: - More Options Panel

/// The expanded "More options" content for the add habit flow
struct AddHabitMoreOptionsPanel: View {
    @Binding var tier: HabitTier
    @Binding var type: HabitType

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Priority
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                HStack(spacing: 10) {
                    mustDoPill
                    niceToDoPill
                }
            }

            Divider()

            // Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Type")
                    .font(JournalTheme.Fonts.habitName())
                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                HStack(spacing: 10) {
                    ForEach(HabitType.allCases, id: \.self) { typeOption in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { type = typeOption }
                        } label: {
                            Text(typeOption.displayName)
                                .font(JournalTheme.Fonts.habitCriteria())
                                .fontWeight(type == typeOption ? .semibold : .regular)
                                .foregroundStyle(type == typeOption ? .white : JournalTheme.Colors.inkBlack)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(type == typeOption ? JournalTheme.Colors.navy : Color.clear))
                                .overlay(Capsule().strokeBorder(type == typeOption ? Color.clear : JournalTheme.Colors.lineLight, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            Text("Reminders & notes available after adding")
                .font(JournalTheme.Fonts.habitCriteria())
                .foregroundStyle(JournalTheme.Colors.completedGray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        )
    }

    private var mustDoPill: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { tier = .mustDo }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "star.fill").font(.custom("PatrickHand-Regular", size: 11))
                Text("Must do")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .fontWeight(tier == .mustDo ? .semibold : .regular)
            }
            .foregroundStyle(tier == .mustDo ? JournalTheme.Colors.amber : JournalTheme.Colors.inkBlack)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(tier == .mustDo ? JournalTheme.Colors.amber.opacity(0.15) : Color.clear))
            .overlay(Capsule().strokeBorder(tier == .mustDo ? JournalTheme.Colors.amber : JournalTheme.Colors.lineLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var niceToDoPill: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { tier = .niceToDo }
        } label: {
            Text("Nice to do")
                .font(JournalTheme.Fonts.habitCriteria())
                .fontWeight(tier == .niceToDo ? .semibold : .regular)
                .foregroundStyle(tier == .niceToDo ? JournalTheme.Colors.navy : JournalTheme.Colors.inkBlack)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(tier == .niceToDo ? JournalTheme.Colors.navy.opacity(0.1) : Color.clear))
                .overlay(Capsule().strokeBorder(tier == .niceToDo ? JournalTheme.Colors.navy : JournalTheme.Colors.lineLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Frequency Detail Section

/// The expanded weekly/monthly frequency detail controls
struct FrequencyDetailSection: View {
    let frequencyType: FrequencyType
    @Binding var frequencyTarget: Int
    @Binding var selectedWeekDays: Set<Int>

    var body: some View {
        VStack(spacing: 0) {
            if frequencyType == .weekly {
                weeklySection
            }
            if frequencyType == .monthly {
                monthlySection
            }
            if frequencyType == .once {
                taskInfoNote
            }
        }
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("On specific days")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                DayOfWeekSelector(selectedDays: $selectedWeekDays)
            }

            HStack {
                Rectangle().fill(JournalTheme.Colors.lineLight).frame(height: 1)
                Text("Or just")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                Rectangle().fill(JournalTheme.Colors.lineLight).frame(height: 1)
            }

            counterRow(label: "\(frequencyTarget) times a week", min: 1, max: 7)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.85)).shadow(color: .black.opacity(0.04), radius: 4, y: 2))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var monthlySection: some View {
        counterRow(label: "\(frequencyTarget) times a month", min: 1, max: 31)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.85)).shadow(color: .black.opacity(0.04), radius: 4, y: 2))
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var taskInfoNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle").font(.custom("PatrickHand-Regular", size: 14)).foregroundStyle(JournalTheme.Colors.teal)
            Text("One-off task \u{00B7} won't affect your streak")
                .font(JournalTheme.Fonts.habitCriteria()).foregroundStyle(JournalTheme.Colors.teal)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(JournalTheme.Colors.teal.opacity(0.1)))
        .transition(.opacity)
    }

    private func counterRow(label: String, min: Int, max: Int) -> some View {
        HStack {
            Text(label)
                .font(JournalTheme.Fonts.habitName())
                .foregroundStyle(JournalTheme.Colors.inkBlack)
            Spacer()
            HStack(spacing: 0) {
                Button {
                    if frequencyTarget > min { frequencyTarget -= 1; selectedWeekDays.removeAll() }
                } label: {
                    Image(systemName: "minus").font(.custom("PatrickHand-Regular", size: 14)).foregroundStyle(JournalTheme.Colors.navy)
                        .frame(width: 36, height: 36).background(Circle().fill(JournalTheme.Colors.paperLight))
                }.buttonStyle(.plain)
                Button {
                    if frequencyTarget < max { frequencyTarget += 1; selectedWeekDays.removeAll() }
                } label: {
                    Image(systemName: "plus").font(.custom("PatrickHand-Regular", size: 14)).foregroundStyle(JournalTheme.Colors.navy)
                        .frame(width: 36, height: 36).background(Circle().fill(JournalTheme.Colors.paperLight))
                }.buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Add Habit View

/// View for adding a new habit with stepped progressive disclosure
struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore
    /// Optional group to auto-add the new habit into
    var addToGroup: HabitGroup? = nil

    @State private var name = ""
    @State private var frequencyType: FrequencyType = .daily
    @State private var frequencyTarget: Int = 3
    @State private var selectedWeekDays: Set<Int> = []
    @State private var showMoreOptions = false
    @State private var tier: HabitTier = .mustDo
    @State private var type: HabitType = .positive
    @State private var enableReminders: Bool = false
    @State private var enableNotesPhotos: Bool = false
    @State private var showConfirmation = false
    @State private var addedHabitName = ""
    @State private var triggersAppBlockSlip: Bool = false

    @FocusState private var nameFieldFocused: Bool

    private var hasName: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isTask: Bool { frequencyType == .once }
    private var submitButtonText: String { isTask ? "Add to today" : "Add habit" }

    private var cleanName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        var result = trimmed
        if let first = result.first, first.isEmoji {
            result = String(result.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return result.isEmpty ? trimmed : result
    }

    var body: some View {
        if showConfirmation {
            AddHabitConfirmationView(habitName: addedHabitName) { dismiss() }
        } else {
            formContent
        }
    }

    private var formContent: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    nameInputField
                    if !hasName { quickPicksSection }
                    if hasName { stepTwoSection }
                    Spacer(minLength: 60)
                }
                .padding(20)
            }
            .linedPaperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JournalTheme.Colors.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { Feedback.buttonPress(); dismiss() }.foregroundStyle(JournalTheme.Colors.inkBlue)
                }
            }
        }
        .onAppear { nameFieldFocused = true }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(addToGroup != nil ? "New sub-habit" : "New habit")
                .font(JournalTheme.Fonts.title())
                .foregroundStyle(JournalTheme.Colors.navy)
            if let group = addToGroup {
                Text("Adding to \(group.name)")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.teal)
                    .italic()
            } else {
                Text("What do you want to start doing?")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .italic()
            }
        }
    }

    private var nameInputField: some View {
        TextField("e.g. Read for 30 min, Buy butter...", text: $name)
            .font(JournalTheme.Fonts.habitName())
            .foregroundStyle(JournalTheme.Colors.inkBlack)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(JournalTheme.Colors.paperLight)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1))
            )
            .focused($nameFieldFocused)
    }

    private var quickPicksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK PICKS")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.completedGray)
                .tracking(1.5)

            FlowLayout(spacing: 10) {
                ForEach(QuickPickSuggestion.defaults) { suggestion in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            name = suggestion.emoji + " " + suggestion.name
                            frequencyType = suggestion.frequency
                            type = suggestion.type
                            triggersAppBlockSlip = suggestion.triggersAppBlockSlip
                        }
                        Feedback.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Text(suggestion.emoji).font(.custom("PatrickHand-Regular", size: 15))
                            Text(suggestion.name)
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.inkBlack)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(Color.white.opacity(0.85))
                                .overlay(Capsule().strokeBorder(JournalTheme.Colors.lineLight, lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var stepTwoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Frequency picker
            VStack(alignment: .leading, spacing: 10) {
                Text("HOW OFTEN?")
                    .font(JournalTheme.Fonts.sectionHeader())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .tracking(1.5)

                FrequencyPillPicker(selection: $frequencyType)
                FrequencyDetailSection(frequencyType: frequencyType, frequencyTarget: $frequencyTarget, selectedWeekDays: $selectedWeekDays)
            }

            // More options (hidden for tasks)
            if !isTask {
                moreOptionsSection
            }

            // Submit button
            Button { addHabit() } label: {
                Text(submitButtonText)
                    .font(.custom("PatrickHand-Regular", size: 17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(isTask ? JournalTheme.Colors.teal : JournalTheme.Colors.navy))
            }
            .buttonStyle(.plain)

            // Defaults hint
            if !isTask {
                Text("Defaults: must-do \u{00B7} \(frequencyType.displayName.lowercased()) \u{00B7} no reminders")
                    .font(JournalTheme.Fonts.habitCriteria())
                    .foregroundStyle(JournalTheme.Colors.completedGray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var moreOptionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { showMoreOptions.toggle() }
            } label: {
                HStack {
                    Text("More options")
                        .font(JournalTheme.Fonts.habitName())
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                    Spacer()
                    Image(systemName: showMoreOptions ? "chevron.up" : "chevron.down")
                        .font(.custom("PatrickHand-Regular", size: 12))
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(showMoreOptions ? JournalTheme.Colors.amber : JournalTheme.Colors.lineLight, lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 10).fill(JournalTheme.Colors.paperLight))
                )
            }
            .buttonStyle(.plain)
            .zIndex(1)

            if showMoreOptions {
                AddHabitMoreOptionsPanel(tier: $tier, type: $type)
                    .padding(.top, 8)
                    .transition(.asymmetric(
                        insertion: .push(from: .top),
                        removal: .push(from: .bottom)
                    ))
            }
        }
        .clipped()
    }

    private func addHabit() {
        let target: Int
        if frequencyType == .daily || frequencyType == .once {
            target = 1
        } else if frequencyType == .weekly && !selectedWeekDays.isEmpty {
            target = selectedWeekDays.count
        } else {
            target = frequencyTarget
        }

        addedHabitName = cleanName

        store.addHabit(
            name: name.trimmingCharacters(in: .whitespaces),
            tier: tier,
            type: type,
            frequencyType: frequencyType,
            frequencyTarget: target,
            groupId: addToGroup?.id,
            isHobby: enableNotesPhotos,
            notificationsEnabled: enableReminders,
            weeklyNotificationDays: Array(selectedWeekDays),
            enableNotesPhotos: enableNotesPhotos,
            triggersAppBlockSlip: triggersAppBlockSlip
        )

        // If adding to a group, also add the new habit to the group's habitIds
        if let group = addToGroup,
           let newHabit = store.habits.first(where: {
               $0.name == name.trimmingCharacters(in: .whitespaces) && $0.groupId == group.id
           }) {
            store.addHabitToGroup(newHabit, group: group)
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            showConfirmation = true
        }
    }
}

#Preview("Add Habit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: config)
    let store = HabitStore(modelContext: container.mainContext)

    return AddHabitView(store: store)
}
