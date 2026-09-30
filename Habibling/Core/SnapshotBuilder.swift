import Foundation
import SwiftData
import WidgetKit

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    var context: ModelContext {
        container.mainContext
    }

    private init() {
        let schema = Schema([Habit.self, Completion.self, MoodEntry.self, WeeklyPost.self, MonthlyReport.self])
        var configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.zzoutuo.Habibling"))
        if FileManager.default.ubiquityIdentityToken == nil {
            configuration = ModelConfiguration(schema: schema)
        }
        do {
            container = try ModelContainer(for: schema, migrationPlan: HabiblingMigrationPlan.self, configurations: [configuration])
        } catch {
            let fallback = ModelConfiguration(schema: schema)
            container = (try? ModelContainer(for: schema, migrationPlan: HabiblingMigrationPlan.self, configurations: [fallback]))
                ?? (try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: false)]))
        }
    }
}

@MainActor
final class SnapshotBuilder {
    static func rebuild(context: ModelContext, settings: AppSettings) {
        let calendar = Calendar.current
        let today = DayBucket.startOfDay(for: .now, calendar: calendar)
        let habitDescriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        let habits = (try? context.fetch(habitDescriptor)) ?? []
        let activeHabits = habits.filter { $0.archivedAt == nil }
        let completionDescriptor = FetchDescriptor<Completion>()
        let allCompletions = (try? context.fetch(completionDescriptor)) ?? []
        var byHabit: [UUID: [Completion]] = [:]
        for completion in allCompletions {
            byHabit[completion.habitPersistentID, default: []].append(completion)
        }
        let calculator = HabitScoreCalculator(calendar: calendar)
        let overall = calculator.overallDailyScores(habits: activeHabits, completionsByHabit: byHabit, from: today.addingTimeInterval(-86400 * 60), to: today)
        let pet = PetDeriver.derive(dailyScores: overall, petCreatedAt: settings.petCreatedAt)
        var tiles: [TodayTileSnapshot] = []
        var doneCount = 0
        for habit in activeHabits {
            let todayCompletions = (byHabit[habit.persistentID] ?? []).filter {
                DayBucket.startOfDay(for: $0.dayBucket, calendar: calendar) == today
            }
            let value = todayCompletions.map(\.value).reduce(0, +)
            let progress: Double
            let done: Bool
            if habit.type == .negative {
                progress = todayCompletions.isEmpty ? 0 : max(0, 1 - value / max(habit.targetValue, 0.0001))
                done = !todayCompletions.isEmpty && value <= habit.targetValue
            } else {
                progress = min(1, value / max(habit.targetValue, 0.0001))
                done = progress >= 1
            }
            if done { doneCount += 1 }
            tiles.append(TodayTileSnapshot(id: habit.persistentID, name: habit.name, colorHex: habit.colorHex,
                                           iconSymbol: habit.iconSymbol, done: done, progress: progress,
                                           type: habit.type.rawValue, targetValue: habit.targetValue))
        }
        let vibePercent = Int(round((overall.last?.score ?? 0) * 100))
        let snapshot = HabiblingSnapshot(
            pet: PetSnapshot(stage: pet.stage.rawValue, mood: pet.mood.rawValue,
                             name: settings.petName, vibePercent: vibePercent, progression: pet.progression),
            tiles: tiles,
            doneCount: doneCount,
            totalCount: activeHabits.count
        )
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
