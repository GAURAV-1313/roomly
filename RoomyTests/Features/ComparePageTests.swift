// Why: in Compare the photo's state and the button that changes it must never read alike. These tests pin
// the words each state shows and which actions it offers.
import XCTest

@testable import Roomy

final class ComparePageTests: XCTestCase {
    /// Regression: a queued photo showed only a "Keep this one" button, which read like a status.
    func testQueuedPhotoSaysSoApartFromItsButton() {
        let queued = ComparePage(isKeeper: false, isQueued: true)
        XCTAssertEqual(queued, .queued)
        XCTAssertEqual(queued.status, "Selected for removal")
        XCTAssertEqual(queued.toggleTitle, "Keep this one")

        let notQueued = ComparePage(isKeeper: false, isQueued: false)
        XCTAssertEqual(notQueued.status, "Not selected")
        XCTAssertEqual(notQueued.toggleTitle, "Remove this one")
        XCTAssertNotEqual(queued.toggleIcon, notQueued.toggleIcon)
    }

    func testKeeperOffersNoRemovalAndCannotBeMadeKeeperAgain() {
        let keeper = ComparePage(isKeeper: true, isQueued: false)
        XCTAssertEqual(keeper, .keeper)
        XCTAssertNil(keeper.toggleTitle)
        XCTAssertFalse(keeper.canBecomeKeeper)
        XCTAssertTrue(ComparePage.queued.canBecomeKeeper)
    }

    /// Regression: a queued keeper showed only its Best badge, with no word that it would be deleted and no
    /// way to take it out in Compare.
    func testAQueuedKeeperSaysSoAndCanBeKept() {
        let page = ComparePage(isKeeper: true, isQueued: true)
        XCTAssertEqual(page, .keeperQueued)
        XCTAssertTrue(page.isKeeper)
        XCTAssertTrue(page.isQueued)
        XCTAssertEqual(page.status, "Keeper · selected for removal")
        XCTAssertEqual(page.toggleTitle, "Keep this one")
        XCTAssertFalse(page.canBecomeKeeper)
    }
}
