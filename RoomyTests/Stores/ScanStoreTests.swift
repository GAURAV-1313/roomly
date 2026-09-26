// Why: the scan store's phases are what the whole UI reacts to. These tests run it against a fake library,
// including the regressions where a cancelled scan ended a newer one early, and where a scan that started
// before a cleanup brought the deleted items back.
import XCTest

@testable import Roomy

final class ScanStoreTests: XCTestCase {
    @MainActor
    func testScanPublishesCategoriesAndGroups() async {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 1), .fixture("c", at: 2)]
        let others: [AssetSnapshot] = [
            .fixture("shot", kind: .screenshot, size: 10), .fixture("clip", kind: .video, size: 99),
        ]
        let store = makeStore(FakePhotoSource(snapshots: photos + others))
        store.scan()
        await store.waitForScan()

        XCTAssertEqual(store.phase, .done)
        XCTAssertEqual(store.screenshots.map(\.id), ["shot"])
        XCTAssertEqual(store.videos.map(\.id), ["clip"])
        XCTAssertEqual(store.similarGroups.count, 1)
        XCTAssertEqual(store.similarGroups.first?.members.count, 3)
        XCTAssertEqual(store.allSimilarExtras.count, 2)
    }

    /// Regression: tapping Rescan mid-scan let the cancelled scan write "idle" while the new one was running.
    @MainActor
    func testRescanNeverLetsTheCancelledScanWrite() async throws {
        let store = makeStore(FakePhotoSource(snapshots: [.fixture("v", kind: .video)], delay: .milliseconds(400)))
        store.scan()
        store.scan()
        try await Task.sleep(for: .milliseconds(120))
        XCTAssertEqual(store.phase, .indexing, "the cancelled scan must not end the new one")

        await store.waitForScan()
        XCTAssertEqual(store.phase, .done)
        XCTAssertEqual(store.videos.map(\.id), ["v"])
    }

    @MainActor
    func testCancelBeforeResultsReturnsToIdleAndStaysThere() async throws {
        let store = makeStore(FakePhotoSource(snapshots: [.fixture("v", kind: .video)], delay: .milliseconds(200)))
        store.scan()
        store.cancel()
        XCTAssertEqual(store.phase, .idle)

        try await Task.sleep(for: .milliseconds(350))
        XCTAssertEqual(store.phase, .idle)
        XCTAssertFalse(store.hasResults)
    }

    /// Regression: cancelling while comparing set the phase to done, so Similar Photos said "All clear".
    @MainActor
    func testCancelWhileComparingIsStoppedNotDoneAndKeepsHashes() async throws {
        let cache = makeCache()
        let photos = (0..<16).map { AssetSnapshot.fixture("p\($0)", at: Double($0)) }
        let store = makeStore(FakePhotoSource(snapshots: photos, tileDelay: .milliseconds(100)), cache: cache)
        store.scan()
        try await waitUntil { store.phase == .comparing }
        try await Task.sleep(for: .milliseconds(150))
        store.cancel()

        XCTAssertEqual(store.phase, .stopped)
        XCTAssertTrue(store.similarGroups.isEmpty)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(store.phase, .stopped, "a stopped scan never reports done later")
        let cached = await cache.load()
        XCTAssertFalse(cached.isEmpty, "hashes computed before the stop are kept for the next scan")
        XCTAssertLessThan(cached.count, photos.count)
    }

    /// Regression: a rescan emptied the earlier groups as soon as indexing ended, and a stop left them empty.
    @MainActor
    func testStoppedRescanKeepsTheEarlierGroups() async throws {
        let cache = makeCache()
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 1), .fixture("c", at: 2)]
        let store = makeStore(FakePhotoSource(snapshots: photos, tileDelay: .milliseconds(200)), cache: cache)
        store.scan()
        await store.waitForScan()
        XCTAssertEqual(store.similarGroups.count, 1)

        await cache.clear()
        store.scan()
        try await waitUntil { store.phase == .comparing }
        XCTAssertEqual(store.similarGroups.count, 1, "earlier groups stay while the new comparison runs")
        store.cancel()
        XCTAssertEqual(store.phase, .stopped)
        XCTAssertEqual(store.similarGroups.count, 1)
    }

    /// Regression: photos that could not be read were counted as compared and never mentioned.
    @MainActor
    func testPhotosThatCannotBeReadAreCountedAsUnchecked() async {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 1), .fixture("icloud", at: 2)]
        let store = makeStore(FakePhotoSource(snapshots: photos, unreadable: ["icloud"]))
        store.scan()
        await store.waitForScan()

        XCTAssertEqual(store.phase, .done)
        XCTAssertEqual(store.uncheckedPhotoCount, 1)
        XCTAssertEqual(store.hashProgress.failed, 1)
        XCTAssertEqual(store.hashProgress.compared, 2)
        XCTAssertEqual(store.similarGroups.first?.members.count, 2)
    }

    @MainActor
    func testScanStoreForgetsDeletedAssetsAndShrinksGroups() async {
        let photos: [AssetSnapshot] = [.fixture("p1"), .fixture("p2", at: 1), .fixture("p3", at: 2)]
        let store = makeStore(FakePhotoSource(snapshots: photos))
        store.scan()
        await store.waitForScan()
        let best = store.similarGroups.first?.best ?? ""

        store.remove([best])
        XCTAssertEqual(store.similarGroups.first?.members.count, 2)
        XCTAssertNotEqual(store.similarGroups.first?.best, best, "a removed keeper hands over to the next photo")

        store.remove(Set(store.similarGroups.first?.members.prefix(1) ?? []))
        XCTAssertTrue(store.similarGroups.isEmpty, "one photo is not a group")
    }

    /// Regression: a scan that read the library before a cleanup put the deleted items back when it finished.
    @MainActor
    func testAScanThatStartedBeforeACleanupNeverBringsRemovedItemsBack() async {
        let photos: [AssetSnapshot] = [.fixture("p1"), .fixture("p2", at: 1), .fixture("p3", at: 2)]
        let shot = AssetSnapshot.fixture("shot", kind: .screenshot, size: 10)
        let store = makeStore(FakePhotoSource(snapshots: photos + [shot], delay: .milliseconds(200)))
        store.scan()
        store.remove(["shot", "p1"])
        await store.waitForScan()

        XCTAssertTrue(store.screenshots.isEmpty)
        XCTAssertNil(store.snapshot("p1"))
        XCTAssertEqual(Set(store.similarGroups.flatMap(\.members)), ["p2", "p3"])
    }

    /// Regression: a group that lost its keeper made the next photo the keeper even when it was queued for
    /// removal, so a later cleanup could take the group's last photos.
    @MainActor
    func testARemovedKeeperHandsOverToAPhotoThatIsNotQueued() async throws {
        let photos: [AssetSnapshot] = [.fixture("p1"), .fixture("p2", at: 1), .fixture("p3", at: 2)]
        let store = makeStore(FakePhotoSource(snapshots: photos))
        store.scan()
        await store.waitForScan()
        let group = try XCTUnwrap(store.similarGroups.first)
        let queued = group.extras[0]

        store.remove([group.best], queued: [queued])

        let updated = try XCTUnwrap(store.similarGroups.first)
        XCTAssertEqual(updated.best, group.extras[1])
        XCTAssertEqual(updated.members.first, updated.best, "the keeper stays first")
    }

    @MainActor
    func testGroupingIsKnownOnlyOnceTheLibraryHasBeenCompared() async {
        let store = makeStore(FakePhotoSource(snapshots: [.fixture("p1"), .fixture("p2", at: 1)]))
        XCTAssertFalse(store.hasFinishedGrouping)
        store.scan()
        await store.waitForScan()
        XCTAssertTrue(store.hasFinishedGrouping)
    }

    /// Every store gets its own keeper file: the app's real one lives in the same folder while tests run.
    @MainActor
    private func makeStore(_ source: FakePhotoSource, cache: HashCache? = nil) -> ScanStore {
        let keepers = "test-keepers-\(UUID().uuidString).json"
        addTeardownBlock { JSONFileStore<[String]>(filename: keepers).delete() }
        return ScanStore(source: source, cache: cache ?? makeCache(), keeperFilename: keepers)
    }

    private func makeCache() -> HashCache {
        let cache = HashCache(filename: "test-hashes-\(UUID().uuidString).json")
        addTeardownBlock { await cache.clear() }
        return cache
    }

    @MainActor
    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(2)
        while !condition() {
            guard ContinuousClock.now < deadline else { return XCTFail("condition not met in time") }
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}
