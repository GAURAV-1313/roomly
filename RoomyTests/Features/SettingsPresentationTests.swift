// Why: Settings makes two promises in words — what Roomy can access, and how deletion works. These tests pin
// the words, so splitting "How deletion works" into points can never change or drop a sentence.
import XCTest

@testable import Roomy

final class SettingsPresentationTests: XCTestCase {
    func testEveryAccessStateHasItsPlainName() {
        XCTAssertEqual(AccessState.authorized.displayName, "Full access")
        XCTAssertEqual(AccessState.limited.displayName, "Limited")
        XCTAssertEqual(AccessState.denied.displayName, "Off")
        XCTAssertEqual(AccessState.restricted.displayName, "Restricted")
        XCTAssertEqual(AccessState.notDetermined.displayName, "Not asked yet")
    }

    func testDeletionPointsReadAsTheOriginalParagraphWordForWord() {
        let paragraph =
            "Nothing is deleted without your approval. Photos and videos move to Recently Deleted and stay "
            + "there for 30 days; space is reclaimed only when you empty it. Duplicate contact cards are "
            + "merged into one, and every original card is backed up first. Apps can't read notes, so notes "
            + "on removed cards are not kept."
        XCTAssertEqual(DeletionPoint.all.map(\.text).joined(separator: " "), paragraph)
    }

    func testEachDeletionPointHasItsOwnIcon() {
        XCTAssertEqual(DeletionPoint.all.count, 3)
        XCTAssertEqual(Set(DeletionPoint.all.map(\.systemImage)).count, DeletionPoint.all.count)
    }
}
