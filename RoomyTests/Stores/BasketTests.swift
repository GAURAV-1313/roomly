// Why: the basket is the single source of truth for selection and must survive relaunches; these tests
// pin its persistence and its select-all behaviour.
import XCTest

@testable import Roomy

final class BasketTests: XCTestCase {
    @MainActor
    func testItemsSurviveARelaunch() async {
        let filename = temporaryFilename()
        Basket(filename: filename).add([.fixture("clip", kind: .video, size: 1_234)])

        let reloaded = Basket(filename: filename)
        XCTAssertTrue(reloaded.contains("clip"))
        XCTAssertEqual(reloaded.items["clip"]?.bytes, 1_234)
        XCTAssertEqual(reloaded.items(of: .video).count, 1)
    }

    @MainActor
    func testToggleAllAddsWhenAnyIsMissingAndRemovesWhenAllArePresent() async {
        let basket = makeBasket()
        let shots: [AssetSnapshot] = [.fixture("one", kind: .screenshot), .fixture("two", kind: .screenshot)]
        basket.add([shots[0]])

        basket.toggleAll(shots)
        XCTAssertTrue(basket.containsAll(["one", "two"]))

        basket.toggleAll(shots)
        XCTAssertTrue(basket.isEmpty)
    }

    @MainActor
    func testContainsAllIsFalseForNothing() async {
        XCTAssertFalse(makeBasket().containsAll([]))
    }

    @MainActor
    func testPruneDropsItemsMissingFromTheLibrary() async {
        let basket = makeBasket()
        basket.add([.fixture("kept"), .fixture("gone")])
        basket.add([ContactGroup(id: "merge", primary: "a", extras: ["b"], reason: .samePhone)])
        basket.prune(keeping: ["kept"], of: [.photo, .screenshot, .video])
        XCTAssertEqual(Set(basket.items.keys), ["kept", "merge"], "a photo rescan never drops contact merges")
    }

    /// Regression: a queued photo that became its group's keeper after a rescan stayed queued, so "Select extras"
    /// then queued every photo of the group.
    @MainActor
    func testReconcileDropsQueuedKeepersAndPhotosInNoGroup() async {
        let basket = makeBasket()
        basket.add([.fixture("keeper"), .fixture("extra"), .fixture("alone"), .fixture("shot", kind: .screenshot)])

        basket.reconcile(libraryIDs: ["keeper", "extra", "alone", "shot"], removablePhotos: nil)
        XCTAssertEqual(basket.count, 4, "while grouping is unknown only missing assets leave")

        basket.reconcile(libraryIDs: ["keeper", "extra", "alone", "shot"], removablePhotos: ["extra"])
        XCTAssertEqual(Set(basket.items.keys), ["extra", "shot"], "screenshots are never similar photos")
    }

    /// Regression: the Review total added originals kept only in iCloud.
    @MainActor
    func testTotalsKeepICloudOriginalsApart() async {
        let basket = makeBasket()
        basket.add([
            .fixture("cloud", kind: .video, size: 3_000, inCloud: 2_000),
            .fixture("shot", kind: .screenshot, size: 500),
        ])
        let review = ReviewSummary(items: Array(basket.items.values))
        XCTAssertEqual(review.bytes, 1_500, "Review counts only space on this phone")
        XCTAssertEqual(review.bytesInCloud, 2_000, "and names what is kept only in iCloud")
    }

    @MainActor
    private func makeBasket() -> Basket {
        Basket(filename: temporaryFilename())
    }

    private func temporaryFilename() -> String {
        let filename = "test-basket-\(UUID().uuidString).json"
        addTeardownBlock { JSONFileStore<[BasketItem]>(filename: filename).delete() }
        return filename
    }
}
