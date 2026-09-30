import BackgroundTasks
import Foundation
import SwiftData

@MainActor
enum BGTaskService {
    static let identifier = "com.zzoutuo.Habibling.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            handleRefresh(task: task as! BGAppRefreshTask)
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleRefresh(task: BGAppRefreshTask) {
        schedule()
        let work = Task { @MainActor in
            CheckInService().drainPendingQueue()
            LiveActivityManager.shared.syncCurrentActivity()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
        }
    }
}
