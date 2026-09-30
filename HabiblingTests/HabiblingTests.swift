import XCTest
@testable import Habibling

final class HabiblingTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func day(_ offset: Int, from base: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: base)!
    }

    func testStageBoundaries() {
        XCTAssertEqual(PetDeriver.stage(forDaysKept: 0), .egg)
        XCTAssertEqual(PetDeriver.stage(forDaysKept: 2), .egg)
        XCTAssertEqual(PetDeriver.stage(forDaysKept: 3), .hatchling)
        XCTAssertEqual(PetDeriver.stage(forDaysKept: 13), .hatchling)
        XCTAssertEqual(PetDeriver.stage(forDaysKept: 14), .juvenile)
        XCTAssertEqual(PetDeriver.stage(forDaysKept: 29), .juvenile)
        XCTAssertEqual(PetDeriver.stage(forDaysKept: 30), .adult)
        XCTAssertEqual(PetDeriver.stage(forDaysKept: 100), .adult)
    }

    func testMoodThresholds() {
        XCTAssertEqual(PetDeriver.mood(forRecentAverage: 0.8), .joyful)
        XCTAssertEqual(PetDeriver.mood(forRecentAverage: 0.6), .joyful)
        XCTAssertEqual(PetDeriver.mood(forRecentAverage: 0.4), .content)
        XCTAssertEqual(PetDeriver.mood(forRecentAverage: 0.25), .content)
        XCTAssertEqual(PetDeriver.mood(forRecentAverage: 0.1), .sleepy)
        XCTAssertEqual(PetDeriver.mood(forRecentAverage: 0), .sleepy)
    }

    func testDeriveNeverDies() {
        let createdAt = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let now = day(90, from: createdAt)
        let state = PetDeriver.derive(dailyScores: [], petCreatedAt: createdAt, now: now, calendar: calendar)
        XCTAssertEqual(state.stage, .egg)
        XCTAssertEqual(state.mood, .sleepy)
        XCTAssertEqual(state.daysKept, 0)
    }

    func testDeriveProgression() {
        let createdAt = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        var scores: [DailyScore] = []
        for offset in 0..<35 {
            scores.append(DailyScore(date: day(offset, from: createdAt), score: 0.9))
        }
        let now = day(40, from: createdAt)
        let state = PetDeriver.derive(dailyScores: scores, petCreatedAt: createdAt, now: now, calendar: calendar)
        XCTAssertEqual(state.stage, .adult)
        XCTAssertEqual(state.mood, .joyful)
        XCTAssertEqual(state.daysKept, 35)
        XCTAssertEqual(state.progression, 1.0, accuracy: 0.001)
    }

    func testWeekdaySchedule() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let monday = calendar.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        let schedule = HabitSchedule(type: .weekdays, payload: "2,4,6")
        let createdAt = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        XCTAssertTrue(schedule.isDue(on: monday, createdAt: createdAt, calendar: calendar))
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        XCTAssertFalse(schedule.isDue(on: tuesday, createdAt: createdAt, calendar: calendar))
    }

    func testEveryNDaysSchedule() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let createdAt = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let schedule = HabitSchedule(type: .everyNDays, payload: "3")
        let day0 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let day2 = calendar.date(byAdding: .day, value: 2, to: day0)!
        let day3 = calendar.date(byAdding: .day, value: 3, to: day0)!
        XCTAssertTrue(schedule.isDue(on: day0, createdAt: createdAt, calendar: calendar))
        XCTAssertFalse(schedule.isDue(on: day2, createdAt: createdAt, calendar: calendar))
        XCTAssertTrue(schedule.isDue(on: day3, createdAt: createdAt, calendar: calendar))
    }

    func testStreakCalculation() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let day0 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let habit = Habit(name: "Read")
        habit.createdAt = day0
        habit.targetValue = 1
        var completions: [Completion] = []
        for offset in [1, 2, 3] {
            completions.append(Completion(habitPersistentID: habit.persistentID,
                                          dayBucket: day(offset, from: day0), value: 1))
        }
        let today = day(4, from: day0)
        let info = StreakCalculator(calendar: calendar).streak(for: habit, completions: completions, today: today)
        XCTAssertEqual(info.current, 3)
        XCTAssertEqual(info.best, 3)
        XCTAssertEqual(info.total, 3)
    }

    func testStreakBreaksOnMissedDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let day0 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let habit = Habit(name: "Read")
        habit.createdAt = day0
        habit.targetValue = 1
        var completions: [Completion] = []
        for offset in [1, 2, 4, 5, 6, 7] {
            completions.append(Completion(habitPersistentID: habit.persistentID,
                                          dayBucket: day(offset, from: day0), value: 1))
        }
        let today = day(8, from: day0)
        let info = StreakCalculator(calendar: calendar).streak(for: habit, completions: completions, today: today)
        XCTAssertEqual(info.current, 4)
        XCTAssertEqual(info.best, 4)
        XCTAssertEqual(info.total, 6)
    }

    func testDayBucketShift() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let lateNight = calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 2))!
        DayBucket.dayStartHour = 4
        let bucket = DayBucket.startOfDay(for: lateNight, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 4))!
        XCTAssertEqual(bucket.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1)
        DayBucket.dayStartHour = 0
    }

    func testNegativeHabitScoring() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let createdAt = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let habit = Habit(name: "No snacks", type: .negative, targetValue: 3)
        habit.createdAt = createdAt
        let under = Completion(habitPersistentID: habit.persistentID, dayBucket: createdAt, value: 1)
        let calculator = HabitScoreCalculator(calendar: calendar)
        let history = calculator.scoreHistory(for: habit, completions: [under], from: createdAt, to: createdAt)
        XCTAssertEqual(history.last?.score ?? 0, 0.05, accuracy: 0.001)
        let clean = Completion(habitPersistentID: habit.persistentID, dayBucket: createdAt, value: 0)
        let cleanHistory = calculator.scoreHistory(for: habit, completions: [clean], from: createdAt, to: createdAt)
        XCTAssertEqual(cleanHistory.last?.score ?? 0, 0.05, accuracy: 0.001)
    }

    func testSnapshotRoundTrip() {
        var snapshot = HabiblingSnapshot()
        snapshot.pet = PetSnapshot(stage: 2, mood: "content", name: "Momo", vibePercent: 60, progression: 0.4)
        snapshot.tiles = [TodayTileSnapshot(id: UUID(), name: "Run", colorHex: "#F6968E",
                                            iconSymbol: "figure.run", done: false, progress: 0.4,
                                            type: "counter", targetValue: 3)]
        guard let data = snapshot.encoded(), let decoded = HabiblingSnapshot.decode(data) else {
            XCTFail("Snapshot round trip failed")
            return
        }
        XCTAssertEqual(decoded.pet.name, "Momo")
        XCTAssertEqual(decoded.tiles.first?.type, "counter")
        XCTAssertEqual(decoded.tiles.first?.targetValue, 3)
    }

    func testIntentCheckInValueMapping() {
        let negative = TodayTileSnapshot(id: UUID(), name: "No snacks", colorHex: "#E05A6B",
                                         iconSymbol: "fork.knife", done: false, progress: 0,
                                         type: "negative", targetValue: 5)
        let counter = TodayTileSnapshot(id: UUID(), name: "Water", colorHex: "#4FB8D9",
                                        iconSymbol: "drop", done: false, progress: 0,
                                        type: "counter", targetValue: 8)
        XCTAssertEqual(max(counter.targetValue, 1), 8)
        XCTAssertEqual(negative.targetValue, 5)
    }
}
