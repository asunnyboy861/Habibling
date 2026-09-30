import SwiftUI
import WidgetKit

struct PetEntry: TimelineEntry {
    let date: Date
    let snapshot: HabiblingSnapshot
}

struct PetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetEntry {
        PetEntry(date: .now, snapshot: Self.demo())
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
        completion(PetEntry(date: .now, snapshot: HabiblingSnapshot.load() ?? Self.demo()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
        let entry = PetEntry(date: .now, snapshot: HabiblingSnapshot.load() ?? Self.demo())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    static func demo() -> HabiblingSnapshot {
        var snapshot = HabiblingSnapshot()
        snapshot.pet = PetSnapshot(stage: 1, mood: "joyful", name: "Momo", vibePercent: 72, progression: 0.2)
        snapshot.tiles = [
            TodayTileSnapshot(id: UUID(), name: "Drink water", colorHex: "#4FB8D9", iconSymbol: "drop", done: false, progress: 0.5),
            TodayTileSnapshot(id: UUID(), name: "Read", colorHex: "#F6968E", iconSymbol: "book", done: true, progress: 1)
        ]
        snapshot.doneCount = 1
        snapshot.totalCount = 2
        return snapshot
    }
}

struct PetHomeWidgetView: View {
    var entry: PetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(entry.snapshot.pet.name)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                Image(systemName: AppTheme.seasonSymbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            PixelPetView(stage: PetStage(rawValue: entry.snapshot.pet.stage) ?? .egg,
                         mood: PetMood(rawValue: entry.snapshot.pet.mood) ?? .content,
                         animated: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 4) {
                ProgressView(value: entry.snapshot.totalCount > 0
                             ? Double(entry.snapshot.doneCount) / Double(entry.snapshot.totalCount) : 0)
                    .tint(AppTheme.accent)
                Text("\(entry.snapshot.doneCount) of \(entry.snapshot.totalCount) today")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "habibling://today"))
    }

    private var mediumView: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                PixelPetView(stage: PetStage(rawValue: entry.snapshot.pet.stage) ?? .egg,
                             mood: PetMood(rawValue: entry.snapshot.pet.mood) ?? .content,
                             animated: false)
                    .frame(width: 64, height: 64)
                Text(entry.snapshot.pet.name)
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(1)
                Text("\(entry.snapshot.doneCount)/\(entry.snapshot.totalCount)")
                    .font(.system(size: 12, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 84)
            VStack(spacing: 6) {
                ForEach(Array(entry.snapshot.tiles.prefix(4).enumerated()), id: \.element.id) { _, tile in
                    TileButton(tile: tile)
                }
                if entry.snapshot.tiles.count > 4 {
                    Text("+\(entry.snapshot.tiles.count - 4) more")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .widgetURL(URL(string: "habibling://today"))
    }
}

struct TileButton: View {
    var tile: TodayTileSnapshot

    var body: some View {
        Button(intent: CheckInHabitIntent(habit: HabitEntity(id: tile.id, name: tile.name))) {
            HStack(spacing: 8) {
                Image(systemName: tile.iconSymbol)
                    .font(.caption)
                    .foregroundStyle(Color(hex: tile.colorHex))
                Text(tile.name)
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: tile.done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(tile.done ? Color(hex: tile.colorHex) : Color(.systemGray4))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct PetLockScreenWidget: View {
    var entry: PetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: "pawprint.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.accent)
                Text(entry.snapshot.pet.name)
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            Text("\(entry.snapshot.doneCount)/\(entry.snapshot.totalCount) today")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
            Text(vibeText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var vibeText: String {
        switch entry.snapshot.pet.mood {
        case "joyful": return "Joyful"
        case "content": return "Content"
        default: return "Napping"
        }
    }
}

struct PetInlineWidget: View {
    var entry: PetEntry

    var body: some View {
        Text("\(entry.snapshot.pet.name) · \(entry.snapshot.doneCount)/\(entry.snapshot.totalCount)")
    }
}

struct PetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PetWidget", provider: PetProvider()) { entry in
            PetHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Pixel Pet")
        .description("Your pet and today's habit tiles. Tap a tile to check in.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PetLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PetLockScreen", provider: PetProvider()) { entry in
            PetLockScreenWidget(entry: entry)
        }
        .configurationDisplayName("Pet Status")
        .description("Pet mood and today's progress on your Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct PetCircularWidget: View {
    var entry: PetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VibeRing(progress: entry.snapshot.totalCount > 0
                     ? Double(entry.snapshot.doneCount) / Double(entry.snapshot.totalCount) : 0,
                     lineWidth: 3,
                     label: "\(entry.snapshot.doneCount)")
                .padding(6)
        }
    }
}

struct PetRingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PetRing", provider: PetProvider()) { entry in
            PetCircularWidget(entry: entry)
        }
        .configurationDisplayName("Today's Ring")
        .description("How many habits are lit today.")
        .supportedFamilies([.accessoryCircular])
    }
}

#if canImport(ActivityKit)
import ActivityKit

struct DailyGoalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DailyGoalActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(AppTheme.accent)
                        .font(.title3)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.petName)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.semibold)
                        ProgressView(value: context.state.totalCount > 0
                                     ? Double(context.state.doneCount) / Double(context.state.totalCount) : 0)
                            .tint(AppTheme.accent)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.doneCount)/\(context.state.totalCount)")
                        .font(.system(.headline, design: .monospaced))
                }
            } compactLeading: {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(AppTheme.accent)
            } compactTrailing: {
                Text("\(context.state.doneCount)/\(context.state.totalCount)")
                    .font(.system(.caption2, design: .monospaced))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    var context: ActivityViewContext<DailyGoalActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "pawprint.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(context.state.petName) is watching pixels light up")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                ProgressView(value: context.state.totalCount > 0
                             ? Double(context.state.doneCount) / Double(context.state.totalCount) : 0)
                    .tint(AppTheme.accent)
                Text("\(context.state.doneCount) of \(context.state.totalCount) habits · vibe \(context.state.vibePercent)%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(14)
    }
}
#endif

@main
struct HabiblingWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PetWidget()
        PetLockWidget()
        PetRingWidget()
        #if canImport(ActivityKit)
        DailyGoalLiveActivity()
        #endif
    }
}
