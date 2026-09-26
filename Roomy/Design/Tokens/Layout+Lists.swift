// Why: the category lists (Figma "Device test fixes": SelectToggle v5, MonthDisclosureHeader v5 and the fixed
// ContactGroupCard) bring a few measures of their own. They live in their own file, beside the shared tokens,
// so the list screens use names instead of numbers and the shared token files stay untouched.
import SwiftUI

extension Layout {
    /// The gap between a small glyph, tag or note and the words beside it: a select toggle's circle, a
    /// member card's "kept", a merged value's "from card 2".
    static let inlineGap: CGFloat = 6
    /// The box the month chevron turns in, so the title never shifts as it rotates.
    static let monthChevron: CGFloat = 16
    /// How tall the hairline between a month's disclosure area and its toggle stands.
    static let monthDividerHeight: CGFloat = 28
    /// The gap between the month chevron and the month's title.
    static let monthChevronGap: CGFloat = 10
    /// The numbered circle before each card in a duplicate-contacts group.
    static let memberNumber: CGFloat = 22
    /// The gap after that circle; the separators between cards start past both.
    static let memberNumberGap: CGFloat = 10
    /// The small "from card 2" tag on a merged value's label line.
    static let sourceTagPadding = EdgeInsets(top: 2, leading: 7, bottom: 2, trailing: 7)
    /// A reason chip's height padding, shared by the neutral and tinted chips.
    static let chipVerticalPadding: CGFloat = 3
}
