import Foundation

enum GoalPeriod: String, Codable, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    var defaultMax: Int {
        switch self {
        case .week: 5
        case .month: 20
        }
    }

    var range: ClosedRange<Int> {
        switch self {
        case .week: 1...50
        case .month: 1...200
        }
    }

    var stepperCaption: String {
        switch self {
        case .week: "drinks per week"
        case .month: "drinks per month"
        }
    }
}

struct DayRecord: Identifiable, Equatable {
    var date: String
    var count: Int
    var id: String { date }
}

struct GoalRecord: Equatable, Identifiable {
    var period: GoalPeriod
    var maxDrinks: Int
    var id: String { period.rawValue }
}

struct SettingsSnapshot: Equatable {
    var firstOpenDate: String
    var onboardingComplete: Bool
    var reminderEnabled: Bool
    var reminderTime: String
    var weekStartsOn: Int
    var hasLock: Bool
}

struct WeekBucket: Identifiable, Equatable {
    var start: Date
    var startKey: String
    var label: String
    var total: Int
    var id: String { startKey }
}

struct MonthDay: Identifiable, Equatable {
    var id: String
    var date: Date?
    var number: String
    var count: Int
    var isToday: Bool
    var isFuture: Bool

    var isLogged: Bool { count > 0 }
}

struct DateRangeKeys: Equatable {
    var startKey: String
    var endKey: String

    func contains(_ key: String) -> Bool {
        key >= startKey && key <= endKey
    }
}
