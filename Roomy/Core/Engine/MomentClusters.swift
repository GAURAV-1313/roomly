// Why: "the same moment" must mean a short span, not a chain. Checking only each pair's gap lets a walk with a
// shot every 45 s chain into one 20-minute group, so moments are tracked as clusters with their first and last
// time, and two moments join only while the joined one still fits in the window. Its span labels the group.
import Foundation

nonisolated struct MomentClusters {
    private var unionFind: UnionFind
    /// First and last creation time of each cluster, stored under its union-find root.
    private var earliest: [Date?]
    private var latest: [Date?]

    init(dates: [Date?]) {
        unionFind = UnionFind(count: dates.count)
        earliest = dates
        latest = dates
    }

    /// Joins the moments of two photos when the result spans at most `window`. Returns that span in whole
    /// seconds, or nil when either photo has no date or the join would stretch the moment past the window.
    mutating func join(_ first: Int, _ second: Int, within window: TimeInterval) -> Int? {
        let firstRoot = unionFind.find(first)
        let secondRoot = unionFind.find(second)
        guard
            let firstStart = earliest[firstRoot], let firstEnd = latest[firstRoot],
            let secondStart = earliest[secondRoot], let secondEnd = latest[secondRoot]
        else { return nil }
        let start = min(firstStart, secondStart)
        let end = max(firstEnd, secondEnd)
        let span = end.timeIntervalSince(start)
        guard span <= window else { return nil }
        unionFind.union(firstRoot, secondRoot)
        let root = unionFind.find(first)
        earliest[root] = start
        latest[root] = end
        return Int(span.rounded())
    }
}
