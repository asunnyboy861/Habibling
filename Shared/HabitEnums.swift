import Foundation

public enum HabitType: String, Codable, CaseIterable, Sendable {
    case binary
    case counter
    case timer
    case negative

    public var displayName: String {
        switch self {
        case .binary: return "Yes or No"
        case .counter: return "Counter"
        case .timer: return "Timer"
        case .negative: return "Limit"
        }
    }
}

public enum HabitScheduleType: String, Codable, CaseIterable, Sendable {
    case daily
    case weekdays
    case everyNDays
    case daysPerWeek

    public var displayName: String {
        switch self {
        case .daily: return "Every day"
        case .weekdays: return "Specific weekdays"
        case .everyNDays: return "Every N days"
        case .daysPerWeek: return "N times a week"
        }
    }
}

public struct HabitSchedule: Codable, Equatable, Sendable {
    public var type: HabitScheduleType
    public var payload: String

    public init(type: HabitScheduleType, payload: String = "") {
        self.type = type
        self.payload = payload
    }

    public static let daily = HabitSchedule(type: .daily)

    public var weekdays: Set<Int> {
        Set(payload.split(separator: ",").compactMap { Int($0) })
    }

    public var n: Int {
        Int(payload) ?? 1
    }

    public func isDue(on date: Date, createdAt: Date, calendar: Calendar) -> Bool {
        switch type {
        case .daily, .daysPerWeek:
            return true
        case .weekdays:
            return weekdays.contains(calendar.component(.weekday, from: date))
        case .everyNDays:
            let start = calendar.startOfDay(for: createdAt)
            let day = calendar.startOfDay(for: date)
            guard let diff = calendar.dateComponents([.day], from: start, to: day).day else { return true }
            return diff >= 0 && diff % max(n, 1) == 0
        }
    }

    public var summary: String {
        switch type {
        case .daily: return "Every day"
        case .weekdays:
            let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let names = weekdays.sorted().map { $0 >= 1 && $0 <= 7 ? symbols[$0 - 1] : "" }
            return names.isEmpty ? "Weekdays" : names.joined(separator: " ")
        case .everyNDays: return "Every \(max(n, 1)) days"
        case .daysPerWeek: return "\(max(n, 1))× per week"
        }
    }
}

public enum CheckInSource: String, Codable, Sendable {
    case manual
    case notification
    case siri
    case widget
    case watch
    case ai
}
