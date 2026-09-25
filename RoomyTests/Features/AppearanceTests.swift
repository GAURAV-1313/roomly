// Why: the Appearance choice is stored by name and turned into the root's colour scheme. System must mean "no
// preference" (nil) so Roomy keeps following the phone; these tests pin that mapping and the stored names.
import SwiftUI
import XCTest

@testable import Roomy

final class AppearanceTests: XCTestCase {
    func testSystemLeavesTheSchemeToThePhone() {
        XCTAssertNil(Appearance.system.colorScheme)
        XCTAssertEqual(Appearance.light.colorScheme, .light)
        XCTAssertEqual(Appearance.dark.colorScheme, .dark)
    }

    func testSegmentsReadSystemLightDarkInOrder() {
        XCTAssertEqual(Appearance.allCases.map(\.title), ["System", "Light", "Dark"])
    }

    /// The raw values are what UserDefaults holds; renaming one would silently reset people's choice.
    func testStoredNamesStayStable() {
        XCTAssertEqual(Appearance.storageKey, "appearance")
        XCTAssertEqual(Appearance.allCases.map(\.rawValue), ["system", "light", "dark"])
        XCTAssertEqual(Appearance(rawValue: "dark"), .dark)
        XCTAssertNil(Appearance(rawValue: "sepia"))
    }
}
