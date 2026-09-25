// Why: the kept card is the one that survives, so it decides where the merged data lives and which photo
// stays. A card in the person's own default account always wins over one in a work or shared account, however
// full that one is: the merge copies every value into the kept card anyway, and personal data (a birthday, a
// home address, a photo) must never be written into an account that can vanish with a job. Among cards in the
// same kind of account the fullest wins, and one with a photo beats one nearly as full without.
import Foundation

nonisolated enum KeptCard {
    /// Cards within this many fields of the fullest one count as close enough to weigh the photo.
    static let closeFieldMargin = 1

    /// The index of the card to keep. Ties go to the earlier card.
    static func index(among indices: [Int], cards: [ContactCard]) -> Int? {
        let personal = indices.filter { cards[$0].isInDefaultContainer }
        let candidates = personal.isEmpty ? indices : personal
        guard let fullest = candidates.map({ cards[$0].fieldCount }).max() else { return nil }
        let close = candidates.filter { cards[$0].fieldCount >= fullest - closeFieldMargin }
        // `max(by:)` keeps the first of equal elements, so earlier cards win ties.
        return close.max { isPreferred(cards[$1], over: cards[$0]) }
    }

    /// True when the cards live in different kinds of account, so the merge moves data between them.
    static func spansAccounts(_ indices: [Int], cards: [ContactCard]) -> Bool {
        Set(indices.map { cards[$0].isInDefaultContainer }).count > 1
    }

    private static func isPreferred(_ card: ContactCard, over other: ContactCard) -> Bool {
        if card.hasImage != other.hasImage { return card.hasImage }
        return card.fieldCount > other.fieldCount
    }
}
