// Why: the line under the title says how many merges there are and what they do to the address book —
// "3 groups · 7 cards → 3" — so the size of the job is clear before anything is picked. Kept pure so the counts
// are tested.
import Foundation

nonisolated struct ContactsSummary: Equatable {
    let groupCount: Int
    /// Every card in every group: the kept ones plus the ones folded into them.
    let cardCount: Int

    init(groups: [ContactGroup], extraCardCount: Int) {
        groupCount = groups.count
        cardCount = groups.count + extraCardCount
    }

    /// "3 groups · 7 cards → 3".
    var subtitle: String { "\(groupCount.counted("group")) · \(cardCount.counted("card")) → \(groupCount)" }
}
