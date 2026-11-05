import Foundation
import Observation

@MainActor
@Observable
final class GoalEditorViewModel {
    var period: GoalPeriod
    var maxDrinks: Int
    let isCreating: Bool
    var saveToken = 0
    private let store: DrinkStore

    init(period: GoalPeriod, existing: GoalRecord?, store: DrinkStore) {
        self.store = store
        self.period = existing?.period ?? period
        self.isCreating = existing == nil
        self.maxDrinks = existing?.maxDrinks ?? period.defaultMax
    }

    var range: ClosedRange<Int> { period.range }

    var stepperRange: ClosedRange<Int> {
        let lower = min(range.lowerBound, maxDrinks)
        let upper = max(range.upperBound, maxDrinks)
        return lower...upper
    }

    var footer: String {
        let day = store.settings.weekStartsOn == 0 ? "Sunday" : "Monday"
        return "Weeks start on \(day). Change this in Settings."
    }

    func applyPeriodChange() {
        if let existing = store.goal(for: period) {
            maxDrinks = existing.maxDrinks
        } else {
            maxDrinks = period.defaultMax
        }
    }

    func save() {
        let limit = min(range.upperBound, max(range.lowerBound, maxDrinks))
        maxDrinks = limit
        store.saveGoal(period: period, maxDrinks: limit)
        Haptics.success()
        saveToken += 1
    }

    func delete() {
        store.deleteGoal(period: period)
    }
}
