// Why: the screen-facing state of the duplicate-contact scan. Reading the address book happens in the
// service; matching runs off the main actor; a newer scan cancels an older one and a cancelled scan never
// writes, the same rule the photo scan follows. A merge that lands while a scan is reading stays merged, and
// a group Contacts refused to save is not offered again — saved, so a relaunch doesn't offer it and fail again.
import Foundation
import Observation

nonisolated enum ContactScanPhase: Sendable, Equatable {
    case idle
    case scanning
    case done
    case failed
}

@Observable
final class DuplicateContactsStore {
    private(set) var phase: ContactScanPhase = .idle
    private(set) var groups: [ContactGroup] = []
    private var cardsByID: [String: ContactCard] = [:]
    /// Cards merged away since the current scan started. It may have read them before the merge, so its
    /// results are filtered until a newer scan starts.
    private var removedSinceScanStarted: Set<String> = []
    /// Groups whose merge Contacts refused; retrying would only fail again.
    private var refusedGroupIDs: Set<String>
    private let refusedFile: JSONFileStore<[String]>

    private let source: any ContactSource
    /// The region national phone numbers are read in, normally the phone's own.
    private let phoneRegion: String
    private var scanTask: Task<Void, Never>?

    init(
        source: any ContactSource, phoneRegion: String = Locale.current.region?.identifier ?? "",
        refusedFilename: String
    ) {
        self.source = source
        self.phoneRegion = phoneRegion
        refusedFile = JSONFileStore(filename: refusedFilename)
        refusedGroupIDs = Set(refusedFile.load() ?? [])
    }

    var groupsByID: [String: ContactGroup] {
        Dictionary(groups.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Cards that would be folded into another card and removed.
    var extraCardCount: Int { groups.reduce(0) { $0 + $1.extras.count } }

    func card(_ id: String) -> ContactCard? { cardsByID[id] }

    func preview(for group: ContactGroup) -> MergePreview? {
        guard let primary = cardsByID[group.primary] else { return nil }
        return MergePreview(
            primary: primary, extras: group.extras.compactMap { cardsByID[$0] }, region: group.phoneRegion)
    }

    func scan() {
        scanTask?.cancel()
        removedSinceScanStarted = []
        phase = .scanning
        scanTask = Task { [source, phoneRegion] in
            do {
                let cards = try await source.cards()
                let groups = await Self.match(cards, region: phoneRegion)
                guard !Task.isCancelled else { return }
                let removed = removedSinceScanStarted
                let current = cards.filter { !removed.contains($0.id) }
                cardsByID = Dictionary(current.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                self.groups = groups.filter { group in
                    !refusedGroupIDs.contains(group.id) && group.members.allSatisfy { !removed.contains($0) }
                }
                phase = .done
            } catch {
                guard !Task.isCancelled else { return }
                Log.contacts.error("scan failed: \(error.localizedDescription)")
                phase = .failed
            }
        }
    }

    /// Forgets groups that were merged or went out of date, so the screen and the dashboard update at once.
    func remove(_ groupIDs: Set<String>) {
        guard !groupIDs.isEmpty else { return }
        for group in groups where groupIDs.contains(group.id) {
            for id in group.extras {
                cardsByID.removeValue(forKey: id)
                removedSinceScanStarted.insert(id)
            }
        }
        groups.removeAll { groupIDs.contains($0.id) }
    }

    /// Stops offering groups Contacts would not save, now and after later scans.
    func stopOffering(_ groupIDs: Set<String>) {
        guard !groupIDs.isEmpty else { return }
        refusedGroupIDs.formUnion(groupIDs)
        refusedFile.save(refusedGroupIDs.sorted())
        groups.removeAll { groupIDs.contains($0.id) }
    }

    /// Waits for the current scan to finish. Used by tests.
    func waitForScan() async {
        await scanTask?.value
    }

    @concurrent
    private nonisolated static func match(_ cards: [ContactCard], region: String) async -> [ContactGroup] {
        ContactMatcher.groups(cards, region: region)
    }
}
