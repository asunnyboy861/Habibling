import Foundation

enum DayBucket {
    static let dayStartKey = "dayStartHour"

    static var dayStartHour: Int {
        get {
            let defaults = UserDefaults(suiteName: HabiblingSnapshot.appGroupId) ?? .standard
            return defaults.integer(forKey: dayStartKey)
        }
        set {
            let defaults = UserDefaults(suiteName: HabiblingSnapshot.appGroupId) ?? .standard
            defaults.set(newValue, forKey: dayStartKey)
        }
    }

    static func startOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        let shifted = calendar.date(byAdding: .hour, value: -dayStartHour, to: date) ?? date
        let day = calendar.startOfDay(for: shifted)
        return calendar.date(byAdding: .hour, value: dayStartHour, to: day) ?? day
    }

    static func day(after date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: 1, to: startOfDay(for: date, calendar: calendar)) ?? date
    }

    static func days(from start: Date, to end: Date, calendar: Calendar = .current) -> [Date] {
        var result: [Date] = []
        var current = startOfDay(for: start, calendar: calendar)
        let last = startOfDay(for: end, calendar: calendar)
        while current <= last {
            result.append(current)
            current = day(after: current, calendar: calendar)
        }
        return result
    }
}
