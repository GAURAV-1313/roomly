// Why: the merge preview and the merge must combine values identically, or the card people approved is not
// the card that gets written. Both call this one function. The kept card's own values are never dropped,
// even two spellings of one number, because a merge may only add to the card that stays. Each added value
// remembers which other card it came from, so the preview can say "from card 2" instead of a vague "added".
import Foundation

nonisolated struct MergeUnionEntry<Value> {
    let value: Value
    /// The position in `extras` of the card this value came from; nil for the kept card's own values.
    let extraIndex: Int?

    /// True when the value comes from a card other than the one being kept.
    var isAdded: Bool { extraIndex != nil }
}

nonisolated enum MergeUnion {
    /// Every kept value in order, then each other card's values whose key has not been seen yet.
    static func merge<Value>(
        kept: [Value], extras: [[Value]], key: (Value) -> String
    ) -> [MergeUnionEntry<Value>] {
        var seen = Set(kept.map(key))
        var merged = kept.map { MergeUnionEntry(value: $0, extraIndex: nil) }
        for (index, values) in extras.enumerated() {
            for value in values where seen.insert(key(value)).inserted {
                merged.append(MergeUnionEntry(value: value, extraIndex: index))
            }
        }
        return merged
    }
}
