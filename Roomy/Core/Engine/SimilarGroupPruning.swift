// Why: photos leave similar groups in two ways, deleted by a cleanup or gone from a fresh index, and both must
// follow one rule: the photos left behind stay together only while the links between them still hold, so two
// photos joined only through a deleted one split apart; a part left with one photo is no longer a group; and a
// part that lost its keeper hands over to a photo that isn't queued for removal, so a queued photo only becomes
// the keeper when nothing else is left. A group's label holds for every member, so it holds for any part too.
import Foundation

nonisolated enum SimilarGroupPruning {
    /// `groups` without the photos in `ids`, keeper first.
    static func groups(_ groups: [SimilarGroup], without ids: Set<String>, queued: Set<String>) -> [SimilarGroup] {
        guard !ids.isEmpty else { return groups }
        return groups.flatMap { parts(of: $0, without: ids, queued: queued) }
    }

    private static func parts(of group: SimilarGroup, without ids: Set<String>, queued: Set<String>)
        -> [SimilarGroup]
    {
        let remaining = group.members.filter { !ids.contains($0) }
        guard remaining.count < group.members.count else { return [group] }
        let links = group.links.filter { !$0.touches(ids) }
        let parts = connected(remaining, links: links, isKnown: !group.links.isEmpty).filter { $0.count > 1 }
        return parts.map { members in
            var part = group
            let memberSet = Set(members)
            // One surviving part keeps the group's id, so an open Compare and the basket still find it.
            if parts.count > 1 {
                part.id = StableID.make(from: members)
            }
            part.members = members
            part.links = links.filter { memberSet.contains($0.first) }
            part.markedByPerson = group.markedByPerson.intersection(memberSet)
            if !memberSet.contains(group.best), let first = members.first {
                let next = members.first { !queued.contains($0) } ?? first
                part = part.withKeeper(next)
            }
            return part
        }
    }

    /// The members split by the links that still join them, in the group's order. Without known links (a group
    /// built by hand) the members stay together.
    private static func connected(_ members: [String], links: [MemberLink], isKnown: Bool) -> [[String]] {
        guard isKnown else { return [members] }
        let position = Dictionary(members.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        var unionFind = UnionFind(count: members.count)
        for link in links {
            if let first = position[link.first], let second = position[link.second] {
                unionFind.union(first, second)
            }
        }
        var parts: [Int: [String]] = [:]
        var order: [Int] = []
        for (index, member) in members.enumerated() {
            let root = unionFind.find(index)
            if parts[root] == nil {
                order.append(root)
            }
            parts[root, default: []].append(member)
        }
        return order.compactMap { parts[$0] }
    }
}
