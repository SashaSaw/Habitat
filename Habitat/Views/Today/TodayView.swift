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
    @State private var selectedDate = Date()
    @State private var selectedHabit: Habit?

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
                            Text("Today")
                                .font(JournalTheme.Fonts.title())
                                .foregroundStyle(JournalTheme.Colors.inkBlack)
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
                                    onSelectHabit: { selectedHabit = $0 }
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
            }
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationStack {
                HabitDetailView(store: store, habit: habit)
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
    private let completionThreshold: CGFloat = 0.75
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

/// A group row with nested habits
struct GroupLinedRow: View {
    let group: HabitGroup
    let habits: [Habit]
    let lineHeight: CGFloat
    let store: HabitStore
    let selectedDate: Date
    let onSelectHabit: (Habit) -> Void

    private let marginLeft = JournalTheme.Dimensions.marginLeft

    private var isSatisfied: Bool {
        group.isSatisfied(habits: store.habits, for: selectedDate)
    }

    private var completedCount: Int {
        group.completedCount(habits: store.habits, for: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Group header
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

            // Child habits (indented)
            ForEach(habits) { habit in
                HabitLinedRow(
                    habit: habit,
                    isCompleted: habit.isCompleted(for: selectedDate),
                    lineHeight: lineHeight,
                    onComplete: { store.setCompletion(for: habit, completed: true, on: selectedDate) },
                    onUncomplete: { store.setCompletion(for: habit, completed: false, on: selectedDate) },
                    onDelete: { store.deleteHabit(habit) },
                    onLongPress: { onSelectHabit(habit) }
                )
                .padding(.leading, 24)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitGroup.self, DailyLog.self], inMemory: true)
}
