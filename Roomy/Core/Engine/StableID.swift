// Why: a group's id must not change between scans, or anything keyed on it (selection, scroll position)
// would reset. FNV-1a over the sorted member ids gives a short, stable string.
import Foundation

nonisolated enum StableID {
    static func make(from ids: [String]) -> String {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in ids.sorted().joined(separator: "|").utf8 {
            hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return String(hash, radix: 36)
    }
}
