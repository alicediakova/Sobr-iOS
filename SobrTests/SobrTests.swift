import XCTest
@testable import Sobr

final class SobrTests: XCTestCase {
    func testDateKeyRoundTrip() {
        let date = DateKey.date(from: "2026-11-04")
        XCTAssertNotNil(date)
        XCTAssertEqual(DateKey.string(from: date!), "2026-11-04")
    }

    func testNovember2026MondayStartPutsTheFirstOnSunday() {
        let november = DateKey.date(from: "2026-11-01")!
        let cells = CalendarMath.monthCells(containing: november, weekStartsOn: 1)
        XCTAssertEqual(cells.count % 7, 0)
        XCTAssertNil(cells[0])
        XCTAssertEqual(DateKey.string(from: cells[6]!), "2026-11-01")
        XCTAssertEqual(CalendarMath.weekdayHeaders(weekStartsOn: 1), ["M", "T", "W", "T", "F", "S", "S"])
    }

    func testWeekRangeFollowsWeekStart() {
        let wednesday = DateKey.date(from: "2026-11-04")!
        let monday = CalendarMath.weekRange(containing: wednesday, weekStartsOn: 1)
        XCTAssertEqual(monday.startKey, "2026-11-02")
        XCTAssertEqual(monday.endKey, "2026-11-08")

        let sunday = CalendarMath.weekRange(containing: wednesday, weekStartsOn: 0)
        XCTAssertEqual(sunday.startKey, "2026-11-01")
        XCTAssertEqual(sunday.endKey, "2026-11-07")
    }

    func testStreakSkipsTheDrinkDayAndToday() {
        let streak = CalendarMath.currentStreak(
            today: "2026-11-04",
            entryDates: ["2026-11-01"],
            firstOpenDate: "2026-10-01"
        )
        XCTAssertEqual(streak, 2)
    }

    func testStreakIsZeroWhenTodayIsLogged() {
        let streak = CalendarMath.currentStreak(
            today: "2026-11-04",
            entryDates: ["2026-11-01", "2026-11-04"],
            firstOpenDate: "2026-10-01"
        )
        XCTAssertEqual(streak, 0)
    }

    func testNewUserStreakCountsFromFirstOpen() {
        let streak = CalendarMath.currentStreak(
            today: "2026-11-04",
            entryDates: [],
            firstOpenDate: "2026-11-01"
        )
        XCTAssertEqual(streak, 3)
    }

    func testLongestStreakUsesTheWidestGap() {
        let longest = CalendarMath.longestStreak(
            today: "2026-11-20",
            entryDates: ["2026-11-05", "2026-11-10"],
            firstOpenDate: "2026-11-01"
        )
        XCTAssertEqual(longest, 9)
    }

    func testAlcoholFreeDaysIncludeTodayAndExcludeDrinks() {
        let free = CalendarMath.alcoholFreeDays(
            monthContaining: DateKey.date(from: "2026-11-04")!,
            today: DateKey.date(from: "2026-11-04")!,
            entryDates: ["2026-11-01"]
        )
        XCTAssertEqual(free, 3)
    }

    func testPreviewReplacesTheSavedDayWithTheDraft() {
        XCTAssertEqual(CalendarMath.previewTotal(savedPeriodTotal: 6, savedOnDay: 2, draft: 3), 7)
    }

    func testWarningStartsAtEightyPercentAndNeverUsesFailureMath() {
        XCTAssertFalse(CalendarMath.isWarning(total: 3, max: 5))
        XCTAssertTrue(CalendarMath.isWarning(total: 4, max: 5))
        XCTAssertTrue(CalendarMath.isWarning(total: 6, max: 5))
        XCTAssertEqual(CalendarMath.progressFraction(total: 10, max: 5), 1, accuracy: 0.001)
    }

    func testLogMessagesStayInformational() {
        XCTAssertEqual(
            CalendarMath.logMessage(draft: 0, weekTotal: 0, weekMax: 5, monthTotal: 0, monthMax: 20),
            "Saving 0 clears this day."
        )
        XCTAssertEqual(
            CalendarMath.logMessage(draft: 2, weekTotal: 6, weekMax: 5, monthTotal: 6, monthMax: 20),
            "This puts you 1 over your weekly goal."
        )
        XCTAssertEqual(
            CalendarMath.logMessage(draft: 1, weekTotal: 2, weekMax: 5, monthTotal: 2, monthMax: nil),
            "3 left this week after this."
        )
    }

    func testSavingZeroDeletesAndFutureDatesAreRejected() async {
        await MainActor.run {
            let store = DrinkStore(inMemory: true)
            let today = Date()
            store.saveCount(2, on: today)
            XCTAssertEqual(store.count(on: today), 2)
            store.saveCount(0, on: today)
            XCTAssertEqual(store.count(on: today), 0)
            XCTAssertTrue(store.entries.isEmpty)

            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            store.saveCount(4, on: tomorrow)
            XCTAssertEqual(store.count(on: tomorrow), 0)
        }
    }

    func testOnlyOneGoalExistsPerPeriodAndPreviewIncludesTheDraft() async {
        await MainActor.run {
            let store = DrinkStore(inMemory: true)
            store.saveGoal(period: .week, maxDrinks: 5)
            store.saveGoal(period: .week, maxDrinks: 9)
            store.saveGoal(period: .month, maxDrinks: 20)
            XCTAssertEqual(store.goals.count, 2)
            XCTAssertEqual(store.goal(for: .week)?.maxDrinks, 9)

            let today = Date()
            store.saveCount(2, on: today)
            let preview = store.previewTotal(draft: 5, on: today, scope: .week)
            XCTAssertEqual(preview, store.weekTotal(containing: today) - 2 + 5)
        }
    }

    func testChangingWeekStartRecalculatesTheWeek() async {
        await MainActor.run {
            let store = DrinkStore(inMemory: true)
            let today = Date()
            guard let past = Calendar.current.date(byAdding: .day, value: -6, to: today) else {
                return XCTFail("Missing date")
            }
            store.setWeekStartsOn(1)
            store.saveCount(2, on: today)
            store.saveCount(4, on: past)
            let mondayTotal = store.weekTotal(containing: today)
            store.setWeekStartsOn(0)
            let sundayTotal = store.weekTotal(containing: today)
            let mondayRange = CalendarMath.weekRange(containing: today, weekStartsOn: 1)
            let sundayRange = CalendarMath.weekRange(containing: today, weekStartsOn: 0)
            let pairs = store.entries.map { ($0.date, $0.count) }
            XCTAssertEqual(mondayTotal, CalendarMath.sum(counts: pairs, in: mondayRange))
            XCTAssertEqual(sundayTotal, CalendarMath.sum(counts: pairs, in: sundayRange))
        }
    }
}
