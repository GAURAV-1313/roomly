// Why: a contact group is what the person approves. It carries, next to its members, what the scan saw of
// each card and the numbering it assumed, so the merge can refuse to write anything the preview did not show.
import Foundation

nonisolated enum ContactMatchReason: Sendable, Hashable {
    case samePhone
    case sameEmail

    /// Lower is stronger. A shared number is stronger evidence than a shared address.
    var strength: Int {
        switch self {
        case .samePhone: 0
        case .sameEmail: 1
        }
    }
}

nonisolated struct ContactGroup: Sendable, Hashable, Identifiable {
    let id: String
    /// The card the others merge into.
    let primary: String
    /// The cards that are folded into `primary` and then removed.
    let extras: [String]
    /// The weakest link that holds the group together, so the label never overstates the evidence.
    let reason: ContactMatchReason
    /// Each member's `ContactCard.fingerprint` at scan time, by card id.
    var fingerprints: [String: String] = [:]
    /// The region whose phone numbering the scan assumed; the merge compares numbers the same way.
    var phoneRegion = ""
    /// Some cards are in the person's own account and some in another (work, shared), so the merge moves
    /// values between accounts. The card says so before anything is selected.
    var spansAccounts = false

    var members: [String] { [primary] + extras }

    /// True when every member still reads exactly as it did in the scan. A missing card or a missing
    /// fingerprint counts as changed, so an unknown state never reaches the address book.
    func isUnchanged(_ current: [ContactCard]) -> Bool {
        let currentByID = Dictionary(current.map { ($0.id, $0.fingerprint) }, uniquingKeysWith: { first, _ in first })
        return members.allSatisfy { id in
            guard let scanned = fingerprints[id], let now = currentByID[id] else { return false }
            return scanned == now
        }
    }
}
