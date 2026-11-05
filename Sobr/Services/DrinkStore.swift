import Foundation
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class DrinkStore {
    @ObservationIgnored private let container: ModelContainer
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let inMemory: Bool
    @ObservationIgnored private var settingsModel: AppSettings

    private(set) var entries: [DayRecord] = []
    private(set) var goals: [GoalRecord] = []
    private(set) var settings: SettingsSnapshot

    init(inMemory: Bool = false) {
        self.inMemory = inMemory
        let schema = Schema([DayEntry.self, DrinkGoal.self, AppSettings.self, CheckIn.self])
        let configuration = ModelConfiguration(
            "Sobr",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        let container: ModelContainer
        if let created = try? ModelContainer(for: schema, configurations: [configuration]) {
            container = created
        } else if inMemory {
            fatalError("Unable to open the in-memory Sobr store.")
        } else {
            Self.removeStore(at: configuration.url)
            guard let created = try? ModelContainer(for: schema, configurations: [configuration]) else {
                fatalError("Unable to open the Sobr store.")
            }
            container = created
        }

        self.container = container
        let context = container.mainContext
        self.context = context

        let existing = (try? context.fetch(FetchDescriptor<AppSettings>())) ?? []
        if let first = existing.first {
            for extra in existing.dropFirst() {
                context.delete(extra)
            }
            settingsModel = first
        } else {
            let created = AppSettings.makeNew()
            context.insert(created)
            try? context.save()
            settingsModel = created
        }

        settings = settingsModel.snapshot
        reloadEntries()
        reloadGoals()
        syncLoggedTodayFlag()
    }

    static func makePreview() -> DrinkStore {
        let store = DrinkStore(inMemory: true)
        store.completeOnboarding()
        store.saveGoal(period: .week, maxDrinks: 5)
        store.saveGoal(period: .month, maxDrinks: 20)
        let calendar = Calendar.current
        let today = Date()
        if let earlier = calendar.date(byAdding: .day, value: -10, to: today) {
            store.saveCount(3, on: earlier)
        }
        if let mid = calendar.date(byAdding: .day, value: -8, to: today) {
            store.saveCount(2, on: mid)
        }
        if let recent = calendar.date(byAdding: .day, value: -3, to: today) {
            store.saveCount(2, on: recent)
        }
        return store
    }

    func count(on date: Date) -> Int {
        let key = DateKey.string(from: date)
        return entries.first { $0.date == key }?.count ?? 0
    }

    func goal(for period: GoalPeriod) -> GoalRecord? {
        goals.first { $0.period == period }
    }

    func weekTotal(containing date: Date, excluding key: String? = nil) -> Int {
        let range = CalendarMath.weekRange(containing: date, weekStartsOn: settings.weekStartsOn)
        return CalendarMath.sum(counts: entryPairs, in: range, excluding: key)
    }

    func monthTotal(containing date: Date, excluding key: String? = nil) -> Int {
        let range = CalendarMath.monthRange(containing: date)
        return CalendarMath.sum(counts: entryPairs, in: range, excluding: key)
    }

    func drinkingDayCount(inMonth date: Date) -> Int {
        let range = CalendarMath.monthRange(containing: date)
        return entries.filter { range.contains($0.date) }.count
    }

    func alcoholFreeDays(inMonth date: Date, today: Date) -> Int {
        CalendarMath.alcoholFreeDays(
            monthContaining: date,
            today: today,
            entryDates: entries.map(\.date)
        )
    }

    func currentStreak(today: Date) -> Int {
        CalendarMath.currentStreak(
            today: DateKey.string(from: today),
            entryDates: entries.map(\.date),
            firstOpenDate: settings.firstOpenDate
        )
    }

    func longestStreak(today: Date) -> Int {
        CalendarMath.longestStreak(
            today: DateKey.string(from: today),
            entryDates: entries.map(\.date),
            firstOpenDate: settings.firstOpenDate
        )
    }

    func previewTotal(draft: Int, on date: Date, scope: GoalPeriod) -> Int {
        let savedOnDay = count(on: date)
        let saved = scope == .week ? weekTotal(containing: date) : monthTotal(containing: date)
        return CalendarMath.previewTotal(savedPeriodTotal: saved, savedOnDay: savedOnDay, draft: draft)
    }

    func recentWeeks(endingAt today: Date, count: Int = 8) -> [WeekBucket] {
        let weekStartsOn = settings.weekStartsOn
        let currentStart = CalendarMath.startOfWeek(containing: today, weekStartsOn: weekStartsOn)
        return (0..<count).reversed().map { offset in
            let start = CalendarMath.addingDays(-7 * offset, to: currentStart, weekStartsOn: weekStartsOn)
            let range = CalendarMath.weekRange(containing: start, weekStartsOn: weekStartsOn)
            let total = CalendarMath.sum(counts: entryPairs, in: range)
            let label = start.formatted(.dateTime.month(.defaultDigits).day())
            return WeekBucket(
                start: start,
                startKey: range.startKey,
                label: label,
                total: total
            )
        }
    }

    func streakSubtitle(today: Date) -> String {
        let todayKey = DateKey.string(from: today)
        if entries.contains(where: { $0.date == todayKey }) {
            return "You logged drinks today."
        }
        if let last = entries.map(\.date).filter({ $0 < todayKey }).max(),
           let date = DateKey.date(from: last) {
            let text = date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
            return "Since your last drink on \(text)."
        }
        let start = DateKey.date(from: settings.firstOpenDate) ?? today
        let text = start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        return "Since you started on \(text)."
    }

    func saveCount(_ count: Int, on date: Date) {
        let key = DateKey.string(from: date)
        let todayKey = DateKey.string(from: Date())
        guard key <= todayKey else { return }

        let clamped = CalendarMath.clampedCount(count)
        let fetched = (try? context.fetch(FetchDescriptor<DayEntry>())) ?? []
        let existing = fetched.first { $0.date == key }

        if clamped == 0 {
            if let existing {
                context.delete(existing)
            }
        } else if let existing {
            existing.count = clamped
            existing.updatedAt = Date()
        } else {
            context.insert(DayEntry(date: key, count: clamped, updatedAt: Date()))
        }

        try? context.save()
        reloadEntries()
        syncLoggedTodayFlag()
        scheduleReminderRefresh()
    }

    func saveGoal(period: GoalPeriod, maxDrinks: Int) {
        let limit = min(period.range.upperBound, max(period.range.lowerBound, maxDrinks))
        let fetched = (try? context.fetch(FetchDescriptor<DrinkGoal>())) ?? []
        let matches = fetched.filter { $0.period == period.rawValue }
        if let first = matches.first {
            first.maxDrinks = limit
            first.updatedAt = Date()
            for extra in matches.dropFirst() {
                context.delete(extra)
            }
        } else {
            context.insert(
                DrinkGoal(period: period.rawValue, maxDrinks: limit, createdAt: Date(), updatedAt: Date())
            )
        }
        try? context.save()
        reloadGoals()
    }

    func deleteGoal(period: GoalPeriod) {
        let fetched = (try? context.fetch(FetchDescriptor<DrinkGoal>())) ?? []
        for goal in fetched where goal.period == period.rawValue {
            context.delete(goal)
        }
        try? context.save()
        reloadGoals()
    }

    func deleteAllData() {
        let fetchedEntries = (try? context.fetch(FetchDescriptor<DayEntry>())) ?? []
        fetchedEntries.forEach { context.delete($0) }
        let fetchedGoals = (try? context.fetch(FetchDescriptor<DrinkGoal>())) ?? []
        fetchedGoals.forEach { context.delete($0) }
        settingsModel.firstOpenDate = DateKey.string(from: Date())
        try? context.save()
        reloadEntries()
        reloadGoals()
        settings = settingsModel.snapshot
        syncLoggedTodayFlag()
        scheduleReminderRefresh()
    }

    func completeOnboarding() {
        settingsModel.onboardingComplete = true
        persistSettings()
    }

    func setWeekStartsOn(_ value: Int) {
        settingsModel.weekStartsOn = value == 0 ? 0 : 1
        persistSettings()
    }

    func setReminderEnabled(_ enabled: Bool) {
        settingsModel.reminderEnabled = enabled
        persistSettings()
        scheduleReminderRefresh()
    }

    func updateReminderTime(_ date: Date) {
        settingsModel.reminderTime = DateKey.timeString(from: date)
        persistSettings()
        scheduleReminderRefresh()
    }

    func rescheduleNotifications() async {
        guard !inMemory else { return }
        let todayKey = DateKey.string(from: Date())
        let todayLogged = entries.contains { $0.date == todayKey }
        await NotificationService.shared.reschedule(
            enabled: settings.reminderEnabled,
            time: settings.reminderTime,
            skipToday: todayLogged
        )
    }

    private var entryPairs: [(date: String, count: Int)] {
        entries.map { ($0.date, $0.count) }
    }

    private func persistSettings() {
        try? context.save()
        settings = settingsModel.snapshot
    }

    private func reloadEntries() {
        let fetched = (try? context.fetch(FetchDescriptor<DayEntry>())) ?? []
        entries = fetched
            .map { DayRecord(date: $0.date, count: $0.count) }
            .sorted { $0.date < $1.date }
    }

    private func reloadGoals() {
        let fetched = (try? context.fetch(FetchDescriptor<DrinkGoal>())) ?? []
        var seen = Set<GoalPeriod>()
        goals = fetched.compactMap { goal in
            guard let period = GoalPeriod(rawValue: goal.period), seen.insert(period).inserted else {
                return nil
            }
            return GoalRecord(period: period, maxDrinks: goal.maxDrinks)
        }
        .sorted { $0.period.rawValue < $1.period.rawValue }
    }

    private func syncLoggedTodayFlag() {
        let key = DateKey.string(from: Date())
        if count(on: Date()) > 0 {
            UserDefaults.standard.set(key, forKey: LoggedTodayFlag.key)
        } else if UserDefaults.standard.string(forKey: LoggedTodayFlag.key) == key {
            UserDefaults.standard.removeObject(forKey: LoggedTodayFlag.key)
        }
    }

    private func scheduleReminderRefresh() {
        guard !inMemory else { return }
        Task { await rescheduleNotifications() }
    }

    private static func removeStore(at url: URL) {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: url)
        try? fileManager.removeItem(atPath: url.path + "-wal")
        try? fileManager.removeItem(atPath: url.path + "-shm")
    }
}
