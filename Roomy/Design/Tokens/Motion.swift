// Why: motion is calm, short and moves one thing at a time (Figma "Motion spec v5"). Every curve and delay lives
// here so views never hand-write timing, and every animation has one Reduce Motion fallback: a quick fade with no
// offset. Nonisolated because these are plain values that views on any actor, and tests, may read.
import SwiftUI

nonisolated enum Motion {
    /// Fades, crossfades and colour: skeleton to content, thumbnails, the result swap.
    static let quick: Animation = .easeOut(duration: 0.2)
    /// Moves, inserts and page changes: the dashboard fade-up, the Review capsule, notice rows.
    static let standard: Animation = .smooth(duration: 0.35)
    /// Size and width changes, and numbers rolling.
    static let snappy: Animation = .snappy(duration: 0.3)
    /// The result pin dropping onto the bar, and nothing else.
    static let settle: Animation = .spring(response: 0.4, dampingFraction: 0.75)
    /// A progress bar's fill following real counts.
    static let progress: Animation = .easeOut(duration: 0.3)
    /// The pin and its label turning from pending to freed, once free space was measured.
    static let reward: Animation = .easeInOut(duration: 0.4)

    /// The selection check's pop: it starts at `popScale` and springs to full size.
    static let pop = Spring(response: 0.25, dampingRatio: 0.7)
    static let popScale: CGFloat = 0.8

    /// How far a block rises while it fades in on the dashboard's first appearance.
    static let rise: CGFloat = 12
    /// The gap between blocks fading in, and the most blocks that wait for one another.
    static let stagger = 0.05
    static let staggerLimit = 6

    /// The usage bar's ticks light up this far apart, starting `sweepDelay` after the card, the whole sweep
    /// taking at most `sweepLimit`.
    static let tickStep = 0.008
    static let sweepDelay = 0.1
    static let sweepLimit = 0.5

    /// The result pin drops this far, this long after the card appears.
    static let pinDrop: CGFloat = 12
    static let pinDelay = 0.2

    /// A skeleton waits this long before it shows, so a wait under it shows nothing at all.
    static let loadingDelay: Duration = .milliseconds(300)
    /// Reading contacts is usually faster than photos, so its card waits a little longer.
    static let contactsLoadingDelay: Duration = .milliseconds(400)

    /// When a staggered block starts: `stagger` apart by position, capped at `staggerLimit` blocks.
    static func staggerDelay(for index: Int) -> Double {
        Double(min(max(index, 0), staggerLimit)) * stagger
    }

    /// When a usage tick lights up: `tickStep` apart, squeezed so `used` ticks finish within `sweepLimit`.
    static func tickDelay(at index: Int, of used: Int) -> Double {
        let step = used > 0 ? min(tickStep, sweepLimit / Double(used)) : tickStep
        return sweepDelay + Double(max(index, 0)) * step
    }
}
