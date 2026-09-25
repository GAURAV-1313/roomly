// Why: the onboarding pages (Figma "v5 — Onboarding, loading & motion") have measures and timings of their own:
// the Welcome stage, the storage capsule, the step rail, the page dots and the permission cards. They live here,
// in one file beside the shared tokens, so the pages use names instead of numbers and the shared files stay
// untouched by this flow.
import SwiftUI

extension Layout {
    /// Roomy on the Welcome stage, and the soft blurred shadow he lands on.
    static let welcomeMascot: CGFloat = 204
    /// At accessibility text sizes Roomy steps back so the words keep the room.
    static let welcomeMascotLarge: CGFloat = 148
    static let welcomeShadow = CGSize(width: 132, height: 14)
    static let welcomeShadowBlur: CGFloat = 6
    /// How far the shadow tucks up under Roomy's feet.
    static let welcomeShadowLift: CGFloat = 19
    /// The "iPhone storage" capsule (Figma "StorageCapsule v5"): its width and the fill's height.
    static let capsuleWidth: CGFloat = 184
    static let capsuleHeight: CGFloat = 8
    /// The truths' glyphs beside their footnote text.
    static let truthSpacing: CGFloat = 5

    /// Page dots (Figma "PageDots v5"): a dot, and the wider current dot.
    static let pageDot: CGFloat = 8
    static let pageDotCurrent: CGFloat = 20

    /// The step rail on How it works: the soft circle with its glyph, the line joining circles, the gap to the
    /// text and the text's insets that line the title up with the circle's centre.
    static let railNode: CGFloat = 32
    static let railGlyph: CGFloat = 16
    static let railLine: CGFloat = 2
    static let railGap: CGFloat = 14
    static let railTextTop: CGFloat = 5
    static let railTextBottom: CGFloat = 18

    /// Roomy on the permissions hero card.
    static let permissionsMascot: CGFloat = 72
    /// The "Required" / "Optional" tag on a permission card.
    static let tagPadding = EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
}

nonisolated extension RoomyColor {
    /// The shadow Roomy lands on; a plain dark tint reads on the wash in light and dark.
    static let groundShadow = Color.black.opacity(0.35)
}

nonisolated extension Motion {
    /// The Welcome story's beats (Figma storyboard 147:12369). Roomy falls this far as he drops in.
    static let welcomeDrop: CGFloat = 120
    /// The drop itself and the spring that lands it.
    static let dropDuration = 0.5
    static let dropSpring = Spring(response: 0.45, dampingRatio: 0.62)
    /// Roomy fades in over the first part of the fall.
    static let dropFade = 0.15
    /// The landing squash: how flat, how fast in, how fast back.
    static let squashScale: CGFloat = 0.94
    static let squashIn = 0.08
    static let squashOut = 0.14
    /// The signal: the fill warms into red, and the capsule shakes this far, for two cycles.
    static let signalWarm: Animation = .easeOut(duration: 0.25)
    static let shakeDistance: CGFloat = 3
    static let shakeStep = 0.064
    /// The clean-down sweep of the fill, and the promise and truths rising in.
    static let sweep: Animation = .smooth(duration: 0.7)
    static let promiseRise: Animation = .smooth(duration: 0.4)
    static let promiseOffset: CGFloat = 10
    static let truthRise: Animation = .smooth(duration: 0.35)
    static let truthOffset: CGFloat = 8
    static let truthStagger = 0.12
    /// Onboarding → dashboard: one root crossfade.
    static let handOff: Animation = .easeInOut(duration: 0.35)
}
