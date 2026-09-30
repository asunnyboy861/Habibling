import Foundation
import WidgetKit

public enum IntentCheckIn {
    @discardableResult
    public static func execute(habitID: UUID, source: String = CheckInSource.widget.rawValue) -> Bool {
        guard var snapshot = HabiblingSnapshot.load(),
              let index = snapshot.tiles.firstIndex(where: { $0.id == habitID }) else { return false }
        let tile = snapshot.tiles[index]
        let value: Double
        switch tile.type {
        case HabitType.negative.rawValue: value = 0
        case HabitType.counter.rawValue, HabitType.timer.rawValue: value = max(tile.targetValue, 1)
        default: value = 1
        }
        PendingCheckInQueue.append(PendingCheckIn(habitID: habitID, dayBucket: .now, value: value, source: source))
        snapshot.tiles[index].done = true
        snapshot.tiles[index].progress = 1
        snapshot.doneCount = min(snapshot.totalCount, snapshot.doneCount + 1)
        snapshot.generatedAt = .now
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }
}

#if canImport(ActivityKit) && !os(watchOS)
import ActivityKit

public struct DailyGoalActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var doneCount: Int
        public var totalCount: Int
        public var vibePercent: Int
        public var petName: String

        public init(doneCount: Int, totalCount: Int, vibePercent: Int, petName: String) {
            self.doneCount = doneCount
            self.totalCount = totalCount
            self.vibePercent = vibePercent
            self.petName = petName
        }
    }

    public var dayKey: String

    public init(dayKey: String) {
        self.dayKey = dayKey
    }
}
#endif
