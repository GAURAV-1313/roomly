// Why: onboarding is three pages in a fixed order, and the rules for moving between them are product rules, not
// layout: Skip jumps to Permissions and never past it, Back never leaves the first page, and only Permissions
// offers "Not now". Keeping them in a pure enum means they are tested instead of scattered through the view.
import Foundation

nonisolated enum OnboardingPage: Int, CaseIterable, Sendable {
    case welcome
    case howItWorks
    case permissions

    /// The page Continue opens; nil on the last page, where Continue ends onboarding instead.
    var next: OnboardingPage? { OnboardingPage(rawValue: rawValue + 1) }

    var previous: OnboardingPage? { OnboardingPage(rawValue: rawValue - 1) }

    /// Skip lands on Permissions, so Photos is always offered before the dashboard.
    var skipTarget: OnboardingPage { .permissions }

    var canGoBack: Bool { previous != nil }
    var canSkip: Bool { self != skipTarget }
    /// Only the last page lets the person leave without granting Photos.
    var offersNotNow: Bool { self == .permissions }
}
