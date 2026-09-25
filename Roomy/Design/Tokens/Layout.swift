// Why: spacing, corner radii and fixed sizes come from the Figma file's 8-point system. Views use these
// names instead of numbers, so a layout change happens in one place.
import SwiftUI

enum Space {
    static let s2: CGFloat = 2
    static let s4: CGFloat = 4
    static let s8: CGFloat = 8
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s20: CGFloat = 20
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    /// Side margin for every screen.
    static let margin: CGFloat = 20
}

enum Radius {
    static let tile: CGFloat = 4
    static let grid: CGFloat = 8
    static let row: CGFloat = 12
    static let control: CGFloat = 16
    /// Photo thumbnails on a category tile, and the icon square on a notice row.
    static let thumb: CGFloat = 10
    /// A category tile's preview well: the tile's 24 minus its 5-point inset, so the corners stay concentric.
    static let well: CGFloat = 19
    static let card: CGFloat = 24
    /// The storage card, which holds a 24-point card 8 points in.
    static let heroCard: CGFloat = 32
}

enum Layout {
    /// Scroll content keeps this much room at the bottom so nothing rests under the floating bar.
    static let bottomBarClearance: CGFloat = 96
    static let bottomBarHeight: CGFloat = 56
    /// The round button beside the Review capsule: its progress ring sits this far in, at this line width.
    static let roundActionRingInset: CGFloat = 5
    static let roundActionRingLine: CGFloat = 3
    static let tapTarget: CGFloat = 44
    static let photoTileSize: CGFloat = 96
    static let screenshotColumns = 4
    /// The storage card (Figma "StorageHeroCard v5"): its inset around the white card, the extra room above
    /// the headline, and how far the robin sinks onto the white card.
    static let heroInset: CGFloat = 8
    static let heroTopInset: CGFloat = 14
    static let heroPerch: CGFloat = 8
    /// The room under the storage card's footer, a little more than above it so the last line settles.
    static let heroFooterBottom: CGFloat = 14
    /// The barcode usage bar: tick width, the pitch it aims for, and its height.
    static let usageTickWidth: CGFloat = 3
    static let usageTickPitch: CGFloat = 6
    static let usageBarHeight: CGFloat = 28
    /// The marker tick on the result's storage bar (Figma "Premium details" marker): its width, how far it rises
    /// above the ticks, and its outline while the space is still pending.
    static let markerWidth: CGFloat = 5
    static let markerRise: CGFloat = 8
    static let markerLine: CGFloat = 1.5
    /// The scan progress bar on the storage card.
    static let progressBarHeight: CGFloat = 6
    /// Category tiles (Figma "CategoryTile v5"): the inset around the preview well and the well's height.
    static let tileInset: CGFloat = 5
    static let tileWellHeight: CGFloat = 72
    static let tileBottomInset: CGFloat = 14
    static let tileSpacing: CGFloat = 12
    /// What a preview well holds: photos, screenshots, video posters, contact avatars, the status glyph.
    static let tilePhoto: CGFloat = 44
    static let tilePhotoOverlap: CGFloat = 12
    static let tileScreenshot = CGSize(width: 25, height: 44)
    static let tileVideo = CGSize(width: 56, height: 44)
    static let tilePlayMark: CGFloat = 22
    static let tileAvatar: CGFloat = 42
    static let tileAvatarOverlap: CGFloat = 10
    static let tileGlyph: CGFloat = 32
    static let skeletonLineHeight: CGFloat = 12
    static let skeletonLineWidth: CGFloat = 96
    /// The tinted well holding Roomy on an empty or access card (Figma "GateCard v5").
    static let gateWellHeight: CGFloat = 150
    /// A small capsule button (Figma "QuietCapsule v5", Size=small).
    static let smallButtonHeight: CGFloat = 36
    /// The status dot on a notice row's icon chip.
    static let noticeDot: CGFloat = 7
    /// The icon square at the start of a notice row.
    static let noticeIcon: CGFloat = 32
    /// Soft shadow under dashboard cards: SwiftUI's radius is about half Figma's 8-point blur; downward offset.
    static let cardShadowRadius: CGFloat = 4
    static let cardShadowY: CGFloat = 4
    /// The most room a long-press preview of a photo or screenshot takes; it keeps the asset's shape inside it.
    static let assetPreviewBounds = CGSize(width: 360, height: 600)
}

enum MascotSize {
    static let hero: CGFloat = 200
    static let result: CGFloat = 160
    static let dashboard: CGFloat = 96
    /// Perched on the storage card.
    static let card: CGFloat = 60
    /// Beside the amount on the cleanup result.
    static let resultRow: CGFloat = 56
    static let emptyState: CGFloat = 120
    static let inline: CGFloat = 48
}
