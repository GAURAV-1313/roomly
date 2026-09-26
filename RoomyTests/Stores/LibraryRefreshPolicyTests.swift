// Why: a change made in Photos must refresh Roomy, but Roomy's own cleanup and a change an earlier scan already
// covered must not start another one, a stopped comparison only has its index re-read, and a library that
// keeps changing is not scanned without pause. These tests pin each rule.
import XCTest

@testable import Roomy

final class LibraryRefreshPolicyTests: XCTestCase {
    private func refresh(
        _ policy: LibraryRefreshPolicy, after generation: Int, phase: ScanPhase = .done,
        isCleaningUp: Bool = false, canUseLibrary: Bool = true
    ) -> LibraryRefreshPolicy.Refresh {
        policy.refresh(after: generation, phase: phase, isCleaningUp: isCleaningUp, canUseLibrary: canUseLibrary)
    }

    /// Regression: after the first scan, changes made in the Photos app were never picked up.
    func testAChangeAfterAFinishedScanRescans() {
        var policy = LibraryRefreshPolicy()
        policy.cover(through: 2)
        XCTAssertEqual(refresh(policy, after: 3), .reindex)
    }

    func testChangesAScanAlreadyCoversAreSkipped() {
        var policy = LibraryRefreshPolicy()
        policy.cover(through: 5)
        XCTAssertEqual(refresh(policy, after: 5), LibraryRefreshPolicy.Refresh.none)
        policy.cover(through: 1)
        XCTAssertEqual(policy.coveredGeneration, 5, "an older number never moves coverage back")
    }

    /// Roomy's own deletions arrive as library changes; once its report is applied they need no rescan.
    func testChangesACleanupMadeAreCoveredOnceItEnds() {
        var policy = LibraryRefreshPolicy()
        policy.cover(through: 1)
        XCTAssertEqual(refresh(policy, after: 4, isCleaningUp: true), LibraryRefreshPolicy.Refresh.none)
        policy.cover(through: 4)
        XCTAssertEqual(refresh(policy, after: 4), LibraryRefreshPolicy.Refresh.none)
        XCTAssertEqual(refresh(policy, after: 5), .reindex)
    }

    /// Regression: after the person stopped a comparison, a video deleted in Photos stayed listed until Resume.
    func testAStoppedComparisonOnlyHasItsIndexReadAgain() {
        let policy = LibraryRefreshPolicy()
        XCTAssertEqual(refresh(policy, after: 1, phase: .stopped), .reindex)
    }

    func testBeforeTheFirstScanDuringACleanupOrWithoutAccessNothingRuns() {
        let policy = LibraryRefreshPolicy()
        XCTAssertEqual(refresh(policy, after: 1, isCleaningUp: true), LibraryRefreshPolicy.Refresh.none)
        XCTAssertEqual(refresh(policy, after: 1, phase: .idle), LibraryRefreshPolicy.Refresh.none)
        XCTAssertEqual(refresh(policy, after: 1, phase: .comparing), LibraryRefreshPolicy.Refresh.none)
        XCTAssertEqual(refresh(policy, after: 1, canUseLibrary: false), LibraryRefreshPolicy.Refresh.none)
    }

    /// Regression: during an iCloud sync every scan's end started the next one at once, so scanning never
    /// stopped and the dashboard stayed on "Finding space".
    func testAutomaticRefreshesKeepAGap() {
        var policy = LibraryRefreshPolicy()
        let start = ContinuousClock.now
        XCTAssertEqual(policy.wait(before: start, gap: .seconds(120)), .zero, "the first refresh runs at once")

        policy.automaticRefreshEnded(at: start)
        XCTAssertEqual(policy.wait(before: start + .seconds(30), gap: .seconds(120)), .seconds(90))
        XCTAssertEqual(policy.wait(before: start + .seconds(200), gap: .seconds(120)), .zero)
    }
}
