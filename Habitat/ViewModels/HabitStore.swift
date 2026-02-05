import Foundation
import SwiftData
import SwiftUI

@Observable
final class HabitStore {
    private var modelContext: ModelContext

    var habits: [Habit] = []
    var groups: [HabitGroup] = []
    var selectedDate: Date = Date()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }

    // MARK: - Data Fetching

    func fetchData() {
        fetchHabits()
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
        habits.filter { $0.tier == .mustDo }
    }

    var niceToDoHabits: [Habit] {
        habits.filter { $0.tier == .niceToDo }
    }

    /// All negative habits (things to avoid)
    var negativeHabits: [Habit] {
        habits.filter { $0.type == .negative }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Positive must-do habits not in any group (excludes negative)
    var standalonePositiveMustDoHabits: [Habit] {
        let groupedHabitIds = Set(mustDoGroups.flatMap { $0.habitIds })
        return mustDoHabits.filter {
            !groupedHabitIds.contains($0.id) && $0.type == .positive
        }
    }

    /// Positive nice-to-do habits (excludes negative)
    var positiveNiceToDoHabits: [Habit] {
        niceToDoHabits.filter { $0.type == .positive }
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

    func addHabit(
        name: String,
        description: String = "",
        tier: HabitTier = .mustDo,
        type: HabitType = .positive,
        frequencyType: FrequencyType = .daily,
        frequencyTarget: Int = 1,
        successCriteria: String? = nil,
        groupId: UUID? = nil
    ) {
        let maxSortOrder = habits.map { $0.sortOrder }.max() ?? 0
        let habit = Habit(
            name: name,
            habitDescription: description,
            tier: tier,
            type: type,
            frequencyType: frequencyType,
            frequencyTarget: frequencyTarget,
            successCriteria: successCriteria,
            groupId: groupId,
            sortOrder: maxSortOrder + 1
        )
        modelContext.insert(habit)
        saveContext()
        fetchHabits()
    }

    func updateHabit(_ habit: Habit) {
        saveContext()
        fetchHabits()
    }

    func deleteHabit(_ habit: Habit) {
        // Remove from any groups
        for group in groups where group.habitIds.contains(habit.id) {
            group.habitIds.removeAll { $0 == habit.id }
        }

        // Remove from local array first (faster than re-fetching)
        habits.removeAll { $0.id == habit.id }

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
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch habit.frequencyType {
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
