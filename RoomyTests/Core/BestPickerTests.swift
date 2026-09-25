// Why: the keeper is the one photo Roomy never offers for removal, so the order that picks it is pinned here:
// what the person marked, then resolution, then sharpness, and file size only as the last word.
import XCTest

@testable import Roomy

final class BestPickerTests: XCTestCase {
    func testPrefersResolutionThenSharpnessThenSize() {
        let small = AssetSnapshot.fixture("small", width: 1000, height: 1000, size: 900)
        let lightFile = AssetSnapshot.fixture("light", size: 100)
        let heavyFile = AssetSnapshot.fixture("heavy", size: 500)
        let hashes = ["small": hashRecord(1, sharpness: 999), "light": hashRecord(1), "heavy": hashRecord(1)]
        XCTAssertEqual(BestPicker.pick([small, lightFile, heavyFile], hashes: hashes)?.id, "heavy")

        let blurry = AssetSnapshot.fixture("blurry", size: 900)
        let sharp = AssetSnapshot.fixture("sharp", size: 500)
        let sharpness = ["blurry": hashRecord(1, sharpness: 5), "sharp": hashRecord(1, sharpness: 50)]
        XCTAssertEqual(BestPicker.pick([blurry, sharp], hashes: sharpness)?.id, "sharp", "a bigger file never wins")
    }

    /// Regression: a few extra KB decided the keeper, so a favourite became an extra and "Select all" queued it.
    func testFavouriteIsKeptOverALargerFile() {
        let favourite = AssetSnapshot.fixture("favourite", favorite: true, size: 100)
        let larger = AssetSnapshot.fixture("larger", size: 900)
        let hashes = ["favourite": hashRecord(1, sharpness: 10), "larger": hashRecord(1, sharpness: 80)]
        XCTAssertEqual(BestPicker.pick([larger, favourite], hashes: hashes)?.id, "favourite")
    }

    func testNearlyEqualSharpnessLetsFileSizeDecide() {
        let first = AssetSnapshot.fixture("first", size: 500)
        let second = AssetSnapshot.fixture("second", size: 400)
        let hashes = ["first": hashRecord(1, sharpness: 100), "second": hashRecord(1, sharpness: 101)]
        XCTAssertEqual(BestPicker.pick([first, second], hashes: hashes)?.id, "first")
    }

    func testThePersonsBurstPickOutranksTheCameras() {
        let camera = AssetSnapshot.fixture("camera", burst: "B", burstPick: .camera, size: 900)
        let person = AssetSnapshot.fixture("person", burst: "B", burstPick: .person, size: 100)
        XCTAssertEqual(BestPicker.pick([camera, person], hashes: [:])?.id, "person")
    }

    /// Regression: members without a known size were dropped from their group once sizes arrived.
    func testUnknownSizeRanksLowestAndNeverLeavesTheGroup() {
        let group = SimilarGroup(id: "g", members: ["a", "b", "c"], best: "a", reason: .exactDuplicate)
        let snapshots: [String: AssetSnapshot] = ["a": .fixture("a"), "b": .fixture("b", size: 10)]
        let refreshed = BestPicker.refreshed([group], snapshots: snapshots, hashes: [:])
        XCTAssertEqual(refreshed.first?.best, "b")
        XCTAssertEqual(refreshed.first?.members, ["b", "a", "c"])
    }

    func testWithKeeperMovesTheKeeperFirstAndIgnoresStrangers() {
        let group = SimilarGroup(id: "g", members: ["a", "b", "c"], best: "a", reason: .burst)
        XCTAssertEqual(group.withKeeper("c").members, ["c", "a", "b"])
        XCTAssertEqual(group.withKeeper("c").extras, ["a", "b"])
        XCTAssertEqual(group.withKeeper("z"), group)
    }
}
