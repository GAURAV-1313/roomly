// Why: the numbers under each category title replaced the summary card, so no count or size the card showed may
// be lost, and none may be made up: an iCloud-only part is named, an unknown size says so. These tests pin the
// line for Similar Photos, Screenshots and Duplicate Contacts.
import XCTest

@testable import Roomy

final class CategoryScreenSummaryTests: XCTestCase {
    private let phoneOnly = SizeTotal(knownBytes: 48_200_000, knownCount: 31)
    private let mixed = SizeTotal(knownBytes: 2_000_000, knownCount: 2, inCloudBytes: 860_000_000)

    func testSimilarSubtitleKeepsEveryCount() {
        let summary = SimilarPhotosSummary(groupCount: 12, extraCount: 31, size: phoneOnly)
        XCTAssertEqual(summary.subtitle, "\(Int64(48_200_000).byteString) · 12 groups · 31 extras")
        let single = SimilarPhotosSummary(groupCount: 1, extraCount: 1, size: phoneOnly)
        XCTAssertEqual(single.subtitle, "\(phoneOnly.text) · 1 group · 1 extra")
    }

    func testSimilarSubtitleNamesTheICloudPart() {
        let summary = SimilarPhotosSummary(groupCount: 2, extraCount: 3, size: mixed)
        XCTAssertEqual(summary.subtitle, "\(mixed.text) · 2 groups · 3 extras")
        XCTAssertTrue(summary.subtitle.contains("\(Int64(860_000_000).byteString) in iCloud"))
    }

    func testSimilarSubtitleNeverShowsAMadeUpSize() {
        let summary = SimilarPhotosSummary(groupCount: 1, extraCount: 2, size: SizeTotal(unknownCount: 2))
        XCTAssertEqual(summary.subtitle, "size unavailable · 1 group · 2 extras")
    }

    func testScreenshotsSubtitleCountsLikeTheDashboardTile() {
        XCTAssertEqual(ScreenshotsSummary(count: 84, size: phoneOnly).subtitle, "\(phoneOnly.text) · 84 screenshots")
        XCTAssertEqual(ScreenshotsSummary(count: 1, size: phoneOnly).subtitle, "\(phoneOnly.text) · 1 screenshot")
        XCTAssertEqual(ScreenshotsSummary(count: 3, size: mixed).subtitle, "\(mixed.text) · 3 screenshots")
    }

    func testContactsSubtitleCountsGroupsAndCardsBeforeAndAfter() {
        let groups = [
            ContactGroup(id: "g1", primary: "a", extras: ["b"], reason: .samePhone),
            ContactGroup(id: "g2", primary: "c", extras: ["d", "e"], reason: .sameEmail),
            ContactGroup(id: "g3", primary: "f", extras: ["g"], reason: .samePhone),
        ]
        XCTAssertEqual(ContactsSummary(groups: groups, extraCardCount: 4).subtitle, "3 groups · 7 cards → 3")
        XCTAssertEqual(ContactsSummary(groups: [groups[0]], extraCardCount: 1).subtitle, "1 group · 2 cards → 1")
    }
}
