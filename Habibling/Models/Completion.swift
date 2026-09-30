import Foundation
import SwiftData

@Model
final class Completion {
    var habitPersistentID: UUID = UUID()
    var dayBucket: Date = Date.now
    var value: Double = 1
    var note: String = ""
    var sourceRaw: String = CheckInSource.manual.rawValue
    var updatedAt: Date = Date.now
    var habit: Habit?

    var source: CheckInSource {
        get { CheckInSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(habitPersistentID: UUID, dayBucket: Date, value: Double, source: CheckInSource = .manual, note: String = "") {
        self.habitPersistentID = habitPersistentID
        self.dayBucket = dayBucket
        self.value = value
        self.sourceRaw = source.rawValue
        self.note = note
        self.updatedAt = .now
    }
}

@Model
final class MoodEntry {
    var dayBucket: Date = Date.now
    var level: Int = 3
    var note: String = ""
    var updatedAt: Date = Date.now

    init(dayBucket: Date, level: Int, note: String = "") {
        self.dayBucket = dayBucket
        self.level = level
        self.note = note
        self.updatedAt = .now
    }
}

@Model
final class WeeklyPost {
    var weekStart: Date = Date.now
    var content: String = ""
    var engine: String = "rules"
    var createdAt: Date = Date.now

    init(weekStart: Date, content: String, engine: String) {
        self.weekStart = weekStart
        self.content = content
        self.engine = engine
        self.createdAt = .now
    }
}

@Model
final class MonthlyReport {
    var monthKey: String = ""
    var content: String = ""
    var createdAt: Date = Date.now

    init(monthKey: String, content: String) {
        self.monthKey = monthKey
        self.content = content
        self.createdAt = .now
    }
}
