import Foundation
import SwiftData
import UIKit
import UserNotifications

struct CheckInFeedback: Equatable {
    var didEvolve: Bool = false
    var newStage: PetStage?
}

@MainActor
final class CheckInService: ObservableObject {
    let persistence: PersistenceController
    let settings: AppSettings
    let calendar: Calendar

    init(persistence: PersistenceController = .shared, settings: AppSettings = .shared, calendar: Calendar = .current) {
        self.persistence = persistence
        self.settings = settings
        self.calendar = calendar
    }

    func upsert(habit: Habit, day: Date, value: Double, source: CheckInSource, note: String? = nil) -> CheckInFeedback {
        let context = persistence.context
        let bucket = DayBucket.startOfDay(for: day, calendar: calendar)
        let habitID = habit.persistentID
        let descriptor = FetchDescriptor<Completion>(predicate: #Predicate { $0.habitPersistentID == habitID })
        let existing = ((try? context.fetch(descriptor)) ?? []).first {
            DayBucket.startOfDay(for: $0.dayBucket, calendar: calendar) == bucket
        }
        if let completion = existing {
            completion.value = value
            completion.updatedAt = .now
            if let note { completion.note = note }
        } else {
            let completion = Completion(habitPersistentID: habitID, dayBucket: bucket, value: value, source: source, note: note ?? "")
            completion.habit = habit
            context.insert(completion)
        }
        try? context.save()
        let feedback = evaluateEvolution()
        SnapshotBuilder.rebuild(context: context, settings: settings)
        return feedback
    }

    func increment(habit: Habit, day: Date = .now, source: CheckInSource) -> CheckInFeedback {
        let value = currentValue(habit: habit, day: day) + stepValue(for: habit)
        return upsert(habit: habit, day: day, value: value, source: source)
    }

    func complete(habit: Habit, day: Date = .now, source: CheckInSource) -> CheckInFeedback {
        let value = habit.type == .negative ? 0 : habit.targetValue
        return upsert(habit: habit, day: day, value: value, source: source)
    }

    func undo(habit: Habit, day: Date = .now) {
        let context = persistence.context
        let bucket = DayBucket.startOfDay(for: day, calendar: calendar)
        let habitID = habit.persistentID
        let descriptor = FetchDescriptor<Completion>(predicate: #Predicate { $0.habitPersistentID == habitID })
        let existing = ((try? context.fetch(descriptor)) ?? []).first {
            DayBucket.startOfDay(for: $0.dayBucket, calendar: calendar) == bucket
        }
        if let completion = existing {
            context.delete(completion)
            try? context.save()
        }
        SnapshotBuilder.rebuild(context: context, settings: settings)
    }

    func currentValue(habit: Habit, day: Date) -> Double {
        let bucket = DayBucket.startOfDay(for: day, calendar: calendar)
        let habitID = habit.persistentID
        let descriptor = FetchDescriptor<Completion>(predicate: #Predicate { $0.habitPersistentID == habitID })
        let completions = (try? persistence.context.fetch(descriptor)) ?? []
        return completions.filter {
            DayBucket.startOfDay(for: $0.dayBucket, calendar: calendar) == bucket
        }.map(\.value).reduce(0, +)
    }

    func stepValue(for habit: Habit) -> Double {
        switch habit.type {
        case .binary: habit.targetValue
        case .counter, .timer: 1
        case .negative: 1
        }
    }

    func missedYesterdayHabits() -> [Habit] {
        let calendar = calendar
        let yesterday = DayBucket.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: .now) ?? .now, calendar: calendar)
        let context = persistence.context
        let habitDescriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        let habits = ((try? context.fetch(habitDescriptor)) ?? []).filter { $0.archivedAt == nil }
        let completionDescriptor = FetchDescriptor<Completion>()
        let completions = (try? context.fetch(completionDescriptor)) ?? []
        let doneIDs = Set(completions.filter {
            DayBucket.startOfDay(for: $0.dayBucket, calendar: calendar) == yesterday
        }.map(\.habitPersistentID))
        return habits.filter {
            $0.schedule.isDue(on: yesterday, createdAt: $0.createdAt, calendar: calendar) && !doneIDs.contains($0.persistentID)
        }
    }

    func rescue(habit: Habit) -> CheckInFeedback {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now) ?? .now
        return complete(habit: habit, day: yesterday, source: .manual)
    }

    func drainPendingQueue() {
        let pending = PendingCheckInQueue.load()
        guard !pending.isEmpty else { return }
        let context = persistence.context
        let habitDescriptor = FetchDescriptor<Habit>()
        let habits = (try? context.fetch(habitDescriptor)) ?? []
        let byID = Dictionary(uniqueKeysWithValues: habits.map { ($0.persistentID, $0) })
        for item in pending {
            guard let habit = byID[item.habitID] else { continue }
            upsert(habit: habit, day: item.dayBucket, value: item.value, source: CheckInSource(rawValue: item.source) ?? .widget)
        }
        PendingCheckInQueue.clear()
    }

    func evaluateEvolution() -> CheckInFeedback {
        let pet = currentPetState()
        var feedback = CheckInFeedback()
        if pet.stage.rawValue > settings.lastShownStage {
            feedback.didEvolve = true
            feedback.newStage = pet.stage
            settings.lastShownStage = pet.stage.rawValue
        }
        return feedback
    }

    func dailyScores(habit: Habit) -> [DailyScore] {
        let habitID = habit.persistentID
        let descriptor = FetchDescriptor<Completion>(predicate: #Predicate { $0.habitPersistentID == habitID })
        let completions = (try? persistence.context.fetch(descriptor)) ?? []
        return HabitScoreCalculator(calendar: calendar).scoreHistory(for: habit, completions: completions, from: habit.createdAt, to: .now)
    }

    func overallScores() -> [DailyScore] {
        let context = persistence.context
        let habitDescriptor = FetchDescriptor<Habit>()
        let habits = (try? context.fetch(habitDescriptor)) ?? []
        let completionDescriptor = FetchDescriptor<Completion>()
        let completions = (try? context.fetch(completionDescriptor)) ?? []
        var byHabit: [UUID: [Completion]] = [:]
        for completion in completions {
            byHabit[completion.habitPersistentID, default: []].append(completion)
        }
        let earliest = habits.map(\.createdAt).min() ?? .now
        return HabitScoreCalculator(calendar: calendar).overallDailyScores(habits: habits, completionsByHabit: byHabit, from: earliest, to: .now)
    }

    func currentPetState() -> PetState {
        PetDeriver.derive(dailyScores: overallScores(), petCreatedAt: settings.petCreatedAt)
    }

    func activeHabits() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        return ((try? persistence.context.fetch(descriptor)) ?? []).filter { $0.archivedAt == nil }
    }

    func allHabits() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? persistence.context.fetch(descriptor)) ?? []
    }

    func completions(for habit: Habit) -> [Completion] {
        let habitID = habit.persistentID
        let descriptor = FetchDescriptor<Completion>(predicate: #Predicate { $0.habitPersistentID == habitID }, sortBy: [SortDescriptor(\.dayBucket)])
        return (try? persistence.context.fetch(descriptor)) ?? []
    }

    func mood(for day: Date) -> MoodEntry? {
        let bucket = DayBucket.startOfDay(for: day, calendar: calendar)
        let descriptor = FetchDescriptor<MoodEntry>()
        return (try? persistence.context.fetch(descriptor))?.first {
            DayBucket.startOfDay(for: $0.dayBucket, calendar: calendar) == bucket
        }
    }

    func setMood(_ level: Int, day: Date, note: String = "") {
        let context = persistence.context
        if let entry = mood(for: day) {
            entry.level = level
            entry.note = note
            entry.updatedAt = .now
        } else {
            context.insert(MoodEntry(dayBucket: day, level: level, note: note))
        }
        try? context.save()
    }
}
