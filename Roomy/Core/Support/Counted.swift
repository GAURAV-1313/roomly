// Why: "1 items" is the kind of small error that makes an app feel careless. Counts with nouns go through
// this one helper.
import Foundation

nonisolated extension Int {
    /// "1 item", "3 items"; pass `plural` for irregular nouns.
    func counted(_ singular: String, plural: String? = nil) -> String {
        let noun = self == 1 ? singular : (plural ?? singular + "s")
        return "\(formatted()) \(noun)"
    }
}
