// Why: which photo a group keeps, and what a size reads, are what the photo screens ask people to trust. These
// tests pin that a photo with no known size stays in its group, that unknown sizes are never shown as zero,
// that only space on this phone counts, and that a chosen keeper survives rescans until it leaves every group.
import XCTest

@testable import Roomy

final class ScanStoreGroupingTests: XCTestCase {
    /// Regression: photos without a known size were dropped from their group once sizes arrived.
    @MainActor
    func testPhotosWithoutASizeStayInTheirGroup() async {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 1), .fixture("c", at: 2)]
        let store = makeStore(FakePhotoSource(snapshots: photos, unsizedIDs: ["b"]))
        store.scan()
        await store.waitForScan()

        XCTAssertEqual(store.similarGroups.first?.members.count, 3)
        XCTAssertNotEqual(store.similarGroups.first?.best, "b", "an unknown size ranks lowest")
        XCTAssertEqual(store.similarSize.unknownCount, 1)
    }

    @MainActor
    func testAllUnknownSizesSaySoInsteadOfZero() async {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 1)]
        let store = makeStore(FakePhotoSource(snapshots: photos, unsizedIDs: ["a", "b"]))
        store.scan()
        await store.waitForScan()
        XCTAssertEqual(store.similarSize.text, "size unavailable")
    }

    /// Regression: an iCloud-only video topped Large Videos and filled Reclaimable with space the phone can't
    /// get back.
    @MainActor
    func testVideosAndReclaimableGoBySpaceOnThisPhone() async {
        let videos: [AssetSnapshot] = [
            .fixture("cloud", kind: .video, size: 3_000_000_000, inCloud: 3_000_000_000),
            .fixture("local", kind: .video, size: 40_000_000),
            .fixture("mixed", kind: .video, size: 900_000_000, inCloud: 800_000_000),
        ]
        let store = makeStore(FakePhotoSource(snapshots: videos))
        store.scan()
        await store.waitForScan()

        XCTAssertEqual(store.videos.map(\.id), ["mixed", "local", "cloud"])
        XCTAssertEqual(store.reclaimableBytes, 140_000_000)
    }

    /// Regression: the person could not choose the keeper, so a favourite shot a few KB smaller was queued.
    @MainActor
    func testChosenKeeperSurvivesRescansAndRelaunches() async {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 1), .fixture("c", at: 2)]
        let keepers = keeperFilename()
        let store = makeStore(FakePhotoSource(snapshots: photos), keepers: keepers)
        store.scan()
        await store.waitForScan()
        let chosen = store.similarGroups.first?.extras.last ?? ""

        store.makeKeeper(chosen)
        XCTAssertEqual(store.similarGroups.first?.best, chosen)
        XCTAssertEqual(store.similarGroups.first?.members.first, chosen)
        XCTAssertFalse(store.similarExtras.contains(chosen))

        store.scan()
        await store.waitForScan()
        XCTAssertEqual(store.similarGroups.first?.best, chosen, "a rescan keeps the choice")

        let relaunched = makeStore(FakePhotoSource(snapshots: photos), keepers: keepers)
        relaunched.scan()
        await relaunched.waitForScan()
        XCTAssertEqual(relaunched.similarGroups.first?.best, chosen, "the choice is saved")
    }

    @MainActor
    func testChoiceIsForgottenOnceItsPhotoLeavesEveryGroup() async {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 1), .fixture("c", at: 2)]
        let keepers = keeperFilename()
        let store = makeStore(FakePhotoSource(snapshots: photos), keepers: keepers)
        store.scan()
        await store.waitForScan()
        let chosen = store.similarGroups.first?.extras.last ?? ""
        store.makeKeeper(chosen)

        let without = makeStore(FakePhotoSource(snapshots: photos.filter { $0.id != chosen }), keepers: keepers)
        without.scan()
        await without.waitForScan()

        let again = makeStore(FakePhotoSource(snapshots: photos), keepers: keepers)
        again.scan()
        await again.waitForScan()
        XCTAssertNotEqual(again.similarGroups.first?.best, chosen, "an old choice never resurfaces")
    }

    /// Regression: a scan that couldn't read the chosen keeper this time (a timeout, an image only in iCloud)
    /// erased the choice, so the next scan brought back the automatic keeper.
    @MainActor
    func testAChoiceSurvivesAScanThatCouldNotReadItsPhoto() async {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 1), .fixture("c", at: 2)]
        let keepers = keeperFilename()
        let store = makeStore(FakePhotoSource(snapshots: photos), keepers: keepers)
        store.scan()
        await store.waitForScan()
        let chosen = store.similarGroups.first?.extras.last ?? ""
        store.makeKeeper(chosen)

        let unreadable = makeStore(FakePhotoSource(snapshots: photos, unreadable: [chosen]), keepers: keepers)
        unreadable.scan()
        await unreadable.waitForScan()
        XCTAssertEqual(unreadable.uncheckedPhotoCount, 1)

        let again = makeStore(FakePhotoSource(snapshots: photos), keepers: keepers)
        again.scan()
        await again.waitForScan()
        XCTAssertEqual(again.similarGroups.first?.best, chosen, "the choice waits for a scan that can read it")
    }

    @MainActor
    private func makeStore(_ source: FakePhotoSource, keepers: String? = nil) -> ScanStore {
        let cache = HashCache(filename: "test-hashes-\(UUID().uuidString).json")
        addTeardownBlock { await cache.clear() }
        return ScanStore(source: source, cache: cache, keeperFilename: keepers ?? keeperFilename())
    }

    private func keeperFilename() -> String {
        let filename = "test-keepers-\(UUID().uuidString).json"
        addTeardownBlock { JSONFileStore<[String]>(filename: filename).delete() }
        return filename
    }
}
