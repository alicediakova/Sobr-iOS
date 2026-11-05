import Foundation
import Observation

@MainActor
@Observable
final class LogDayViewModel {
    let date: Date
    let wasLogged: Bool
    private let store: DrinkStore

    var draft: Int
    var saveToken = 0

    init(date: Date, store: DrinkStore) {
        self.date = date
        self.store = store
        let existing = store.count(on: date)
        self.wasLogged = existing > 0
        self.draft = existing
    }

    var title: String {
        date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    var weekTotal: Int {
        store.previewTotal(draft: draft, on: date, scope: .week)
    }

    var monthTotal: Int {
        store.previewTotal(draft: draft, on: date, scope: .month)
    }

    var weekMax: Int? {
        store.goal(for: .week)?.maxDrinks
    }

    var monthMax: Int? {
        store.goal(for: .month)?.maxDrinks
    }

    var message: String {
        CalendarMath.logMessage(
            draft: draft,
            weekTotal: weekTotal,
            weekMax: weekMax,
            monthTotal: monthTotal,
            monthMax: monthMax
        )
    }

    var messageIsWarning: Bool {
        if let weekMax, weekTotal > weekMax { return true }
        if let monthMax, monthTotal > monthMax { return true }
        return false
    }

    func save() {
        store.saveCount(draft, on: date)
        Haptics.success()
        saveToken += 1
    }

    func clearDay() {
        draft = 0
        store.saveCount(0, on: date)
        Haptics.success()
        saveToken += 1
    }
}
