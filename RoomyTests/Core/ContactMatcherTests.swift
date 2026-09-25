// Why: a wrong contact group leads to a wrong merge, which has no system prompt and no Recently Deleted.
// These tests pin precision: only shared numbers and emails link cards, shared switchboards and big clusters
// do not, exact copies are still found, and a group's label never overstates its evidence.
import XCTest

@testable import Roomy

final class ContactMatcherTests: XCTestCase {
    private func groups(_ cards: [ContactCard]) -> [ContactGroup] {
        ContactMatcher.groups(cards, region: "US")
    }

    func testPhoneFormattingAndCountryCodeStillMatch() {
        let found = groups([
            .fixture("a", "Ana Silva", phones: ["+1 (555) 123-4567"]),
            .fixture("b", "Ana S.", phones: ["555.123.4567"]),
        ])
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.first?.reason, .samePhone)
    }

    func testEmailIgnoresCase() {
        let found = groups([.fixture("a", "", emails: ["Jo@Mail.com"]), .fixture("b", "", emails: ["jo@mail.com "])])
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.first?.reason, .sameEmail)
    }

    func testASharedNameAloneNeverGroupsCards() {
        let gymAndPlumber: [ContactCard] = [
            .fixture("gym", "Mike", phones: ["555-111-2222"], emails: ["mike@gym.com"]),
            .fixture("plumber", "Mike", phones: ["555-333-4444"]),
        ]
        XCTAssertTrue(groups(gymAndPlumber).isEmpty, "regression: two different Mikes were merged")
        XCTAssertTrue(groups([.fixture("a", "Kim Park"), .fixture("b", "Park Kim")]).isEmpty)
        XCTAssertTrue(groups([.fixture("a", "José García"), .fixture("b", "garcia jose")]).isEmpty)
    }

    func testShortCodesNeverLinkCards() {
        XCTAssertTrue(
            groups([.fixture("a", "Pizza", phones: ["112"]), .fixture("b", "Taxi", phones: ["112"])]).isEmpty)
    }

    func testAValueSharedByManyDifferentlyNamedCardsIsIgnored() {
        let office = "+44 20 7946 0000"
        let cards = (1...4).map { ContactCard.fixture("c\($0)", "Person \($0)", phones: [office]) }
        XCTAssertTrue(groups(cards).isEmpty, "a switchboard number is not one person")
    }

    func testIdenticalCopiesAreFoundBeyondTheHubLimit() {
        func copies(_ count: Int) -> [ContactCard] {
            (1...count).map {
                ContactCard.fixture("c\($0)", "Ana Silva", phones: ["+1 555 123 4567"], emails: ["ana@x.com"])
            }
        }
        XCTAssertEqual(groups(copies(4)).first?.members.count, 4, "regression: four identical cards were not found")
        XCTAssertEqual(groups(copies(6)).first?.members.count, 6)
    }

    func testFullestCardIsKeptAndTiesGoToTheFirst() {
        let found = groups([
            .fixture("thin", "Sam Lee", phones: ["5551234567"]),
            .fixture("full", "Sam Lee", phones: ["5551234567", "5550000000"], emails: ["sam@x.com"]),
        ])
        XCTAssertEqual(found.first?.primary, "full")
        XCTAssertEqual(found.first?.extras, ["thin"])

        let tie = groups([
            .fixture("first", "Kim Park", phones: ["5551234567"]),
            .fixture("second", "Kim Park", phones: ["5551234567"]),
        ])
        XCTAssertEqual(tie.first?.primary, "first")
    }

    /// Regression: two people on one office line with different extensions were linked as "Same number".
    func testDifferentExtensionsOfOneLineNeverLink() {
        let found = groups([
            .fixture("bob", "Bob Ray", phones: ["555-123-4567 x12"]),
            .fixture("alice", "Alice Lin", phones: ["555-123-4567 x34"]),
        ])
        XCTAssertTrue(found.isEmpty)
    }

    /// Regression: a work card far fuller than the personal one was kept, so the birthday, address and photo on
    /// the personal card were written into the work account and the personal card deleted.
    func testAPersonalCardIsKeptOverAFarFullerWorkCard() throws {
        let work = ContactCard.fixture(
            "work", "Lee Min",
            phones: ["5550001111", "5550002222", "5550003333", "5550004444"], emails: ["lee@acme.com"])
        let personal = ContactCard.fixture(
            "home", "Lee Min", phones: ["5550001111"], hasImage: true, isInDefaultContainer: true)
        let group = try XCTUnwrap(groups([work, personal]).first)
        XCTAssertEqual(group.primary, "home")
        XCTAssertTrue(group.spansAccounts, "the card says the merge moves data between accounts")
        let sameAccount = try XCTUnwrap(groups([work, .fixture("other", "Lee Min", phones: ["5550001111"])]).first)
        XCTAssertFalse(sameAccount.spansAccounts)
    }

    func testCloseCardsPreferTheDefaultAccountThenThePhoto() {
        let work = ContactCard.fixture("work", "Lee Min", phones: ["5550001111", "5550002222"], emails: ["lee@w.com"])
        let personal = ContactCard.fixture(
            "home", "Lee Min", phones: ["5550001111"], emails: ["lee@x.com"], isInDefaultContainer: true)
        XCTAssertEqual(
            groups([work, personal]).first?.primary, "home", "regression: personal data moved into a work account")

        let photo = ContactCard.fixture("photo", "Lee Min", phones: ["5550001111"], hasImage: true)
        XCTAssertEqual(groups([work, photo]).first?.primary, "work", "a much fuller card still wins")
        let closePhoto = ContactCard.fixture("photo", "Lee Min", phones: ["5550001111", "5550002222"], hasImage: true)
        XCTAssertEqual(groups([work, closePhoto]).first?.primary, "photo")
    }

    func testGroupIsLabelledByItsWeakestLinkAndHasAStableID() {
        let cards: [ContactCard] = [
            .fixture("a", "Lee Min", emails: ["lee@x.com"]),
            .fixture("b", "Lee Min", phones: ["5550001111"], emails: ["lee@x.com"]),
            .fixture("c", "Other", phones: ["5550001111"]),
        ]
        let found = groups(cards)
        XCTAssertEqual(found.first?.members.count, 3)
        XCTAssertEqual(found.first?.reason, .sameEmail, "regression: card a shares no number, yet read 'Same number'")
        XCTAssertEqual(found.first?.id, groups(cards.reversed()).first?.id)
    }

    func testGroupNoticesACardEditedAfterTheScan() throws {
        let ana = ContactCard.fixture("a", "Ana Silva", phones: ["5551234567"])
        let copy = ContactCard.fixture("b", "Ana", phones: ["5551234567"])
        let group = try XCTUnwrap(groups([ana, copy]).first)
        XCTAssertEqual(group.phoneRegion, "US")
        XCTAssertTrue(group.isUnchanged([ana, copy]))

        let renamed = ContactCard.fixture("b", "Bruno Costa", phones: ["5551234567"])
        XCTAssertFalse(group.isUnchanged([ana, renamed]), "regression: an edited card was merged anyway")
        XCTAssertFalse(group.isUnchanged([ana]), "a card that disappeared counts as changed")
        XCTAssertFalse(ContactGroup(id: "g", primary: "a", extras: ["b"], reason: .samePhone).isUnchanged([ana, copy]))
    }
}
