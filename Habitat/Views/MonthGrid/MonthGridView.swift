import SwiftUI
import SwiftData
import UIKit

/// A scroll view that locks scrolling to one axis at a time with a sticky header
struct AxisLockedScrollView<Header: View, Content: View>: UIViewRepresentable {
    let header: Header
    let content: Content

    init(@ViewBuilder _ header: () -> Header, @ViewBuilder content: () -> Content) {
        self.header = header()
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        // Main scroll view for content
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.isDirectionalLockEnabled = true
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.decelerationRate = .fast
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Header hosting controller
        let headerHosting = UIHostingController(rootView: header)
        headerHosting.view.backgroundColor = .clear
        headerHosting.view.translatesAutoresizingMaskIntoConstraints = false

        // Content hosting controller
        let contentHosting = UIHostingController(rootView: content)
        contentHosting.view.backgroundColor = .clear
        contentHosting.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentHosting.view)
        containerView.addSubview(scrollView)
        containerView.addSubview(headerHosting.view)

        // Store references
        context.coordinator.contentHosting = contentHosting
        context.coordinator.headerHosting = headerHosting
        context.coordinator.headerView = headerHosting.view

        NSLayoutConstraint.activate([
            // Header at top, clips to container bounds horizontally
            headerHosting.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerHosting.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),

            // Scroll view fills container but starts below header
            scrollView.topAnchor.constraint(equalTo: headerHosting.view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Content inside scroll view
            contentHosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentHosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentHosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentHosting.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])

        return containerView
    }

    func updateUIView(_ containerView: UIView, context: Context) {
        context.coordinator.contentHosting?.rootView = content
        context.coordinator.headerHosting?.rootView = header
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var contentHosting: UIHostingController<Content>?
        var headerHosting: UIHostingController<Header>?
        var headerView: UIView?
        private var isDecelerating = false

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            if isDecelerating {
                scrollView.setContentOffset(scrollView.contentOffset, animated: false)
            }
            isDecelerating = false
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Sync header horizontal position with scroll view
            headerView?.transform = CGAffineTransform(translationX: -scrollView.contentOffset.x, y: 0)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            isDecelerating = decelerate
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isDecelerating = false
        }
    }
}

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
        AxisLockedScrollView {
            // Sticky header
            VStack(alignment: .leading, spacing: 0) {
                // Month header
                Text(Self.monthFormatter.string(from: selectedMonth))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(JournalTheme.Colors.inkBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                if hasContent {
                    HabitHeaderRowView(habits: standaloneHabits, groups: groups)
                }
            }
        } content: {
            // Scrollable content
            VStack(alignment: .leading, spacing: 0) {
                if !hasContent {
                    Text("No \(showMustDos ? "must-do" : "nice-to-do") habits")
                        .font(JournalTheme.Fonts.habitCriteria())
                        .foregroundStyle(JournalTheme.Colors.completedGray)
                        .padding()
                } else {
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
                .padding(.horizontal, 4)
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
                .padding(.horizontal, 4)
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
