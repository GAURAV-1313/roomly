// Why: every launch after onboarding opens with the Welcome story's heart, shortened to about two seconds: the
// nearly full capsule turns red and shakes, then sweeps down to green as Roomy lands, and the app crossfades to
// the dashboard. The beats and their times are a pure list, reusing `WelcomeBeat`, so the order, the length and
// "no promise, no truths" are unit-tested; the view only runs the list. The scan has already started in
// `AppState`, so the intro costs no time.
import Foundation

nonisolated enum LaunchIntroBeat: Sendable, Equatable, CaseIterable {
    case signal
    case drop
    case sweep
    case pleased
    /// The hand-off to the dashboard.
    case finish

    /// When the beat starts after the intro appears. The red signal and its shake play out before the sweep, and
    /// Roomy starts falling just before it so he lands while the fill is cleaned down.
    var start: Duration {
        switch self {
        case .signal: .milliseconds(200)
        case .drop: .milliseconds(850)
        case .sweep: .milliseconds(950)
        case .pleased: .milliseconds(1600)
        case .finish: .milliseconds(2100)
        }
    }

    /// The Welcome beat this plays on the shared stage; nil for the hand-off.
    var welcomeBeat: WelcomeBeat? {
        switch self {
        case .signal: .signal
        case .drop: .drop
        case .sweep: .sweep
        case .pleased: .pleased
        case .finish: nil
        }
    }

    /// The beats in the order they play.
    static let beats = allCases.sorted { $0.start < $1.start }
}
