// Why: the screen-facing permission state for Photos. The framework calls live in Services/Permissions;
// this store only holds the current answer so views can react to it.
import Foundation
import Observation

@Observable
final class PhotoAccess {
    private(set) var state = PhotoPermission.current()

    func refresh() { state = PhotoPermission.current() }
    func request() async { state = await PhotoPermission.request() }
    func presentLimitedPicker() async { await PhotoPermission.presentLimitedPicker() }
}
