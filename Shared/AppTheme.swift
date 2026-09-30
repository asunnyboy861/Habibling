import SwiftUI

public enum AppTheme {
    public static var accentHex: String {
        let theme = UserDefaults(suiteName: HabiblingSnapshot.appGroupId)?.string(forKey: "accentTheme")
            ?? UserDefaults.standard.string(forKey: "accentTheme") ?? "coral"
        switch theme {
        case "mint": return "#57C79A"
        case "ocean": return "#4E8FD9"
        case "lavender": return "#9B7EDE"
        case "sunset": return "#E07A4E"
        default: return "#F6968E"
        }
    }

    public static var accent: Color { Color(hex: accentHex) }

    public static let palette = ["#F6968E", "#57C79A", "#4E8FD9", "#9B7EDE", "#E07A4E", "#E8C547", "#4FB8D9", "#E05A6B"]

    public static let iconChoices = [
        "checkmark.circle", "figure.run", "book", "cup.and.saucer", "pill", "moon.stars",
        "drop", "heart", "brain.head.profile", "figure.walk", "pencil", "music.note",
        "camera", "banknote", "leaf", "fork.knife"
    ]

    #if os(iOS)
    public static var card: Color { Color(.secondarySystemGroupedBackground) }
    public static var page: Color { Color(.systemGroupedBackground) }
    #else
    public static var card: Color { Color.black.opacity(0.3) }
    public static var page: Color { Color.black.opacity(0.2) }
    #endif

    public static var pixelTitle: Font { .system(.headline, design: .monospaced) }
    public static var pixelCaption: Font { .system(.caption2, design: .monospaced) }

    public static func moodSymbol(_ level: Int) -> String {
        switch level {
        case 1: return "cloud.drizzle"
        case 2: return "cloud"
        case 3: return "cloud.sun"
        case 4: return "sun.min"
        default: return "sun.max.fill"
        }
    }

    public static var seasonSymbol: String {
        switch PetSeason.current(from: .now) {
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .fall: return "wind"
        case .winter: return "snowflake"
        case .holiday: return "gift"
        }
    }

    public static func stageProgressText(_ state: PetState) -> String {
        switch state.stage {
        case .egg: return "\(max(0, 3 - state.daysKept)) days to hatch"
        case .hatchling: return "\(max(0, 14 - state.daysKept)) days to juvenile"
        case .juvenile: return "\(max(0, 30 - state.daysKept)) days to adult"
        case .adult: return "Fully grown"
        }
    }
}

public struct CardBackground: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

public extension View {
    func pixelCard() -> some View {
        modifier(CardBackground())
    }
}
