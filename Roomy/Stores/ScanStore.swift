// Why: the main-actor view of the scan. It starts the pipeline and applies its events in order. A newer
// scan cancels the older one, and a cancelled scan never writes state — that rule fixed a race where
// tapping Rescan mid-scan flipped the screen to "done" too early. A scan stopped while comparing is
// `.stopped`, never `.done`: an unfinished comparison must not read as "no similar photos". Assets a cleanup
// removed stay removed even when a scan that read the library before the cleanup finishes after it. A keeper
// the person chose in Compare lives here, the one place groups are stored (see `KeeperChoices`).
// Screens read the results through `ScanStore+Scope`, filtered by `scope`; the `all…` lists are the whole
// library, for the cleanup's group checks. A size carried over from an earlier scan never outlives fresh data:
// see `applyIndex`.
import Foundation
import Observation

nonisolated enum ScanPhase: Sendable, Equatable {
    case idle
    case indexing
    case comparing
    /// Stopped while comparing: screenshots and videos are current (a library change re-reads the index),
    /// similar photos are not finished and any groups shown come from an earlier scan.
    case stopped
    case done
}

@Observable
final class ScanStore {
    private(set) var phase: ScanPhase = .idle
    private(set) var indexProgress = IndexProgress()
    private(set) var hashProgress = HashProgress()
    private(set) var allScreenshots: [AssetSnapshot] = []
    /// Most space on this phone first; videos kept only in iCloud come after, largest first.
    private(set) var allVideos: [AssetSnapshot] = []
    /// Every group, whatever the scope. The cleanup checks these, so it never empties a group.
    private(set) var allSimilarGroups: [SimilarGroup] = []
    /// What the screens show and count. Set only through `AppState.libraryScope`, which saves it.
    var scope = LibraryScope.onThisPhone
    /// True once the current index has been compared and grouped, so `allSimilarGroups` is the whole answer.
    private(set) var hasFinishedGrouping = false
    /// Photos the last comparison could not read, so they were not checked for similar shots.
    private(set) var uncheckedPhotoCount = 0
    /// Grows each time results settle: a scan finished or stopped, or a stopped comparison's index was read
    /// again. That last one keeps the phase at `.stopped`, so the basket follows this instead of the phase.
    private(set) var settledCount = 0
    private var snapshotsByID: [String: AssetSnapshot] = [:]
    /// Assets removed since the current scan started. It may have read the library before they went, so its
    /// results are filtered until a newer scan starts.
    private var removedSinceScanStarted: Set<String> = []
    /// Where the store settles if the running scan is stopped now.
    private var restingPhase: ScanPhase = .idle
    private var keeperChoices: KeeperChoices

    private let pipeline: ScanPipeline
    private var scanTask: Task<Void, Never>?

    /// No default file: a store built without naming one (a test) must never touch the app's saved keepers.
    init(source: any PhotoSource, cache: HashCache, keeperFilename: String) {
        pipeline = ScanPipeline(source: source, cache: cache)
        keeperChoices = KeeperChoices(filename: keeperFilename)
    }

    var isScanning: Bool { phase == .indexing || phase == .comparing }
    var hasResults: Bool { !snapshotsByID.isEmpty }
    var allIDs: Set<String> { Set(snapshotsByID.keys) }

    func snapshot(_ id: String) -> AssetSnapshot? { snapshotsByID[id] }
    func snapshots(_ ids: some Sequence<String>) -> [AssetSnapshot] { ids.compactMap { snapshotsByID[$0] } }
    func bytes(of ids: some Sequence<String>) -> Int64 { snapshots(ids).totalBytes }
    func sizeTotal(of ids: some Sequence<String>) -> SizeTotal { snapshots(ids).sizeTotal }

    func scan() {
        scanTask?.cancel()
        removedSinceScanStarted = []
        phase = .indexing
        indexProgress = IndexProgress()
        hashProgress = HashProgress()
        scanTask = Task { [pipeline] in
            for await event in pipeline.run() {
                guard !Task.isCancelled else { return }
                apply(event)
            }
            guard !Task.isCancelled else { return }
            phase = .done
            restingPhase = .done
            settledCount += 1
        }
    }

    /// Reads the index again without comparing, for a comparison the person stopped: screenshots and videos
    /// stay current, and the comparison waits until they resume it.
    func refreshIndex() {
        guard phase == .stopped else { return }
        scanTask?.cancel()
        removedSinceScanStarted = []
        scanTask = Task { [source = pipeline.source] in
            for await event in source.indexLibrary() {
                guard !Task.isCancelled else { return }
                if case .finished(let snapshots) = event {
                    applyIndex(snapshots.filter { !removedSinceScanStarted.contains($0.id) })
                    settledCount += 1
                }
            }
        }
    }

    /// Stopping before the index arrives keeps the earlier results as they were; stopping while comparing
    /// keeps the earlier groups but marks the comparison as not finished.
    func cancel() {
        scanTask?.cancel()
        scanTask = nil
        guard isScanning else { return }
        phase = restingPhase
        if phase != .idle {
            settledCount += 1
        }
    }

    /// Forgets assets that were deleted, so every screen updates without a rescan. A group left with one
    /// photo is no longer a group; a group that lost its keeper hands over to its next photo that isn't
    /// `queued` for removal, so a queued photo only becomes the keeper when nothing else is left.
    func remove(_ ids: Set<String>, queued: Set<String> = []) {
        guard !ids.isEmpty else { return }
        removedSinceScanStarted.formUnion(ids)
        for id in ids {
            snapshotsByID.removeValue(forKey: id)
        }
        allScreenshots.removeAll { ids.contains($0.id) }
        allVideos.removeAll { ids.contains($0.id) }
        allSimilarGroups = SimilarGroupPruning.groups(allSimilarGroups, without: ids, queued: queued)
    }

    /// Makes `id` the keeper of the group that holds it, replacing any earlier choice in that group.
    func makeKeeper(_ id: String) {
        guard let index = allSimilarGroups.firstIndex(where: { $0.members.contains(id) }) else { return }
        allSimilarGroups[index] = keeperChoices.choose(id, in: allSimilarGroups[index])
    }

    /// Waits for the current scan to finish or stop.
    func waitForScan() async {
        await scanTask?.value
    }

    private func apply(_ event: ScanEvent) {
        switch event {
        case .indexing(let progress):
            indexProgress = progress
        case .indexed(let indexed):
            applyIndex(indexed.filter { !removedSinceScanStarted.contains($0.id) })
            hasFinishedGrouping = false
            phase = .comparing
            restingPhase = .stopped
        case .comparing(let progress):
            hashProgress = progress
        case .grouped(let groups, let sizes, let unchecked):
            // Fresh sizes replace every carried one; a member Photos gave no size to reads "size unavailable".
            for id in groups.lazy.flatMap(\.members) {
                snapshotsByID[id]?.size = sizes[id]
            }
            allSimilarGroups = keeperChoices.applied(
                to: SimilarGroupPruning.groups(groups, without: removedSinceScanStarted, queued: []),
                libraryIDs: allIDs, unchecked: unchecked)
            hasFinishedGrouping = true
            uncheckedPhotoCount = unchecked.count
            restingPhase = .done
        }
    }

    /// Earlier groups stay, minus photos that are gone, until the new comparison replaces them, so a rescan
    /// never empties the Similar screen. Known sizes of unchanged photos carry over for the same reason, until
    /// the comparison measures them again. Screenshots and videos are measured by the index itself, so their
    /// fresh size, even an unknown one, always wins: an old one would keep a stale "in iCloud".
    private func applyIndex(_ snapshots: [AssetSnapshot]) {
        var fresh = Dictionary(snapshots.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for (id, old) in snapshotsByID {
            guard let size = old.size, var current = fresh[id], current.kind == .photo, current.size == nil,
                current.modificationDate == old.modificationDate
            else { continue }
            current.size = size
            fresh[id] = current
        }
        let gone = Set(snapshotsByID.keys).subtracting(fresh.keys)
        snapshotsByID = fresh
        allScreenshots = snapshots.compactMap { $0.kind == .screenshot ? fresh[$0.id] : nil }
        allVideos = snapshots.compactMap { $0.kind == .video ? fresh[$0.id] : nil }.sorted(by: Self.freesMoreSpace)
        allSimilarGroups = SimilarGroupPruning.groups(allSimilarGroups, without: gone, queued: [])
    }

    /// Orders by what deleting would give back on this phone, then by full size, so the top of the list is
    /// where space comes from.
    private static func freesMoreSpace(_ first: AssetSnapshot, _ second: AssetSnapshot) -> Bool {
        let onPhone = (first: first.bytesOnPhone ?? 0, second: second.bytesOnPhone ?? 0)
        guard onPhone.first == onPhone.second else { return onPhone.first > onPhone.second }
        return (first.fileSize ?? 0) > (second.fileSize ?? 0)
    }
}
