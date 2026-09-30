import SwiftUI
import SwiftData

struct StatsView: View {
    @EnvironmentObject private var checkIns: CheckInService
    @EnvironmentObject private var purchases: PurchaseManager
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext

    @State private var habits: [Habit] = []
    @State private var overall: [DailyScore] = []
    @State private var petState = PetState(stage: .egg, mood: .content, season: .spring, progression: 0, daysKept: 0)
    @State private var shareImage: UIImage?
    @State private var showPaywall = false
    @State private var generatingWeekly = false
    @State private var generatingMonthly = false
    @State private var weeklyPost: WeeklyPost?
    @State private var monthlyReport: MonthlyReport?
    @State private var aiError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    mosaicCard
                    habitSummaryCard
                    coachSection
                }
                .padding(16)
            }
            .background(AppTheme.page)
            .navigationTitle("Stats")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear(perform: reload)
        }
    }

    private var mosaicCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Year mosaic")
                    .font(AppTheme.pixelTitle)
                Spacer()
                Button {
                    renderShareImage()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
            }
            MosaicView(values: yearValues, days: yearDays, accent: AppTheme.accent)
                .frame(height: 112)
            HStack(spacing: 4) {
                Text("Less")
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
                RoundedRectangle(cornerRadius: 2).fill(Color(.systemGray5)).frame(width: 11, height: 11)
                ForEach([0.3, 0.55, 0.8, 1.0], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2).fill(AppTheme.accent.opacity(level)).frame(width: 11, height: 11)
                }
                Text("More")
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(petState.daysKept) pixels earned")
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .pixelCard()
        .sheet(item: Binding(get: { shareImage.map(ShareImageHolder.init) }, set: { shareImage = $0?.image })) { holder in
            ShareSheet(items: [holder.image])
        }
    }

    private var habitSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habits")
                .font(AppTheme.pixelTitle)
            if habits.isEmpty {
                Text("Add habits to see their story here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(habits, id: \.persistentID) { habit in
                NavigationLink {
                    HabitDetailView(habit: habit)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: habit.iconSymbol)
                            .foregroundStyle(Color(hex: habit.colorHex))
                            .frame(width: 34, height: 34)
                            .background(Color(hex: habit.colorHex).opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Text(habit.schedule.summary)
                                .font(AppTheme.pixelCaption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StreakBadge(habit: habit)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .pixelCard()
    }

    private var coachSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Coach")
                    .font(AppTheme.pixelTitle)
                Spacer()
                Text(AICoachService.shared.currentEngine.rawValue)
                    .font(AppTheme.pixelCaption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(Capsule())
            }
            weeklyCard
            monthlyCard
            if let aiError {
                Text(aiError)
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.orange)
            }
        }
        .pixelCard()
    }

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Weekly reflection", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    Task { await generateWeekly() }
                } label: {
                    if generatingWeekly {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.plain)
                .disabled(generatingWeekly)
            }
            if let post = weeklyPost {
                Text(post.content)
                    .font(.subheadline)
                Text("Generated by \(post.engine) · \(post.weekStart.formatted(.dateTime.month().day()))")
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
            } else {
                Text("A warm recap of your week — free, on-device when Apple Intelligence is available.")
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthlyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Monthly deep report", systemImage: "doc.text.magnifyingglass")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    if AICoachService.shared.currentEngine == .rules {
                        showPaywall = true
                    } else {
                        Task { await generateMonthly() }
                    }
                } label: {
                    if generatingMonthly {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.plain)
                .disabled(generatingMonthly)
            }
            if let report = monthlyReport {
                Text(report.content)
                    .font(.subheadline)
                Text(report.monthKey)
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Wins, patterns, and one focus — powered by Apple Intelligence or Cloud AI.")
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var yearValues: [Date: Double] {
        var result: [Date: Double] = [:]
        for score in overall {
            result[Calendar.current.startOfDay(for: score.date)] = score.score
        }
        return result
    }

    private var yearDays: [Date] {
        ShareRenderer.yearDays(end: .now)
    }

    private func reload() {
        habits = checkIns.activeHabits()
        overall = checkIns.overallScores()
        petState = checkIns.currentPetState()
        let context = checkIns.persistence.context
        if let latest = try? context.fetch(FetchDescriptor<WeeklyPost>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])) {
            weeklyPost = latest.first
        }
        if let latest = try? context.fetch(FetchDescriptor<MonthlyReport>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])) {
            monthlyReport = latest.first
        }
    }

    private func coachSummary() -> AICoachService.Summary {
        var summary = AICoachService.Summary()
        summary.habitCount = habits.count
        let streakCalculator = StreakCalculator()
        var bestName = ""
        var bestDays = 0
        for habit in habits {
            let info = streakCalculator.streak(for: habit, completions: checkIns.completions(for: habit))
            if info.best > bestDays {
                bestDays = info.best
                bestName = habit.name
            }
            summary.doneCount += info.total
        }
        summary.bestStreakName = bestName
        summary.bestStreakDays = bestDays
        summary.momentum = overall.suffix(7).map(\.score).reduce(0, +) / Double(max(overall.suffix(7).count, 1))
        var moods = 0.0
        var moodCount = 0
        if let entries = try? checkIns.persistence.context.fetch(FetchDescriptor<MoodEntry>()) {
            for entry in entries.suffix(7) {
                moods += Double(entry.level)
                moodCount += 1
            }
        }
        summary.moodAverage = moodCount > 0 ? moods / Double(moodCount) : nil
        summary.topHabitNames = habits.prefix(3).map(\.name)
        return summary
    }

    private func generateWeekly() async {
        generatingWeekly = true
        aiError = nil
        defer { generatingWeekly = false }
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        _ = await AICoachService.shared.generateWeeklyPost(context: modelContext,
                                                           weekStart: weekStart,
                                                           summary: coachSummary())
        if let error = AICoachService.shared.lastError {
            aiError = error
        }
        reload()
    }

    private func generateMonthly() async {
        generatingMonthly = true
        aiError = nil
        defer { generatingMonthly = false }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        _ = await AICoachService.shared.generateMonthlyReport(context: modelContext,
                                                              monthKey: formatter.string(from: .now),
                                                              summary: coachSummary())
        if let error = AICoachService.shared.lastError {
            aiError = error
        }
        reload()
    }

    private func renderShareImage() {
        let days = yearDays
        let values = yearValues
        let image = ShareRenderer.renderMosaic(values: values,
                                               days: days,
                                               title: "\(settings.petName)'s Year in Pixels",
                                               subtitle: "One pixel a day.",
                                               accentHex: AppTheme.accentHex)
        shareImage = image
    }
}

private struct ShareImageHolder: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct StreakBadge: View {
    var habit: Habit

    @EnvironmentObject private var checkIns: CheckInService
    @State private var streak = 0

    var body: some View {
        Text("\(streak) day streak")
            .font(AppTheme.pixelCaption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: habit.colorHex).opacity(0.12))
            .clipShape(Capsule())
            .foregroundStyle(Color(hex: habit.colorHex))
            .onAppear {
                streak = StreakCalculator().streak(for: habit, completions: checkIns.completions(for: habit)).current
            }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
