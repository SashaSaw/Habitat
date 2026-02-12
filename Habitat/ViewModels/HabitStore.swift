import Foundation
import SwiftData
import SwiftUI

@Observable
final class HabitStore {
    private var modelContext: ModelContext

    var habits: [Habit] = []
    var allHabits: [Habit] = []
    var groups: [HabitGroup] = []
    var selectedDate: Date = Date()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }

    // MARK: - Data Fetching

    func fetchData() {
        fetchHabits()
        fetchAllHabits()
        fetchGroups()
    }

    private func fetchHabits() {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        do {
            habits = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch habits: \(error)")
            habits = []
        }
    }

    private func fetchAllHabits() {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        do {
            allHabits = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch all habits: \(error)")
            allHabits = []
        }
    }

    // MARK: - Live/Archived Habits

    var liveHabits: [Habit] {
        allHabits.filter { $0.isActive }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var archivedHabits: [Habit] {
        allHabits.filter { !$0.isActive }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func archiveHabit(_ habit: Habit) {
        habit.isActive = false
        saveContext()
        fetchData()
    }

    func unarchiveHabit(_ habit: Habit) {
        habit.isActive = true
        saveContext()
        fetchData()
    }

    func reorderHabits(_ habits: [Habit]) {
        for (index, habit) in habits.enumerated() {
            habit.sortOrder = index
        }
        saveContext()
        fetchAllHabits()
    }

    private func fetchGroups() {
        let descriptor = FetchDescriptor<HabitGroup>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        do {
            groups = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch groups: \(error)")
            groups = []
        }
    }

    // MARK: - Filtered Habits

    var mustDoHabits: [Habit] {
        habits.filter { $0.tier == .mustDo && !$0.isTask }
    }

    var niceToDoHabits: [Habit] {
        habits.filter { $0.tier == .niceToDo && !$0.isTask }
    }

    /// All negative habits (things to avoid)
    var negativeHabits: [Habit] {
        habits.filter { $0.type == .negative && !$0.isTask }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// One-off tasks (frequency == .once) that are active
    var todayTasks: [Habit] {
        habits.filter { $0.isTask }
    }

    /// All recurring habits (excludes one-off tasks) — for stats and month views
    var recurringHabits: [Habit] {
        habits.filter { !$0.isTask }
    }

    /// Positive must-do habits not in any group (excludes negative)
    var standalonePositiveMustDoHabits: [Habit] {
        let groupedHabitIds = Set(mustDoGroups.flatMap { $0.habitIds })
        return mustDoHabits.filter {
            !groupedHabitIds.contains($0.id) && $0.type == .positive
        }
    }

    /// Positive nice-to-do habits (excludes negative and tasks)
    var positiveNiceToDoHabits: [Habit] {
        niceToDoHabits.filter { $0.type == .positive && !$0.isTask }
    }

    /// Uncompleted one-off tasks: created today OR rolled over from previous days, excluding completed
    var todayVisibleTasks: [Habit] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return habits.filter { habit in
            guard habit.isTask else { return false }
            // Exclude completed tasks (they appear in todayCompletedTasks)
            guard !habit.isCompleted(for: today) else { return false }
            let createdDay = calendar.startOfDay(for: habit.createdAt)
            // Show if created today, or if created before today and still uncompleted (rollover)
            return createdDay == today || !habit.isCompleted(for: createdDay)
        }
    }

    /// Completed tasks for today (to show in done section)
    var todayCompletedTasks: [Habit] {
        let today = Date()
        return habits.filter { $0.isTask && $0.isCompleted(for: today) }
    }

    var mustDoGroups: [HabitGroup] {
        groups.filter { $0.tier == .mustDo }
    }

    var niceToDoGroups: [HabitGroup] {
        groups.filter { $0.tier == .niceToDo }
    }

    /// Returns habits that are not in any must-do group (standalone must-dos)
    var standaloneMustDoHabits: [Habit] {
        let groupedHabitIds = Set(mustDoGroups.flatMap { $0.habitIds })
        return mustDoHabits.filter { !groupedHabitIds.contains($0.id) }
    }

    /// Returns habits for a specific group
    func habits(for group: HabitGroup) -> [Habit] {
        habits.filter { group.habitIds.contains($0.id) }
    }

    // MARK: - Habit CRUD Operations

    @discardableResult
    func addHabit(
        name: String,
        description: String = "",
        tier: HabitTier = .mustDo,
        type: HabitType = .positive,
        frequencyType: FrequencyType = .daily,
        frequencyTarget: Int = 1,
        successCriteria: String? = nil,
        groupId: UUID? = nil,
        isHobby: Bool = false,
        iconImageData: Data? = nil,
        notificationsEnabled: Bool = false,
        dailyNotificationMinutes: [Int] = [],
        weeklyNotificationDays: [Int] = [],
        options: [String] = [],
        enableNotesPhotos: Bool = false,
        habitPrompt: String = "",
        scheduleTimes: [String] = [],
        triggersAppBlockSlip: Bool = false
    ) -> Habit {
        let maxSortOrder = habits.map { $0.sortOrder }.max() ?? 0

        // Tasks are always nice-to-do and positive
        let effectiveTier: HabitTier = frequencyType == .once ? .niceToDo : tier
        let effectiveType: HabitType = frequencyType == .once ? .positive : type

        let habit = Habit(
            name: name,
            habitDescription: description,
            tier: effectiveTier,
            type: effectiveType,
            frequencyType: frequencyType,
            frequencyTarget: frequencyTarget,
            successCriteria: successCriteria,
            groupId: groupId,
            sortOrder: maxSortOrder + 1,
            isHobby: isHobby
        )
        habit.iconImageData = iconImageData
        habit.notificationsEnabled = notificationsEnabled
        habit.dailyNotificationMinutes = dailyNotificationMinutes
        habit.weeklyNotificationDays = weeklyNotificationDays
        habit.options = options
        habit.enableNotesPhotos = enableNotesPhotos
        habit.habitPrompt = habitPrompt
        habit.scheduleTimes = scheduleTimes
        habit.triggersAppBlockSlip = triggersAppBlockSlip

        modelContext.insert(habit)
        saveContext()
        fetchData()

        // Schedule notifications for the new habit
        if notificationsEnabled {
            Task {
                await NotificationService.shared.scheduleNotifications(for: habit)
            }
        }

        // Refresh smart reminders since habit list changed
        refreshSmartReminders()

        return habit
    }

    func updateHabit(_ habit: Habit) {
        saveContext()
        fetchData()
    }

    func deleteHabit(_ habit: Habit) {
        // Cancel any scheduled notifications for this habit
        Task {
            await NotificationService.shared.cancelNotifications(for: habit)
        }

        // Remove from any groups
        for group in groups where group.habitIds.contains(habit.id) {
            group.habitIds.removeAll { $0 == habit.id }
        }

        // Remove from local arrays
        habits.removeAll { $0.id == habit.id }
        allHabits.removeAll { $0.id == habit.id }

        // Then delete from database
        modelContext.delete(habit)
        saveContext()
    }

    func deactivateHabit(_ habit: Habit) {
        habit.isActive = false
        saveContext()
        fetchHabits()
    }

    // MARK: - Group CRUD Operations

    func addGroup(
        name: String,
        tier: HabitTier = .mustDo,
        requireCount: Int = 1,
        habitIds: [UUID] = []
    ) {
        let maxSortOrder = groups.map { $0.sortOrder }.max() ?? 0
        let group = HabitGroup(
            name: name,
            tier: tier,
            requireCount: requireCount,
            habitIds: habitIds,
            sortOrder: maxSortOrder + 1
        )
        modelContext.insert(group)

        // Update habits to reference this group
        for habitId in habitIds {
            if let habit = habits.first(where: { $0.id == habitId }) {
                habit.groupId = group.id
            }
        }

        saveContext()
        fetchData()
    }

    func updateGroup(_ group: HabitGroup) {
        saveContext()
        fetchGroups()
    }

    func deleteGroup(_ group: HabitGroup) {
        // Remove group reference from habits
        for habitId in group.habitIds {
            if let habit = habits.first(where: { $0.id == habitId }) {
                habit.groupId = nil
            }
        }

        modelContext.delete(group)
        saveContext()
        fetchData()
    }

    /// Creates a new group by combining two habits (iOS folder-style creation)
    func createGroupFromHabits(_ habit1: Habit, _ habit2: Habit) -> HabitGroup {
        // Use the tier of the first habit
        let tier = habit1.tier

        // Create a default name
        let groupName = "New Group"

        let maxSortOrder = groups.map { $0.sortOrder }.max() ?? 0
        let group = HabitGroup(
            name: groupName,
            tier: tier,
            requireCount: 1,
            habitIds: [habit1.id, habit2.id],
            sortOrder: maxSortOrder + 1
        )
        modelContext.insert(group)

        // Update habits to reference this group
        habit1.groupId = group.id
        habit2.groupId = group.id

        saveContext()
        fetchData()

        return group
    }

    func addHabitToGroup(_ habit: Habit, group: HabitGroup) {
        if !group.habitIds.contains(habit.id) {
            group.habitIds.append(habit.id)
            habit.groupId = group.id
            saveContext()
            fetchData()
        }
    }

    func removeHabitFromGroup(_ habit: Habit, group: HabitGroup) {
        group.habitIds.removeAll { $0 == habit.id }
        habit.groupId = nil
        saveContext()
        fetchData()
    }

    // MARK: - Completion Logic

    func toggleCompletion(for habit: Habit, on date: Date = Date()) {
        let isCurrentlyCompleted = habit.isCompleted(for: date)
        let newCompletedState = !isCurrentlyCompleted

        _ = DailyLog.createOrUpdate(
            for: habit,
            on: date,
            completed: newCompletedState,
            context: modelContext
        )

        // Update streaks
        updateStreak(for: habit)

        saveContext()
        refreshSmartReminders()
    }

    func setCompletion(for habit: Habit, completed: Bool, value: Double? = nil, on date: Date = Date()) {
        _ = DailyLog.createOrUpdate(
            for: habit,
            on: date,
            completed: completed,
            value: value,
            context: modelContext
        )

        // Update streaks
        updateStreak(for: habit)

        saveContext()
        refreshSmartReminders()
    }

    /// Reschedules smart reminders based on current habit state
    /// Called after completion changes so reminder content stays accurate
    func refreshSmartReminders() {
        guard UserSchedule.shared.smartRemindersEnabled else { return }
        Task {
            await SmartReminderService.shared.rescheduleAllReminders(
                habits: self.habits,
                groups: self.groups
            )
        }
    }

    /// Records which sub-habit option was selected when completing a group habit
    func recordSelectedOption(for habit: Habit, option: String, on date: Date) {
        if let log = habit.log(for: date) {
            log.selectedOption = option
            saveContext()
        }
    }

    /// Saves hobby completion with optional note and photo
    func saveHobbyCompletion(for habit: Habit, on date: Date, note: String?, image: UIImage?) {
        var photoPath: String? = nil
        if let image = image {
            photoPath = PhotoStorageService.shared.savePhoto(image, for: habit.id, on: date)
        }

        // Update existing DailyLog with note and photoPath
        let log = DailyLog.createOrUpdate(
            for: habit,
            on: date,
            completed: true,
            note: note,
            photoPath: photoPath,
            context: modelContext
        )

        // Ensure the log properties are set directly (SwiftData sometimes needs this)
        if let note = note {
            log.note = note
        }
        if let photoPath = photoPath {
            log.photoPath = photoPath
        }

        saveContext()
    }

    // MARK: - Good Day Logic

    func isGoodDay(for date: Date) -> Bool {
        // Get standalone POSITIVE must-do habits (not in any group, excludes negative)
        let standaloneMustDos = mustDoHabits.filter { $0.groupId == nil && $0.type == .positive }

        // If there are no positive must-do habits AND no must-do groups, it's not a "good day"
        // (nothing to complete means no achievement)
        if standaloneMustDos.isEmpty && mustDoGroups.isEmpty {
            return false
        }

        // All standalone positive must-do habits must be completed
        let allMustDosCompleted = standaloneMustDos.allSatisfy { $0.isCompleted(for: date) }

        // All must-do groups must be satisfied
        let allGroupsSatisfied = mustDoGroups.allSatisfy { group in
            group.isSatisfied(habits: habits, for: date)
        }

        // All negative habits must NOT be completed (no slips)
        let noNegativeSlips = negativeHabits.allSatisfy { !$0.isCompleted(for: date) }

        return allMustDosCompleted && allGroupsSatisfied && noNegativeSlips
    }

    /// Returns good days in a date range
    func goodDays(from startDate: Date, to endDate: Date) -> [Date] {
        var goodDays: [Date] = []
        let calendar = Calendar.current
        var currentDate = startDate

        while currentDate <= endDate {
            if isGoodDay(for: currentDate) {
                goodDays.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return goodDays
    }

    // MARK: - Must-Do Progress (for streak tracker bar)

    /// Total number of must-do items for today (standalone habits + groups)
    func mustDoTotalCount(for date: Date) -> Int {
        let standaloneMustDos = mustDoHabits.filter { $0.groupId == nil && $0.type == .positive }
        return standaloneMustDos.count + mustDoGroups.count
    }

    /// Number of completed must-do items for today
    func mustDoCompletedCount(for date: Date) -> Int {
        let standaloneMustDos = mustDoHabits.filter { $0.groupId == nil && $0.type == .positive }
        let completedStandalone = standaloneMustDos.filter { $0.isCompleted(for: date) }.count
        let completedGroups = mustDoGroups.filter { $0.isSatisfied(habits: habits, for: date) }.count
        return completedStandalone + completedGroups
    }

    /// Current good-day streak (consecutive days where all must-dos were completed)
    func currentGoodDayStreak() -> Int {
        var streak = 0
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: Date())

        if isGoodDay(for: date) {
            streak = 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        } else {
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }

        var daysChecked = 0
        while isGoodDay(for: date) && daysChecked < 365 {
            streak += 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
            daysChecked += 1
        }

        return streak
    }

    /// Completed nice-to-do habits for a given date (for the Done section)
    func completedNiceToDoHabits(for date: Date) -> [Habit] {
        positiveNiceToDoHabits.filter { $0.isCompleted(for: date) }
    }

    /// Uncompleted nice-to-do habits for a given date
    func uncompletedNiceToDoHabits(for date: Date) -> [Habit] {
        positiveNiceToDoHabits.filter { !$0.isCompleted(for: date) }
    }

    // MARK: - Streak Calculation

    func updateStreak(for habit: Habit) {
        if habit.type == .negative {
            // For negative habits, streak = days since last done
            let daysSince = calculateDaysSinceLastDone(for: habit)
            habit.currentStreak = daysSince
            if daysSince > habit.bestStreak {
                habit.bestStreak = daysSince
            }
        } else {
            // Existing logic for positive habits
            let streak = calculateCurrentStreak(for: habit)
            habit.currentStreak = streak
            if streak > habit.bestStreak {
                habit.bestStreak = streak
            }
        }
    }

    /// Calculates days since habit was last completed (for negative habits)
    func calculateDaysSinceLastDone(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let completedLogs = habit.dailyLogs
            .filter { $0.completed }
            .sorted { $0.date > $1.date }

        guard let lastCompletedLog = completedLogs.first else {
            // Never completed - count from creation date
            let creationDay = calendar.startOfDay(for: habit.createdAt)
            let daysSinceCreation = calendar.dateComponents([.day], from: creationDay, to: today).day ?? 0
            return max(0, daysSinceCreation)
        }

        let lastCompletedDate = calendar.startOfDay(for: lastCompletedLog.date)
        let daysSince = calendar.dateComponents([.day], from: lastCompletedDate, to: today).day ?? 0
        return max(0, daysSince)
    }

    func calculateCurrentStreak(for habit: Habit) -> Int {
        // Tasks don't have streaks
        if habit.isTask { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch habit.frequencyType {
        case .once:
            return 0
        case .daily:
            return calculateDailyStreak(for: habit, from: today)
        case .weekly:
            return calculateWeeklyStreak(for: habit, target: habit.frequencyTarget, from: today)
        case .monthly:
            return calculateMonthlyStreak(for: habit, target: habit.frequencyTarget, from: today)
        }
    }

    private func calculateDailyStreak(for habit: Habit, from date: Date) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = date

        // Check if today is completed
        if habit.isCompleted(for: checkDate) {
            streak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        } else {
            // If today is not completed, check yesterday to see if streak is still alive
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        // Count backwards
        while habit.isCompleted(for: checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        return streak
    }

    private func calculateWeeklyStreak(for habit: Habit, target: Int, from date: Date) -> Int {
        let calendar = Calendar.current
        var streak = 0

        // Get the start of current week
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!

        // Check current week
        let currentWeekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let currentWeekCompletions = habit.completionCount(from: weekStart, to: min(date, currentWeekEnd))

        if currentWeekCompletions >= target {
            streak = 1
        }

        // Count previous weeks
        weekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!

        while true {
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let completions = habit.completionCount(from: weekStart, to: weekEnd)

            if completions >= target {
                streak += 1
                weekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
            } else {
                break
            }
        }

        return streak
    }

    private func calculateMonthlyStreak(for habit: Habit, target: Int, from date: Date) -> Int {
        let calendar = Calendar.current
        var streak = 0

        // Get the start of current month
        var monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!

        // Check current month
        let currentMonthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        let currentMonthCompletions = habit.completionCount(from: monthStart, to: min(date, currentMonthEnd))

        if currentMonthCompletions >= target {
            streak = 1
        }

        // Count previous months
        monthStart = calendar.date(byAdding: .month, value: -1, to: monthStart)!

        while true {
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            let completions = habit.completionCount(from: monthStart, to: monthEnd)

            if completions >= target {
                streak += 1
                monthStart = calendar.date(byAdding: .month, value: -1, to: monthStart)!
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Statistics

    func completionRate(for habit: Habit, days: Int = 30) -> Double {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        // Use -(days - 1) because today counts as day 1
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: endDate) else { return 0 }

        let completedDays = habit.completionCount(from: startDate, to: endDate)
        return Double(completedDays) / Double(days)
    }

    func goodDayRate(days: Int = 30) -> Double {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        // Use -(days - 1) because today counts as day 1
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: endDate) else { return 0 }

        let goodDaysList = goodDays(from: startDate, to: endDate)
        return Double(goodDaysList.count) / Double(days)
    }

    // MARK: - Sample Data

    func createSampleData() {
        // Only create if no habits exist
        guard habits.isEmpty else { return }

        // Must-do habits
        addHabit(name: "Brush teeth", tier: .mustDo, type: .positive, frequencyType: .daily)
        addHabit(name: "Floss", tier: .mustDo, type: .positive, frequencyType: .daily)
        addHabit(name: "Drink water", tier: .mustDo, type: .positive, frequencyType: .daily, successCriteria: "3L")
        addHabit(name: "Wake up by 9am", tier: .mustDo, type: .positive, frequencyType: .daily)
        addHabit(name: "Sleep by midnight", tier: .mustDo, type: .positive, frequencyType: .daily)
        addHabit(name: "Go outside", tier: .mustDo, type: .positive, frequencyType: .daily)

        // Nice-to-do habits
        addHabit(name: "Guitar 🎸", tier: .niceToDo, type: .positive, frequencyType: .daily, successCriteria: "15 mins")
        addHabit(name: "Draw 🎨", tier: .niceToDo, type: .positive, frequencyType: .daily)
        addHabit(name: "Exercise", tier: .niceToDo, type: .positive, frequencyType: .weekly, frequencyTarget: 4)
        addHabit(name: "Morning walk", tier: .niceToDo, type: .positive, frequencyType: .daily)

        fetchHabits()

        // Create "Do something creative" group
        let guitarHabit = habits.first { $0.name.contains("Guitar") }
        let drawHabit = habits.first { $0.name.contains("Draw") }

        if let guitar = guitarHabit, let draw = drawHabit {
            addGroup(
                name: "Do something creative",
                tier: .mustDo,
                requireCount: 1,
                habitIds: [guitar.id, draw.id]
            )
        }
    }

    // MARK: - Private Helpers

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
