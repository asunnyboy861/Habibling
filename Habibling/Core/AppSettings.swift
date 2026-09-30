import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    @Published var petName: String {
        didSet { defaults.set(petName, forKey: "petName") }
    }
    @Published var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: "onboardingCompleted") }
    }
    @Published var petCreatedAt: Date {
        didSet { defaults.set(petCreatedAt.timeIntervalSince1970, forKey: "petCreatedAt") }
    }
    @Published var lastShownStage: Int {
        didSet { defaults.set(lastShownStage, forKey: "lastShownStage") }
    }
    @Published var accentTheme: String {
        didSet {
            defaults.set(accentTheme, forKey: "accentTheme")
            (UserDefaults(suiteName: HabiblingSnapshot.appGroupId) ?? .standard).set(accentTheme, forKey: "accentTheme")
        }
    }

    var hasPetAnchor: Bool {
        defaults.object(forKey: "petCreatedAt") != nil
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        petName = defaults.string(forKey: "petName") ?? "Momo"
        onboardingCompleted = defaults.bool(forKey: "onboardingCompleted")
        let stored = defaults.double(forKey: "petCreatedAt")
        petCreatedAt = stored > 0 ? Date(timeIntervalSince1970: stored) : .now
        lastShownStage = defaults.integer(forKey: "lastShownStage")
        accentTheme = defaults.string(forKey: "accentTheme") ?? "coral"
    }

    static var themeHex: String {
        switch shared.accentTheme {
        case "mint": "#57C79A"
        case "ocean": "#4E8FD9"
        case "lavender": "#9B7EDE"
        case "sunset": "#E07A4E"
        default: "#F6968E"
        }
    }
}
