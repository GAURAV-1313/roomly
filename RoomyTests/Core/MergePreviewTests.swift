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
        XCTAssertEqual(preview.phones.map(\.sourceCard), [1, 2])
    }

    /// The tag reads "from card N", so each added value must name the card the member rows number N.
    func testAddedValuesNameTheCardTheyComeFrom() {
        let preview = MergePreview(
            primary: .fixture("a", "Rahul Verma", emails: ["rahul@example.com"]),
            extras: [
                .fixture("b", "Rahul V", emails: ["rahul@example.com"]),
                .fixture(
                    "c", "R. Verma", phones: ["+91 99870 55310"], emails: ["RAHUL@example.com", "r@work.example"]),
            ],
            region: "IN")
        XCTAssertEqual(preview.emails.map(\.text), ["rahul@example.com", "r@work.example"])
        XCTAssertEqual(preview.emails.map(\.sourceCard), [1, 3])
        XCTAssertEqual(preview.phones.map(\.sourceCard), [3])
        XCTAssertEqual(preview.emails.map(\.isAdded), [false, true])
    }

    func testTheCompanyNamesItsCardAndIsAbsentWhenNoCardHasOne() {
        let fromSecond = MergePreview(
            primary: .fixture("a", "Ana"), extras: [ContactCard(id: "b", name: "Ana", organization: "Northwind")],
            region: "")
        XCTAssertEqual(fromSecond.organization, MergedValue(text: "Northwind", sourceCard: 2))
        XCTAssertNil(
            MergePreview(primary: .fixture("a", "Ana"), extras: [.fixture("b", "Ana")], region: "").organization)
    }

    func testMembersAreNumberedKeptFirstAndMarkTheValuesThatLinkThem() {
        let preview = MergePreview(
            primary: .fixture("a", "Anika Mehta", phones: ["+1 555 123 4567", "+1 555 400 1234"]),
            extras: [.fixture("b", "Anika M", phones: ["(555) 123-4567"], emails: ["anika@example.com"])],
            region: "US")
        XCTAssertEqual(preview.members.map(\.number), [1, 2])
        XCTAssertEqual(preview.members.map(\.isKept), [true, false])
        XCTAssertEqual(preview.members[0].values.map(\.isShared), [true, false])
        XCTAssertEqual(preview.members[1].values.map(\.text), ["(555) 123-4567", "anika@example.com"])
        XCTAssertEqual(preview.members[1].values.map(\.isShared), [true, false])
    }

    func testAValueOnlyOneCardCarriesIsNotMarkedEvenIfItRepeatsOnThatCard() {
        let members = MergeMember.members(
            of: [.fixture("a", "Jo", emails: ["jo@x.com", "JO@x.com"]), .fixture("b", "Jo", emails: ["j@y.com"])],
            region: "")
        XCTAssertEqual(members[0].values.map(\.isShared), [false, false])
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
