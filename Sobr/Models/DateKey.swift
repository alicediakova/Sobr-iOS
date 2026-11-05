import Foundation

enum DateKey {
    static func string(from date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let pieces = key.split(separator: "-")
        guard pieces.count == 3,
              let year = Int(pieces[0]),
              let month = Int(pieces[1]),
              let day = Int(pieces[2]) else {
            return nil
        }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func timeString(from date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 21, parts.minute ?? 0)
    }

    static func date(fromTime hhmm: String, calendar: Calendar = .current) -> Date {
        let pieces = hhmm.split(separator: ":")
        var parts = calendar.dateComponents([.year, .month, .day], from: Date())
        parts.hour = Int(pieces.first ?? "21") ?? 21
        parts.minute = pieces.count > 1 ? (Int(pieces[1]) ?? 0) : 0
        return calendar.date(from: parts) ?? Date()
    }
}
