// Why: hashing decides which photos count as compared. These tests pin that an update which re-reads old
// records never turns a photo it compared before into "not checked" just because its image can't be read now,
// while an edited photo is still never compared by how it used to look.
import XCTest

@testable import Roomy

final class PhotoHasherTests: XCTestCase {
    /// Regression: a record from before contrast was measured was dropped when re-reading it failed (image only
    /// in iCloud, or a timeout), so the photo left its groups and read "not checked".
    func testAnOlderRecordOfTheSamePhotoIsKeptWhenItCantBeReadAgain() async {
        let photo = AssetSnapshot.fixture("icloud")
        let legacy = hashRecord(0x0F0F_0F0F_0F0F_0F0F, contrast: nil)
        var failures = 0
        let results = await PhotoHasher.hash(
            [photo], cached: ["icloud": legacy], source: FakePhotoSource(snapshots: [photo], unreadable: ["icloud"])
        ) { failures = $0.failed }

        XCTAssertEqual(results["icloud"], legacy)
        XCTAssertEqual(failures, 0, "a photo judged by its old bits was still compared")
    }

    func testAnEditedPhotoThatCantBeReadLosesItsOldHash() async {
        let photo = AssetSnapshot.fixture("edited")
        var stale = hashRecord(1)
        stale.modificationDate = Date(timeIntervalSince1970: 0)
        let results = await PhotoHasher.hash(
            [photo], cached: ["edited": stale], source: FakePhotoSource(snapshots: [photo], unreadable: ["edited"])
        ) { _ in }

        XCTAssertNil(results["edited"], "an edited photo is never compared by how it used to look")
    }
}
