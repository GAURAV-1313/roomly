// Why: the Welcome wash is alive but never busy: its gradient's ends drift a few percent on a slow sine, so it
// breathes without drawing the eye. The maths is pure so the bounds are tested; the view only feeds it the time.
import Foundation

nonisolated enum WelcomeDrift {
    /// One full drift, there and back.
    static let period = 12.0
    /// How far each end of the gradient moves, as a fraction of the page.
    static let amplitude = 0.04

    /// The gradient's start and end, as unit points, at `time` seconds.
    static func ends(at time: TimeInterval) -> (start: CGPoint, end: CGPoint) {
        let phase = sin(time / period * 2 * .pi) * amplitude
        return (CGPoint(x: 0.5 + phase, y: 0 + phase), CGPoint(x: 0.5 - phase, y: 1 - phase))
    }
}
