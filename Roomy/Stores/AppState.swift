// Why: the container of long-lived stores. It builds each store and service once and wires them together,
// so stores receive their dependencies instead of creating them. Flows that span stores — starting scans,
// running a cleanup and applying its result (`AppState+Cleanup`) — live on this type. Views reach it with
// @Environment.
// It also keeps the scan in step with the library through `LibraryWatcher`: a change made outside Roomy leads
// to a refresh.
import Foundation
import Observation

@Observable
final class AppState {
    let library: PhotoLibrary
    let photoAccess = PhotoAccess()
    let contactAccess = ContactAccess()
    let scan: ScanStore
    let contacts: DuplicateContactsStore
    let cleanup: CleanupStore
    let basket = Basket()
    private(set) var volume = VolumeStats.current()
    private let hashCache = HashCache()
    private let watcher: LibraryWatcher

    init(
        library: PhotoLibrary = PhotoLibrary(), contactSource: any ContactSource = ContactBook(),
        cleaner: any Cleaner = DeletionService(), libraryChanges: any LibraryChangeSource = PhotoLibraryChanges()
    ) {
        self.library = library
        let scan = ScanStore(source: library, cache: hashCache, keeperFilename: "roomy-keepers.json")
        let cleanup = CleanupStore(cleaner: cleaner)
        let access = photoAccess
        self.scan = scan
        self.cleanup = cleanup
        contacts = DuplicateContactsStore(source: contactSource, refusedFilename: "roomy-refused-merges.json")
        watcher = LibraryWatcher(
            scan: scan, source: libraryChanges, canUseLibrary: { access.state.canUse },
            isCleaningUp: { cleanup.isWorking })
    }

    /// Duplicate contacts need the whole address book; a partial view would miss most duplicates.
    var canScanContacts: Bool { contactAccess.state == .authorized }

    /// The basket as Review may offer it: photos only while Photos access works, similar photos only once this
    /// session has grouped the library, merges only for groups the contact scan can see. Everything else waits,
    /// outside every count.
    var review: BasketReview { review(of: basket.items.values) }

    /// People change permissions, free space and photos outside the app, so all three are re-read on return.
    func refreshOnForeground() {
        photoAccess.refresh()
        contactAccess.refresh()
        volume = .current()
        cleanup.measure(freeNow: volume.free)
        startScansIfNeeded()
        watcher.checkForMissedChanges()
    }

    func startScansIfNeeded() {
        if photoAccess.state.canUse {
            watcher.start()
        }
        if photoAccess.state.canUse && scan.phase == .idle {
            startPhotoScan()
        }
        if canScanContacts && contacts.phase == .idle {
            contacts.scan()
        }
    }

    func rescan() {
        if photoAccess.state.canUse {
            startPhotoScan()
        }
        if canScanContacts {
            contacts.scan()
        }
    }

    func requestPhotoAccess() async {
        await photoAccess.request()
        startScansIfNeeded()
    }

    func requestContactAccess() async {
        await contactAccess.request()
        startScansIfNeeded()
    }

    /// After changing a limited selection the library is different, so it is scanned again.
    func manageLimitedPhotos() async {
        await photoAccess.presentLimitedPicker()
        startPhotoScan()
    }

    /// Called when a scan settles, finished or stopped; either way the index is current.
    func scanDidFinish() {
        volume = .current()
        reconcilePhotoSelection()
    }

    /// Only a finished scan knows which groups are gone; before that, saved merges wait instead of vanishing.
    func contactScanDidFinish() {
        guard contacts.phase == .done else { return }
        basket.prune(keeping: Set(contacts.groups.map(\.id)), of: [.contactGroup])
    }

    /// The keeper is never up for removal, so a photo chosen as keeper leaves the basket in the same step.
    func makeKeeper(_ id: String) {
        scan.makeKeeper(id)
        basket.remove([id])
    }

    /// Runs what the person confirmed in Review, and of that only what can still run safely, then removes from
    /// every store exactly what the report says is gone. The plan comes from `confirmed`, never from the basket,
    /// so an item that became ready while the confirmation was open is never deleted or merged unseen.
    func cleanUp(_ confirmed: [BasketItem]) async {
        guard !cleanup.isWorking else { return }
        // Access can change outside the app; nothing is asked of Photos or Contacts on a stale answer.
        photoAccess.refresh()
        contactAccess.refresh()
        let plan = CleanupPlan.make(
            confirmed: review(of: confirmed), contactGroups: contacts.groupsByID, similarGroups: scan.similarGroups)
        // Measured now rather than reused from the last foreground, so any rise is counted from this moment.
        // An empty plan (everything vanished since Review opened) still ends in a result, never in silence.
        volume = .current()
        let report = await cleanup.run(plan, freeBefore: volume.free)
        // The library changes seen so far are this cleanup's own, and the report below applies them.
        watcher.coverChangesSoFar()
        apply(report)
        volume = .current()
    }

    func clearScanCache() {
        Task { await hashCache.clear() }
    }

    private func startPhotoScan() {
        watcher.startScan()
    }
}
