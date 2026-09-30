import AppIntents
import Foundation
import SwiftUI

struct HabitEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    static let defaultQuery = HabitEntityQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        let tiles = HabiblingSnapshot.load()?.tiles ?? []
        return tiles.filter { identifiers.contains($0.id) }.map { HabitEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        let tiles = HabiblingSnapshot.load()?.tiles ?? []
        return tiles.map { HabitEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> HabitEntity? {
        let tiles = HabiblingSnapshot.load()?.tiles ?? []
        return tiles.first(where: { !$0.done }).map { HabitEntity(id: $0.id, name: $0.name) }
    }
}

struct CheckInHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Check In"
    static let description = IntentDescription("Log today's check-in for one of your habits.")

    @Parameter(title: "Habit")
    var habit: HabitEntity?

    init() {}

    init(habit: HabitEntity?) {
        self.habit = habit
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let entity: HabitEntity?
        if let habit {
            entity = habit
        } else {
            entity = await HabitEntityQuery().defaultResult()
        }
        guard let entity else {
            return .result(dialog: "No habits yet. Open Habibling to add your first one!")
        }
        if IntentCheckIn.execute(habitID: entity.id, source: CheckInSource.siri.rawValue) {
            return .result(dialog: "Checked in \(entity.name). Your pet is happy!")
        }
        return .result(dialog: "Couldn't find that habit. Open Habibling and try again.")
    }
}

struct HabiblingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckInHabitIntent(),
            phrases: [
                "Check in with \(.applicationName)",
                "Log a habit in \(.applicationName)",
                "Do my \(.applicationName) check-in"
            ],
            shortTitle: "Check In",
            systemImageName: "checkmark.square.fill"
        )
    }
}
