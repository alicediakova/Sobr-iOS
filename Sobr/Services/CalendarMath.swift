import Foundation

enum CalendarMath {
    static func calendar(weekStartsOn: Int) -> Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = weekStartsOn == 0 ? 1 : 2
        return calendar
    }

    static func startOfMonth(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    static func startOfWeek(containing date: Date, weekStartsOn: Int) -> Date {
        let calendar = calendar(weekStartsOn: weekStartsOn)
        let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: parts) ?? calendar.startOfDay(for: date)
    }

    static func addingDays(_ days: Int, to date: Date, weekStartsOn: Int = 1) -> Date {
        calendar(weekStartsOn: weekStartsOn).date(byAdding: .day, value: days, to: date) ?? date
    }

    static func weekRange(containing date: Date, weekStartsOn: Int) -> DateRangeKeys {
        let start = startOfWeek(containing: date, weekStartsOn: weekStartsOn)
        let end = addingDays(6, to: start, weekStartsOn: weekStartsOn)
        return DateRangeKeys(startKey: DateKey.string(from: start), endKey: DateKey.string(from: end))
    }

    static func monthRange(containing date: Date, calendar: Calendar = .current) -> DateRangeKeys {
        let start = startOfMonth(for: date, calendar: calendar)
        let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let end = calendar.date(byAdding: .day, value: dayCount - 1, to: start) ?? start
        return DateRangeKeys(startKey: DateKey.string(from: start, calendar: calendar), endKey: DateKey.string(from: end, calendar: calendar))
    }

    static func weekdayHeaders(weekStartsOn: Int) -> [String] {
        let sundayFirst = ["S", "M", "T", "W", "T", "F", "S"]
        let offset = weekStartsOn == 0 ? 0 : 1
        return (0..<7).map { sundayFirst[($0 + offset) % 7] }
    }

    static func monthCells(containing date: Date, weekStartsOn: Int) -> [Date?] {
        let calendar = calendar(weekStartsOn: weekStartsOn)
        let start = startOfMonth(for: date, calendar: calendar)
        let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let weekday = calendar.component(.weekday, from: start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: start))
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }

    static func dayDiff(from start: String, to end: String, calendar: Calendar = .current) -> Int {
        guard let startDate = DateKey.date(from: start, calendar: calendar),
              let endDate = DateKey.date(from: end, calendar: calendar) else {
            return 0
        }
        return calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    static func currentStreak(today: String, entryDates: [String], firstOpenDate: String) -> Int {
        if entryDates.contains(today) {
            return 0
        }
        if let last = entryDates.filter({ $0 < today }).max() {
            return max(0, dayDiff(from: last, to: today) - 1)
        }
        let anchor = min(firstOpenDate, today)
        return max(0, dayDiff(from: anchor, to: today))
    }

    static func longestStreak(today: String, entryDates: [String], firstOpenDate: String) -> Int {
        let drinks = entryDates.filter { $0 <= today }.sorted()
        let anchor = min(firstOpenDate, today)
        if drinks.isEmpty {
            return max(0, dayDiff(from: anchor, to: today))
        }

        var best = 0
        if anchor < drinks[0] {
            best = max(best, dayDiff(from: anchor, to: drinks[0]))
        }
        if drinks.count >= 2 {
            for index in 0..<(drinks.count - 1) {
                best = max(best, dayDiff(from: drinks[index], to: drinks[index + 1]) - 1)
            }
        }
        if let last = drinks.last, last < today {
            best = max(best, dayDiff(from: last, to: today) - 1)
        }
        return max(0, best)
    }

    static func alcoholFreeDays(monthContaining date: Date, today: Date, entryDates: [String]) -> Int {
        let todayKey = DateKey.string(from: today)
        let range = monthRange(containing: date)
        let last = min(todayKey, range.endKey)
        guard last >= range.startKey else { return 0 }
        let elapsed = dayDiff(from: range.startKey, to: last) + 1
        let drinking = entryDates.filter { $0 >= range.startKey && $0 <= last }.count
        return max(0, elapsed - drinking)
    }

    static func sum(counts: [(date: String, count: Int)], in range: DateRangeKeys, excluding excluded: String? = nil) -> Int {
        counts.reduce(0) { partial, entry in
            guard range.contains(entry.date), entry.date != excluded else { return partial }
            return partial + entry.count
        }
    }

    static func previewTotal(savedPeriodTotal: Int, savedOnDay: Int, draft: Int) -> Int {
        savedPeriodTotal - savedOnDay + draft
    }

    static func isWarning(total: Int, max: Int?) -> Bool {
        guard let max, max > 0 else { return false }
        return total * 5 >= max * 4
    }

    static func progressFraction(total: Int, max: Int?) -> Double {
        guard let max, max > 0 else { return 0 }
        return min(1, Double(total) / Double(max))
    }

    static func clampedCount(_ count: Int) -> Int {
        min(30, max(0, count))
    }

    static func logMessage(draft: Int, weekTotal: Int, weekMax: Int?, monthTotal: Int, monthMax: Int?) -> String {
        if draft == 0 {
            return "Saving 0 clears this day."
        }

        var overLines: [String] = []
        if let weekMax, weekTotal > weekMax {
            overLines.append("This puts you \(weekTotal - weekMax) over your weekly goal.")
        }
        if let monthMax, monthTotal > monthMax {
            overLines.append("This puts you \(monthTotal - monthMax) over your monthly goal.")
        }
        if !overLines.isEmpty {
            return overLines.joined(separator: " ")
        }
        if let weekMax {
            return "\(weekMax - weekTotal) left this week after this."
        }
        if let monthMax {
            return "\(monthMax - monthTotal) left this month after this."
        }
        return ""
    }

    static func isCurrentMonth(_ date: Date, today: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, equalTo: today, toGranularity: .month)
    }
}
