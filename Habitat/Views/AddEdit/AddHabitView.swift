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
                            .font(.system(size: 40))
                    } else if !name.isEmpty {
                        Text(initials)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Edit overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 24))
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

// MARK: - Add Habit View

/// View for adding a new habit
struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore

    @State private var name = ""
    @State private var habitDescription = ""
    @State private var tier: HabitTier = .mustDo
    @State private var type: HabitType = .positive
    @State private var frequencyType: FrequencyType = .daily
    @State private var frequencyTarget: Int = 4
    @State private var successCriteria = ""
    @State private var selectedGroupId: UUID?
    @State private var isHobby: Bool = false
    @State private var iconImageData: Data?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Icon Section
                    FormCard(header: "Icon") {
                        HStack {
                            Spacer()
                            HabitIconPicker(
                                name: name,
                                tier: tier,
                                iconImageData: $iconImageData
                            )
                            Spacer()
                        }
                    }

                    // Basic Info Section
                    FormCard(header: "Basic Info") {
                        CardTextField(
                            label: "Name",
                            placeholder: "Enter habit name",
                            text: $name,
                            isRequired: true
                        )

                        CardTextField(
                            label: "Description",
                            placeholder: "Optional description",
                            text: $habitDescription
                        )
                    }

                    // Type Section
                    FormCard(
                        header: "Habit Type",
                        footer: type == .positive
                            ? "Something you want to do"
                            : "Something you want to avoid"
                    ) {
                        CardSegmentedPicker(
                            label: "Type",
                            selection: $type,
                            displayName: { $0.displayName }
                        )
                    }

                    // Hobby Section (only for positive habits)
                    if type == .positive {
                        FormCard(
                            footer: isHobby
                                ? "You'll be prompted to add photos and notes when completing"
                                : "Enable to track photos and notes for this activity"
                        ) {
                            CardToggle(label: "This is a hobby", isOn: $isHobby)
                        }

                        // Priority Section
                        FormCard(
                            header: "Priority",
                            footer: tier == .mustDo
                                ? "Must-do habits are required for a 'good day'"
                                : "Nice-to-do habits are bonus and tracked separately"
                        ) {
                            CardSegmentedPicker(
                                label: "Priority Level",
                                selection: $tier,
                                displayName: { $0.displayName }
                            )
                        }
                    }

                    // Frequency Section
                    FormCard(header: "Frequency") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How often?")
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.completedGray)

                            Picker("Frequency", selection: $frequencyType) {
                                ForEach(FrequencyType.allCases, id: \.self) { freq in
                                    Text(freq.displayName).tag(freq)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(JournalTheme.Colors.inkBlue)

                            if frequencyType == .weekly {
                                Stepper("Target: \(frequencyTarget)x per week", value: $frequencyTarget, in: 1...7)
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                            } else if frequencyType == .monthly {
                                Stepper("Target: \(frequencyTarget)x per month", value: $frequencyTarget, in: 1...31)
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                            }
                        }
                    }

                    // Success Criteria Section
                    FormCard(
                        header: "Success Criteria",
                        footer: "Define what counts as completing this habit. Leave empty for simple yes/no tracking."
                    ) {
                        CardTextField(
                            label: "Target",
                            placeholder: "e.g., 3L, 15 mins, 5000 steps",
                            text: $successCriteria
                        )
                    }

                    // Group Assignment Section
                    if !store.groups.isEmpty {
                        FormCard(
                            header: "Group",
                            footer: "Add this habit to a group where completing any habit satisfies the requirement."
                        ) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Assign to group")
                                    .font(JournalTheme.Fonts.habitCriteria())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)

                                Picker("Group", selection: $selectedGroupId) {
                                    Text("None").tag(nil as UUID?)
                                    ForEach(store.groups) { group in
                                        Text(group.name).tag(group.id as UUID?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(JournalTheme.Colors.inkBlue)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .linedPaperBackground()
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JournalTheme.Colors.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(JournalTheme.Colors.inkBlue)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addHabit()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty
                        ? JournalTheme.Colors.completedGray
                        : JournalTheme.Colors.inkBlue)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addHabit() {
        let target = frequencyType == .daily ? 1 : frequencyTarget

        store.addHabit(
            name: name.trimmingCharacters(in: .whitespaces),
            description: habitDescription,
            tier: tier,
            type: type,
            frequencyType: frequencyType,
            frequencyTarget: target,
            successCriteria: successCriteria.isEmpty ? nil : successCriteria,
            groupId: selectedGroupId,
            isHobby: type == .positive && isHobby,
            iconImageData: iconImageData
        )

        if let groupId = selectedGroupId,
           let group = store.groups.first(where: { $0.id == groupId }),
           let habit = store.habits.last {
            store.addHabitToGroup(habit, group: group)
        }

        dismiss()
    }
}

// MARK: - Edit Habit View

/// View for editing an existing habit
struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: HabitStore
    let habit: Habit

    @State private var name: String
    @State private var habitDescription: String
    @State private var tier: HabitTier
    @State private var type: HabitType
    @State private var frequencyType: FrequencyType
    @State private var frequencyTarget: Int
    @State private var successCriteria: String
    @State private var selectedGroupId: UUID?
    @State private var isHobby: Bool
    @State private var iconImageData: Data?
    @State private var showingDeleteConfirmation = false

    init(store: HabitStore, habit: Habit) {
        self.store = store
        self.habit = habit
        _name = State(initialValue: habit.name)
        _habitDescription = State(initialValue: habit.habitDescription)
        _tier = State(initialValue: habit.tier)
        _type = State(initialValue: habit.type)
        _successCriteria = State(initialValue: habit.successCriteria ?? "")
        _selectedGroupId = State(initialValue: habit.groupId)
        _frequencyType = State(initialValue: habit.frequencyType)
        _frequencyTarget = State(initialValue: habit.frequencyTarget)
        _isHobby = State(initialValue: habit.isHobby)
        _iconImageData = State(initialValue: habit.iconImageData)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Icon Section
                    FormCard(header: "Icon") {
                        HStack {
                            Spacer()
                            HabitIconPicker(
                                name: name,
                                tier: tier,
                                iconImageData: $iconImageData
                            )
                            Spacer()
                        }
                    }

                    // Basic Info Section
                    FormCard(header: "Basic Info") {
                        CardTextField(
                            label: "Name",
                            placeholder: "Enter habit name",
                            text: $name,
                            isRequired: true
                        )

                        CardTextField(
                            label: "Description",
                            placeholder: "Optional description",
                            text: $habitDescription
                        )
                    }

                    // Stats Section
                    FormCard(header: "Statistics") {
                        VStack(spacing: 12) {
                            HStack {
                                Label("Current Streak", systemImage: "flame.fill")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                                Spacer()
                                Text("\(habit.currentStreak) days")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }

                            Divider()

                            HStack {
                                Label("Best Streak", systemImage: "trophy.fill")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                                Spacer()
                                Text("\(habit.bestStreak) days")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }

                            Divider()

                            HStack {
                                Label("Completion Rate", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                                Spacer()
                                Text("\(Int(store.completionRate(for: habit) * 100))%")
                                    .font(JournalTheme.Fonts.habitName())
                                    .foregroundStyle(JournalTheme.Colors.completedGray)
                            }
                        }
                    }

                    // Type Section
                    FormCard(header: "Habit Type") {
                        CardSegmentedPicker(
                            label: "Type",
                            selection: $type,
                            displayName: { $0.displayName }
                        )
                    }

                    // Priority & Hobby (only for positive)
                    if type == .positive {
                        FormCard(header: "Priority") {
                            CardSegmentedPicker(
                                label: "Priority Level",
                                selection: $tier,
                                displayName: { $0.displayName }
                            )
                        }

                        FormCard(
                            footer: isHobby
                                ? "You'll be prompted to add photos and notes when completing"
                                : "Enable to track photos and notes for this activity"
                        ) {
                            CardToggle(label: "This is a hobby", isOn: $isHobby)
                        }
                    }

                    // Frequency Section
                    FormCard(header: "Frequency") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Frequency", selection: $frequencyType) {
                                ForEach(FrequencyType.allCases, id: \.self) { freq in
                                    Text(freq.displayName).tag(freq)
                                }
                            }
                            .pickerStyle(.segmented)

                            if frequencyType == .weekly {
                                Stepper("Target: \(frequencyTarget)x per week", value: $frequencyTarget, in: 1...7)
                                    .font(JournalTheme.Fonts.habitName())
                            } else if frequencyType == .monthly {
                                Stepper("Target: \(frequencyTarget)x per month", value: $frequencyTarget, in: 1...31)
                                    .font(JournalTheme.Fonts.habitName())
                            }
                        }
                    }

                    // Success Criteria
                    FormCard(header: "Success Criteria") {
                        CardTextField(
                            label: "Target",
                            placeholder: "e.g., 3L, 15 mins, 5000 steps",
                            text: $successCriteria
                        )
                    }

                    // Delete Button
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Habit")
                        }
                        .font(JournalTheme.Fonts.habitName())
                        .foregroundStyle(JournalTheme.Colors.negativeRedDark)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(JournalTheme.Colors.negativeRedDark.opacity(0.5), lineWidth: 1.5)
                        )
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .linedPaperBackground()
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JournalTheme.Colors.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(JournalTheme.Colors.inkBlue)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty
                        ? JournalTheme.Colors.completedGray
                        : JournalTheme.Colors.inkBlue)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Delete Habit?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    store.deleteHabit(habit)
                    dismiss()
                }
            } message: {
                Text("This will permanently delete '\(habit.name)' and all its history. This cannot be undone.")
            }
        }
    }

    private func saveChanges() {
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.habitDescription = habitDescription
        habit.tier = tier
        habit.type = type
        habit.successCriteria = successCriteria.isEmpty ? nil : successCriteria
        habit.frequencyType = frequencyType
        habit.frequencyTarget = frequencyType == .daily ? 1 : frequencyTarget
        habit.isHobby = type == .positive && isHobby
        habit.iconImageData = iconImageData

        store.updateHabit(habit)
        dismiss()
    }
}

#Preview("Add Habit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitGroup.self, DailyLog.self, configurations: config)
    let store = HabitStore(modelContext: container.mainContext)

    return AddHabitView(store: store)
}
