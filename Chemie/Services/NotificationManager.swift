import Foundation
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter` for the three kinds of local alerts
/// Chemie schedules: treatment step reminders, low-stock inventory alerts, and an
/// optional recurring "time to test your pool" nudge.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    static let recurringTestReminderID = "com.thegoodkitchen.chemie.recurring-test-reminder"

    private let center = UNUserNotificationCenter.current()

    private init() {}

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    var isAuthorized: Bool {
        get async {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral
        }
    }

    /// Schedules a one-off local notification for a specific treatment step, returning
    /// the identifier so it can be tracked and cancelled if the step is undone.
    @discardableResult
    func scheduleStepReminder(title: String, body: String, fireDate: Date) async -> String? {
        guard await requestAuthorizationIfNeeded(), fireDate > .now else { return nil }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = max(fireDate.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            return identifier
        } catch {
            return nil
        }
    }

    @discardableResult
    func scheduleLowStockAlert(productName: String, quantityDescription: String) async -> String? {
        guard await requestAuthorizationIfNeeded() else { return nil }

        let content = UNMutableNotificationContent()
        content.title = "Running Low: \(productName)"
        content.body = "You're down to \(quantityDescription). Consider restocking soon."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let identifier = "low-stock-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            return identifier
        } catch {
            return nil
        }
    }

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelNotifications(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Schedules (or replaces) a recurring reminder to test the pool every `intervalDays` days.
    func scheduleRecurringTestReminder(intervalDays: Int) async {
        cancelRecurringTestReminder()
        guard intervalDays > 0, await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to Test Your Pool"
        content.body = "It's been \(intervalDays) day\(intervalDays == 1 ? "" : "s") since your reminder was set — log a new water test in Chemie."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(intervalDays * 86_400),
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: Self.recurringTestReminderID,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancelRecurringTestReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.recurringTestReminderID])
    }
}
