// Why: "only one card is visible" was the device-test complaint: a group showed only its merged result, so the
// person could not see which cards were being folded together or why. Each member card is listed with its own
// phones and emails, and the values it shares with another card in the group — the ones that linked them —
// are marked, compared with the matcher's own keys so the mark means exactly what linked the cards.
import Foundation

nonisolated struct MemberValue: Sendable, Hashable {
    let text: String
    /// True when another card in the group carries the same number or address.
    let isShared: Bool
}

nonisolated struct MergeMember: Sendable, Equatable {
    /// The kept card's number; the cards folded into it follow from 2.
    static let keptNumber = 1

    /// 1 for the kept card, then 2, 3… in the group's order.
    let number: Int
    let name: String
    /// Phones first, then emails, each as the card spells it.
    let values: [MemberValue]

    var isKept: Bool { number == Self.keptNumber }

    /// Numbers the cards (the kept one first) and marks each value another card in the group shares.
    static func members(of cards: [ContactCard], region: String) -> [MergeMember] {
        let keysByCard = cards.map { keys(of: $0, region: region) }
        return cards.enumerated().map { index, card in
            let otherKeys = keysByCard.enumerated().filter { $0.offset != index }.map(\.element)
            let sharedKeys = otherKeys.reduce(into: Set<String>()) { $0.formUnion($1) }
            let phones = card.phones.map { phone in
                MemberValue(text: phone, isShared: phoneKey(phone, region: region).map(sharedKeys.contains) ?? false)
            }
            let emails = card.emails.map { email in
                MemberValue(text: email, isShared: emailKey(email).map(sharedKeys.contains) ?? false)
            }
            return MergeMember(number: index + keptNumber, name: card.name, values: phones + emails)
        }
    }

    /// A card's matching keys; phones and emails are prefixed so a number never equals an address.
    private static func keys(of card: ContactCard, region: String) -> Set<String> {
        let phones = card.phones.compactMap { phoneKey($0, region: region) }
        let emails = card.emails.compactMap(emailKey)
        return Set(phones + emails)
    }

    private static func phoneKey(_ raw: String, region: String) -> String? {
        ContactNormalizer.phoneKey(raw, region: region).map { "tel:" + $0 }
    }

    private static func emailKey(_ raw: String) -> String? {
        ContactNormalizer.emailKey(raw).map { "mail:" + $0 }
    }
}
