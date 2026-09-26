// Why: which months are folded is the view's own UI state, but the rules around it are not: the row above the
// months shows only when there are more than three (below that it costs more than it saves), and it offers
// "Collapse all" while any month is open. Kept pure so those rules are tested.
import Foundation

nonisolated struct MonthFolding: Equatable {
    /// With more months than this, the list gets its "Collapse all" / "Expand all" row.
    static let foldAllThreshold = 3

    /// Month ids, newest first.
    let ids: [String]
    let collapsed: Set<String>

    var showsFoldAllRow: Bool { ids.count > Self.foldAllThreshold }
    /// "4 months".
    var countLabel: String { ids.count.counted("month") }
    var isAnyOpen: Bool { ids.contains { !collapsed.contains($0) } }
    var foldAllTitle: String { isAnyOpen ? "Collapse all" : "Expand all" }

    /// The folded months after "Collapse all" or "Expand all".
    var afterFoldAll: Set<String> { isAnyOpen ? Set(ids) : [] }

    func isOpen(_ id: String) -> Bool { !collapsed.contains(id) }

    /// The folded months after tapping one month's header.
    func toggling(_ id: String) -> Set<String> {
        collapsed.symmetricDifference([id])
    }
}
