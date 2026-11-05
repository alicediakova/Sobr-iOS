import Foundation
import Observation
import UIKit
import UserNotifications

enum LoggedTodayFlag {
    static let key = "sobr.todayLoggedKey"
}

enum NotificationAuthorization: Equatable {
    case notDetermined
    case denied
    case authorized
}

@Observable
final class AppRouter {
    static let shared = AppRouter()
    var openTodayLog = false
}

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let identifierPrefix = "sobr.reminder."

    func authorizationStatus() async -> NotificationAuthorization {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func reschedule(enabled: Bool, time: String, skipToday: Bool) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let existing = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: existing)

        guard enabled else { return }
        let status = await authorizationStatus()
        guard status == .authorized else { return }

        let pieces = time.split(separator: ":")
        let hour = Int(pieces.first ?? "21") ?? 21
        let minute = pieces.count > 1 ? (Int(pieces[1]) ?? 0) : 0
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())

        for offset in 0..<30 {
            if offset == 0 && skipToday { continue }
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = hour
            components.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = "Log today"
            content.body = "How many drinks today? It takes two taps."
            content.sound = .default
            content.userInfo = ["action": "logToday"]
            let identifier = identifierPrefix + DateKey.string(from: day, calendar: calendar)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let today = DateKey.string(from: Date())
        if UserDefaults.standard.string(forKey: LoggedTodayFlag.key) == today {
            completionHandler([])
            return
        }
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let action = response.notification.request.content.userInfo["action"] as? String
        if action == "logToday" {
            Task { @MainActor in
                AppRouter.shared.openTodayLog = true
            }
        }
        completionHandler()
    }
}
