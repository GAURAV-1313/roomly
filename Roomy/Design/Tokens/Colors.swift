// Why: mirrors the Figma variables (Roomy/Color) one to one, so design and code cannot drift. Every colour
// is a light/dark pair. Red is used only on the confirm-delete button; amber only for "finish the job".
// Nonisolated on purpose: SwiftUI resolves colours on its render thread, and a light/dark provider written
// in a main-actor context inherits that isolation and traps there.
import SwiftUI
import UIKit

nonisolated enum RoomyColor {
    static let bg = adaptive("FBF9F7", "17151C")
    static let card = adaptive("FFFFFF", "1F1C25")
    static let nested = adaptive("FAF8F6", "26222E")
    static let chip = adaptive("F4F1ED", "2A2632")

    static let textPrimary = adaptive("1D1A22", "F5F3F7")
    static let textSecondary = adaptive("67616F", "A79FB0")
    static let onAccent = adaptive("FFFFFF", "FFFFFF")
    static let separator = adaptive("F0EBE5", "322D3B")

    /// Deep navy ink: quiet and premium, complementary to the robin's terracotta.
    static let accent = adaptive("24365C", "5F7CB8")
    static let accentSoft = adaptive("24365C", "5F7CB8", lightAlpha: 0.08, darkAlpha: 0.14)
    static let accentTint = adaptive("24365C", "5F7CB8", lightAlpha: 0.12, darkAlpha: 0.18)

    static let destructive = adaptive("E5484D", "FF6369")
    static let warning = adaptive("D98E04", "F5B324")
    static let warningSoft = adaptive("D98E04", "F5B324", lightAlpha: 0.12, darkAlpha: 0.16)
    static let success = adaptive("2F8A57", "4CC282")
    static let successSoft = adaptive("2F8A57", "4CC282", lightAlpha: 0.10, darkAlpha: 0.18)

    /// The storage card's soft navy-to-parchment wash, top to bottom.
    static let heroTintTop = adaptive("E4EAF4", "232B3C")
    static let heroTintBottom = adaptive("F6F1EA", "1F1C25")
    /// The soft shadow under dashboard cards and tiles.
    static let cardShadow = adaptive("1E1814", "000000", lightAlpha: 0.06, darkAlpha: 0.30)

    /// Each category has its own quiet colour, used for its tile's preview well and glyphs.
    static let similar = adaptive("5E8C6A", "7FB08C")
    static let similarSoft = adaptive("5E8C6A", "7FB08C", lightAlpha: 0.14, darkAlpha: 0.22)
    static let screenshots = adaptive("7B6BB0", "9D8FD6")
    static let screenshotsSoft = adaptive("7B6BB0", "9D8FD6", lightAlpha: 0.14, darkAlpha: 0.22)
    static let videos = adaptive("B8704A", "D9936C")
    static let videosSoft = adaptive("B8704A", "D9936C", lightAlpha: 0.14, darkAlpha: 0.22)
    static let contacts = adaptive("3E8A9A", "62AFC0")
    static let contactsSoft = adaptive("3E8A9A", "62AFC0", lightAlpha: 0.18, darkAlpha: 0.24)

    static let ringUsed = adaptive("C9C2B8", "4A4452")
    static let ringReclaimable = accent
    static let ringTrack = adaptive("EFEAE4", "2A2632")

    static let glassStroke = adaptive("FFFFFF", "FFFFFF", lightAlpha: 0.60, darkAlpha: 0.25)
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
