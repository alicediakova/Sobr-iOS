import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let store: DrinkStore
    var authorization: NotificationAuthorization = .notDetermined

    init(store: DrinkStore) {
        self.store = store
    }

    var reminderTime: Date {
        DateKey.date(fromTime: store.settings.reminderTime)
    }

    var showDeniedNote: Bool {
        authorization == .denied
    }

    func refresh() async {
        authorization = await NotificationService.shared.authorizationStatus()
        if store.settings.reminderEnabled {
            await store.rescheduleNotifications()
        }
    }

    func setReminderEnabled(_ enabled: Bool) async {
        if !enabled {
            store.setReminderEnabled(false)
            await store.rescheduleNotifications()
            return
        }

        let status = await NotificationService.shared.authorizationStatus()
        authorization = status
        switch status {
        case .notDetermined:
            let granted = await NotificationService.shared.requestAuthorization()
            authorization = await NotificationService.shared.authorizationStatus()
            guard granted else {
                store.setReminderEnabled(false)
                return
            }
        case .denied:
            store.setReminderEnabled(false)
            return
        case .authorized:
            break
        }

        store.setReminderEnabled(true)
        await store.rescheduleNotifications()
    }

    func updateTime(_ date: Date) {
        store.updateReminderTime(date)
    }

    func openSettings() {
        NotificationService.shared.openSystemSettings()
    }
}
