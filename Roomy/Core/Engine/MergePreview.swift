// Why: people approve a merge by reading its result. The preview is computed with the same keys and the same
// union function as the merge, and names the card every value comes from, so nothing is hidden. Cards are
// numbered the way the group card lists them: 1 is the card that stays, then the others in the group's order.
import Foundation

nonisolated struct MergedValue: Sendable, Hashable {
    let text: String
    /// The card the value comes from, numbered like the member rows: 1 is the kept card.
    let sourceCard: Int

    /// True when the value comes from a card other than the one being kept.
    var isAdded: Bool { sourceCard > MergeMember.keptNumber }
}

nonisolated struct MergePreview: Sendable, Equatable {
    let name: String
    /// The company the merged card keeps, or nil when no card has one.
    let organization: MergedValue?
    let phones: [MergedValue]
    let emails: [MergedValue]
    /// Every card in the group, the kept one first, with the values that tie it to the others marked.
    let members: [MergeMember]
    /// Photos that cannot stay on the merged card, which holds one. They remain in the backup.
    let photosOnlyInBackup: Int

    var addedCount: Int { (phones + emails).filter(\.isAdded).count }

    init(primary: ContactCard, extras: [ContactCard], region: String) {
        let cards = [primary] + extras
        name = cards.first { !$0.name.isEmpty }?.name ?? ""
        organization = cards.firstIndex { !$0.organization.isEmpty }.map {
            MergedValue(text: cards[$0].organization, sourceCard: $0 + MergeMember.keptNumber)
        }
        phones = Self.values(
            MergeUnion.merge(kept: primary.phones, extras: extras.map(\.phones)) {
                ContactNormalizer.phoneIdentity($0, region: region)
            })
        emails = Self.values(
            MergeUnion.merge(kept: primary.emails, extras: extras.map(\.emails), key: ContactNormalizer.emailIdentity))
        members = MergeMember.members(of: cards, region: region)
        photosOnlyInBackup = max(0, cards.filter(\.hasImage).count - 1)
    }

    /// The kept card is card 1, so the first extra is card 2.
    private static func values(_ entries: [MergeUnionEntry<String>]) -> [MergedValue] {
        entries.map { entry in
            let card = entry.extraIndex.map { $0 + MergeMember.keptNumber + 1 } ?? MergeMember.keptNumber
            return MergedValue(text: entry.value, sourceCard: card)
        }
    }
}
