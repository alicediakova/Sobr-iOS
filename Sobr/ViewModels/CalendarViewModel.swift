import Foundation
import Observation

@MainActor
struct CalendarViewModel {
    let store: DrinkStore
    let visibleMonth: Date
    let today: Date

    var monthTitle: String {
        visibleMonth.formatted(.dateTime.month(.wide).year())
    }

    var glanceTitle: String {
        let month = visibleMonth.formatted(.dateTime.month(.wide))
        return "\(month) at a glance"
    }

    var weekdayHeaders: [String] {
        CalendarMath.weekdayHeaders(weekStartsOn: store.settings.weekStartsOn)
    }

    var canAdvance: Bool {
        !CalendarMath.isCurrentMonth(visibleMonth, today: today)
    }

    var isCurrentMonth: Bool {
        CalendarMath.isCurrentMonth(visibleMonth, today: today)
    }

    var days: [MonthDay] {
        let todayKey = DateKey.string(from: today)
        return CalendarMath.monthCells(containing: visibleMonth, weekStartsOn: store.settings.weekStartsOn)
            .enumerated()
            .map { index, date in
                guard let date else {
                    return MonthDay(
                        id: "blank-\(index)-\(monthTitle)",
                        date: nil,
                        number: "",
                        count: 0,
                        isToday: false,
                        isFuture: false
                    )
                }
                let key = DateKey.string(from: date)
                let number = Calendar.current.component(.day, from: date)
                return MonthDay(
                    id: key,
                    date: date,
                    number: "\(number)",
                    count: store.count(on: date),
                    isToday: key == todayKey,
                    isFuture: key > todayKey
                )
            }
    }

    var streakValue: Int {
        store.currentStreak(today: today)
    }

    var streakUnit: String {
        streakValue == 1 ? "day alcohol-free" : "days alcohol-free"
    }

    var streakSubtitle: String {
        store.streakSubtitle(today: today)
    }

    var drinkTotal: Int {
        store.monthTotal(containing: visibleMonth)
    }

    var drinkingDays: Int {
        store.drinkingDayCount(inMonth: visibleMonth)
    }

    var alcoholFreeDays: Int {
        store.alcoholFreeDays(inMonth: visibleMonth, today: today)
    }

    var weekTotal: Int {
        store.weekTotal(containing: today)
    }

    var weekMax: Int? {
        store.goal(for: .week)?.maxDrinks
    }

    var monthMax: Int? {
        store.goal(for: .month)?.maxDrinks
    }

    var todayCount: Int {
        store.count(on: today)
    }

    var logTodayTitle: String {
        if todayCount > 0 {
            return "Today: \(drinkWord(todayCount)) · Edit"
        }
        return "Log Today"
    }

    var statusLine: String? {
        guard isCurrentMonth else { return nil }
        if let monthMax {
            let delta = monthMax - drinkTotal
            if delta >= 0 {
                return "\(delta) left this month"
            }
            return "\(-delta) over your monthly goal"
        }
        if let weekMax {
            let delta = weekMax - weekTotal
            if delta >= 0 {
                return "\(delta) left this week"
            }
            return "\(-delta) over your weekly goal"
        }
        return nil
    }

    var statusIsWarning: Bool {
        guard isCurrentMonth else { return false }
        if let monthMax {
            return CalendarMath.isWarning(total: drinkTotal, max: monthMax)
        }
        return CalendarMath.isWarning(total: weekTotal, max: weekMax)
    }

    func accessibilityLabel(for day: MonthDay) -> String {
        guard let date = day.date else { return "" }
        let formatted = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        if day.isFuture {
            return "\(formatted), unavailable"
        }
        if day.isLogged {
            return "\(formatted), \(drinkWord(day.count))"
        }
        if day.isToday {
            return "\(formatted), today, not logged"
        }
        return "\(formatted), not logged"
    }

    private func drinkWord(_ count: Int) -> String {
        count == 1 ? "1 drink" : "\(count) drinks"
    }
}
