// Why: a group of near-identical photos with one keeper. The reason is stored as data so every screen
// can show *why* photos were grouped, and so tests can assert it. A photo the person marked in Photos — a
// favourite, or a frame they picked from a burst — can be removed by hand but is never suggested in bulk,
// because only one of them can be the keeper.
import Foundation

nonisolated enum SimilarityReason: Sendable, Hashable {
    case exactDuplicate
    case nearDuplicate
    case burst
    /// Taken within the same moment, which spans `seconds` from first to last shot (0 = taken together).
    case moment(seconds: Int)
    /// Linked by different kinds of evidence (a burst frame and a copy saved a month later) that do not all
    /// hold for every member, so nothing more specific can honestly be said.
    case similar

    /// Lower is stronger. A group shows the weakest reason among its links, so its label holds for every
    /// member and never claims more than the loosest match earned.
    var strength: Int {
        switch self {
        case .exactDuplicate: 0
        case .nearDuplicate: 1
        case .burst: 2
        case .moment: 3
        case .similar: 4
        }
    }

    /// True when this reason promises less than `other`. Between two moments, the longer one is weaker.
    func isWeaker(than other: SimilarityReason) -> Bool {
        if case .moment(let seconds) = self, case .moment(let otherSeconds) = other {
            return seconds > otherSeconds
        }
        return strength > other.strength
    }
}

nonisolated struct SimilarGroup: Identifiable, Sendable, Hashable {
    var id: String
    /// Asset ids, keeper first.
    var members: [String]
    var best: String
    var reason: SimilarityReason
    var date: Date?
    /// The links that joined the members. Empty for a group built by hand, which then stays whole.
    var links: [MemberLink] = []
    /// Members the person marked in Photos: favourites and burst frames they picked.
    var markedByPerson: Set<String> = []

    /// Everything except the keeper: the photos a person may choose to remove.
    var extras: [String] { members.filter { $0 != best } }
    /// The extras Roomy suggests and "Select extras" queues: never one the person marked in Photos.
    var suggestedExtras: [String] { extras.filter { !markedByPerson.contains($0) } }

    /// The same group with `id` as its keeper, moved to the front. Unchanged when `id` is not a member.
    func withKeeper(_ keeper: String) -> SimilarGroup {
        guard members.contains(keeper) else { return self }
        var updated = self
        updated.best = keeper
        updated.members = [keeper] + members.filter { $0 != keeper }
        return updated
    }
}
