// Why: mirrors the Figma variables (Roomy/Color) one to one, so design and code cannot drift. Every colour
// is a light/dark pair. Dark mode is its own palette ("Dark v2" in Figma), not light inverted: warm near-blacks
// stepping up in lightness for elevation, and solid deep category wells instead of colour washed over grey. Red is used only on the confirm-delete button; amber only for "finish the job".
// Nonisolated on purpose: SwiftUI resolves colours on its render thread, and a light/dark provider written
// in a main-actor context inherits that isolation and traps there.
import SwiftUI
import UIKit

nonisolated enum RoomyColor {
    static let bg = adaptive("FBF9F7", "0F0E0C")
    static let card = adaptive("FFFFFF", "1B1917")
    static let nested = adaptive("FAF8F6", "242220")
    /// The body of a sheet. The page colour in light; in dark a step above the page, so a sheet stands clear of the
    /// dimmed screen behind it, and a step below `card`, so the cards on it still rise.
    static let sheet = adaptive("FBF9F7", "151412")
    static let chip = adaptive("F4F1ED", "2C2A27")

    static let textPrimary = adaptive("1D1A22", "F5F3F1")
    static let textSecondary = adaptive("67616F", "ADA8A4")
    static let onAccent = adaptive("FFFFFF", "FFFFFF")
    static let separator = adaptive("F0EBE5", "33312F")

    /// Deep navy ink: quiet and premium, complementary to the robin's terracotta.
    static let accent = adaptive("24365C", "5F88D4")
    static let accentSoft = adaptive("24365C", "5F88D4", lightAlpha: 0.08, darkAlpha: 0.16)
    static let accentTint = adaptive("24365C", "5F88D4", lightAlpha: 0.12, darkAlpha: 0.24)

    /// Deep red, only for the one delete button (and the welcome's "storage full" moment). Deep enough that its
    /// white label keeps strong contrast through the glass on iOS 26 and the less transparent glass of iOS 27.
    static let destructive = adaptive("B3261E", "D32F2F")
    static let warning = adaptive("D98E04", "F2B54A")
    static let warningSoft = adaptive("D98E04", "372912", lightAlpha: 0.12)
    static let success = adaptive("2F8A57", "65C98C")
    static let successSoft = adaptive("2F8A57", "182F20", lightAlpha: 0.10)

    /// The storage card's soft navy-to-parchment wash, top to bottom.
    static let heroTintTop = adaptive("E4EAF4", "182336")
    static let heroTintBottom = adaptive("F6F1EA", "121417")
    /// The soft shadow under dashboard cards and tiles. None in dark, where shadows can't be seen; cards there rise by
    /// lightness and `cardEdge` instead.
    static let cardShadow = adaptive("1E1814", "000000", lightAlpha: 0.06, darkAlpha: 0)
    /// A faint top light on dark cards; invisible in light mode, where the shadow does the lifting.
    static let cardEdge = adaptive("FFFFFF", "FFFFFF", lightAlpha: 0, darkAlpha: 0.07)

    /// Each category has its own quiet colour, used for its tile's preview well and glyphs. In dark the soft well is a
    /// solid deep tone of the category, and the glyph colour is lifted to about 7.5:1 against it.
    static let similar = adaptive("5E8C6A", "8DCAA1")
    static let similarSoft = adaptive("5E8C6A", "1A2E21", lightAlpha: 0.14)
    static let screenshots = adaptive("7B6BB0", "BAAFEE")
    static let screenshotsSoft = adaptive("7B6BB0", "29253B", lightAlpha: 0.14)
    static let videos = adaptive("B8704A", "EBA68B")
    static let videosSoft = adaptive("B8704A", "37231F", lightAlpha: 0.14)
    static let contacts = adaptive("3E8A9A", "7AC6D9")
    static let contactsSoft = adaptive("3E8A9A", "132D33", lightAlpha: 0.18)

    static let ringUsed = adaptive("C9C2B8", "44423F")
    static let ringReclaimable = accent
    static let ringTrack = adaptive("EFEAE4", "2C2A27")

    static let glassStroke = adaptive("FFFFFF", "FFFFFF", lightAlpha: 0.60, darkAlpha: 0.14)
    static let dim = adaptive("000000", "000000", lightAlpha: 0.35, darkAlpha: 0.45)

    private static func adaptive(_ light: String, _ dark: String, lightAlpha: Double = 1, darkAlpha: Double = 1)
        -> Color
    {
        Color(
            UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: dark, alpha: darkAlpha)
                    : UIColor(hex: light, alpha: lightAlpha)
            })
    }
}

/// Roomy the robin never re-themes: it looks the same in light and dark.
nonisolated enum MascotColor {
    static let body = Color(UIColor(hex: "463222"))
    static let dark = Color(UIColor(hex: "362619"))
    static let breast = Color(UIColor(hex: "E2572B"))
    static let beak = Color(UIColor(hex: "F4A93E"))
    static let eye = Color(UIColor(hex: "241A12"))
    static let face = Color(UIColor(hex: "FBF9F7"))
}

nonisolated extension UIColor {
    convenience init(hex: String, alpha: Double = 1) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: alpha)
    }
}
