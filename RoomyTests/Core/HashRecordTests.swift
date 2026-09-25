// Why: a flat frame's hash says nothing, so whether a photo "has detail" decides whether it may be linked at
// all. These tests pin that signal, how it is measured, and that old cached records are measured again.
import XCTest

@testable import Roomy

final class HashRecordTests: XCTestCase {
    private let mixedHash: UInt64 = 0x0F0F_3C3C_A5A5_F00F

    func testContrastIsZeroForFlatTilesAndHighForBusyOnes() {
        XCTAssertEqual(PerceptualHash.contrast(gray: [UInt8](repeating: 12, count: 1024)), 0)
        XCTAssertEqual(PerceptualHash.contrast(gray: [0, 255]), 127.5)
        XCTAssertEqual(PerceptualHash.contrast(gray: []), 0)
    }

    func testOnlyPhotosWithStructureHaveDetail() {
        XCTAssertTrue(hashRecord(mixedHash, contrast: 40).hasDetail)
        XCTAssertFalse(hashRecord(mixedHash, contrast: 2).hasDetail, "a dark frame with sensor noise")
        XCTAssertFalse(hashRecord(0, contrast: 40).hasDetail, "a smooth gradient hashes to zero")
        XCTAssertFalse(hashRecord(.max, contrast: 40).hasDetail)
        XCTAssertTrue(hashRecord(mixedHash, contrast: nil).hasDetail, "an old record is judged by its bits")
    }

    /// A cache written before contrast was measured would hide flat photos until each was edited.
    func testRecordsWithoutContrastAreHashedAgain() {
        let photo = AssetSnapshot.fixture("a")
        XCTAssertTrue(PhotoHasher.needsHashing(photo, cached: ["a": hashRecord(mixedHash, contrast: nil)]))
        XCTAssertFalse(PhotoHasher.needsHashing(photo, cached: ["a": hashRecord(mixedHash, contrast: 40)]))
    }

    /// Caches from earlier versions have no contrast field and must still load.
    func testRecordsWithoutContrastStillDecode() throws {
        let json = Data(#"{"dhash": 5, "sharpness": 1}"#.utf8)
        let record = try JSONDecoder().decode(HashRecord.self, from: json)
        XCTAssertNil(record.contrast)
    }
}
