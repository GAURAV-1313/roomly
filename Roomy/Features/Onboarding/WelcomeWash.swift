// Why: the Welcome page sits on the dashboard's navy-to-parchment wash, full bleed, so the first screen already
// looks like the app it opens into. The wash drifts slowly, which is the only thing still moving at rest besides
// Roomy's blink. The drift stops under Reduce Motion and in Low Power Mode, where a decorative animation is not
// worth the battery.
import SwiftUI

struct WelcomeWash: View {
    /// The drift is slow, so a modest frame rate is indistinguishable and cheaper.
    private static let frameInterval = 1.0 / 30

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        TimelineView(.animation(minimumInterval: Self.frameInterval, paused: reduceMotion || isLowPower)) { context in
            let ends = WelcomeDrift.ends(at: context.date.timeIntervalSinceReferenceDate)
            LinearGradient(
                stops: [
                    .init(color: RoomyColor.heroTintTop, location: 0),
                    .init(color: RoomyColor.heroTintBottom, location: Self.parchmentStop),
                    .init(color: RoomyColor.bg, location: Self.washEnd),
                ],
                startPoint: UnitPoint(x: ends.start.x, y: ends.start.y),
                endPoint: UnitPoint(x: ends.end.x, y: ends.end.y))
        }
        .task { await followLowPowerMode() }
        .accessibilityHidden(true)
    }

    /// Where the wash has turned to parchment, and where it has become the page colour, which the pinned buttons
    /// below sit on (Figma: 70% and 100% of the 560-point wash on an 852-point page).
    private static let parchmentStop = 0.46
    private static let washEnd = 0.66

    private func followLowPowerMode() async {
        for await _ in NotificationCenter.default.notifications(named: .NSProcessInfoPowerStateDidChange) {
            guard !Task.isCancelled else { return }
            isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
}
