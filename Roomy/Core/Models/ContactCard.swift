// Why: CNContact objects stay in Services/. This value type carries only what the matcher compares, the merge
// preview shows and the kept-card choice weighs, so it can cross actors and be tested.
import Foundation

nonisolated struct ContactCard: Sendable, Hashable, Identifiable {
    let id: String
    let name: String
    var organization = ""
    var phones: [String] = []
    var emails: [String] = []
    var hasImage = false
    /// True when the card lives in the phone's default account, the one the person owns.
    var isInDefaultContainer = false

    /// How much the card holds. The fullest card in a group becomes the one the others merge into.
    var fieldCount: Int {
        (name.isEmpty ? 0 : 1) + (organization.isEmpty ? 0 : 1) + phones.count + emails.count
    }

    /// Everything the person read in the merge preview. If this differs at merge time, the card was edited
    /// after the scan and the approved preview no longer describes what would be written.
    var fingerprint: String {
        let separator = "\u{1F}"
        let fields = [name, organization, phones.joined(separator: separator), emails.joined(separator: separator)]
        return fields.joined(separator: "\u{1E}")
    }
}
