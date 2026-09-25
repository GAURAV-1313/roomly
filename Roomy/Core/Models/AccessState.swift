// Why: "granted" is not the same as "can see everything". One app-level enum, including `.limited`,
// lets every screen handle Photos and Contacts permission the same way.
import Foundation

nonisolated enum AccessState: Sendable, Equatable {
    case notDetermined
    case restricted
    case denied
    case limited
    case authorized

    var canUse: Bool { self == .authorized || self == .limited }
}
