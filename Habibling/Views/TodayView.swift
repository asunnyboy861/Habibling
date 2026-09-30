import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var checkIns: CheckInService
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var habits: [Habit] = []
    @State private var missedHabits: [Habit] = []
    @State private var petState = PetState(stage: .egg, mood: .content, season: .spring, progression: 0, daysKept: 0)
    @State private var showAdd = false
    @State private var burstTrigger = 0
    @State private var paywallHabit = false
    @State private var logHabit: Habit?
    @State private var noteHabit: Habit?
    @State private var encouragement = ""

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if !missedHabits.isEmpty {
                        RescueCard(habits: missedHabits) { habit in
                            let feedback = checkIns.rescue(habit: habit)
                            celebrate(feedback: feedback)
                            reload()
                        }
                    }
                    if habits.isEmpty {
                        emptyCard
                    }
                    ForEach(habits, id: \.persistentID) { habit in
                        HabitRow(habit: habit,
                                 currentValue: checkIns.currentValue(habit: habit, day: .now),
                                 onToggle: { toggle(habit) },
                                 onIncrement: { increment(habit) },
                                 onDecrement: { decrement(habit) },
                                 onLog: { logHabit = habit },
                                 onNote: { noteHabit = habit })
                    }
                    MoodRow()
                        .pixelCard()
                    Text(encouragement)
                        .font(AppTheme.pixelCaption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(16)
            }
            .background(AppTheme.page)
            .navigationTitle(titleText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: reload) {
                AddEditHabitView()
            }
            .sheet(item: $logHabit, onDismiss: reload) { habit in
                ValueLogSheet(habit: habit) { value in
                    let feedback = checkIns.upsert(habit: habit, day: .now, value: value, source: .manual)
                    celebrate(feedback: feedback)
                    reload()
                }
            }
            .sheet(item: $noteHabit, onDismiss: reload) { habit in
                NoteSheet(habit: habit, checkIns: checkIns)
            }
            .overlay(BerryBurst(trigger: burstTrigger))
        }
        .onAppear(perform: reload)
        .onReceive(checkIns.objectWillChange) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { reload() }
        }
    }

    private var titleText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: .now)
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            PixelPetView(stage: petState.stage, mood: petState.mood)
                .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 6) {
                Text(settings.petName)
                    .font(AppTheme.pixelTitle)
                Text(petState.mood == .joyful ? "Feeling joyful" : petState.mood == .content ? "Feeling content" : "Napping peacefully")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: petState.progression)
                    .tint(AppTheme.accent)
                Text(AppTheme.stageProgressText(petState))
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VibeRing(progress: Double(petState.daysKept) / max(1, Double(max(habits.count, 1))),
                     lineWidth: 8,
                     label: "\(doneCount)/\(habits.count)",
                     sublabel: "today")
                .frame(width: 74, height: 74)
        }
        .pixelCard()
    }

    private var doneCount: Int {
        habits.filter { habit in
            let value = checkIns.currentValue(habit: habit, day: .now)
            if habit.type == .negative {
                return checkIns.completions(for: habit).contains {
                    calendar.isDate($0.dayBucket, inSameDayAs: .now) && $0.value <= habit.targetValue
                }
            }
            return value >= habit.targetValue
        }.count
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No habits yet")
                .font(AppTheme.pixelTitle)
            Text("Tap + to add your first habit. Every check-in lights a pixel and feeds your pet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .pixelCard()
    }

    private func reload() {
        habits = checkIns.activeHabits()
        missedHabits = checkIns.missedYesterdayHabits()
        petState = checkIns.currentPetState()
        if encouragement.isEmpty {
            Task {
                let summary = AICoachService.Summary(dueCount: habits.count, doneCount: doneCount)
                encouragement = await AICoachService.shared.encouragement(summary: summary)
            }
        }
    }

    private func celebrate(feedback: CheckInFeedback) {
        SoundPlayer.shared.playChirp()
        Haptics.success()
        burstTrigger += 1
        if feedback.didEvolve, let stage = feedback.newStage {
            EvolutionCelebration.show(stage: stage, petName: settings.petName)
        }
    }

    private func toggle(_ habit: Habit) {
        let value = checkIns.currentValue(habit: habit, day: .now)
        if habit.type == .negative {
            let logged = checkIns.completions(for: habit).contains { calendar.isDate($0.dayBucket, inSameDayAs: .now) }
            if logged {
                checkIns.undo(habit: habit)
            } else {
                checkIns.complete(habit: habit, source: .manual)
            }
        } else if value >= habit.targetValue {
            checkIns.undo(habit: habit)
        } else {
            let feedback = checkIns.complete(habit: habit, source: .manual)
            celebrate(feedback: feedback)
        }
        reload()
    }

    private func increment(_ habit: Habit) {
        let feedback = checkIns.increment(habit: habit, source: .manual)
        if habit.type == .negative {
            Haptics.light()
        } else {
            celebrate(feedback: feedback)
        }
        reload()
    }

    private func decrement(_ habit: Habit) {
        let current = checkIns.currentValue(habit: habit, day: .now)
        let next = max(0, current - checkIns.stepValue(for: habit))
        if next == 0 {
            checkIns.undo(habit: habit)
        } else {
            checkIns.upsert(habit: habit, day: .now, value: next, source: .manual)
        }
        reload()
    }
}

struct RescueCard: View {
    var habits: [Habit]
    var onRescue: (Habit) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.accent)
                Text("Yesterdays left dim")
                    .font(AppTheme.pixelTitle)
                Spacer()
            }
            Text("No guilt here — light them up anyway. Your history is never wrong.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(habits, id: \.persistentID) { habit in
                Button {
                    onRescue(habit)
                } label: {
                    HStack {
                        Image(systemName: habit.iconSymbol)
                            .foregroundStyle(Color(hex: habit.colorHex))
                        Text(habit.name)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("Rescue")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(10)
                    .background(AppTheme.page)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .pixelCard()
    }
}

struct MoodRow: View {
    @EnvironmentObject private var checkIns: CheckInService
    @State private var selected = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How was today?")
                .font(AppTheme.pixelTitle)
            HStack {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        selected = level
                        checkIns.setMood(level, day: .now)
                        Haptics.light()
                    } label: {
                        Image(systemName: AppTheme.moodSymbol(level))
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selected == level ? AppTheme.accent.opacity(0.18) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(selected == level ? AppTheme.accent : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            selected = checkIns.mood(for: .now)?.level ?? 3
        }
    }
}
