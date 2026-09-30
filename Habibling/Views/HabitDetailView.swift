import SwiftUI

struct HabitDetailView: View {
    var habit: Habit

    @EnvironmentObject private var checkIns: CheckInService
    @Environment(\.dismiss) private var dismiss

    @State private var month = Date.now
    @State private var completions: [Completion] = []
    @State private var streak = StreakCalculator.StreakInfo(current: 0, best: 0, total: 0)
    @State private var vibe = 0.0
    @State private var editingDay: Date?
    @State private var showEdit = false

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                streakCard
                monthCard
                sparklineCard
                if !notes.isEmpty {
                    notesCard
                }
            }
            .padding(16)
        }
        .background(AppTheme.page)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddEditHabitView(habit: habit)
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: reload) {
            if let editingDay {
                HistoryEditSheet(habit: habit, day: editingDay, checkIns: checkIns) {
                    reload()
                }
            }
        }
        .onAppear(perform: reload)
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            VibeRing(progress: vibe, lineWidth: 9, label: "\(Int(vibe * 100))", sublabel: "vibe")
                .frame(width: 86, height: 86)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: habit.iconSymbol)
                        .foregroundStyle(Color(hex: habit.colorHex))
                    Text(habit.type.displayName)
                        .font(AppTheme.pixelTitle)
                }
                Text(habit.schedule.summary)
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
                Text("Target: \(Int(habit.targetValue)) \(habit.type == .negative ? "max" : habit.unitLabel.isEmpty ? "per day" : habit.unitLabel)")
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .pixelCard()
    }

    private var streakCard: some View {
        HStack {
            streakTile(value: streak.current, label: "Current")
            Divider().frame(height: 40)
            streakTile(value: streak.best, label: "Best")
            Divider().frame(height: 40)
            streakTile(value: streak.total, label: "Total")
        }
        .frame(maxWidth: .infinity)
        .pixelCard()
    }

    private func streakTile(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.bold)
            Text(label)
                .font(AppTheme.pixelCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var monthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    month = calendar.date(byAdding: .month, value: -1, to: month) ?? month
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                Spacer()
                Text(month.formatted(.dateTime.month().year()))
                    .font(AppTheme.pixelTitle)
                Spacer()
                Button {
                    month = calendar.date(byAdding: .month, value: 1, to: month) ?? month
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
            MonthCalendar(values: dayValues, month: month, accent: Color(hex: habit.colorHex)) { day in
                editingDay = day
                showEdit = true
            }
            Text("Tap any day to fix your history — it is never wrong.")
                .font(AppTheme.pixelCaption)
                .foregroundStyle(.secondary)
        }
        .pixelCard()
    }

    private var sparklineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 30 days")
                .font(AppTheme.pixelTitle)
            MosaicView(values: recentValues,
                       days: recentDays,
                       accent: Color(hex: habit.colorHex))
                .frame(height: 100)
        }
        .pixelCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes")
                .font(AppTheme.pixelTitle)
            ForEach(notes, id: \.updatedAt) { completion in
                VStack(alignment: .leading, spacing: 2) {
                    Text(completion.dayBucket.formatted(.dateTime.month().day()))
                        .font(AppTheme.pixelCaption)
                        .foregroundStyle(.secondary)
                    Text(completion.note)
                        .font(.subheadline)
                }
                Divider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelCard()
    }

    private var notes: [Completion] {
        completions.filter { !$0.note.isEmpty }.suffix(6).reversed()
    }

    private var dayValues: [Date: Double] {
        var result: [Date: Double] = [:]
        for completion in completions {
            let day = calendar.startOfDay(for: completion.dayBucket)
            let progress: Double
            if habit.type == .negative {
                progress = completion.value <= habit.targetValue ? max(0.3, 1 - completion.value / max(habit.targetValue, 0.0001)) : 0
            } else {
                progress = min(1, completion.value / max(habit.targetValue, 0.0001))
            }
            result[day] = max(result[day] ?? 0, progress)
        }
        return result
    }

    private var recentValues: [Date: Double] {
        dayValues
    }

    private var recentDays: [Date] {
        ShareRenderer.yearDays(end: .now).suffix(30)
    }

    private func reload() {
        completions = checkIns.completions(for: habit)
        streak = StreakCalculator(calendar: calendar).streak(for: habit, completions: completions)
        vibe = HabitScoreCalculator(calendar: calendar).currentVibe(for: habit, completions: completions)
    }
}

struct HistoryEditSheet: View {
    var habit: Habit
    var day: Date
    var checkIns: CheckInService
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var value: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(day.formatted(.dateTime.weekday().month().day()))
                    .font(AppTheme.pixelTitle)
                Stepper(value: $value, in: 0...10000, step: max(1, habit.targetValue / 4)) {
                    Text("\(Int(value)) \(habit.type == .negative ? "used" : habit.unitLabel.isEmpty ? "" : habit.unitLabel)")
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 32)
                Button("Save for this day") {
                    if value == 0 {
                        checkIns.undo(habit: habit, day: day)
                    } else {
                        checkIns.upsert(habit: habit, day: day, value: value, source: .manual)
                    }
                    onSaved()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Edit history")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            let bucket = DayBucket.startOfDay(for: day)
            let existing = checkIns.completions(for: habit).first {
                Calendar.current.isDate($0.dayBucket, inSameDayAs: bucket)
            }
            value = existing?.value ?? (habit.type == .negative ? habit.targetValue : habit.targetValue)
        }
    }
}
