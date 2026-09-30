import BackgroundTasks
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        ReminderScheduler.registerCategories()
        BGTaskService.register()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        if response.actionIdentifier == "DONE_ACTION" {
            await markDone(userInfo: userInfo)
        } else if response.actionIdentifier == "SNOOZE_ACTION" {
            ReminderScheduler.snooze(userInfo: userInfo)
        }
    }

    @MainActor
    private func markDone(userInfo: [AnyHashable: Any]) async {
        guard let idString = userInfo["habitID"] as? String,
              let habitID = UUID(uuidString: idString) else { return }
        let service = CheckInService()
        guard let habit = service.allHabits().first(where: { $0.persistentID == habitID }) else { return }
        service.complete(habit: habit, source: .notification)
        SoundPlayer.shared.playChirp()
        Haptics.success()
    }
}

@main
struct HabiblingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var settings = AppSettings.shared
    @StateObject private var checkIns = CheckInService()
    @StateObject private var purchases = PurchaseManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(checkIns)
                .environmentObject(purchases)
                .modelContainer(PersistenceController.shared.container)
                .tint(AppTheme.accent)
        }
    }
}
