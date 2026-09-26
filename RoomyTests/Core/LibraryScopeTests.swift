// Why: the scope decides what Roomy shows, counts and may delete, so its rule is pinned for one asset, one saved
// basket item and one similar group, including the cases where a group is hidden rather than shown with a
// keeper Roomy didn't pick.
import XCTest

@testable import Roomy

final class LibraryScopeTests: XCTestCase {
    private let local = AssetSnapshot.fixture("local", kind: .video, size: 100)
    private let cloud = AssetSnapshot.fixture("cloud", kind: .video, size: 3_000, inCloud: 3_000)
    private let mixed = AssetSnapshot.fixture("mixed", kind: .video, size: 900, inCloud: 800)
    private let unsized = AssetSnapshot.fixture("unsized", kind: .video)

    func testOnThisPhoneLeavesOutAnythingKeptOnlyInICloud() {
        XCTAssertTrue(local.isInScope(.onThisPhone))
        XCTAssertTrue(unsized.isInScope(.onThisPhone), "an unknown size counts as on this phone")
        XCTAssertFalse(cloud.isInScope(.onThisPhone))
        XCTAssertFalse(mixed.isInScope(.onThisPhone))
        XCTAssertTrue([local, cloud, mixed, unsized].allSatisfy { $0.isInScope(.includingICloud) })
    }

    func testTheSwitchReadsAndWritesTheScope() {
        var scope = LibraryScope.onThisPhone
        XCTAssertFalse(scope.includesICloud)
        scope.includesICloud = true
        XCTAssertEqual(scope, .includingICloud)
        scope.includesICloud = false
        XCTAssertEqual(scope, .onThisPhone)
        XCTAssertEqual(LibraryScope(rawValue: LibraryScope.includingICloud.rawValue), .includingICloud)
    }

    func testBasketItemsFollowTheSameRule() {
        XCTAssertFalse(BasketItem(cloud).isInScope(.onThisPhone))
        XCTAssertTrue(BasketItem(cloud).isInScope(.includingICloud))
        XCTAssertTrue(BasketItem(local).isInScope(.onThisPhone))
        XCTAssertTrue(BasketItem(id: "merge", kind: .contactGroup, bytes: nil).isInScope(.onThisPhone))
    }

    /// Regression: an item selected while kept only in iCloud stayed "in iCloud" in Review after it was
    /// downloaded, and a stale "on this phone" would let one slip past the scope.
    func testReviewItemsTakeTheScansLatestSize() {
        let saved = BasketItem(id: "clip", kind: .video, bytes: 0, bytesInCloud: 3_000)
        let downloaded = AssetSnapshot.fixture("clip", kind: .video, size: 3_000)
        XCTAssertEqual(saved.refreshed(from: downloaded), BasketItem(id: "clip", kind: .video, bytes: 3_000))
        XCTAssertEqual(saved.refreshed(from: .fixture("clip", kind: .video)), saved, "no size keeps what is known")
        XCTAssertEqual(saved.refreshed(from: nil), saved)

        let offloaded = BasketItem(local).refreshed(from: .fixture("local", kind: .video, size: 100, inCloud: 100))
        XCTAssertFalse(offloaded.isInScope(.onThisPhone))
    }

    func testAGroupShowsOnlyItsMembersInScope() {
        let group = SimilarGroup(id: "g", members: ["k", "a", "b"], best: "k", reason: .burst)
        let shown = group.limited { $0 != "b" }
        XCTAssertEqual(shown?.members, ["k", "a"])
        XCTAssertEqual(shown?.extras, ["a"])
        XCTAssertEqual(group.limited { _ in true }, group)
    }

    func testAGroupLeftWithOnePhotoIsHidden() {
        let group = SimilarGroup(id: "g", members: ["k", "a"], best: "k", reason: .burst)
        XCTAssertNil(group.limited { $0 == "k" })
    }

    /// Showing the rest would put the Best badge on a photo Roomy didn't pick.
    func testAGroupWhoseKeeperIsOnlyInICloudIsHidden() {
        let group = SimilarGroup(id: "g", members: ["k", "a", "b"], best: "k", reason: .burst)
        XCTAssertNil(group.limited { $0 != "k" })
    }
}
