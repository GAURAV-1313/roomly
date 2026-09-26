// Why: the words beside a video are small derivations from real data. These tests pin that none of them invents
// a value — no date, no size, iCloud-only files.
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
}
