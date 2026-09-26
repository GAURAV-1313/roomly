// Why: every screen reads the scan through its scoped views, so these tests pin that items kept only in iCloud
// appear nowhere and count nowhere by default, appear with their iCloud size named once included, switch without
// a rescan, and that a size from an earlier scan never outlives fresh data about where the files are.
import XCTest

@testable import Roomy

final class ScanStoreScopeTests: XCTestCase {
    private let library: [AssetSnapshot] = [
        .fixture("shot", kind: .screenshot, size: 200),
        .fixture("cloudShot", kind: .screenshot, size: 300, inCloud: 300),
        .fixture("clip", kind: .video, size: 5_000),
        .fixture("cloudClip", kind: .video, size: 9_000, inCloud: 9_000),
        .fixture("keeper", width: 6000, height: 8000),
        .fixture("extra", at: 1),
        .fixture("cloudExtra", at: 2),
    ]

    @MainActor
    func testICloudOnlyItemsAppearAndCountOnlyOnceIncluded() async {
        let store = makeStore(FakePhotoSource(snapshots: library, inCloudIDs: ["cloudExtra"]))
        store.scan()
        await store.waitForScan()

        XCTAssertEqual(store.screenshots.map(\.id), ["shot"])
        XCTAssertEqual(store.videos.map(\.id), ["clip"])
        XCTAssertEqual(store.similarGroups.first?.members, ["keeper", "extra"])
        XCTAssertEqual(store.suggestedExtras, ["extra"])
        XCTAssertEqual(store.similarSize.inCloudBytes, 0)
        XCTAssertEqual(store.reclaimableBytes, 200 + 5_000 + 1_000)

        store.scope = .includingICloud
        XCTAssertEqual(store.screenshots.count, 2)
        XCTAssertEqual(store.videos.map(\.id), ["clip", "cloudClip"])
        XCTAssertEqual(Set(store.suggestedExtras), ["extra", "cloudExtra"])
        XCTAssertEqual(store.similarSize.inCloudBytes, 1_000, "named apart, as \"+ X in iCloud\"")
        XCTAssertEqual(store.reclaimableBytes, 200 + 5_000 + 1_000, "iCloud bytes are never counted as space here")
    }

    @MainActor
    func testAGroupWhoseKeeperIsOnlyInICloudIsHiddenButStillGuarded() async throws {
        let store = makeStore(FakePhotoSource(snapshots: library, inCloudIDs: ["keeper"]))
        store.scan()
        await store.waitForScan()
        let group = try XCTUnwrap(store.allSimilarGroups.first)
        XCTAssertEqual(group.best, "keeper")

        XCTAssertTrue(store.similarGroups.isEmpty)
        XCTAssertNil(store.similarGroup(group.id))
        XCTAssertEqual(Set(store.allSimilarExtras), ["extra", "cloudExtra"], "the basket still knows the whole group")
    }

    /// Regression: a video's size from an earlier scan was carried over when Photos no longer reported one, so an
    /// original downloaded since kept reading "in iCloud".
    @MainActor
    func testAVideosFreshSizeReplacesAStaleICloudOne() async {
        let source = ChangingPhotoSource(FakePhotoSource(snapshots: library))
        let store = makeStore(source)
        store.scan()
        await store.waitForScan()
        XCTAssertEqual(store.snapshot("cloudClip")?.size?.isInCloud, true)

        source.replaceSnapshots(library.filter { $0.id != "cloudClip" } + [.fixture("cloudClip", kind: .video)])
        store.scan()
        await store.waitForScan()
        XCTAssertNil(store.snapshot("cloudClip")?.size)
        XCTAssertTrue(store.videos.contains { $0.id == "cloudClip" })
    }

    /// Regression: a grouped photo Photos gave no size for kept the earlier scan's "in iCloud".
    @MainActor
    func testAPhotosFreshMeasurementReplacesACarriedOne() async {
        let source = ChangingPhotoSource(FakePhotoSource(snapshots: library, inCloudIDs: ["cloudExtra"]))
        let store = makeStore(source)
        store.scan()
        await store.waitForScan()
        XCTAssertEqual(store.snapshot("cloudExtra")?.size?.isInCloud, true)

        source.replaceLibrary(FakePhotoSource(snapshots: library, unsizedIDs: ["cloudExtra"]))
        store.scan()
        await store.waitForScan()
        XCTAssertNil(store.snapshot("cloudExtra")?.size)
        XCTAssertEqual(store.similarGroups.first?.members.count, 3)

        source.replaceLibrary(FakePhotoSource(snapshots: library))
        store.scan()
        await store.waitForScan()
        XCTAssertEqual(store.snapshot("cloudExtra")?.size?.isInCloud, false, "downloaded since")
    }

    @MainActor
    private func makeStore(_ source: any PhotoSource) -> ScanStore {
        let keepers = "test-keepers-\(UUID().uuidString).json"
        let cache = HashCache(filename: "test-hashes-\(UUID().uuidString).json")
        addTeardownBlock {
            await cache.clear()
            JSONFileStore<[String]>(filename: keepers).delete()
        }
        return ScanStore(source: source, cache: cache, keeperFilename: keepers)
    }
}
