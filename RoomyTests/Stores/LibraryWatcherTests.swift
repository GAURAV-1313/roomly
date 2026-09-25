// Why: the rules for following library changes are only worth something if the store applies them in the
// right order: wait for a running scan, skip Roomy's own cleanup (even when Photos reports it late), re-read
// only the index of a stopped comparison, keep a gap between automatic refreshes, and catch changes made while
// the app was away. These tests drive the watcher with a fake change source and a library that can change
// mid-test.
import XCTest

@testable import Roomy

final class LibraryWatcherTests: XCTestCase {
    private final class Flag {
        var isOn: Bool
        init(_ isOn: Bool) { self.isOn = isOn }
    }

    private let photos: [AssetSnapshot] =
        (0..<6).map { AssetSnapshot.fixture("p\($0)", at: Double($0)) }
        + [.fixture("clip", kind: .video, at: 9, size: 900_000_000)]

    private var withoutClip: [AssetSnapshot] { photos.filter { $0.id != "clip" } }

    /// Regression: after the first scan, a video deleted in the Photos app stayed listed.
    @MainActor
    func testAChangeAfterAFinishedScanRescansOnce() async throws {
        let (source, changes) = (ChangingPhotoSource(FakePhotoSource(snapshots: photos)), FakeLibraryChanges())
        let (watcher, scan) = makeWatcher(source, changes: changes)
        watcher.start()
        XCTAssertTrue(changes.isObserving)
        watcher.startScan()
        await scan.waitForScan()

        source.replaceSnapshots(withoutClip)
        changes.recordChange()
        try await waitUntil { source.indexCount == 2 && scan.phase == .done }
        XCTAssertTrue(scan.videos.isEmpty)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(source.indexCount, 2, "one change, one rescan")
    }

    @MainActor
    func testAChangeDuringAScanWaitsForItThenRescansOnce() async throws {
        let source = ChangingPhotoSource(FakePhotoSource(snapshots: photos, delay: .milliseconds(200)))
        let changes = FakeLibraryChanges()
        let (watcher, scan) = makeWatcher(source, changes: changes)
        watcher.start()
        watcher.startScan()
        changes.recordChange()

        try await waitUntil { source.indexCount == 2 && scan.phase == .done }
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(source.indexCount, 2)
        XCTAssertEqual(scan.phase, .done)
    }

    /// Roomy's own deletions arrive as changes; once its report is applied they must not start a rescan.
    @MainActor
    func testChangesACleanupMadeNeverRescan() async throws {
        let (source, changes) = (ChangingPhotoSource(FakePhotoSource(snapshots: photos)), FakeLibraryChanges())
        let isCleaningUp = Flag(false)
        let (watcher, scan) = makeWatcher(source, changes: changes, isCleaningUp: { isCleaningUp.isOn })
        watcher.start()
        watcher.startScan()
        await scan.waitForScan()

        isCleaningUp.isOn = true
        changes.recordChange()
        watcher.coverChangesSoFar()
        isCleaningUp.isOn = false
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(source.indexCount, 1)
    }

    /// Regression: Photos may report the cleanup's own deletion after the cleanup returned and its changes were
    /// covered; that late report started a full rescan after every cleanup.
    @MainActor
    func testACleanupsOwnChangeReportedLateNeverRescans() async throws {
        let (source, changes) = (ChangingPhotoSource(FakePhotoSource(snapshots: photos)), FakeLibraryChanges())
        let (watcher, scan) = makeWatcher(source, changes: changes)
        watcher.start()
        watcher.startScan()
        await scan.waitForScan()

        watcher.coverChangesSoFar()
        try await Task.sleep(for: .milliseconds(20))
        changes.recordChange()
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(source.indexCount, 1)
        XCTAssertEqual(scan.phase, .done)
    }

    @MainActor
    func testAChangeAfterTheCleanupWindowStillRescans() async throws {
        let (source, changes) = (ChangingPhotoSource(FakePhotoSource(snapshots: photos)), FakeLibraryChanges())
        let (watcher, scan) = makeWatcher(source, changes: changes)
        watcher.start()
        watcher.startScan()
        await scan.waitForScan()

        watcher.coverChangesSoFar()
        try await Task.sleep(for: .milliseconds(250))
        changes.recordChange()
        try await waitUntil { source.indexCount == 2 && scan.phase == .done }
    }

    /// Regression: during an iCloud sync a new full scan started the moment the last one ended, forever.
    @MainActor
    func testAutomaticRefreshesKeepAGap() async throws {
        let (source, changes) = (ChangingPhotoSource(FakePhotoSource(snapshots: photos)), FakeLibraryChanges())
        let (watcher, scan) = makeWatcher(source, changes: changes, gap: .seconds(1))
        watcher.start()
        watcher.startScan()
        await scan.waitForScan()

        changes.recordChange()
        try await waitUntil { source.indexCount == 2 && scan.phase == .done }
        changes.recordChange()
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(source.indexCount, 2, "the next automatic refresh waits for the gap")
        XCTAssertEqual(scan.phase, .done)
        try await waitUntil { source.indexCount == 3 && scan.phase == .done }
    }

    /// Regression: after the person stopped a comparison, a change in Photos was dropped and Large Videos kept
    /// listing a deleted video until they tapped Resume.
    @MainActor
    func testAStoppedComparisonHasItsIndexReadAgainWithoutComparing() async throws {
        let source = ChangingPhotoSource(FakePhotoSource(snapshots: photos, tileDelay: .milliseconds(200)))
        let changes = FakeLibraryChanges()
        let (watcher, scan) = makeWatcher(source, changes: changes)
        watcher.start()
        watcher.startScan()
        try await waitUntil { scan.phase == .comparing }
        scan.cancel()
        XCTAssertEqual(scan.phase, .stopped)

        source.replaceSnapshots(withoutClip)
        changes.recordChange()
        try await waitUntil { scan.videos.isEmpty }
        XCTAssertEqual(scan.phase, .stopped, "the comparison stays stopped until the person resumes it")
        XCTAssertFalse(scan.hasFinishedGrouping)
        XCTAssertEqual(source.indexCount, 2)
    }

    @MainActor
    func testAChangeMadeWhileAwayIsFoundOnReturn() async throws {
        let (source, changes) = (ChangingPhotoSource(FakePhotoSource(snapshots: photos)), FakeLibraryChanges())
        let (watcher, scan) = makeWatcher(source, changes: changes)
        watcher.start()
        watcher.startScan()
        await scan.waitForScan()

        changes.changeWhileAway()
        watcher.checkForMissedChanges()
        try await waitUntil { source.indexCount == 2 && scan.phase == .done }
    }

    // MARK: - Helpers

    @MainActor
    private func makeWatcher(
        _ source: ChangingPhotoSource, changes: FakeLibraryChanges, gap: Duration = .zero,
        isCleaningUp: @escaping () -> Bool = { false }
    ) -> (LibraryWatcher, ScanStore) {
        let cache = HashCache(filename: "test-hashes-\(UUID().uuidString).json")
        let keepers = "test-keepers-\(UUID().uuidString).json"
        addTeardownBlock {
            await cache.clear()
            JSONFileStore<[String]>(filename: keepers).delete()
        }
        let scan = ScanStore(source: source, cache: cache, keeperFilename: keepers)
        let watcher = LibraryWatcher(
            scan: scan, source: changes, canUseLibrary: { true }, isCleaningUp: isCleaningUp,
            changeDelay: .milliseconds(10), refreshGap: gap, ownChangeWindow: .milliseconds(100))
        return (watcher, scan)
    }

    @MainActor
    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(3)
        while !condition() {
            guard ContinuousClock.now < deadline else { return XCTFail("condition not met in time") }
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}
