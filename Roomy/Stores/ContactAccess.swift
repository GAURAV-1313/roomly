// Why: the screen-facing permission state for Contacts, mirroring PhotoAccess.
import Foundation
import Observation

@Observable
final class ContactAccess {
    private(set) var state = ContactPermission.current()

    func refresh() { state = ContactPermission.current() }
    func request() async { state = await ContactPermission.request() }
}
