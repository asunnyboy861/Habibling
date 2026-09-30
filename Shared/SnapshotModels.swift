import Foundation

public struct PetSnapshot: Codable, Equatable, Sendable {
    public var stage: Int
    public var mood: String
    public var name: String
    public var vibePercent: Int
    public var progression: Double

    public init(stage: Int = 0, mood: String = "joyful", name: String = "Habibling", vibePercent: Int = 0, progression: Double = 0) {
        self.stage = stage
        self.mood = mood
        self.name = name
        self.vibePercent = vibePercent
        self.progression = progression
    }
}

public struct TodayTileSnapshot: Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var iconSymbol: String
    public var done: Bool
    public var progress: Double
    public var type: String
    public var targetValue: Double

    public init(id: UUID, name: String, colorHex: String, iconSymbol: String, done: Bool, progress: Double,
                type: String = HabitType.binary.rawValue, targetValue: Double = 1) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconSymbol = iconSymbol
        self.done = done
        self.progress = progress
        self.type = type
        self.targetValue = targetValue
    }
}

public struct HabiblingSnapshot: Codable, Equatable, Sendable {
    public static let appGroupId = "group.com.zzoutuo.Habibling"
    public static let snapshotKey = "snapshot.json"
    public static let pendingKey = "pending.json"

    public var pet: PetSnapshot
    public var tiles: [TodayTileSnapshot]
    public var doneCount: Int
    public var totalCount: Int
    public var generatedAt: Date

    public init(pet: PetSnapshot = PetSnapshot(), tiles: [TodayTileSnapshot] = [], doneCount: Int = 0, totalCount: Int = 0, generatedAt: Date = .now) {
        self.pet = pet
        self.tiles = tiles
        self.doneCount = doneCount
        self.totalCount = totalCount
        self.generatedAt = generatedAt
    }

    public func encoded() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(self)
    }

    public static func decode(_ data: Data) -> HabiblingSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(HabiblingSnapshot.self, from: data)
    }

    public static func load() -> HabiblingSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: snapshotKey) else { return nil }
        return decode(data)
    }

    public func save() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId),
              let data = encoded() else { return }
        defaults.set(data, forKey: Self.snapshotKey)
    }
}

public struct PendingCheckIn: Codable, Equatable, Sendable {
    public var habitID: UUID
    public var dayBucket: Date
    public var value: Double
    public var source: String

    public init(habitID: UUID, dayBucket: Date, value: Double, source: String) {
        self.habitID = habitID
        self.dayBucket = dayBucket
        self.value = value
        self.source = source
    }
}

public enum PendingCheckInQueue {
    public static func load() -> [PendingCheckIn] {
        guard let defaults = UserDefaults(suiteName: HabiblingSnapshot.appGroupId),
              let data = defaults.data(forKey: HabiblingSnapshot.pendingKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PendingCheckIn].self, from: data)) ?? []
    }

    public static func append(_ item: PendingCheckIn) {
        var items = load()
        items.append(item)
        save(items)
    }

    public static func save(_ items: [PendingCheckIn]) {
        guard let defaults = UserDefaults(suiteName: HabiblingSnapshot.appGroupId) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        defaults.set(try? encoder.encode(items), forKey: HabiblingSnapshot.pendingKey)
    }

    public static func clear() {
        UserDefaults(suiteName: HabiblingSnapshot.appGroupId)?.removeObject(forKey: HabiblingSnapshot.pendingKey)
    }
}
