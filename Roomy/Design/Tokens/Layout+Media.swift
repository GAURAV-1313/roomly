// Why: the video rows, the player sheet and the contact cards (Figma "VideoRow v5", "VideoStage v5",
// "ContactGroupCard v5") use a few sizes the shared scale doesn't have. They are named here, beside the other
// tokens, so a change to one of them still happens in one place.
import SwiftUI

extension Layout {
    /// A video row's poster; it sits 8 points in from the card, so its corners are Radius.control.
    static let videoPoster = CGSize(width: 104, height: 72)
    /// Room between a video row's size column and the card's trailing edge.
    static let videoRowTrailingInset: CGFloat = 14
    /// The play mark on a row's poster and the glyph inside it.
    static let videoPlayMark: CGFloat = 28
    static let videoPlayGlyph: CGFloat = 13
    /// At accessibility text sizes the poster spans the row, so its play mark grows to a full tap target.
    static let videoPlayGlyphLarge: CGFloat = 20
    /// The duration pill in a poster's corner.
    static let durationPillRadius: CGFloat = 6
    static let durationPillPadding = EdgeInsets(top: 1, leading: 5, bottom: 1, trailing: 5)
    /// A video's shape, for the full-width poster and the player stage.
    static let videoAspectRatio: CGFloat = 16 / 9
    /// The accent ring around a selected video row or contact group.
    static let selectedRingWidth: CGFloat = 2
    /// The Photos-style check on a row at the default text size; rows scale it with Dynamic Type.
    static let selectionCheck: CGFloat = 22
    /// Gap between the values in a merge preview.
    static let mergePreviewSpacing: CGFloat = 10
}
