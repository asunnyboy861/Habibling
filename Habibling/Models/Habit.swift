import Foundation
import SwiftData

@Model
final class Habit {
    var persistentID: UUID = UUID()
    var name: String = ""
    var iconSymbol: String = "checkmark.circle"
    var colorHex: String = "#F6968E"
    var typeRaw: String = HabitType.binary.rawValue
    var scheduleTypeRaw: String = HabitScheduleType.daily.rawValue
    var schedulePayload: String = ""
    var targetValue: Double = 1
    var unitLabel: String = ""
    var category: String = ""
    var reminderEnabled: Bool = false
    var reminderHour: Int = 9
    var reminderMinute: Int = 0
    var createdAt: Date = Date.now
    var archivedAt: Date?
    var sortOrder: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion]? = []

    var type: HabitType {
        get { HabitType(rawValue: typeRaw) ?? .binary }
        set { typeRaw = newValue.rawValue }
    }

    var schedule: HabitSchedule {
        get { HabitSchedule(type: HabitScheduleType(rawValue: scheduleTypeRaw) ?? .daily, payload: schedulePayload) }
        set { scheduleTypeRaw = newValue.type.rawValue; schedulePayload = newValue.payload }
    }

    init(name: String, iconSymbol: String = "checkmark.circle", colorHex: String = "#F6968E",
         type: HabitType = .binary, schedule: HabitSchedule = .daily, targetValue: Double = 1,
         unitLabel: String = "", category: String = "") {
        self.persistentID = UUID()
        self.name = name
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.typeRaw = type.rawValue
        self.scheduleTypeRaw = schedule.type.rawValue
        self.schedulePayload = schedule.payload
        self.targetValue = targetValue
        self.unitLabel = unitLabel
        self.category = category
        self.createdAt = .now
        self.sortOrder = 0
    }
}
