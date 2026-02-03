import SwiftUI
import SwiftData

/// Month Grid View showing habit completion over the month
struct MonthGridView: View {
    @Bindable var store: HabitStore
    @State private var selectedMonth = Date()
    @State private var showingNiceToDoGrid = false

    var body: some View {
        NavigationStack {
            MonthGridContentView(
                store: store,
                selectedMonth: $selectedMonth,
                showMustDos: !showingNiceToDoGrid
            )
            .navigationTitle(showingNiceToDoGrid ? "Nice To Do" : "Must Do")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            showingNiceToDoGrid.toggle()
                        }
                    } label: {
                        Text(showingNiceToDoGrid ? "Must Do" : "Nice To Do")
                            .font(.system(size: 14, weight: .medium))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            withAnimation {
                                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Button {
                            withAnimation {
                                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
            }
        }
    }
}

/// The actual content of the Month Grid
struct MonthGridContentView: View {
    @Bindable var store: HabitStore
    @Binding var selectedMonth: Date
    let showMustDos: Bool

    // Static formatters for performance
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    // Standalone habits (not in any group)
    private var standaloneHabits: [Habit] {
        if showMustDos {
            return store.standaloneMustDoHabits
        } else {
            return store.niceToDoHabits
        }
    }

    // Groups (only for must-do view)
    private var groups: [HabitGroup] {
        showMustDos ? store.mustDoGroups : []
    }

    private var calendar: Calendar { Calendar.current }

    private var monthDates: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))
        else { return [] }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    private var hasContent: Bool {
        !standaloneHabits.isEmpty || !groups.isEmpty
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // Month header
                Text(Self.monthFormatter.string(from: selectedMonth))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                if !hasContent {
                    Text("No \(showMustDos ? "must-do" : "nice-to-do") habits")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                        .padding()
                } else {
                    // Grid
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            // Day rows
                            ForEach(monthDates, id: \.self) { date in
                                DayRowView(
                                    date: date,
                                    habits: standaloneHabits,
                                    groups: groups,
                                    allHabits: store.habits,
                                    isGoodDay: showMustDos ? store.isGoodDay(for: date) : false,
                                    showGoodDayHighlight: showMustDos
                                )
                            }
                        } header: {
                            // Habit and group name headers
                            HabitHeaderRowView(habits: standaloneHabits, groups: groups)
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .graphPaperBackground()
    }
}

/// Header row with habit and group names
struct HabitHeaderRowView: View {
    let habits: [Habit]
    let groups: [HabitGroup]

    var body: some View {
        HStack(spacing: 0) {
            // Day column header
            Text("Day")
                .font(JournalTheme.Fonts.sectionHeader())
                .foregroundStyle(JournalTheme.Colors.inkBlue)
                .frame(width: 50, alignment: .leading)
                .padding(.horizontal, 8)

            // Habit column headers
            ForEach(habits) { habit in
                Text(habit.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                    .lineLimit(2)
                    .frame(width: 60, alignment: .center)
                    .padding(.horizontal, 4)
            }

            // Group column headers
            ForEach(groups) { group in
                Text(group.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(JournalTheme.Colors.inkBlue) // Blue to distinguish groups
                    .lineLimit(2)
                    .frame(width: 60, alignment: .center)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}

/// A single day row in the grid
struct DayRowView: View {
    let date: Date
    let habits: [Habit]
    let groups: [HabitGroup]
    let allHabits: [Habit] // All habits for checking group satisfaction
    let isGoodDay: Bool
    let showGoodDayHighlight: Bool

    // Static formatters for performance
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isFuture: Bool {
        date > Date()
    }

    var body: some View {
        HStack(spacing: 0) {
            // Day number and weekday
            VStack(alignment: .leading, spacing: 0) {
                Text(Self.dayFormatter.string(from: date))
                    .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(isToday ? JournalTheme.Colors.inkBlue : JournalTheme.Colors.inkBlack)

                Text(Self.weekdayFormatter.string(from: date))
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(JournalTheme.Colors.completedGray)
            }
            .frame(width: 50, alignment: .leading)
            .padding(.horizontal, 8)

            // Habit completion cells
            ForEach(habits) { habit in
                GridCellView(
                    isCompleted: habit.isCompleted(for: date),
                    habitType: habit.type,
                    isFuture: isFuture,
                    showCross: showGoodDayHighlight // Only show crosses in must-do view
                )
                .frame(width: 60)
            }

            // Group completion cells
            ForEach(groups) { group in
                GridCellView(
                    isCompleted: group.isSatisfied(habits: allHabits, for: date),
                    habitType: .positive, // Groups are always positive
                    isFuture: isFuture,
                    showCross: showGoodDayHighlight
                )
                .frame(width: 60)
            }
        }
        .padding(.vertical, 6)
        .background(
            Group {
                if showGoodDayHighlight && isGoodDay && !isFuture {
                    JournalTheme.Colors.goodDayGreen.opacity(0.4)
                } else if isToday {
                    JournalTheme.Colors.lineMedium.opacity(0.2)
                } else {
                    Color.clear
                }
            }
        )
    }
}

/// A single cell in the grid showing completion status
struct GridCellView: View {
    let isCompleted: Bool
    let habitType: HabitType
    let isFuture: Bool
    let showCross: Bool

    var body: some View {
        Group {
            if isFuture {
                // Future dates are empty
                Color.clear
            } else if isCompleted {
                // Completed - show checkmark
                HandDrawnCheckmark(size: 18, color: JournalTheme.Colors.inkBlue)
            } else if showCross {
                // Not completed in must-do view - show cross
                HandDrawnCross(size: 18, color: JournalTheme.Colors.negativeRedDark.opacity(0.6))
            } else {
                // Not completed in nice-to-do view - empty
                Color.clear
            }
        }
        .frame(width: 24, height: 24)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitGroup.self, DailyLog.self], inMemory: true)
}
