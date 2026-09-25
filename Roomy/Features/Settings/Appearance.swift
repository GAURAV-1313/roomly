// Why: some people want Roomy light or dark whatever the phone says. The choice is one small value kept in
// UserDefaults (already declared in the privacy manifest) and applied once at the app's root, so every screen,
// sheet and onboarding follow it. System is the default and means "no preference": nil, not a guess at the
// phone's current setting, so Roomy keeps following the phone when it changes.
import SwiftUI

nonisolated enum Appearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    /// The UserDefaults key the choice is stored under.
    static let storageKey = "appearance"

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// What the root asks for: nil lets the phone's own setting decide.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
