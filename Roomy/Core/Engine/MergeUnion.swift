// Why: the merge preview and the merge must combine values identically, or the card people approved is not
// the card that gets written. Both call this one function. The kept card's own values are never dropped,
// even two spellings of one number, because a merge may only add to the card that stays.
import Foundation

nonisolated enum MergeUnion {
    /// Every kept value in order, then each other card's values whose key has not been seen yet.
    static func merge<Value>(
        kept: [Value], extras: [[Value]], key: (Value) -> String
    ) -> [(value: Value, isAdded: Bool)] {
        var seen = Set(kept.map(key))
        var merged = kept.map { (value: $0, isAdded: false) }
        for values in extras {
            for value in values where seen.insert(key(value)).inserted {
                merged.append((value: value, isAdded: true))
            }
        }
        return merged
    }
}
