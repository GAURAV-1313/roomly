// Why: a group or a month can be wholly, partly or not at all in the basket, and its toggle must say which:
// two booleans ("any selected", "all selected") could disagree, so the three cases are one value, derived
// from counts in one place and tested.
import Foundation

nonisolated enum SelectionState: Sendable, Equatable {
    /// Nothing is selected.
    case off
    /// Some, but not all, are selected.
    case mixed
    /// Everything is selected.
    case on

    /// `selected` of `total` items are in the basket. An empty set is off, so it never reads as selected.
    init(selected: Int, of total: Int) {
        if total <= 0 || selected <= 0 {
            self = .off
        } else if selected >= total {
            self = .on
        } else {
            self = .mixed
        }
    }
}
