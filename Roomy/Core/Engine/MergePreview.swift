// Why: people approve a merge by reading its result. The preview is computed with the same keys and the same
// union function as the merge, and marks every value that comes from another card, so nothing is hidden.
import Foundation

nonisolated struct MergedValue: Sendable, Hashable {
    let text: String
    /// True when the value comes from a card other than the one being kept.
    let isAdded: Bool
}

nonisolated struct MergePreview: Sendable, Equatable {
    let name: String
    let organization: String
    let phones: [MergedValue]
    let emails: [MergedValue]
    /// Photos that cannot stay on the merged card, which holds one. They remain in the backup.
    let photosOnlyInBackup: Int

    var addedCount: Int { (phones + emails).filter(\.isAdded).count }

    init(primary: ContactCard, extras: [ContactCard], region: String) {
        let cards = [primary] + extras
        name = cards.first { !$0.name.isEmpty }?.name ?? ""
        organization = cards.first { !$0.organization.isEmpty }?.organization ?? ""
        phones = MergeUnion.merge(kept: primary.phones, extras: extras.map(\.phones)) {
            ContactNormalizer.phoneIdentity($0, region: region)
        }.map { MergedValue(text: $0.value, isAdded: $0.isAdded) }
        emails = MergeUnion.merge(
            kept: primary.emails, extras: extras.map(\.emails), key: ContactNormalizer.emailIdentity
        )
        .map { MergedValue(text: $0.value, isAdded: $0.isAdded) }
        photosOnlyInBackup = max(0, cards.filter(\.hasImage).count - 1)
    }
}
