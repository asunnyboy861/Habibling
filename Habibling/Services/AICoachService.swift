import Foundation
import SwiftData

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
enum AppleIntelligenceEngine {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    static func respond(instructions: String, prompt: String) async throws -> String {
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        return response.content
    }
}
#endif

@MainActor
final class AICoachService: ObservableObject {
    static let shared = AICoachService()

    @Published var isGenerating = false
    @Published var lastError: String?

    enum Engine: String {
        case apple = "Apple Intelligence"
        case cloud = "Cloud AI"
        case rules = "Habibling Coach"
    }

    var currentEngine: Engine {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), AppleIntelligenceEngine.isAvailable { return .apple }
        #endif
        if PurchaseManager.shared.isCloudPlus { return .cloud }
        return .rules
    }

    var deepReportsAvailable: Bool {
        currentEngine == .cloud || currentEngine == .apple
    }

    struct Summary {
        var habitCount = 0
        var dueCount = 0
        var doneCount = 0
        var bestStreakName = ""
        var bestStreakDays = 0
        var momentum = 0.0
        var moodAverage: Double?
        var topHabitNames: [String] = []
    }

    func weeklySummaryText(_ summary: Summary) -> String {
        let rate = summary.dueCount > 0 ? Int(round(Double(summary.doneCount) / Double(summary.dueCount) * 100)) : 0
        var lines: [String] = []
        lines.append("Habits tracked: \(summary.habitCount)")
        lines.append("Check-ins this week: \(summary.doneCount) of \(summary.dueCount) scheduled (\(rate)%)")
        lines.append("Momentum score: \(Int(summary.momentum * 100)) out of 100")
        if !summary.bestStreakName.isEmpty {
            lines.append("Strongest streak: \(summary.bestStreakName) — \(summary.bestStreakDays) days")
        }
        if let mood = summary.moodAverage {
            let moodWord = mood >= 4 ? "great" : mood >= 3 ? "steady" : "low"
            lines.append("Average mood: \(String(format: "%.1f", mood)) of 5 (feeling \(moodWord))")
        }
        if !summary.topHabitNames.isEmpty {
            lines.append("Most consistent: \(summary.topHabitNames.prefix(3).joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }

    func monthlySummaryText(_ summary: Summary, monthKey: String) -> String {
        let rate = summary.dueCount > 0 ? Int(round(Double(summary.doneCount) / Double(summary.dueCount) * 100)) : 0
        return """
        Month: \(monthKey)
        Habits tracked: \(summary.habitCount)
        Check-ins: \(summary.doneCount) of \(summary.dueCount) (\(rate)%)
        Momentum: \(Int(summary.momentum * 100))/100
        Best streak: \(summary.bestStreakName) \(summary.bestStreakDays) days
        Top habits: \(summary.topHabitNames.prefix(4).joined(separator: ", "))
        """
    }

    func generateWeeklyPost(context: ModelContext, weekStart: Date, summary: Summary) async -> WeeklyPost? {
        isGenerating = true
        lastError = nil
        defer { isGenerating = false }
        let content: String
        switch currentEngine {
        case .apple:
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                content = (try? await AppleIntelligenceEngine.respond(
                    instructions: Self.coachInstructions,
                    prompt: "Write a warm weekly reflection for this habit tracker user. 90 words max. Never guilt, never punish, celebrate small wins.\n\n\(weeklySummaryText(summary))")) ?? ""
                if content.isEmpty { lastError = "Apple Intelligence is unavailable right now." }
            } else {
                content = ""
            }
            #else
            content = ""
            #endif
        case .cloud:
            content = (try? await GLMCloudService.shared.complete(messages: [
                ["role": "system", "content": Self.coachInstructions],
                ["role": "user", "content": "Write a warm weekly reflection for this habit tracker user. 120 words max. Include one concrete suggestion for next week.\n\n\(weeklySummaryText(summary))"]
            ], maxTokens: 4096)) ?? ""
            if content.isEmpty { lastError = "Cloud AI is unavailable. Check your Cloud+ subscription and connection." }
        case .rules:
            content = Self.rulesWeeklyPost(summary)
        }
        guard !content.isEmpty else { return nil }
        let engine = currentEngine == .rules ? Engine.rules.rawValue : currentEngine.rawValue
        let post = WeeklyPost(weekStart: weekStart, content: content, engine: engine)
        context.insert(post)
        try? context.save()
        return post
    }

    func generateMonthlyReport(context: ModelContext, monthKey: String, summary: Summary) async -> MonthlyReport? {
        isGenerating = true
        lastError = nil
        defer { isGenerating = false }
        let content: String
        switch currentEngine {
        case .apple:
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                content = (try? await AppleIntelligenceEngine.respond(
                    instructions: Self.coachInstructions,
                    prompt: "Write a deep monthly report for this habit tracker user. Structure: Wins, Patterns, One Focus for next month. 180 words max. Never guilt.\n\n\(monthlySummaryText(summary, monthKey: monthKey))")) ?? ""
                if content.isEmpty { lastError = "Apple Intelligence is unavailable right now." }
            } else {
                content = ""
            }
            #else
            content = ""
            #endif
        case .cloud:
            content = (try? await GLMCloudService.shared.complete(messages: [
                ["role": "system", "content": Self.coachInstructions],
                ["role": "user", "content": "Write a deep monthly report for this habit tracker user. Structure it with these sections: Wins, Patterns, One Focus for next month. 200 words max. Reference the real numbers.\n\n\(monthlySummaryText(summary, monthKey: monthKey))"]
            ], maxTokens: 4096)) ?? ""
            if content.isEmpty { lastError = "Cloud AI is unavailable. Check your Cloud+ subscription and connection." }
        case .rules:
            content = Self.rulesMonthlyReport(summary, monthKey: monthKey)
        }
        guard !content.isEmpty else { return nil }
        let report = MonthlyReport(monthKey: monthKey, content: content)
        context.insert(report)
        try? context.save()
        return report
    }

    func encouragement(summary: Summary) async -> String {
        switch currentEngine {
        case .apple:
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                if let text = try? await AppleIntelligenceEngine.respond(
                    instructions: "You are Habibling's pet-side coach. One short playful sentence (max 18 words) a pixel pet might say. Warm, never guilt-based.",
                    prompt: weeklySummaryText(summary)) , !text.isEmpty {
                    return text
                }
            }
            #endif
            return Self.rulesEncouragement(summary)
        case .cloud, .rules:
            return Self.rulesEncouragement(summary)
        }
    }

    private static let coachInstructions = """
    You are the Habibling coach inside a pixel-pet habit tracker. Your voice is warm, playful, and jargon-free.
    Hard rules: never shame, never mention failing or broken streaks, never tell the user they missed something.
    Frame gaps as rest. Celebrate tiny wins with specifics from the data. Use plain short sentences. No emojis, no markdown headers, no bullet symbols.
    """

    static func rulesEncouragement(_ summary: Summary) -> String {
        let rate = summary.dueCount > 0 ? Double(summary.doneCount) / Double(summary.dueCount) : 0
        let pool: [String]
        if rate >= 0.8 {
            pool = [
                "Your pet is doing a happy dance — today is fully lit!",
                "Every pixel glowing. Your pet is proud of you.",
                "Full board! Your pet is napping with a big smile.",
                "A perfect little day. Your pet is beaming."
            ]
        } else if rate >= 0.4 {
            pool = [
                "Good progress today — your pet is wiggling with joy.",
                "Pixels are filling in. Slow and steady wins.",
                "Your pet likes where this is going.",
                "Momentum is building. Your pet can feel it."
            ]
        } else {
            pool = [
                "One pixel is all it takes. Your pet is patient.",
                "No rush — your pet is napping until you're ready.",
                "A tiny step still moves the mosaic forward.",
                "Your pet isn't going anywhere. Neither is your progress."
            ]
        }
        return pool.randomElement() ?? "One pixel a day."
    }

    static func rulesWeeklyPost(_ summary: Summary) -> String {
        let rate = summary.dueCount > 0 ? Int(round(Double(summary.doneCount) / Double(summary.dueCount) * 100)) : 0
        var lines: [String] = []
        lines.append("This week you checked in \(summary.doneCount) times across \(summary.habitCount) habits — that's \(rate)% of everything you planned.")
        if summary.bestStreakDays > 0 && !summary.bestStreakName.isEmpty {
            lines.append("Your \(summary.bestStreakName) streak reached \(summary.bestStreakDays) days, and that consistency is exactly what your pet feeds on.")
        }
        if let mood = summary.moodAverage {
            let moodLine = mood >= 3.5 ? "Your mood averaged \(String(format: "%.1f", mood)) out of 5 — your best habits and your mood are keeping each other company."
                : "Your mood averaged \(String(format: "%.1f", mood)) out of 5 this week. Rest counts as progress here, and your pet never stops waiting for you."
            lines.append(moodLine)
        }
        lines.append(rate >= 60
            ? "Next week, keep the same rhythm. Your pet only needs one pixel a day."
            : "Next week, pick your smallest habit and protect just that one. One pixel a day is still a masterpiece in progress.")
        return lines.joined(separator: " ")
    }

    static func rulesMonthlyReport(_ summary: Summary, monthKey: String) -> String {
        let rate = summary.dueCount > 0 ? Int(round(Double(summary.doneCount) / Double(summary.dueCount) * 100)) : 0
        let focus = summary.topHabitNames.first ?? summary.bestStreakName
        return """
        Wins: You completed \(summary.doneCount) check-ins this month (\(rate)% of your plan). \
        \(summary.bestStreakDays > 0 && !summary.bestStreakName.isEmpty ? "Your \(summary.bestStreakName) streak hit \(summary.bestStreakDays) days — a genuine highlight." : "You kept showing up, and that consistency matters more than any single number.")

        Patterns: \(summary.topHabitNames.isEmpty ? "Your habit mix is still forming." : "Your strongest routines were \(summary.topHabitNames.prefix(3).joined(separator: ", ")).") \
        Momentum sits at \(Int(summary.momentum * 100)) out of 100, which means the pace you chose is \(summary.momentum >= 0.6 ? "sustainable" : "asking for a little more rest").

        One Focus: \(focus.isEmpty ? "Pick one habit to carry through next month." : "Carry \(focus) into next month untouched — let it be your anchor pixel.")
        """
    }
}
