import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var singletonID: Int
    var firstOpenDate: String
    var onboardingComplete: Bool
    var reminderEnabled: Bool
    var reminderTime: String
    var weekStartsOn: Int
    var hasLock: Bool

    init(
        singletonID: Int,
        firstOpenDate: String,
        onboardingComplete: Bool,
        reminderEnabled: Bool,
        reminderTime: String,
        weekStartsOn: Int,
        hasLock: Bool
    ) {
        self.singletonID = singletonID
        self.firstOpenDate = firstOpenDate
        self.onboardingComplete = onboardingComplete
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.weekStartsOn = weekStartsOn
        self.hasLock = hasLock
    }

    static func makeNew(today: Date = Date()) -> AppSettings {
        AppSettings(
            singletonID: 1,
            firstOpenDate: DateKey.string(from: today),
            onboardingComplete: false,
            reminderEnabled: false,
            reminderTime: "21:00",
            weekStartsOn: 1,
            hasLock: false
        )
    }

    var snapshot: SettingsSnapshot {
        SettingsSnapshot(
            firstOpenDate: firstOpenDate,
            onboardingComplete: onboardingComplete,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            weekStartsOn: weekStartsOn,
            hasLock: hasLock
        )
    }
}
