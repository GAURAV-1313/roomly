// Why: Photos must always be offered before the dashboard, so Skip may jump ahead but never past Permissions,
// Back never leaves the first page, and only Permissions lets the person leave with "Not now". The How it works
// rail is numbered 01 to 04 in order.
import XCTest

@testable import Roomy

final class OnboardingPageTests: XCTestCase {
    func testContinueWalksThePagesInOrderAndEndsOnPermissions() {
        XCTAssertEqual(OnboardingPage.welcome.next, .howItWorks)
        XCTAssertEqual(OnboardingPage.howItWorks.next, .permissions)
        XCTAssertNil(OnboardingPage.permissions.next)
    }

    func testBackNeverLeavesTheFirstPage() {
        XCTAssertFalse(OnboardingPage.welcome.canGoBack)
        XCTAssertEqual(OnboardingPage.howItWorks.previous, .welcome)
        XCTAssertEqual(OnboardingPage.permissions.previous, .howItWorks)
    }

    func testSkipStopsAtPermissionsAndIsNotOfferedThere() {
        for page in OnboardingPage.allCases {
            XCTAssertEqual(page.skipTarget, .permissions)
        }
        XCTAssertTrue(OnboardingPage.welcome.canSkip)
        XCTAssertTrue(OnboardingPage.howItWorks.canSkip)
        XCTAssertFalse(OnboardingPage.permissions.canSkip)
    }

    func testOnlyPermissionsOffersNotNow() {
        XCTAssertEqual(OnboardingPage.allCases.filter(\.offersNotNow), [.permissions])
    }

    func testStepsAreNumberedInOrder() {
        XCTAssertEqual(OnboardingStep.allCases.map(\.index), ["01", "02", "03", "04"])
    }
}
