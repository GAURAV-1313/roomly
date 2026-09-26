// Why: the launch intro has one timing of its own, the crossfade into the dashboard. It lives beside the shared
// motion tokens, in its own file, so the intro's beat list and its test read a name instead of a number.
import SwiftUI

nonisolated extension Motion {
    /// Intro → dashboard: one root crossfade, as long as onboarding's hand-off, in seconds.
    static let introFade = 0.35
    static let introHandOff: Animation = .easeInOut(duration: introFade)
}
