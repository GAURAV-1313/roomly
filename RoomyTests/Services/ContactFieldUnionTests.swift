// Why: a merge deletes cards with no system prompt, so everything on them must end up on the kept card or in
// the backup. These tests fold in-memory cards (no address book is touched) and read back the result.
import Contacts
import XCTest

@testable import Roomy

final class ContactFieldUnionTests: XCTestCase {
    private func card(_ given: String, phones: [String] = [], configure: (CNMutableContact) -> Void = { _ in })
        -> CNMutableContact
    {
        let contact = CNMutableContact()
        contact.givenName = given
        contact.familyName = "Smith"
        contact.phoneNumbers = phones.map {
            CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: $0))
        }
        configure(contact)
        return contact
    }

    func testSingleValueFieldsFillGapsAndNeverOverwrite() {
        let kept = card("Robert") { $0.jobTitle = "Chef" }
        let extra = card("Robert") {
            $0.nickname = "Bobby"
            $0.middleName = "James"
            $0.namePrefix = "Dr."
            $0.nameSuffix = "Jr."
            $0.phoneticGivenName = "ロバート"
            $0.previousFamilyName = "Jones"
            $0.jobTitle = "Cook"
            $0.nonGregorianBirthday = DateComponents(
                calendar: Calendar(identifier: .hebrew), year: 5780, month: 1, day: 1)
        }
        ContactFieldUnion.fold([extra], into: kept, region: "US")
        XCTAssertEqual(kept.nickname, "Bobby", "regression: the nickname was lost in the merge")
        XCTAssertEqual(kept.middleName, "James")
        XCTAssertEqual(kept.namePrefix, "Dr.")
        XCTAssertEqual(kept.nameSuffix, "Jr.")
        XCTAssertEqual(kept.phoneticGivenName, "ロバート")
        XCTAssertEqual(kept.previousFamilyName, "Jones")
        XCTAssertNotNil(kept.nonGregorianBirthday)
        XCTAssertEqual(kept.jobTitle, "Chef")
    }

    func testRelationsAndProfilesKeepTheirDistinguishingParts() {
        let kept = card("Ann") {
            $0.contactRelations = [
                CNLabeledValue(label: CNLabelContactRelationMother, value: CNContactRelation(name: "Jane"))
            ]
            $0.socialProfiles = [
                CNLabeledValue(
                    label: nil,
                    value: CNSocialProfile(
                        urlString: "https://a.example/1", username: "", userIdentifier: nil, service: "Site"))
            ]
        }
        let extra = card("Ann") {
            $0.contactRelations = [
                CNLabeledValue(label: CNLabelContactRelationSister, value: CNContactRelation(name: "Jane"))
            ]
            $0.socialProfiles = [
                CNLabeledValue(
                    label: nil,
                    value: CNSocialProfile(
                        urlString: "https://a.example/2", username: "", userIdentifier: nil, service: "Site"))
            ]
        }
        ContactFieldUnion.fold([extra], into: kept, region: "US")
        XCTAssertEqual(kept.contactRelations.count, 2, "regression: Jane the sister was dropped for Jane the mother")
        XCTAssertEqual(kept.socialProfiles.count, 2)
    }

    func testThePhotoIsCarriedOverWhenTheKeptCardHasNone() {
        let kept = card("Mom")
        let extra = card("Mom") { $0.imageData = Self.tinyPNG }
        ContactFieldUnion.fold([extra], into: kept, region: "US")
        XCTAssertEqual(kept.imageData, Self.tinyPNG)
    }

    func testTheMergedCardEqualsThePreview() {
        let keptPhones = ["+1 555 123 4567", "(555) 123-4567"]
        let extraPhones = ["555.123.4567", "5559990000", "5559990000 x2"]
        let kept = card("Ana", phones: keptPhones)
        ContactFieldUnion.fold([card("Ana", phones: extraPhones)], into: kept, region: "US")
        let preview = MergePreview(
            primary: .fixture("a", "Ana Smith", phones: keptPhones),
            extras: [.fixture("b", "Ana Smith", phones: extraPhones)],
            region: "US")
        XCTAssertEqual(
            kept.phoneNumbers.map(\.value.stringValue), preview.phones.map(\.text),
            "regression: the preview and the merge disagreed on the kept card's numbers")
        XCTAssertTrue(
            kept.phoneNumbers.map(\.value.stringValue).contains("5559990000 x2"),
            "regression: a number with an extension was dropped because the bare number was already there")
    }

    func testTheBackupKeepsThePhoto() throws {
        let contact = card("Mom") { $0.imageData = Self.tinyPNG }
        let data = try VCardBackup.vCardData(for: [contact])
        let restored = try CNContactVCardSerialization.contacts(with: data)
        XCTAssertEqual(restored.count, 1)
        XCTAssertNotNil(restored.first?.imageData, "regression: the backup could not bring a photo back")
        XCTAssertEqual(VCardPhoto.adding(Self.tinyPNG, to: data), data, "a card never gets a second photo")
    }

    func testAPhotoMissingFromTheVCardIsAdded() throws {
        let withoutPhoto = try CNContactVCardSerialization.data(with: [card("Mom")])
        let restored = try CNContactVCardSerialization.contacts(with: VCardPhoto.adding(Self.tinyPNG, to: withoutPhoto))
        XCTAssertEqual(restored.first?.givenName, "Mom")
        XCTAssertEqual(restored.first?.imageData, Self.tinyPNG, "regression: the backup dropped the card's photo")
    }

    /// A 1×1 PNG.
    private static let tinyPNG =
        Data(
            base64Encoded:
                "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")
        ?? Data()
}
