// Why: which root a launch shows is one small rule, kept pure so it is tested: the full onboarding the first time,
// then the short launch intro on every later launch, then the dashboard. Finishing onboarding goes straight to the
// dashboard, never through the intro, and with Reduce Motion the intro is skipped entirely.
import Foundation

nonisolated enum LaunchRoot: Sendable, Equatable {
    case onboarding
    case intro
    case dashboard

    /// The UserDefaults key saying onboarding was finished.
    static let didOnboardKey = "didOnboard"

    /// `isIntroDue`: onboarding was already finished when this launch began, and the intro hasn't ended yet.
    init(didOnboard: Bool, isIntroDue: Bool, reduceMotion: Bool) {
        if !didOnboard {
            self = .onboarding
        } else if isIntroDue && !reduceMotion {
            self = .intro
        } else {
            self = .dashboard
        }
    }
}
