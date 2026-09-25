// Why: Settings says in plain words what Roomy can see. The wording belongs to the screen, not to the access
// model, so it lives here as a pure mapping with its own test.
import Foundation

nonisolated extension AccessState {
    var displayName: String {
        switch self {
        case .authorized: "Full access"
        case .limited: "Limited"
        case .denied: "Off"
        case .restricted: "Restricted"
        case .notDetermined: "Not asked yet"
        }
    }
}
