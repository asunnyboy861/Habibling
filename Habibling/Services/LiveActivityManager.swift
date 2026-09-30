import Foundation
import WidgetKit

#if canImport(ActivityKit)
import ActivityKit

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentID: String?

    static var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func startIfNeeded(snapshot: HabiblingSnapshot) {
        guard Self.isEnabled else { return }
        let dayKey = Self.dayKey(for: .now)
        let attributes = DailyGoalActivityAttributes(dayKey: dayKey)
        if currentID == nil {
            currentID = Activity<DailyGoalActivityAttributes>.activities.first?.id
        }
        if let id = currentID, let activity = Activity<DailyGoalActivityAttributes>.activities.first(where: { $0.id == id }) {
            if activity.attributes.dayKey != dayKey {
                Task { await activity.end(activity.content, dismissalPolicy: .immediate) }
                currentID = nil
                startFresh(attributes: attributes, snapshot: snapshot)
            } else {
                Task {
                    let state = Self.state(from: snapshot)
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                }
            }
            return
        }
        if let existing = Activity<DailyGoalActivityAttributes>.activities.first {
            currentID = existing.id
            Task {
                await existing.update(ActivityContent(state: Self.state(from: snapshot), staleDate: nil))
            }
            return
        }
        startFresh(attributes: attributes, snapshot: snapshot)
    }

    private func startFresh(attributes: DailyGoalActivityAttributes, snapshot: HabiblingSnapshot) {
        guard Activity<DailyGoalActivityAttributes>.activities.isEmpty else { return }
        let state = Self.state(from: snapshot)
        Task {
            do {
                let activity = try Activity<DailyGoalActivityAttributes>.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil)
                )
                self.currentID = activity.id
            } catch {
                currentID = nil
            }
        }
    }

    func syncCurrentActivity() {
        guard let snapshot = HabiblingSnapshot.load() else { return }
        startIfNeeded(snapshot: snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func endAll() {
        Task {
            for activity in Activity<DailyGoalActivityAttributes>.activities {
                await activity.end(activity.content, dismissalPolicy: .immediate)
            }
            currentID = nil
        }
    }

    private static func state(from snapshot: HabiblingSnapshot) -> DailyGoalActivityAttributes.ContentState {
        DailyGoalActivityAttributes.ContentState(
            doneCount: snapshot.doneCount,
            totalCount: snapshot.totalCount,
            vibePercent: snapshot.pet.vibePercent,
            petName: snapshot.pet.name
        )
    }

    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
#endif
