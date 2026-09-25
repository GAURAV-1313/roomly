// Why: an onboarding card must show, and tell VoiceOver, the same state the person has granted, and offer only a
// fix that can work. Limited and restricted access are easy to fold into the wrong case, so each state is pinned
// here — including restricted, which offers no button because nothing in Settings can change it.
import XCTest

@testable import Roomy

final class PermissionStatusTests: XCTestCase {
    func testNotAskedOffersAllowInline() {
        let status = PermissionStatus(.notDetermined, kind: .photos)
        XCTAssertNil(status.label)
        XCTAssertEqual(status.action, .allow)
        XCTAssertTrue(status.isActionInline)
        XCTAssertNil(status.footer)
    }

    func testAllowedShowsACheckAndNothingToFix() {
        let status = PermissionStatus(.authorized, kind: .contacts)
        XCTAssertEqual(status.label, "Allowed")
        XCTAssertTrue(status.isGranted)
        XCTAssertNil(status.action)
        XCTAssertNil(status.footer)
    }

    func testLimitedPhotosChangesTheSelectionButLimitedContactsOpensSettings() {
        let photos = PermissionStatus(.limited, kind: .photos)
        XCTAssertEqual(photos.label, "Limited")
        XCTAssertEqual(photos.action, .changeSelection)
        XCTAssertEqual(photos.footer, "Roomy sees only the photos you picked.")

        let contacts = PermissionStatus(.limited, kind: .contacts)
        XCTAssertEqual(contacts.action, .openSettings)
        XCTAssertEqual(contacts.footer, "Duplicates hide across the whole address book.")
    }

    func testDeniedOpensSettingsAndNamesThePermission() {
        let status = PermissionStatus(.denied, kind: .contacts)
        XCTAssertEqual(status.label, "Off")
        XCTAssertEqual(status.action, .openSettings)
        XCTAssertFalse(status.isActionInline)
        XCTAssertEqual(status.footer, "Turn on Contacts for Roomy in Settings.")
    }

    func testRestrictedExplainsButOffersNoButton() {
        let status = PermissionStatus(.restricted, kind: .photos)
        XCTAssertEqual(status.label, "Restricted")
        XCTAssertNil(status.action)
        XCTAssertEqual(status.footer, "Access is managed on this phone.")
    }

    func testVoiceOverHearsTheSameStateTheEyeSees() {
        XCTAssertEqual(PermissionStatus(.notDetermined, kind: .photos).accessibilityValue, "Not asked yet")
        XCTAssertEqual(PermissionStatus(.authorized, kind: .photos).accessibilityValue, "Allowed")
        XCTAssertEqual(PermissionStatus(.limited, kind: .photos).accessibilityValue, "Limited")
        XCTAssertEqual(PermissionStatus(.denied, kind: .photos).accessibilityValue, "Off")
        XCTAssertEqual(PermissionStatus(.restricted, kind: .photos).accessibilityValue, "Restricted")
    }

    func testPhotosIsRequiredAndContactsOptional() {
        XCTAssertEqual(PermissionKind.photos.tag, "Required")
        XCTAssertEqual(PermissionKind.contacts.tag, "Optional")
    }
}
