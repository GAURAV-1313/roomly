// Why: the photo screens (Similar Photos, Compare, Screenshots) have their own measures from the Figma v5 tiles.
// They live beside the shared layout tokens, not in the views, so a tile or grid change happens in one place.
import SwiftUI

extension Layout {
    /// The gap between screenshot tiles (Figma "ScreenshotTile v5"): wide enough that white screenshots stay
    /// apart on the parchment.
    static let screenshotGutter: CGFloat = 4
    /// Screenshot columns at accessibility text sizes, when the section headers grow taller.
    static let screenshotColumnsAccessible = 3
    /// How far a tile's selection check sits from the tile's edge.
    static let tileCheckInset: CGFloat = 6
    /// The accent ring on a selected photo or screenshot.
    static let tileSelectedRing: CGFloat = 3
    /// The thinner accent ring that marks the keeper.
    static let tileKeeperRing: CGFloat = 2
    /// The hairline that keeps an unselected white screenshot distinct from the parchment.
    static let tileHairline: CGFloat = 1
    /// Pixel size requested for a full-screen photo in Compare: sharp on any iPhone without loading the original.
    static let comparePhotoPixels = CGSize(width: 1600, height: 1600)
    /// The glyph inside Compare's round and pager buttons, and in its status badges.
    static let compareGlyph: CGFloat = 16
    /// How far Compare's dark scrims reach past the controls, so the glass reads on a bright photo.
    static let compareScrimOverhang: CGFloat = 24
}
