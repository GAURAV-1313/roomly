// Why: duplicate contacts are found the same way as duplicate photos — link cards that share a value, then
// union-find the links into groups. Precision beats recall: only a shared number or email links cards (a
// shared name alone is two people as often as one), a value shared by many differently named cards (an
// office switchboard, a family email) links nothing, and a group is labelled by its weakest link.
import Foundation

nonisolated enum ContactMatcher {
    /// A value on more cards than this is a shared line or address, unless every card carries the same name:
    /// then the cards are copies of one card, the most obvious duplicates of all.
    static let hubLimit = 3
    /// Bigger groups are more likely a bad link than one person with many cards, unless all share a name.
    static let maxGroupSize = 4

    static func groups(_ cards: [ContactCard], region: String) -> [ContactGroup] {
        let nameKeys = cards.map { ContactNormalizer.nameKey($0.name) }
        var unionFind = UnionFind(count: cards.count)
        var strongest: [Int: ContactMatchReason] = [:]
        let signals: [(ContactMatchReason, (ContactCard) -> Set<String>)] = [
            (.samePhone, { Set($0.phones.compactMap { ContactNormalizer.phoneKey($0, region: region) }) }),
            (.sameEmail, { Set($0.emails.compactMap(ContactNormalizer.emailKey)) }),
        ]
        for (reason, keys) in signals {
            for owners in owners(of: cards, keys: keys).values where isEvidence(owners, nameKeys: nameKeys) {
                for index in owners {
                    unionFind.union(owners[0], index)
                    strongest[index] = stronger(strongest[index], reason)
                }
            }
        }
        var membersByRoot: [Int: [Int]] = [:]
        for index in cards.indices {
            membersByRoot[unionFind.find(index), default: []].append(index)
        }
        let names = Dictionary(cards.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        return membersByRoot.values
            .filter { $0.count > 1 && ($0.count <= maxGroupSize || sharesOneName($0, nameKeys: nameKeys)) }
            .compactMap { makeGroup($0, cards: cards, strongest: strongest, region: region) }
            .sorted { (names[$0.primary] ?? "", $0.id) < (names[$1.primary] ?? "", $1.id) }
    }

    /// Which cards carry each key.
    private static func owners(of cards: [ContactCard], keys: (ContactCard) -> Set<String>) -> [String: [Int]] {
        var owners: [String: [Int]] = [:]
        for (index, card) in cards.enumerated() {
            for key in keys(card) {
                owners[key, default: []].append(index)
            }
        }
        return owners
    }

    private static func isEvidence(_ owners: [Int], nameKeys: [String?]) -> Bool {
        owners.count > 1 && (owners.count <= hubLimit || sharesOneName(owners, nameKeys: nameKeys))
    }

    private static func sharesOneName(_ indices: [Int], nameKeys: [String?]) -> Bool {
        let names = Set(indices.map { nameKeys[$0] })
        guard names.count == 1, let only = names.first else { return false }
        return only != nil
    }

    private static func makeGroup(
        _ indices: [Int], cards: [ContactCard], strongest: [Int: ContactMatchReason], region: String
    ) -> ContactGroup? {
        guard let primary = KeptCard.index(among: indices, cards: cards) else { return nil }
        // Each card's best link is why it belongs; the group is only as sure as its least sure card.
        guard let reason = indices.compactMap({ strongest[$0] }).max(by: { $0.strength < $1.strength }) else {
            return nil
        }
        return ContactGroup(
            id: StableID.make(from: indices.map { cards[$0].id }),
            primary: cards[primary].id,
            extras: indices.filter { $0 != primary }.map { cards[$0].id },
            reason: reason,
            fingerprints: Dictionary(
                indices.map { (cards[$0].id, cards[$0].fingerprint) }, uniquingKeysWith: { first, _ in first }),
            phoneRegion: region,
            spansAccounts: KeptCard.spansAccounts(indices, cards: cards))
    }

    private static func stronger(_ current: ContactMatchReason?, _ new: ContactMatchReason) -> ContactMatchReason {
        guard let current else { return new }
        return new.strength < current.strength ? new : current
    }
}
