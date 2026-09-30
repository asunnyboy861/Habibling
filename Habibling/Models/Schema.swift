import Foundation
import SwiftData

enum HabiblingSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Habit.self, Completion.self, MoodEntry.self, WeeklyPost.self, MonthlyReport.self]
    }
}

enum HabiblingMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [HabiblingSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
