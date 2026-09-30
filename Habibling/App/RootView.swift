import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var checkIns: CheckInService
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if settings.onboardingCompleted {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear(perform: wake)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { wake() }
        }
    }

    private func wake() {
        checkIns.drainPendingQueue()
        WatchLink.shared.checkInHandler = { habitID, value in
            guard let habit = checkIns.allHabits().first(where: { $0.persistentID == habitID }) else { return }
            checkIns.upsert(habit: habit, day: .now, value: value, source: .watch)
            SoundPlayer.shared.playChirp()
        }
        if let snapshot = HabiblingSnapshot.load() {
            WatchLink.shared.pushSnapshot(snapshot)
            LiveActivityManager.shared.startIfNeeded(snapshot: snapshot)
        }
        BGTaskService.schedule()
    }
}

struct MainTabView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "square.grid.2x2.fill") }
            PetView()
                .tabItem { Label("Pet", systemImage: "pawprint.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
