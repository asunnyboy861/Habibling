import Foundation
import UserNotifications

enum ReminderCopy {
    static let pool = [
        "One pixel for \"%@\" — your pet is waiting.",
        "Tiny step: %@. It takes a moment.",
        "A quick tap on %@ keeps your story going.",
        "%@ is on today's board. Ready when you are.",
        "Your pet wonders about %@ today.",
        "Keep the pixel streak cozy — %@.",
        "One tap, one pixel, one happy pet: %@.",
        "No pressure, just a nudge: %@.",
        "Today's pixel for %@ is still dim.",
        "%@ — small effort, real momentum."
    ]

    static func random(habitName: String) -> String {
        String(format: pool.randomElement() ?? pool[0], habitName)
    }
}

final class ReminderScheduler {
    static let categoryIdentifier = "HABIBLING_REMINDER"
    static let snoozeInterval: TimeInterval = 3600

    static func registerCategories() {
        let done = UNNotificationAction(identifier: "DONE_ACTION", title: "Done ✓", options: [.authenticationRequired])
        let snooze = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Snooze 1h", options: [])
        let category = UNNotificationCategory(identifier: categoryIdentifier, actions: [done, snooze], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func schedule(habit: Habit) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: pendingIDs(for: habit))
        guard habit.reminderEnabled else { return }
        let dueDates = (0..<28).compactMap { offset -> Date? in
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: .now) else { return nil }
            return habit.schedule.isDue(on: day, createdAt: habit.createdAt, calendar: .current) ? day : nil
        }
        for day in dueDates {
            guard var components = Calendar.current.dateComponents([.year, .month, .day], from: day) as DateComponents? else { continue }
            components.hour = habit.reminderHour
            components.minute = habit.reminderMinute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = habit.name
            content.body = ReminderCopy.random(habitName: habit.name)
            content.sound = .default
            content.categoryIdentifier = categoryIdentifier
            content.userInfo = ["habitID": habit.persistentID.uuidString]
            let identifier = "\(habit.persistentID.uuidString)-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    static func scheduleAll(_ habits: [Habit]) {
        for habit in habits where habit.archivedAt == nil {
            schedule(habit: habit)
        }
    }

    static func snooze(userInfo: [AnyHashable: Any]) {
        guard let idString = userInfo["habitID"] as? String,
              let habitID = UUID(uuidString: idString) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Gentle reminder"
        content.body = "One pixel when you're ready."
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = ["habitID": habitID.uuidString]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "snooze-\(habitID.uuidString)-\(Int(Date().timeIntervalSince1970))", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func pendingIDs(for habit: Habit) -> [String] {
        UNUserNotificationCenter.current().getPendingNotificationRequests { _ in }
        return (0..<28).compactMap { offset in
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: .now) else { return nil }
            let c = Calendar.current.dateComponents([.year, .month, .day], from: day)
            return "\(habit.persistentID.uuidString)-\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
        }
    }
}
