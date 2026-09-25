// Why: the contacts screen and the dashboard tile both read this store; these tests pin its scan and the
// way a merge updates it without a rescan.
import XCTest

@testable import Roomy

final class DuplicateContactsStoreTests: XCTestCase {
    private let cards: [ContactCard] = [
        .fixture("a", "Ana Silva", phones: ["5551234567"]),
        .fixture("b", "Ana", phones: ["+1 555 123 4567"], emails: ["ana@x.com"]),
        .fixture("c", "Bo"),
    ]

    @MainActor
    func testScanFindsGroupsAndMergedGroupsDisappear() async throws {
        let store = makeStore(FakeContactSource(cards: cards))
        store.scan()
        await store.waitForScan()

        XCTAssertEqual(store.phase, .done)
        XCTAssertEqual(store.groups.count, 1)
        XCTAssertEqual(store.extraCardCount, 1)
        let group = try XCTUnwrap(store.groups.first)
        XCTAssertEqual(store.preview(for: group)?.emails.map(\.text), ["ana@x.com"])

        store.remove([group.id])
        XCTAssertTrue(store.groups.isEmpty)
    }

    /// Regression: a scan that read the address book before a merge put the merged group back when it finished.
    @MainActor
    func testAScanThatStartedBeforeAMergeNeverBringsTheGroupBack() async throws {
        let store = makeStore(FakeContactSource(cards: cards, delay: .milliseconds(200)))
        store.scan()
        await store.waitForScan()
        let group = try XCTUnwrap(store.groups.first)

        store.scan()
        store.remove([group.id])
        await store.waitForScan()

        XCTAssertEqual(store.phase, .done)
        XCTAssertTrue(store.groups.isEmpty)
        XCTAssertEqual(store.extraCardCount, 0)
    }

    /// Regression: refused groups were remembered only in memory, so after a relaunch the same read-only group
    /// was offered again and failed again, although the result said it wouldn't be suggested again.
    @MainActor
    func testAGroupContactsRefusedIsNotOfferedAgainEvenAfterARelaunch() async {
        let refusedFile = temporaryFilename()
        let store = makeStore(FakeContactSource(cards: cards), refusedFilename: refusedFile)
        store.scan()
        await store.waitForScan()
        let refused = Set(store.groups.map(\.id))
        XCTAssertFalse(refused.isEmpty)

        store.stopOffering(refused)
        store.scan()
        await store.waitForScan()
        XCTAssertTrue(store.groups.isEmpty, "regression: a group that can never be saved was offered again")

        let relaunched = makeStore(FakeContactSource(cards: cards), refusedFilename: refusedFile)
        relaunched.scan()
        await relaunched.waitForScan()
        XCTAssertTrue(relaunched.groups.isEmpty, "the refusal is saved")
    }

    /// Every store gets its own file, so tests never read or erase the app's saved refusals.
    @MainActor
    private func makeStore(_ source: FakeContactSource, refusedFilename: String? = nil) -> DuplicateContactsStore {
        DuplicateContactsStore(
            source: source, phoneRegion: "US", refusedFilename: refusedFilename ?? temporaryFilename())
    }

    private func temporaryFilename() -> String {
        let filename = "test-refused-\(UUID().uuidString).json"
        addTeardownBlock { JSONFileStore<[String]>(filename: filename).delete() }
        return filename
    }
}
