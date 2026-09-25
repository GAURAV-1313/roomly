// Why: the Recently Deleted reminder is a claim about the person's phone, so its wording follows what Roomy
// measured: certain right after a cleanup, uncertain after a rise it could not explain.
import XCTest

@testable import Roomy

final class PendingSpaceNoticeTests: XCTestCase {
    private let pending = PendingReclaim(
        entries: [.init(bytes: 40_000_000, itemCount: 2, date: Date(timeIntervalSince1970: 0))],
        freeBefore: 10_000_000_000)

    func testRightAfterACleanupTheSpaceIsSaidToBeWaiting() {
        let notice = PendingSpaceNotice(pending)
        XCTAssertEqual(notice.title, "\(Int64(40_000_000).byteString) in Recently Deleted")
        XCTAssertEqual(notice.message, "Empty it in Photos to free it.")
        XCTAssertTrue(notice.hint.hasPrefix("It still uses space"))
    }

    /// Regression: 40 MB moved, then Recently Deleted emptied while iOS cleared 100 MB of caches. The 140 MB
    /// rise read as unexplained and the reminder went on saying "It still uses space" for up to 30 days.
    func testAfterAnUnexplainedRiseTheSpaceIsOnlySaidToBePossiblyWaiting() {
        let notice = PendingSpaceNotice(pending.rebased(freeNow: 10_140_000_000))
        XCTAssertEqual(notice.title, "\(Int64(40_000_000).byteString) may be in Recently Deleted")
        XCTAssertFalse(notice.message.contains("still uses space"))
        XCTAssertFalse(notice.hint.contains("still uses space"))
    }
}
