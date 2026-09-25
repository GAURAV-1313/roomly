// Why: groups need both membership and the weakest reason any two members were linked, because a label must
// hold for every photo in the group: a copy plus a different shot taken 3 s later is "taken 3s apart", not
// "exact duplicate". The same two photos can be linked more than once (an exact copy is often also taken in
// the same moment), so each pair keeps its STRONGEST evidence, and the group's label is the weakest over its
// pairs. The links themselves are kept too, so a group that later loses a photo can tell whether it holds.
import Foundation

nonisolated struct Links {
    /// One connected group: its photos and the links between them, as indices.
    struct Component {
        var members: [Int]
        var pairs: [(Int, Int)]
    }

    private struct PairKey: Hashable {
        let low: Int
        let high: Int

        init(_ first: Int, _ second: Int) {
            low = min(first, second)
            high = max(first, second)
        }
    }

    private var unionFind: UnionFind
    /// The strongest reason seen for each linked pair.
    private var reasonByPair: [PairKey: SimilarityReason] = [:]
    /// Linked pairs in the order they were first seen, each once.
    private var pairs: [(Int, Int)] = []
    private let count: Int

    init(count: Int) {
        self.count = count
        unionFind = UnionFind(count: count)
    }

    mutating func link(_ first: Int, _ second: Int, reason: SimilarityReason) {
        unionFind.union(first, second)
        let key = PairKey(first, second)
        guard let existing = reasonByPair[key] else {
            reasonByPair[key] = reason
            pairs.append((first, second))
            return
        }
        if existing.isWeaker(than: reason) {
            reasonByPair[key] = reason
        }
    }

    /// Connected groups of two or more photos, each with the links inside it.
    mutating func components() -> [Component] {
        var byRoot: [Int: Component] = [:]
        for index in 0..<count {
            byRoot[unionFind.find(index), default: Component(members: [], pairs: [])].members.append(index)
        }
        for pair in pairs {
            byRoot[unionFind.find(pair.0)]?.pairs.append(pair)
        }
        return byRoot.values.filter { $0.members.count > 1 }.sorted { $0.members[0] < $1.members[0] }
    }

    /// The weakest of the pairs' strongest reasons: the label that holds for every link in the group.
    func weakestReason(in component: Component) -> SimilarityReason {
        component.pairs.compactMap { reasonByPair[PairKey($0.0, $0.1)] }.max { $1.isWeaker(than: $0) }
            ?? .moment(seconds: 0)
    }
}
