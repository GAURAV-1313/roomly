// Why: Apple's Dynamic Type scale (unchanged in iOS 26) plus one display size for the number that matters.
// Using text styles, not point sizes, keeps every label scaling with the person's text size setting.
import SwiftUI

enum RoomyFont {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title1 = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.bold)
    static let title3 = Font.title3.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let subheadline = Font.subheadline
    static let subheadlineSemibold = Font.subheadline.weight(.semibold)
    static let footnote = Font.footnote
    static let footnoteSemibold = Font.footnote.weight(.semibold)
    static let caption = Font.caption
    /// The number that matters: Large Title size, rounded, with monospaced digits so a counting number never
    /// jitters. A text style, so it grows with the person's text size.
    static let hero = Font.system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit()
    /// The amount on the storage card's footer: what can be cleaned up.
    static let amount = Font.system(.title2, design: .rounded, weight: .bold).monospacedDigit()
}
