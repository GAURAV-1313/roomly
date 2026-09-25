// Why: a category keeps one colour everywhere it appears — its dashboard tile, its screen's summary card,
// its empty state and its Review section — so the person can tell where they are at a glance. One mapping
// keeps every screen on the same colour.
import SwiftUI

extension Route {
    /// Each category keeps one colour across its tile; other routes use the accent.
    var categoryTint: Color {
        switch self {
        case .similarPhotos: RoomyColor.similar
        case .screenshots: RoomyColor.screenshots
        case .largeVideos: RoomyColor.videos
        case .duplicateContacts: RoomyColor.contacts
        case .settings: RoomyColor.accent
        }
    }

    var categoryTintSoft: Color {
        switch self {
        case .similarPhotos: RoomyColor.similarSoft
        case .screenshots: RoomyColor.screenshotsSoft
        case .largeVideos: RoomyColor.videosSoft
        case .duplicateContacts: RoomyColor.contactsSoft
        case .settings: RoomyColor.accentSoft
        }
    }
}
