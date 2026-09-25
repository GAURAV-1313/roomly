// Why: Review must let every item that will go be seen and taken out one by one, yet a selection of thousands
// can't open as one endless list. A section shows its first rows, then offers all of them; the rule is pure
// and tested so no item can end up behind an "and N more" that can't be opened.
import Foundation

nonisolated struct ReviewSectionRows: Equatable {
    /// Rows a section shows before "Show all".
    static let collapsedCount = 3

    let total: Int
    var isExpanded = false

    var visibleCount: Int { isExpanded ? total : min(total, Self.collapsedCount) }

    /// The control that opens or closes the rest; nil when every row already shows.
    var toggleTitle: String? {
        guard total > Self.collapsedCount else { return nil }
        return isExpanded ? "Show fewer" : "Show all \(total.formatted())"
    }
}
