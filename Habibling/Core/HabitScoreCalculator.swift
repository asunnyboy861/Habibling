import Foundation

struct HabitScoreCalculator {
    static let alpha = 0.05

    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func scoreHistory(for habit: Habit,
                      completions: [Completion],
                      from start: Date,
                      to end: Date) -> [DailyScore] {
        var score = 0.0
        var result: [DailyScore] = []
        let target = max(habit.targetValue, 0.0001)
        let byDay = Dictionary(completions.map { (DayBucket.startOfDay(for: $0.dayBucket, calendar: calendar), $0) },
                               uniquingKeysWith: { $0.updatedAt >= $1.updatedAt ? $0 : $1 })
        var day = DayBucket.startOfDay(for: max(start, habit.createdAt), calendar: calendar)
        let last = DayBucket.startOfDay(for: end, calendar: calendar)

        while day <= last {
            defer { day = DayBucket.day(after: day, calendar: calendar) }
            guard habit.schedule.isDue(on: day, createdAt: habit.createdAt, calendar: calendar) else { continue }
            var value = 0.0
            if let completion = byDay[day] {
                if habit.type == .negative {
                    value = completion.value <= target ? 1 : 0
                } else {
                    value = min(1.0, completion.value / target)
                }
            }
            score = (1 - Self.alpha) * score + Self.alpha * value
            result.append(DailyScore(date: day, score: score))
        }
        return result
    }

    func currentVibe(for habit: Habit, completions: [Completion], today: Date = .now) -> Double {
        scoreHistory(for: habit, completions: completions, from: habit.createdAt, to: today).last?.score ?? 0
    }

    func overallDailyScores(habits: [Habit], completionsByHabit: [UUID: [Completion]], from: Date, to: Date) -> [DailyScore] {
        var perDay: [Date: [Double]] = [:]
        for habit in habits {
            guard habit.archivedAt == nil else { continue }
            for score in scoreHistory(for: habit, completions: completionsByHabit[habit.persistentID] ?? [], from: from, to: to) {
                perDay[score.date, default: []].append(score.score)
            }
        }
        return perDay.keys.sorted().map { day in
            let values = perDay[day] ?? []
            return DailyScore(date: day, score: values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count))
        }
    }
}

struct StreakCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    struct StreakInfo: Equatable {
        let current: Int
        let best: Int
        let total: Int
    }

    func streak(for habit: Habit, completions: [Completion], today: Date = .now) -> StreakInfo {
        let target = max(habit.targetValue, 0.0001)
        let doneDays = Set(completions.filter { c in
            habit.type == .negative ? c.value <= target : c.value >= target
        }.map { DayBucket.startOfDay(for: $0.dayBucket, calendar: calendar) })
        let allDays = DayBucket.days(from: habit.createdAt, to: today, calendar: calendar)
            .filter { habit.schedule.isDue(on: $0, createdAt: habit.createdAt, calendar: calendar) }

        var best = 0
        var run = 0
        for day in allDays {
            if doneDays.contains(day) {
                run += 1
                best = max(best, run)
            } else if day < DayBucket.startOfDay(for: today, calendar: calendar) {
                run = 0
            }
        }
        var current = 0
        for day in allDays.reversed() {
            if doneDays.contains(day) {
                current += 1
            } else if day >= DayBucket.startOfDay(for: today, calendar: calendar) {
                continue
            } else {
                break
            }
        }
        return StreakInfo(current: current, best: max(best, current), total: doneDays.count)
    }
}
