// Why: the basket is reconciled whenever the scan's results settle. A stopped comparison has its index read
// again without leaving `.stopped`, so these tests pin that every settling, that one included, is announced.
import XCTest

@testable import Roomy

final class ScanStoreSettleTests: XCTestCase {
    private let photos: [AssetSnapshot] =
        (0..<6).map { AssetSnapshot.fixture("p\($0)", at: Double($0)) }
        + [.fixture("clip", kind: .video, at: 9, size: 900_000_000)]

    @MainActor
    func testAFinishedScanSettles() async {
        let store = makeStore(ChangingPhotoSource(FakePhotoSource(snapshots: photos)))
        XCTAssertEqual(store.settledCount, 0)
        store.scan()
        await store.waitForScan()
        XCTAssertEqual(store.settledCount, 1)
    }

    /// Regression: a video deleted in Photos during a stopped comparison left the index, but the phase stayed
    /// `.stopped`, so the basket was never reconciled and still counted the video until Resume.
    @MainActor
    func testReadingAStoppedComparisonsIndexAgainSettles() async throws {
        var library = FakePhotoSource(snapshots: photos)
        library.tileDelay = .milliseconds(200)
        let source = ChangingPhotoSource(library)
        let store = makeStore(source)
        store.scan()
        try await waitUntil { store.phase == .comparing }
        store.cancel()
        XCTAssertEqual(store.phase, .stopped)
        XCTAssertEqual(store.settledCount, 1, "a stop settles")

        source.replaceSnapshots(photos.filter { $0.id != "clip" })
        store.refreshIndex()
        await store.waitForScan()
        XCTAssertEqual(store.phase, .stopped)
        XCTAssertTrue(store.videos.isEmpty)
        XCTAssertEqual(store.settledCount, 2)
    }

    @MainActor
    func testStoppingBeforeAnyResultsDoesNotSettle() async {
        var library = FakePhotoSource(snapshots: photos)
        library.delay = .milliseconds(200)
        let store = makeStore(ChangingPhotoSource(library))
        store.scan()
        store.cancel()
        XCTAssertEqual(store.phase, .idle)
        XCTAssertEqual(store.settledCount, 0)
    }

    // MARK: - Helpers

    @MainActor
    private func makeStore(_ source: ChangingPhotoSource) -> ScanStore {
        let keepers = "test-keepers-\(UUID().uuidString).json"
        let cache = HashCache(filename: "test-hashes-\(UUID().uuidString).json")
        addTeardownBlock {
            await cache.clear()
            JSONFileStore<[String]>(filename: keepers).delete()
        }
        return ScanStore(source: source, cache: cache, keeperFilename: keepers)
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
