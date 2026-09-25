// Why: the only code that changes the address book. Order matters: refetch every card and check it still
// reads exactly as the approved preview showed it, write one vCard backup of all of them, and only then save
// — one save request per group, so one read-only card (an Exchange directory entry, say) fails its own
// group and nothing else. Every group that is not merged is reported with the reason.
import Contacts

nonisolated enum ContactMerger {
    static func merge(_ groups: [ContactGroup]) async -> ContactMergeResult {
        guard !groups.isEmpty else { return ContactMergeResult() }
        return await Task.detached(priority: .userInitiated) { mergeAll(groups) }.value
    }

    private enum Refetch {
        case ready([CNContact])
        /// A card was edited or removed after the scan.
        case changed
        /// The address book could not be read just now.
        case unreadable
    }

    private static func mergeAll(_ groups: [ContactGroup]) -> ContactMergeResult {
        let store = CNContactStore()
        var result = ContactMergeResult()
        var ready: [(group: ContactGroup, cards: [CNContact])] = []
        for group in groups {
            switch refetch(group, from: store) {
            case .ready(let cards): ready.append((group, cards))
            case .changed: result.changedGroupIDs.append(group.id)
            case .unreadable: result.failedGroupIDs.append(group.id)
            }
        }
        guard !ready.isEmpty else { return result }

        let backup: URL
        do {
            backup = try VCardBackup.write(ready.flatMap(\.cards))
        } catch {
            Log.contacts.error("backup failed, nothing merged: \(error.localizedDescription)")
            result.failedGroupIDs += ready.map(\.group.id)
            return result
        }
        for (group, cards) in ready {
            save(group, cards: cards, in: store, into: &result)
        }
        if result.mergedGroupIDs.isEmpty {
            VCardBackup.discard(backup)
        } else {
            VCardBackup.keep(backup)
            result.backupFile = backup
        }
        return result
    }

    /// The group's cards, kept card first, if every one still reads as it did in the scan.
    private static func refetch(_ group: ContactGroup, from store: CNContactStore) -> Refetch {
        let keys = ContactFieldUnion.keys + ContactCard.contactKeys + VCardBackup.requiredKeys
        let predicate = CNContact.predicateForContacts(withIdentifiers: group.members)
        do {
            let found = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
            let byID = Dictionary(found.map { ($0.identifier, $0) }, uniquingKeysWith: { first, _ in first })
            let ordered = group.members.compactMap { byID[$0] }
            guard ordered.count == group.members.count, group.isUnchanged(ordered.map { ContactCard($0) }) else {
                Log.contacts.notice("group \(group.id) changed since the scan")
                return .changed
            }
            return .ready(ordered)
        } catch {
            Log.contacts.error("refetch \(group.id) failed: \(error.localizedDescription)")
            return .unreadable
        }
    }

    private static func save(
        _ group: ContactGroup, cards: [CNContact], in store: CNContactStore, into result: inout ContactMergeResult
    ) {
        guard let kept = cards.first?.mutableCopy() as? CNMutableContact else {
            result.failedGroupIDs.append(group.id)
            return
        }
        let extras = Array(cards.dropFirst())
        ContactFieldUnion.fold(extras, into: kept, region: group.phoneRegion)
        let request = CNSaveRequest()
        request.update(kept)
        for extra in extras {
            if let removable = extra.mutableCopy() as? CNMutableContact {
                request.delete(removable)
            }
        }
        do {
            try store.execute(request)
            result.mergedGroupIDs.append(group.id)
            result.removedCardCount += extras.count
        } catch {
            Log.contacts.error("merge \(group.id) failed: \(error.localizedDescription)")
            classify(error, group: group.id, into: &result)
        }
    }

    /// A passing problem leaves the group in Review to try again. A card that vanished counts as changed.
    /// Anything else, usually a card in a read-only account, will fail every time, so it is refused.
    private static func classify(_ error: Error, group: String, into result: inout ContactMergeResult) {
        switch (error as? CNError)?.code {
        case .communicationError, .dataAccessError, .authorizationDenied:
            result.failedGroupIDs.append(group)
        case .recordDoesNotExist:
            result.changedGroupIDs.append(group)
        default:
            result.refusedGroupIDs.append(group)
        }
    }
}
