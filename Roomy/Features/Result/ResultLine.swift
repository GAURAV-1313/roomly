// Why: a partial result reads as a list, not a paragraph: every sentence past the lead is its own row, and each
// row carries what kind of outcome it names so its icon can say it at a glance. The kinds are outcomes the
// report measured, never new facts; none of them is an error the person caused, so none is drawn in red.
import Foundation

nonisolated struct ResultLine: Equatable, Identifiable {
    enum Kind: Equatable {
        /// Photos stopped early: declined, timed out, failed, or no access.
        case stopped
        /// Items that weren't in the library Roomy can see.
        case notFound
        /// The last photo of a similar group, kept.
        case kept
        /// Items that couldn't run safely and are still in Review.
        case held
        /// Contact groups that are now one card each.
        case merged
        /// Contact groups left as they were: changed, refused or failed.
        case contactsLeft
    }

    let kind: Kind
    let text: String

    var id: String { text }
}
