import SwiftUI
import WatchConnectivity

@main
struct HabiblingWatchApp: App {
    @StateObject private var store = WatchStore.shared

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(store)
                .tint(AppTheme.accent)
        }
    }
}

final class WatchStore: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchStore()

    @Published var snapshot: HabiblingSnapshot?
    @Published var statusText = "Waiting for iPhone"

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func checkIn(tile: TodayTileSnapshot) {
        let session = WCSession.default
        let message: [String: Any] = ["habitID": tile.id.uuidString, "value": value(for: tile)]
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
        if let index = snapshot?.tiles.firstIndex(where: { $0.id == tile.id }) {
            snapshot?.tiles[index].done = true
            let total = snapshot?.totalCount ?? 0
            let done = snapshot?.doneCount ?? 0
            snapshot?.doneCount = min(total, done + 1)
        }
        statusText = ""
    }

    private func value(for tile: TodayTileSnapshot) -> Double {
        switch tile.type {
        case HabitType.negative.rawValue: return 0
        case HabitType.counter.rawValue, HabitType.timer.rawValue: return max(tile.targetValue, 1)
        default: return 1
        }
    }

    private func load(from context: [String: Any]) {
        guard let payload = context["snapshot"] as? [String: Any],
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let snapshot = HabiblingSnapshot.decode(data) else { return }
        DispatchQueue.main.async {
            self.snapshot = snapshot
            self.statusText = ""
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        load(from: session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        load(from: applicationContext)
    }
}

struct WatchHomeView: View {
    @EnvironmentObject private var store: WatchStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    if let snapshot = store.snapshot {
                        petHeader(snapshot: snapshot)
                        ForEach(snapshot.tiles, id: \.id) { tile in
                            WatchTileButton(tile: tile) {
                                store.checkIn(tile: tile)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            PixelPetView(stage: .egg, mood: .content, animated: false)
                                .frame(width: 60, height: 60)
                            Text(store.statusText)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Habibling")
        }
    }

    private func petHeader(snapshot: HabiblingSnapshot) -> some View {
        VStack(spacing: 4) {
            PixelPetView(stage: PetStage(rawValue: snapshot.pet.stage) ?? .egg,
                         mood: PetMood(rawValue: snapshot.pet.mood) ?? .content,
                         animated: false)
                .frame(width: 64, height: 64)
            Text(snapshot.pet.name)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
            Text("\(snapshot.doneCount) of \(snapshot.totalCount) today")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

struct WatchTileButton: View {
    var tile: TodayTileSnapshot
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: tile.iconSymbol)
                    .foregroundStyle(Color(hex: tile.colorHex))
                Text(tile.name)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(1)
                Spacer()
                Image(systemName: tile.done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(tile.done ? Color(hex: tile.colorHex) : Color.white.opacity(0.35))
            }
        }
        .buttonStyle(.plain)
        .disabled(tile.done)
    }
}
