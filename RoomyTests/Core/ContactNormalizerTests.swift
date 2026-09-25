// Why: a phone key that differs for one number misses duplicates, and one that is shared by two numbers merges
// two people. These tests pin both sides across several countries' ways of writing numbers.
import XCTest

@testable import Roomy

final class ContactNormalizerTests: XCTestCase {
    private func assertSameNumber(_ first: String, _ second: String, region: String, line: UInt = #line) {
        let key = ContactNormalizer.phoneKey(first, region: region)
        XCTAssertNotNil(key, line: line)
        XCTAssertEqual(key, ContactNormalizer.phoneKey(second, region: region), line: line)
    }

    private func assertDifferentNumbers(_ first: String, _ second: String, region: String, line: UInt = #line) {
        XCTAssertNotEqual(
            ContactNormalizer.phoneKey(first, region: region), ContactNormalizer.phoneKey(second, region: region),
            line: line)
    }

    func testInternationalAndNationalFormsShareAKey() {
        assertSameNumber("+33 6 12 34 56 78", "06 12 34 56 78", region: "FR")
        assertSameNumber("+61 412 345 678", "0412 345 678", region: "AU")
        assertSameNumber("+49 30 1234567", "030 1234567", region: "DE")
        assertSameNumber("+34 612 345 678", "612 345 678", region: "ES")
        assertSameNumber("+65 9123 4567", "9123 4567", region: "SG")
        assertSameNumber("+44 (0)20 7946 0000", "020 7946 0000", region: "GB")
        assertSameNumber("+39 06 1234 5678", "06 1234 5678", region: "IT")
        assertSameNumber("+91 98765 43210", "098765 43210", region: "IN")
        assertSameNumber("+1 (555) 123-4567", "1-555-123-4567", region: "US")
    }

    func testInternationalCallPrefixesMeanPlus() {
        assertSameNumber("0049 30 1234567", "+49 30 1234567", region: "DE")
        assertSameNumber("011 33 6 12 34 56 78", "+33 6 12 34 56 78", region: "US")
        assertSameNumber("0011 44 20 7946 0000", "+44 20 7946 0000", region: "AU")
    }

    func testAnExtensionIsReadHoweverItIsWritten() {
        assertSameNumber("(555) 123-4567 ext. 12", "555 123 4567 x12", region: "US")
        assertSameNumber("555 123 4567;12", "+1 555 123 4567 x12", region: "US")
        assertSameNumber("555 123 4567,,12", "5551234567 x 12", region: "US")
        XCTAssertEqual(ContactNormalizer.phoneKey("555 123 4567 x12", region: "US"), "+15551234567x12")
    }

    /// Regression: extensions were dropped, so Bob on x12 and Alice on x34 of one office line shared a key and
    /// were offered as one person, and a merge dropped "x2" when the kept card had the bare number.
    func testDifferentExtensionsAreDifferentNumbers() {
        assertDifferentNumbers("555-123-4567 x12", "555-123-4567 x34", region: "US")
        assertDifferentNumbers("555-123-4567 x12", "555-123-4567", region: "US")
        XCTAssertNotEqual(
            ContactNormalizer.phoneIdentity("5559990000 x2", region: "US"),
            ContactNormalizer.phoneIdentity("5559990000", region: "US"))
    }

    func testDifferentNumbersNeverShareAKey() {
        assertDifferentNumbers("+91 98765 43210", "+1 987 654 3210", region: "US")
        assertDifferentNumbers("+33 6 12 34 56 78", "+44 6 12 34 56 78", region: "FR")
        assertDifferentNumbers("+49 30 1234567", "+49 30 1234568", region: "DE")
        assertDifferentNumbers("555 123 4567 x12", "555 123 4568", region: "US")
    }

    func testUnknownRegionComparesDigitsAndShortCodesHaveNoKey() {
        assertSameNumber("612-345-678", "612 345 678", region: "")
        XCTAssertNil(ContactNormalizer.phoneKey("112", region: "US"))
        XCTAssertNil(ContactNormalizer.phoneKey("*123#", region: "US"))
    }

    func testNameKeyIgnoresAccentsCaseAndOrder() {
        XCTAssertEqual(ContactNormalizer.nameKey("José  García"), ContactNormalizer.nameKey("garcia jose"))
        XCTAssertNil(ContactNormalizer.nameKey("  "))
    }
}
