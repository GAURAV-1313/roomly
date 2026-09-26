// Why: a group can hold up to four cards, or more when every card carries one name, and listing them all
// would push the merge result off screen. The first three show; the rest wait behind "+2 more cards", which
// opens in place. Kept pure so the cut and the words are tested.
import Foundation

nonisolated struct MemberList: Equatable {
    /// Cards shown before the "more" row.
    static let visibleLimit = 3

    let members: [MergeMember]
    let isExpanded: Bool

    var visible: [MergeMember] {
        isExpanded ? members : Array(members.prefix(Self.visibleLimit))
    }

    /// "+2 more cards"; nil when every card already shows.
    var moreLabel: String? {
        let hidden = members.count - visible.count
        guard hidden > 0 else { return nil }
        return "+\(hidden.counted("more card", plural: "more cards"))"
    }
}
