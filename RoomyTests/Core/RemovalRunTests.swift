// Why: what a delete reports is a product promise. These tests run the removal accounting against a pretend
// library: assets that were never there are never "moved", a refused prompt removes nothing, and no similar
// group ever loses its last photo, even when the screen was out of date.
import XCTest

@testable import Roomy

final class RemovalRunTests: XCTestCase {
    /// Regression: an asset missing before the request, or every asset while Photos access was off, was
    /// counted as moved because it was missing afterwards.
    func testOnlyAssetsThatExistedAndAreGoneCountAsRemoved() async {
        let library = PretendLibrary(["a", "b"])
        let removal = await library.remove(["a", "b", "gone"])

        XCTAssertEqual(removal.removedIDs, ["a", "b"])
        XCTAssertEqual(removal.unavailableIDs, ["gone"])
        XCTAssertEqual(library.requests, [["a", "b"]], "an asset that isn't there is never asked for")
    }

    func testAnUnreachableLibraryIsNeverAskedAndNothingIsMoved() async {
        let library = PretendLibrary([])
        let removal = await library.remove(["a", "b"])

        XCTAssertEqual(removal.removedIDs, [])
        XCTAssertEqual(removal.unavailableIDs, ["a", "b"])
        XCTAssertTrue(library.requests.isEmpty)
    }

    func testARefusedPromptRemovesNothingAndStopsTheRest() async {
        let library = PretendLibrary(["a", "b", "c", "d", "e"], refusing: 2)
        let removal = await library.remove(["a", "b", "c", "d", "e"], batchSize: 2)

        XCTAssertEqual(removal.removedIDs, ["a", "b"])
        XCTAssertEqual(removal.stop, .declined)
        XCTAssertEqual(library.requests, [["a", "b"], ["c", "d"]], "no prompt after Don't Allow")
    }

    /// Regression: the keeper was deleted in Photos while its extra stayed queued; deleting the extra emptied
    /// the group.
    func testTheLastPhotoOfAGroupIsKeptWhenItsKeeperIsGone() async {
        let library = PretendLibrary(["extra"])
        let removal = await library.remove(["extra"], groups: [["keeper", "extra"]])

        XCTAssertEqual(removal.sparedIDs, ["extra"])
        XCTAssertEqual(removal.removedIDs, [])
        XCTAssertTrue(library.requests.isEmpty)
    }

    func testAQueuedKeeperStaysWhenItsWholeGroupIsQueued() async {
        let library = PretendLibrary(["keeper", "a", "b"])
        let removal = await library.remove(["a", "b", "keeper"], groups: [["keeper", "a", "b"]])

        XCTAssertEqual(removal.sparedIDs, ["keeper"])
        XCTAssertEqual(removal.removedIDs, ["a", "b"])
    }

    func testExtrasGoWhenTheirKeeperStays() async {
        let library = PretendLibrary(["keeper", "a"])
        let removal = await library.remove(["a"], groups: [["keeper", "a"]])

        XCTAssertEqual(removal.removedIDs, ["a"])
        XCTAssertEqual(removal.sparedIDs, [])
    }

    func testSurvivorRuleKeepsAPhotoThatIsAloneInItsGroup() {
        XCTAssertEqual(SurvivorRule.spared(queued: ["lone"], groups: [["lone"]], existing: ["lone"]), ["lone"])
        XCTAssertEqual(
            SurvivorRule.spared(queued: ["a"], groups: [["keeper", "a"]], existing: ["keeper", "a"]), [],
            "a group that keeps an unqueued photo gives up nothing")
    }
}

/// A photo library in memory: deleting a batch takes it out, unless the batch is the one the person refuses.
private final class PretendLibrary {
    private var assets: Set<String>
    private let refusedRequest: Int?
    private(set) var requests: [[String]] = []

    /// `refusing` is the 1-based request the person answers with Don't Allow.
    init(_ assets: Set<String>, refusing refusedRequest: Int? = nil) {
        self.assets = assets
        self.refusedRequest = refusedRequest
    }

    func remove(_ ids: [String], groups: [[String]] = [], batchSize: Int = 10) async -> AssetRemoval {
        await RemovalRun.run(
            ids, keepingOneOf: groups, batchSize: batchSize,
            existing: { Set($0).intersection(self.assets) },
            delete: { batch in
                self.requests.append(batch)
                guard self.requests.count != self.refusedRequest else { return .declined }
                self.assets.subtract(batch)
                return nil
            })
    }
}
