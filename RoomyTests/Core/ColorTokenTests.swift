// Why: every colour token is parsed from a hex string; a parsing bug would silently recolour the app. And
// SwiftUI resolves colours on its own render thread, which once crashed the app (see the second test).
import UIKit
import XCTest

@testable import Roomy

final class ColorTokenTests: XCTestCase {
    func testHexParsing() {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(hex: "24365C").getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(Int((red * 255).rounded()), 0x24)
        XCTAssertEqual(Int((green * 255).rounded()), 0x36)
        XCTAssertEqual(Int((blue * 255).rounded()), 0x5C)
    }

    /// Regression: the light/dark provider inherited the main actor, and SwiftUI's async renderer resolving
    /// it off the main thread trapped in `_swift_task_checkIsolatedSwift`.
    func testColoursResolveOffTheMainThread() async {
        let resolved = await Task.detached {
            UIColor(RoomyColor.accent).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        }.value
        var red: CGFloat = 0
        resolved.getRed(&red, green: nil, blue: nil, alpha: nil)
        XCTAssertEqual(Int((red * 255).rounded()), 0x5F, "the dark accent is #5F7CB8")
    }
}
