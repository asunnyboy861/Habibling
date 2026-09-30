import Foundation

public struct DailyScore: Equatable, Codable, Sendable {
    public let date: Date
    public let score: Double

    public init(date: Date, score: Double) {
        self.date = date
        self.score = score
    }
}

public enum PetStage: Int, Codable, CaseIterable, Sendable {
    case egg = 0
    case hatchling = 1
    case juvenile = 2
    case adult = 3

    public var displayName: String {
        switch self {
        case .egg: "Egg"
        case .hatchling: "Hatchling"
        case .juvenile: "Juvenile"
        case .adult: "Adult"
        }
    }
}

public enum PetMood: String, Codable, CaseIterable, Sendable {
    case joyful
    case content
    case sleepy
}

public enum PetSeason: String, Codable, CaseIterable, Sendable {
    case spring
    case summer
    case fall
    case winter
    case holiday

    public static func current(from date: Date, calendar: Calendar = .current) -> PetSeason {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        if month == 12 && day >= 15 { return .holiday }
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }

    public var accentHex: String {
        switch self {
        case .spring: "#8FD694"
        case .summer: "#4FB8D9"
        case .fall: "#E0965A"
        case .winter: "#9AB6E0"
        case .holiday: "#E05A6B"
        }
    }
}

public struct PetState: Equatable, Codable, Sendable {
    public let stage: PetStage
    public let mood: PetMood
    public let season: PetSeason
    public let progression: Double
    public let daysKept: Int

    public init(stage: PetStage, mood: PetMood, season: PetSeason, progression: Double, daysKept: Int) {
        self.stage = stage
        self.mood = mood
        self.season = season
        self.progression = progression
        self.daysKept = daysKept
    }
}

public enum PetDeriver {
    public static func stage(forDaysKept days: Int) -> PetStage {
        switch days {
        case ..<3: return .egg
        case 3..<14: return .hatchling
        case 14..<30: return .juvenile
        default: return .adult
        }
    }

    public static func mood(forRecentAverage average: Double) -> PetMood {
        if average >= 0.6 { return .joyful }
        if average >= 0.25 { return .content }
        return .sleepy
    }

    public static func derive(dailyScores: [DailyScore],
                              petCreatedAt: Date,
                              now: Date = .now,
                              calendar: Calendar = .current) -> PetState {
        let daysKept = dailyScores.filter { $0.score >= 0.5 }.count
        let recentWindow = dailyScores.suffix(7)
        let recentAverage = recentWindow.isEmpty ? 0 : recentWindow.map(\.score).reduce(0, +) / Double(recentWindow.count)
        return PetState(
            stage: stage(forDaysKept: daysKept),
            mood: mood(forRecentAverage: recentAverage),
            season: .current(from: now, calendar: calendar),
            progression: min(1.0, Double(daysKept) / 30.0),
            daysKept: daysKept
        )
    }
}
