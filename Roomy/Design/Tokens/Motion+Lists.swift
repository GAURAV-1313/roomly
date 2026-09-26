// Why: opening and folding a month is the one new motion on the category lists (Figma "MonthDisclosureHeader
// v5"). Its timing lives with the other motion tokens, in its own file, and like them it has one Reduce Motion
// fallback: the chevron and the rows only crossfade, with `Motion.quick`.
import SwiftUI

nonisolated extension Motion {
    /// A month's rows sliding in under its header, or folding away.
    static let disclose: Animation = standard
    /// The chevron's turn, a little quicker than the rows so it leads them.
    static let chevronTurn: Animation = snappy
    /// How far the chevron turns when its month opens: right-pointing to down-pointing.
    static let chevronOpenAngle: Angle = .degrees(90)
}
