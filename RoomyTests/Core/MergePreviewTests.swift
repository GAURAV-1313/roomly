// Why: people approve a merge by reading this preview, so it must show every value the merged card will hold
// and nothing it will not.
import XCTest

@testable import Roomy

final class MergePreviewTests: XCTestCase {
    func testUnionKeepsFirstSpellingAndTagsAddedValues() {
        let preview = MergePreview(
            primary: .fixture("a", "Ana Silva", phones: ["+1 555 123 4567"], emails: ["ana@x.com"]),
            extras: [.fixture("b", "", phones: ["(555) 123-4567", "5559990000"], emails: ["ANA@x.com", "a@y.com"])],
            region: "US")
        XCTAssertEqual(preview.name, "Ana Silva")
        XCTAssertEqual(preview.phones.map(\.text), ["+1 555 123 4567", "5559990000"])
        XCTAssertEqual(preview.phones.map(\.isAdded), [false, true])
        XCTAssertEqual(preview.emails.map(\.text), ["ana@x.com", "a@y.com"])
        XCTAssertEqual(preview.addedCount, 2)
    }

    func testTheKeptCardsOwnValuesAreAllShown() {
        let preview = MergePreview(
            primary: .fixture("a", "Ana", phones: ["+1 555 123 4567", "(555) 123-4567"]),
            extras: [.fixture("b", "Ana", phones: ["555.123.4567"])], region: "US")
        XCTAssertEqual(
            preview.phones.map(\.text), ["+1 555 123 4567", "(555) 123-4567"],
            "regression: the preview hid a number the merged card keeps")
    }

    func testPhotosThatCannotStayOnTheCardAreCounted() {
        let withPhoto = ContactCard.fixture("a", "Mom", hasImage: true)
        XCTAssertEqual(
            MergePreview(primary: withPhoto, extras: [.fixture("b", "Mom")], region: "").photosOnlyInBackup, 0)
        let bothPhotos = MergePreview(primary: withPhoto, extras: [.fixture("b", "Mom", hasImage: true)], region: "")
        XCTAssertEqual(bothPhotos.photosOnlyInBackup, 1)
    }
}
