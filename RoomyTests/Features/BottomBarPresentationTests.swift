// Why: beside "Select all" the Review capsule shortens, and VoiceOver must still hear the full words; the bulk
// action flips in place. These tests pin both titles, that they count the same items, and that items on hold
// alone keep the capsule quiet.
import XCTest

@testable import Roomy

final class BottomBarPresentationTests: XCTestCase {
    private func review(_ items: [BasketItem]) -> BasketReview {
        BasketReview(items: items, canUsePhotos: true, canCheckSimilarGroups: true, mergeableGroupIDs: ["merge"])
    }

    func testBesideABulkActionTheTitleShortensAndVoiceOverKeepsTheWords() {
        let items = (1...8).map { BasketItem(id: "shot\($0)", kind: .screenshot, bytes: 1_000_000) }
        let model = ReviewBarModel(review: review(items), hasBulkAction: true)
        XCTAssertEqual(model.title, "Review 8 · \(Int64(8_000_000).byteString)")
        XCTAssertEqual(model.accessibilityLabel, "Review 8 items · \(Int64(8_000_000).byteString)")
        XCTAssertTrue(model.isProminent)
        XCTAssertEqual(ReviewBarModel(review: review(items), hasBulkAction: false).title, model.accessibilityLabel)
    }

    func testMergesWithNoSizeCountItems() {
        let model = ReviewBarModel(
            review: review([BasketItem(id: "merge", kind: .contactGroup, bytes: nil)]), hasBulkAction: true)
        XCTAssertEqual(model.title, "Review 1 item")
    }

    func testNothingSavedHidesTheCapsuleAndHeldItemsKeepItQuiet() {
        XCTAssertNil(ReviewBarModel(review: review([]), hasBulkAction: true).title)
        let held = ReviewBarModel(
            review: review([BasketItem(id: "stale", kind: .contactGroup, bytes: nil)]), hasBulkAction: true)
        XCTAssertEqual(held.title, "Review · 1 on hold")
        XCTAssertFalse(held.isProminent)
    }

    func testBulkActionFlipsInPlaceAndNamesWhatItSelects() {
        let off = BulkSelection(isAllSelected: false, noun: "extras") {}
        XCTAssertEqual(off.title, "Select all")
        XCTAssertEqual(off.accessibilityLabel, "Select all extras")
        XCTAssertEqual(off.systemImage, "circle")
        let on = BulkSelection(isAllSelected: true) {}
        XCTAssertEqual(on.title, "Deselect all")
        XCTAssertEqual(on.accessibilityLabel, "Deselect all")
    }
}
