import Foundation
import SwiftData

struct BackupHabit: Codable {
    var persistentID: UUID
    var name: String
    var iconSymbol: String
    var colorHex: String
    var type: String
    var scheduleType: String
    var schedulePayload: String
    var targetValue: Double
    var unitLabel: String
    var category: String
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var createdAt: Date
    var archivedAt: Date?
    var sortOrder: Int
}

struct BackupCompletion: Codable {
    var habitID: UUID
    var dayBucket: Date
    var value: Double
    var note: String
    var source: String
    var updatedAt: Date
}

struct BackupFile: Codable {
    var version: Int
    var exportedAt: Date
    var habits: [BackupHabit]
    var completions: [BackupCompletion]
}

enum BackupService {
    static func exportJSON(context: ModelContext) throws -> URL {
        let habits = try context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)]))
        let completions = try context.fetch(FetchDescriptor<Completion>())
        let backup = BackupFile(
            version: 1,
            exportedAt: .now,
            habits: habits.map { habit in
                BackupHabit(persistentID: habit.persistentID, name: habit.name, iconSymbol: habit.iconSymbol,
                            colorHex: habit.colorHex, type: habit.typeRaw, scheduleType: habit.scheduleTypeRaw,
                            schedulePayload: habit.schedulePayload, targetValue: habit.targetValue,
                            unitLabel: habit.unitLabel, category: habit.category,
                            reminderEnabled: habit.reminderEnabled, reminderHour: habit.reminderHour,
                            reminderMinute: habit.reminderMinute, createdAt: habit.createdAt,
                            archivedAt: habit.archivedAt, sortOrder: habit.sortOrder)
            },
            completions: completions.map { completion in
                BackupCompletion(habitID: completion.habitPersistentID, dayBucket: completion.dayBucket,
                                 value: completion.value, note: completion.note, source: completion.sourceRaw,
                                 updatedAt: completion.updatedAt)
            }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Habibling-Backup-\(dateStamp()).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func exportCSV(context: ModelContext) throws -> URL {
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let names = Dictionary(uniqueKeysWithValues: habits.map { ($0.persistentID, $0.name) })
        let completions = try context.fetch(FetchDescriptor<Completion>(sortBy: [SortDescriptor(\.dayBucket)]))
        var rows = ["habit,date,value,note"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for completion in completions {
            let name = names[completion.habitPersistentID] ?? "Unknown"
            let note = completion.note.replacingOccurrences(of: ",", with: "'")
            rows.append("\(name),\(formatter.string(from: completion.dayBucket)),\(completion.value),\(note)")
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Habibling-Export-\(dateStamp()).csv")
        try rows.joined(separator: "\n").data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    @MainActor
    static func importJSON(from url: URL, context: ModelContext) throws -> Int {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupFile.self, from: data)
        let existingHabits = try context.fetch(FetchDescriptor<Habit>())
        var byID = Dictionary(uniqueKeysWithValues: existingHabits.map { ($0.persistentID, $0) })
        var imported = 0
        for backupHabit in backup.habits {
            if let existing = byID[backupHabit.persistentID] {
                existing.name = backupHabit.name
                existing.targetValue = backupHabit.targetValue
                existing.archivedAt = backupHabit.archivedAt
            } else {
                let habit = Habit(name: backupHabit.name, iconSymbol: backupHabit.iconSymbol, colorHex: backupHabit.colorHex,
                                  type: HabitType(rawValue: backupHabit.type) ?? .binary,
                                  schedule: HabitSchedule(type: HabitScheduleType(rawValue: backupHabit.scheduleType) ?? .daily,
                                                          payload: backupHabit.schedulePayload),
                                  targetValue: backupHabit.targetValue, unitLabel: backupHabit.unitLabel,
                                  category: backupHabit.category)
                habit.persistentID = backupHabit.persistentID
                habit.createdAt = backupHabit.createdAt
                habit.archivedAt = backupHabit.archivedAt
                habit.reminderEnabled = backupHabit.reminderEnabled
                habit.reminderHour = backupHabit.reminderHour
                habit.reminderMinute = backupHabit.reminderMinute
                habit.sortOrder = backupHabit.sortOrder
                context.insert(habit)
                byID[backupHabit.persistentID] = habit
            }
        }
        let existingCompletions = try context.fetch(FetchDescriptor<Completion>())
        var seen = Set(existingCompletions.map { "\($0.habitPersistentID)-\(Int($0.dayBucket.timeIntervalSince1970 / 3600))" })
        for backupCompletion in backup.completions {
            guard let habit = byID[backupCompletion.habitID] else { continue }
            let key = "\(backupCompletion.habitID)-\(Int(backupCompletion.dayBucket.timeIntervalSince1970 / 3600))"
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            let completion = Completion(habitPersistentID: backupCompletion.habitID,
                                        dayBucket: backupCompletion.dayBucket,
                                        value: backupCompletion.value,
                                        source: CheckInSource(rawValue: backupCompletion.source) ?? .manual,
                                        note: backupCompletion.note)
            completion.updatedAt = backupCompletion.updatedAt
            completion.habit = habit
            context.insert(completion)
            imported += 1
        }
        try? context.save()
        SnapshotBuilder.rebuild(context: context, settings: AppSettings.shared)
        return imported
    }

    private static func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter.string(from: .now)
    }
}
