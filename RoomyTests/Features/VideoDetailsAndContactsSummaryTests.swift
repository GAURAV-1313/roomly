// Why: the words beside a video and above the contact groups are small derivations from real data. These tests
// pin that none of them invents a value — no date, no size, iCloud-only files — and that the counts add up.
import XCTest

@testable import Roomy

final class VideoDetailsAndContactsSummaryTests: XCTestCase {
    func testResolutionNamesTheCommonSizesByTheLongSide() {
        XCTAssertEqual(VideoDetails.resolutionLabel(width: 3840, height: 2160), "4K")
        XCTAssertEqual(VideoDetails.resolutionLabel(width: 1080, height: 1920), "1080p", "portrait counts too")
        XCTAssertEqual(VideoDetails.resolutionLabel(width: 1280, height: 720), "720p")
        XCTAssertEqual(VideoDetails.resolutionLabel(width: 640, height: 480), "640p")
    }

    func testRowLineSaysWhenTheFilesAreOnlyInICloud() {
        let here = AssetSnapshot.fixture("here", kind: .video, width: 3840, height: 2160, size: 1_000_000_000)
        let cloud = AssetSnapshot.fixture(
            "cloud", kind: .video, width: 3840, height: 2160, size: 1_000_000_000, inCloud: 1_000_000_000)
        XCTAssertTrue(VideoDetails.rowLine(here).hasSuffix(" · 4K"))
        XCTAssertTrue(VideoDetails.rowLine(cloud).hasSuffix(" · 4K · in iCloud"))
    }

    func testFactsNeverInventAValue() {
        let unknown = AssetSnapshot(
            id: "v", kind: .video, creationDate: nil, modificationDate: nil, pixelWidth: 3840, pixelHeight: 2160,
            duration: 10, burstIdentifier: nil, isFavorite: false)
        XCTAssertEqual(
            VideoDetails.facts(unknown),
            [
                VideoFact(title: "Recorded", value: "—"),
                VideoFact(title: "Resolution", value: "3840 × 2160"),
                VideoFact(title: "Size", value: "size unavailable"),
            ])
        let cloud = AssetSnapshot.fixture("c", kind: .video, size: 3_000_000_000, inCloud: 3_000_000_000)
        XCTAssertEqual(VideoDetails.facts(cloud).last?.value, "\(Int64(3_000_000_000).byteString) · in iCloud")
    }

    func testContactsSummaryCountsGroupsAndCardsBeforeAndAfter() {
        let groups = [
            ContactGroup(id: "g1", primary: "a", extras: ["b"], reason: .samePhone),
            ContactGroup(id: "g2", primary: "c", extras: ["d", "e"], reason: .sameEmail),
            ContactGroup(id: "g3", primary: "f", extras: ["g"], reason: .samePhone),
        ]
        let summary = ContactsSummary(groups: groups, extraCardCount: 4)
        XCTAssertEqual(summary.value, "3 groups")
        XCTAssertEqual(summary.detail, "7 cards → 3")
        XCTAssertEqual(ContactsSummary(groups: [groups[0]], extraCardCount: 1).value, "1 group")
    }
}
