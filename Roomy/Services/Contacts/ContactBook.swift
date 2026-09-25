// Why: the one reader of the address book for the duplicate scan. It fetches only the keys the matcher
// compares (Apple's advice, and less private data in memory), off the main actor because every Contacts
// fetch is disk I/O, and returns Sendable cards. It also notes which cards live in the default account, so
// a merge keeps data in the account the person owns.
import Contacts

nonisolated protocol ContactSource: Sendable {
    func cards() async throws -> [ContactCard]
}

nonisolated struct ContactBook: ContactSource {
    func cards() async throws -> [ContactCard] {
        try await Task.detached(priority: .userInitiated) { try Self.fetchCards() }.value
    }

    private static func fetchCards() throws -> [ContactCard] {
        let store = CNContactStore()
        let inDefaultContainer = identifiersInDefaultContainer(of: store)
        let request = CNContactFetchRequest(keysToFetch: ContactCard.contactKeys)
        request.sortOrder = .userDefault
        var cards: [ContactCard] = []
        try store.enumerateContacts(with: request) { contact, _ in
            cards.append(
                ContactCard(contact, isInDefaultContainer: inDefaultContainer.contains(contact.identifier)))
        }
        Log.contacts.notice("read \(cards.count) contacts")
        return cards
    }

    /// Without this the kept card is chosen by fullness alone, which is still a valid choice.
    private static func identifiersInDefaultContainer(of store: CNContactStore) -> Set<String> {
        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier())
        do {
            let contacts = try store.unifiedContacts(
                matching: predicate, keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor])
            return Set(contacts.map(\.identifier))
        } catch {
            Log.contacts.error("default account unreadable: \(error.localizedDescription)")
            return []
        }
    }
}
