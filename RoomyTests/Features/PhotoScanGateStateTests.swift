// Why: "All clear" and "your library is tidy" are claims about photos Roomy looked at. These tests pin when a
// category screen may say them: never for a stopped comparison, never without saying access is limited, and
// never while some photos were not compared.
import XCTest

@testable import Roomy

final class PhotoScanGateStateTests: XCTestCase {
    private func state(
        _ phase: ScanPhase, access: AccessState = .authorized, isEmpty: Bool, needsComparison: Bool = false
    ) -> PhotoScanGateState {
        .make(access: access, phase: phase, isEmpty: isEmpty, needsComparison: needsComparison)
    }

    func testAccessComesFirst() {
        XCTAssertEqual(state(.done, access: .notDetermined, isEmpty: true), .askForAccess)
        XCTAssertEqual(state(.done, access: .denied, isEmpty: false), .denied)
        XCTAssertEqual(state(.idle, access: .restricted, isEmpty: true), .restricted)
    }

    func testScanPhasesBeforeResults() {
        XCTAssertEqual(state(.idle, isEmpty: true), .notScanned)
        XCTAssertEqual(state(.indexing, isEmpty: true), .scanning)
        XCTAssertEqual(state(.comparing, isEmpty: true, needsComparison: true), .scanning)
        XCTAssertEqual(state(.comparing, isEmpty: false), .content(note: nil))
        XCTAssertEqual(state(.done, isEmpty: true), .empty(isLimited: false))
    }

    /// Regression: with no screenshots, the Screenshots screen showed its loading skeleton for the whole
    /// comparison — minutes on a big library — although the answer was known once the library was read.
    func testCategoriesThatNeedNoComparisonAreSettledOnceIndexed() {
        XCTAssertEqual(state(.comparing, isEmpty: true), .empty(isLimited: false))
        XCTAssertEqual(state(.comparing, access: .limited, isEmpty: true), .empty(isLimited: true))
    }

    /// Regression: after Cancel while comparing, Similar Photos said "All clear".
    func testStoppedComparisonIsNeverAllClear() {
        XCTAssertEqual(state(.stopped, isEmpty: true, needsComparison: true), .comparisonNotFinished)
        XCTAssertEqual(
            state(.stopped, isEmpty: false, needsComparison: true), .content(note: .comparisonNotFinished))
        XCTAssertEqual(state(.stopped, isEmpty: true), .empty(isLimited: false), "screenshots were fully indexed")
    }

    /// Regression: with limited access an empty category read as a whole-library claim.
    func testLimitedAccessSaysResultsArePartial() {
        XCTAssertEqual(state(.done, access: .limited, isEmpty: true), .empty(isLimited: true))
        XCTAssertEqual(state(.done, access: .limited, isEmpty: false), .content(note: .limitedAccess))
    }
}

final class SimilarPhotosCopyTests: XCTestCase {
    /// Regression: photos that could not be read were skipped and the screen still said the library was tidy.
    func testUncheckedPhotosAreNamed() {
        let complete = SimilarPhotosCopy(uncheckedCount: 0)
        XCTAssertEqual(complete.emptyTitle, "All clear")
        XCTAssertNil(complete.uncheckedNote)

        let partial = SimilarPhotosCopy(uncheckedCount: 12)
        XCTAssertEqual(partial.emptyTitle, "No similar shots found")
        XCTAssertFalse(partial.emptyMessage.contains("tidy"))
        XCTAssertEqual(
            partial.uncheckedNote, "12 photos couldn't be compared, usually because they're stored only in iCloud.")
        XCTAssertEqual(
            SimilarPhotosCopy(uncheckedCount: 1).uncheckedNote,
            "1 photo couldn't be compared, usually because it's stored only in iCloud.")
    }
}
