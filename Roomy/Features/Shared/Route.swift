// Why: every screen reachable from the dashboard is a value, so navigation is data and deep links or
// state restoration can be added without touching the views.
import Foundation

nonisolated enum Route: Hashable {
    case similarPhotos
    case screenshots
    case largeVideos
    case duplicateContacts
    case settings
}
