import Foundation

@MainActor
struct ProgressViewModel {
    let store: DrinkStore
    let today: Date

    var weekTotal: Int { store.weekTotal(containing: today) }
    var monthTotal: Int { store.monthTotal(containing: today) }
    var weekGoal: GoalRecord? { store.goal(for: .week) }
    var monthGoal: GoalRecord? { store.goal(for: .month) }
    var weeks: [WeekBucket] { store.recentWeeks(endingAt: today) }
    var currentStreak: Int { store.currentStreak(today: today) }
    var longestStreak: Int { store.longestStreak(today: today) }
    var alcoholFreeDays: Int { store.alcoholFreeDays(inMonth: today, today: today) }

    func goalRowTitle(_ goal: GoalRecord) -> String {
        switch goal.period {
        case .week:
            return "Max \(goal.maxDrinks) drinks per week"
        case .month:
            return "Max \(goal.maxDrinks) drinks per month"
        }
    }

    func weekCaption(for bucket: WeekBucket) -> String {
        let day = bucket.start.formatted(.dateTime.month(.abbreviated).day())
        let drinks = bucket.total == 1 ? "1 drink" : "\(bucket.total) drinks"
        return "Week of \(day) · \(drinks)"
    }
}
