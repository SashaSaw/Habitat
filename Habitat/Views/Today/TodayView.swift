import SwiftUI
import SwiftData

/// Main Today View showing all habits for the current day
struct TodayView: View {
    @Bindable var store: HabitStore
    @State private var showingAddHabit = false
    @State private var showingAddGroup = false

    var body: some View {
        NavigationStack {
            TodayContentView(store: store)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddHabit = true
                        } label: {
                            Label("Add Habit", systemImage: "plus.circle")
                        }

                        Button {
                            showingAddGroup = true
                        } label: {
                            Label("Add Group", systemImage: "folder.badge.plus")
                        }

                        Divider()

                        Button {
                            store.createSampleData()
                        } label: {
                            Label("Load Sample Data", systemImage: "tray.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(JournalTheme.Colors.inkBlue)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(store: store)
            }
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView(store: store)
            }
        }
    }
}

/// The actual content of the Today View - aligns text to paper lines
struct TodayContentView: View {
    @Bindable var store: HabitStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedDate = Date()
    @State private var lastKnownDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedHabit: Habit?
    @State private var selectedGroup: HabitGroup?

    // Alert state for deleting empty groups
    @State private var groupToDeleteAfterHabit: HabitGroup? = nil
    @State private var showDeleteGroupAlert: Bool = false

    // Celebration state
    @State private var showCelebration: Bool = false
    @State private var wasGoodDay: Bool = false

    private let lineHeight = JournalTheme.Dimensions.lineSpacing
    private let marginLeft = JournalTheme.Dimensions.marginLeft

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Paper background that extends infinitely
                LinedPaperBackground(lineSpacing: lineHeight)

                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title "Today" - takes 2 lines
                        LinedRow(height: lineHeight * 2) {
                            HStack(spacing: 8) {
                                Text("Today")
                                    .font(JournalTheme.Fonts.title())
                                    .foregroundStyle(JournalTheme.Colors.inkBlack)

                                if store.isGoodDay(for: selectedDate) {
                                    Text("✓ Must-dos complete!")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(JournalTheme.Colors.goodDayGreenDark)
                                }
                            }
                        }

                        // Date header - takes 1 line
                        LinedRow(height: lineHeight) {
                            Text(formattedDate)
                                .font(JournalTheme.Fonts.dateHeader())
                                .foregroundStyle(JournalTheme.Colors.inkBlack)
                        }

                        // Empty line
                        LinedRow(height: lineHeight) {
                            EmptyView()
                        }

                        // Must-Do Section
                        if !store.mustDoHabits.isEmpty || !store.mustDoGroups.isEmpty {
                            LinedRow(height: lineHeight) {
                                Text("MUST DO")
                                    .font(JournalTheme.Fonts.sectionHeader())
                                    .foregroundStyle(JournalTheme.Colors.sectionHeader)
                                    .tracking(2)
                            }

                            // Standalone must-do habits
                            ForEach(store.standaloneMustDoHabits) { habit in
                                HabitLinedRow(
                                    habit: habit,
                                    isCompleted: habit.isCompleted(for: selectedDate),
                                    lineHeight: lineHeight,
                                    onComplete: { store.setCompletion(for: habit, completed: true, on: selectedDate) },
                                    onUncomplete: { store.setCompletion(for: habit, completed: false, on: selectedDate) },
                                    onDelete: { store.deleteHabit(habit) },
                                    onLongPress: { selectedHabit = habit }
                                )
                            }
                            .animation(.easeInOut(duration: 0.25), value: store.standaloneMustDoHabits.count)

                            // Must-do groups with their habits
                            ForEach(store.mustDoGroups) { group in
                                GroupLinedRow(
                                    group: group,
                                    habits: store.habits(for: group),
                                    lineHeight: lineHeight,
                                    store: store,
                                    selectedDate: selectedDate,
                                    onSelectHabit: { selectedHabit = $0 },
                                    onDelete: { store.deleteGroup(group) },
                                    onLastHabitDeleted: {
                                        groupToDeleteAfterHabit = group
                                        showDeleteGroupAlert = true
                                    },
                                    onLongPress: { selectedGroup = group }
                                )
                            }
                        }

                        // Empty line between sections
                        LinedRow(height: lineHeight) {
                            EmptyView()
                        }

                        // Nice-To-Do Section
                        if !store.niceToDoHabits.isEmpty {
                            LinedRow(height: lineHeight) {
                                Text("NICE TO DO")
                                    .font(JournalTheme.Fonts.sectionHeader())
                                    .foregroundStyle(JournalTheme.Colors.sectionHeader)
                                    .tracking(2)
                            }

                            ForEach(store.niceToDoHabits) { habit in
                                HabitLinedRow(
                                    habit: habit,
                                    isCompleted: habit.isCompleted(for: selectedDate),
                                    lineHeight: lineHeight,
                                    onComplete: { store.setCompletion(for: habit, completed: true, on: selectedDate) },
                                    onUncomplete: { store.setCompletion(for: habit, completed: false, on: selectedDate) },
                                    onDelete: { store.deleteHabit(habit) },
                                    onLongPress: { selectedHabit = habit }
                                )
                            }
                            .animation(.easeInOut(duration: 0.25), value: store.niceToDoHabits.count)
                        }

                        // Empty state
                        if store.habits.isEmpty {
                            LinedRow(height: lineHeight * 3) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("No habits yet")
                                        .font(JournalTheme.Fonts.habitName())
                                        .foregroundStyle(JournalTheme.Colors.completedGray)
                                    Text("Tap + to add your first habit")
                                        .font(JournalTheme.Fonts.habitCriteria())
                                        .foregroundStyle(JournalTheme.Colors.completedGray)
                                }
                            }
                        }

                        // Extra empty lines to fill screen
                        ForEach(0..<20, id: \.self) { _ in
                            LinedRow(height: lineHeight) {
                                EmptyView()
                            }
                        }
                    }
                }

                // Celebration overlay
                if showCelebration {
                    CelebrationOverlay(isShowing: $showCelebration)
                }
            }
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationStack {
                HabitDetailView(store: store, habit: habit)
            }
        }
        .sheet(item: $selectedGroup) { group in
            EditGroupView(store: store, group: group)
        }
        .alert("Delete Empty Group?", isPresented: $showDeleteGroupAlert) {
            Button("Keep Group") {
                groupToDeleteAfterHabit = nil
            }
            Button("Delete Group", role: .destructive) {
                if let group = groupToDeleteAfterHabit {
                    store.deleteGroup(group)
                }
                groupToDeleteAfterHabit = nil
            }
        } message: {
            Text("The group '\(groupToDeleteAfterHabit?.name ?? "")' is now empty. Would you like to delete it?")
        }
        .onAppear {
            wasGoodDay = store.isGoodDay(for: selectedDate)
        }
        .onChange(of: store.habits.map { $0.isCompleted(for: selectedDate) }) { _, _ in
            let isNowGoodDay = store.isGoodDay(for: selectedDate)
            if isNowGoodDay && !wasGoodDay {
                // Just became a good day - celebrate!
                withAnimation {
                    showCelebration = true
                }
                HapticFeedback.completionConfirmed()
            }
            wasGoodDay = isNowGoodDay
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let today = Calendar.current.startOfDay(for: Date())
                if today != lastKnownDay {
                    selectedDate = Date()
                    lastKnownDay = today
                    wasGoodDay = store.isGoodDay(for: selectedDate)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            let today = Calendar.current.startOfDay(for: Date())
            if today != lastKnownDay {
                selectedDate = Date()
                lastKnownDay = today
                wasGoodDay = store.isGoodDay(for: selectedDate)
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }
}

/// A row that aligns to the paper lines
struct LinedRow<Content: View>: View {
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    private let marginLeft = JournalTheme.Dimensions.marginLeft

    var body: some View {
        HStack(spacing: 0) {
            content()
        }
        .frame(height: height, alignment: .bottomLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, marginLeft + 8)
        .padding(.trailing, 16)
    }
}

/// A habit row with swipe-to-strikethrough gesture and swipe-left-to-delete
struct HabitLinedRow: View {
    let habit: Habit
    let isCompleted: Bool
    let lineHeight: CGFloat
    let onComplete: () -> Void
    let onUncomplete: () -> Void
    let onDelete: () -> Void
    let onLongPress: () -> Void

    // Swipe gesture state
    @State private var strikethroughProgress: CGFloat
    @State private var isDragging: Bool = false
    @State private var hasPassedThreshold: Bool = false
    @State private var textWidth: CGFloat = 0

    // Delete gesture state
    @State private var deleteOffset: CGFloat = 0
    @State private var hasPassedDeleteThreshold: Bool = false

    // Constants
    private let completionThreshold: CGFloat = 0.3
    private let deleteThreshold: CGFloat = 0.5
    private let marginLeft = JournalTheme.Dimensions.marginLeft

    init(habit: Habit, isCompleted: Bool, lineHeight: CGFloat,
         onComplete: @escaping () -> Void,
         onUncomplete: @escaping () -> Void,
         onDelete: @escaping () -> Void,
         onLongPress: @escaping () -> Void) {
        self.habit = habit
        self.isCompleted = isCompleted
        self.lineHeight = lineHeight
        self.onComplete = onComplete
        self.onUncomplete = onUncomplete
        self.onDelete = onDelete
        self.onLongPress = onLongPress
        // Initialize progress based on completion state
        self._strikethroughProgress = State(initialValue: isCompleted ? 1.0 : 0.0)
        self._hasPassedThreshold = State(initialValue: isCompleted)
    }

    // Computed property to determine if visually completed
    private var isVisuallyCompleted: Bool {
        strikethroughProgress >= completionThreshold
    }

    // Delete progress as percentage (0 to 1)
    private var deleteProgress: CGFloat {
        guard deleteOffset < 0 else { return 0 }
        return min(1, abs(deleteOffset) / 200) // 200pt = full delete
    }

    var body: some View {
        GeometryReader { geometry in
            let hitboxWidth = geometry.size.width

            ZStack {
                // Delete background (red, only shown when swiping left)
                if deleteOffset < 0 {
                    HStack {
                        Spacer()
                        ZStack {
                            JournalTheme.Colors.negativeRedDark

                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                                .opacity(deleteProgress > 0.3 ? 1 : deleteProgress * 3)
                        }
                        .frame(width: abs(deleteOffset))
                    }
                }

                // Main content
                HStack(spacing: 12) {
                    // Checkbox indicator - fills based on progress
                    Circle()
                        .strokeBorder(
                            isVisuallyCompleted
                                ? JournalTheme.Colors.inkBlue
                                : JournalTheme.Colors.completedGray,
                            lineWidth: 1.5
                        )
                        .background(
                            Circle()
                                .fill(isVisuallyCompleted
                                    ? JournalTheme.Colors.inkBlue.opacity(0.1)
                                    : Color.clear)
                        )
                        .frame(width: 20, height: 20)

                    // Habit text with strikethrough overlay
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .font(JournalTheme.Fonts.habitName())
                            .foregroundStyle(
                                isVisuallyCompleted
                                    ? JournalTheme.Colors.completedGray
                                    : JournalTheme.Colors.inkBlack
                            )

                        if let criteria = habit.successCriteria, !criteria.isEmpty {
                            Text("(\(criteria))")
                                .font(JournalTheme.Fonts.habitCriteria())
                                .foregroundStyle(JournalTheme.Colors.completedGray)
                        }
                    }
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeometry.size.width
                                }
                                .onChange(of: textGeometry.size.width) { _, newWidth in
                                    textWidth = newWidth
                                }
                        }
                    )
                    .overlay(alignment: .leading) {
                        // Always show the strikethrough overlay, let the Canvas decide visibility
                        StrikethroughLine(
                            width: textWidth > 0 ? textWidth : 200, // Fallback width
                            color: JournalTheme.Colors.inkBlue,
                            progress: $strikethroughProgress
                        )
                    }

                    Spacer()
                }
                .frame(height: lineHeight, alignment: .bottom)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, marginLeft + 8)
                .padding(.trailing, 16)
                .background(Color.clear)
                .offset(x: deleteOffset)
            }
            .contentShape(Rectangle())
            .gesture(swipeGesture(hitboxWidth: hitboxWidth))
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        HapticFeedback.selection()
                        onLongPress()
                    }
            )
            .onTapGesture {
                // Tap to undo completion
                if isCompleted {
                    withAnimation(JournalTheme.Animations.strikethrough) {
                        strikethroughProgress = 0.0
                        hasPassedThreshold = false
                    }
                    HapticFeedback.selection()
                    onUncomplete()
                }
            }
            .onChange(of: isCompleted) { _, newValue in
                // Sync with external state changes (only when not dragging)
                if !isDragging {
                    withAnimation(JournalTheme.Animations.strikethrough) {
                        strikethroughProgress = newValue ? 1.0 : 0.0
                        hasPassedThreshold = newValue
                    }
                }
            }
        }
        .frame(height: lineHeight)
    }

    private func swipeGesture(hitboxWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                isDragging = true

                let translation = value.translation.width

                // Determine if this is a delete swipe (left) or completion swipe (right)
                if translation < 0 {
                    // Swiping LEFT - delete gesture
                    deleteOffset = translation

                    // Reset completion progress if we're deleting
                    if strikethroughProgress > 0 && !isCompleted {
                        strikethroughProgress = 0
                    }

                    // Check delete threshold for haptic
                    let deleteProgress = abs(translation) / hitboxWidth
                    let currentlyPastDelete = deleteProgress >= deleteThreshold
                    if currentlyPastDelete != hasPassedDeleteThreshold {
                        hasPassedDeleteThreshold = currentlyPastDelete
                        HapticFeedback.thresholdCrossed()
                    }
                } else {
                    // Swiping RIGHT - completion gesture
                    deleteOffset = 0
                    hasPassedDeleteThreshold = false

                    if isCompleted {
                        // Already completed - this would uncomplete, but we use left swipe for that now
                        // Just ignore right swipe on completed items
                    } else {
                        // Forward swipe: swipe right to draw the strikethrough
                        let forwardProgress = translation / hitboxWidth
                        strikethroughProgress = max(0, min(1, forwardProgress))

                        // Check threshold crossing for haptic feedback
                        let currentlyPastThreshold = strikethroughProgress >= completionThreshold
                        if currentlyPastThreshold != hasPassedThreshold {
                            hasPassedThreshold = currentlyPastThreshold
                            HapticFeedback.thresholdCrossed()
                        }
                    }
                }
            }
            .onEnded { value in
                isDragging = false

                let translation = value.translation.width

                if translation < 0 {
                    // Was swiping LEFT - check delete threshold
                    let deleteProgress = abs(translation) / hitboxWidth

                    if deleteProgress >= deleteThreshold {
                        // Delete the habit - let SwiftUI handle the animation
                        HapticFeedback.completionConfirmed()
                        // Reset offset first, then delete with animation
                        deleteOffset = 0
                        withAnimation(.easeOut(duration: 0.25)) {
                            onDelete()
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            deleteOffset = 0
                        }
                    }
                    hasPassedDeleteThreshold = false
                } else {
                    // Was swiping RIGHT - check completion threshold
                    if !isCompleted {
                        if strikethroughProgress >= completionThreshold {
                            // Past threshold - complete the habit
                            withAnimation(JournalTheme.Animations.strikethrough) {
                                strikethroughProgress = 1.0
                            }
                            HapticFeedback.completionConfirmed()
                            onComplete()
                            hasPassedThreshold = true
                        } else {
                            // Didn't reach threshold - rewind to zero
                            withAnimation(JournalTheme.Animations.strikethrough) {
                                strikethroughProgress = 0
                            }
                            hasPassedThreshold = false
                        }
                    }
                }
            }
    }
}

/// A group row with nested habits and swipe-to-delete
struct GroupLinedRow: View {
    let group: HabitGroup
    let habits: [Habit]
    let lineHeight: CGFloat
    let store: HabitStore
    let selectedDate: Date
    let onSelectHabit: (Habit) -> Void
    let onDelete: () -> Void
    let onLastHabitDeleted: () -> Void
    let onLongPress: () -> Void

    // Delete gesture state
    @State private var deleteOffset: CGFloat = 0
    @State private var hasPassedDeleteThreshold: Bool = false

    private let deleteThreshold: CGFloat = 0.5
    private let marginLeft = JournalTheme.Dimensions.marginLeft

    private var isSatisfied: Bool {
        group.isSatisfied(habits: store.habits, for: selectedDate)
    }

    private var completedCount: Int {
        group.completedCount(habits: store.habits, for: selectedDate)
    }

    private var deleteProgress: CGFloat {
        guard deleteOffset < 0 else { return 0 }
        return min(1, abs(deleteOffset) / 200)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Group header with delete gesture
            GeometryReader { geometry in
                let hitboxWidth = geometry.size.width

                ZStack {
                    // Delete background (red, only shown when swiping left)
                    if deleteOffset < 0 {
                        HStack {
                            Spacer()
                            ZStack {
                                JournalTheme.Colors.negativeRedDark

                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white)
                                    .opacity(deleteProgress > 0.3 ? 1 : deleteProgress * 3)
                            }
                            .frame(width: abs(deleteOffset))
                        }
                    }

                    // Group header content
                    HStack(spacing: 12) {
                        Circle()
                            .strokeBorder(isSatisfied ? JournalTheme.Colors.inkBlue : JournalTheme.Colors.completedGray, lineWidth: 1.5)
                            .background(
                                Circle()
                                    .fill(isSatisfied ? JournalTheme.Colors.inkBlue.opacity(0.1) : Color.clear)
                            )
                            .frame(width: 20, height: 20)

                        Text(group.name)
                            .font(JournalTheme.Fonts.habitName())
                            .foregroundStyle(isSatisfied ? JournalTheme.Colors.completedGray : JournalTheme.Colors.inkBlack)

                        Text("(\(completedCount)/\(group.requireCount))")
                            .font(JournalTheme.Fonts.habitCriteria())
                            .foregroundStyle(JournalTheme.Colors.completedGray)

                        Spacer()
                    }
                    .frame(height: lineHeight, alignment: .bottom)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, marginLeft + 8)
                    .padding(.trailing, 16)
                    .background(Color.clear)
                    .offset(x: deleteOffset)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onChanged { value in
                            let translation = value.translation.width

                            if translation < 0 {
                                // Swiping LEFT - delete gesture
                                deleteOffset = translation

                                // Check delete threshold for haptic
                                let progress = abs(translation) / hitboxWidth
                                let currentlyPastDelete = progress >= deleteThreshold
                                if currentlyPastDelete != hasPassedDeleteThreshold {
                                    hasPassedDeleteThreshold = currentlyPastDelete
                                    HapticFeedback.thresholdCrossed()
                                }
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.width

                            if translation < 0 {
                                let progress = abs(translation) / hitboxWidth

                                if progress >= deleteThreshold {
                                    // Delete the group
                                    HapticFeedback.completionConfirmed()
                                    deleteOffset = 0
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        onDelete()
                                    }
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        deleteOffset = 0
                                    }
                                }
                            }
                            hasPassedDeleteThreshold = false
                        }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            HapticFeedback.selection()
                            onLongPress()
                        }
                )
            }
            .frame(height: lineHeight)

            // Child habits (indented)
            ForEach(habits) { habit in
                HabitLinedRow(
                    habit: habit,
                    isCompleted: habit.isCompleted(for: selectedDate),
                    lineHeight: lineHeight,
                    onComplete: { store.setCompletion(for: habit, completed: true, on: selectedDate) },
                    onUncomplete: { store.setCompletion(for: habit, completed: false, on: selectedDate) },
                    onDelete: {
                        // Check if this is the last habit in the group
                        let isLastHabit = habits.count == 1
                        store.deleteHabit(habit)
                        if isLastHabit {
                            onLastHabitDeleted()
                        }
                    },
                    onLongPress: { onSelectHabit(habit) }
                )
                .padding(.leading, 24)
            }
        }
    }
}

// MARK: - Celebration Overlay

struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var textOpacity: Double = 0
    @State private var textScale: Double = 0.5
    @State private var congratsScale: Double = 1.0

    var body: some View {
        ZStack {
            // White overlay to dim the background
            Color.white
                .opacity(0.7)
                .ignoresSafeArea()

            // Green overlay background
            JournalTheme.Colors.goodDayGreen
                .opacity(0.5)
                .ignoresSafeArea()

            // Confetti particles
            ForEach(confettiParticles) { particle in
                ConfettiPiece(particle: particle)
            }

            // Celebration text
            VStack(spacing: 16) {
                Text("Congratulations!")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.goodDayGreenDark)
                    .scaleEffect(congratsScale)

                Text("Today was a good day!")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.8))
                
                Text("Give yourself a pat on the back!")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack.opacity(0.8))

                Text("Tap anywhere to continue")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.goodDayGreenDark.opacity(0.8))
                    .padding(.top, 20)
            }
            .opacity(textOpacity)
            .scaleEffect(textScale)
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) {
                isShowing = false
            }
        }
        .onAppear {
            // Animate text in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                textOpacity = 1
                textScale = 1
            }

            // Pulse animation for Congratulations - expand then shrink over 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.3)) {
                    congratsScale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        congratsScale = 1.0
                    }
                }
            }

            // Create confetti from both sides
            createConfetti()
        }
    }

    private func createConfetti() {
        let colors: [Color] = [
            JournalTheme.Colors.goodDayGreenDark,
            JournalTheme.Colors.goodDayGreen,
            JournalTheme.Colors.inkBlue,
            Color.yellow,
            Color.orange,
            Color.pink
        ]

        // Left side confetti (angled right and up)
        for i in 0..<25 {
            let particle = ConfettiParticle(
                id: i,
                x: -20,
                y: UIScreen.main.bounds.height * 0.6,
                color: colors.randomElement() ?? .green,
                velocityX: CGFloat.random(in: 150...350),
                velocityY: CGFloat.random(in: (-600)...(-300)),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: (-720)...720),
                size: CGFloat.random(in: 8...14),
                shape: ConfettiShape.allCases.randomElement() ?? .rectangle
            )
            confettiParticles.append(particle)
        }

        // Right side confetti (angled left and up)
        for i in 25..<50 {
            let particle = ConfettiParticle(
                id: i,
                x: UIScreen.main.bounds.width + 20,
                y: UIScreen.main.bounds.height * 0.6,
                color: colors.randomElement() ?? .green,
                velocityX: CGFloat.random(in: (-350)...(-150)),
                velocityY: CGFloat.random(in: (-600)...(-300)),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: (-720)...720),
                size: CGFloat.random(in: 8...14),
                shape: ConfettiShape.allCases.randomElement() ?? .rectangle
            )
            confettiParticles.append(particle)
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let velocityX: CGFloat
    let velocityY: CGFloat
    var rotation: Double
    let rotationSpeed: Double
    let size: CGFloat
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var position: CGPoint
    @State private var rotation: Double
    @State private var opacity: Double = 1

    init(particle: ConfettiParticle) {
        self.particle = particle
        _position = State(initialValue: CGPoint(x: particle.x, y: particle.y))
        _rotation = State(initialValue: particle.rotation)
    }

    var body: some View {
        Group {
            switch particle.shape {
            case .rectangle:
                Rectangle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size * 0.6)
            case .circle:
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            case .triangle:
                Triangle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            }
        }
        .rotationEffect(.degrees(rotation))
        .position(position)
        .opacity(opacity)
        .onAppear {
            // Animate the particle with physics
            withAnimation(.easeOut(duration: 2.5)) {
                position = CGPoint(
                    x: particle.x + particle.velocityX * 2,
                    y: particle.y + particle.velocityY * 2 + 800 // gravity pulls down
                )
                rotation = particle.rotation + particle.rotationSpeed * 2
                opacity = 0
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitGroup.self, DailyLog.self], inMemory: true)
}
