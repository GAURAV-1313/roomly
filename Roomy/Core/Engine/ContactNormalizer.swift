// Why: two cards are the same person only if their values match after the formatting people type is
// removed. The matcher, the merge preview and the merge itself all compare through these keys, so what the
// preview promises is exactly what the merge does.
import Foundation

nonisolated enum ContactNormalizer {
    /// Shorter numbers are service codes ("112", "*123#"), not people.
    static let minimumPhoneDigits = 7

    /// The number in international form, so "+33 6 12 34 56 78", "0033 6 12 34 56 78" and, on a French
    /// phone, "06 12 34 56 78" share one key. A national number is read in `region`'s numbering; a region
    /// Roomy does not know compares the plain digits. An extension is part of the key however it is written
    /// ("ext. 12", "x12", ";12"): two people on one office line are two numbers, and a merge must keep both.
    static func phoneKey(_ raw: String, region: String) -> String? {
        let parts = splitExtension(raw)
        guard let number = internationalNumber(parts.number, region: region) else { return nil }
        return parts.extension.isEmpty ? number : number + "x" + parts.extension
    }

    /// What a number is compared by when merging: its key, or the text itself when it has no key.
    static func phoneIdentity(_ raw: String, region: String) -> String {
        phoneKey(raw, region: region) ?? raw
    }

    /// Case-insensitive. Gmail dots and plus-tags are kept: they can be different mailboxes elsewhere.
    static func emailKey(_ raw: String) -> String? {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return email.contains("@") ? email : nil
    }

    static func emailIdentity(_ raw: String) -> String {
        emailKey(raw) ?? raw
    }

    /// "José  García" and "garcia jose" share a key: accents, case, order and punctuation are ignored.
    static func nameKey(_ raw: String) -> String? {
        let folded = raw.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        let words = folded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return words.isEmpty ? nil : words.sorted().joined(separator: " ")
    }

    private static func internationalNumber(_ raw: Substring, region: String) -> String? {
        let number = raw.replacingOccurrences(of: "(0)", with: "")
        let digits = number.filter { $0.isASCII && $0.isNumber }
        guard digits.count >= minimumPhoneDigits else { return nil }
        if number.trimmingCharacters(in: .whitespaces).hasPrefix("+") {
            return "+" + digits
        }
        let numbering = PhoneNumbering(region: region)
        if let international = numbering.droppingInternationalPrefix(digits) {
            return "+" + international
        }
        guard let callingCode = numbering.callingCode else { return digits }
        return "+" + callingCode + numbering.droppingTrunkPrefix(digits)
    }

    /// The number before an extension or dialling pause ("555 123 4567 ext. 12", "x12", ";12", ",12") and the
    /// digits after it. Letters before the first digit ("Tel 555…") are not treated as an extension.
    private static func splitExtension(_ raw: String) -> (number: Substring, extension: String) {
        var hasSeenDigit = false
        for index in raw.indices {
            let character = raw[index]
            if character.isNumber {
                hasSeenDigit = true
            } else if hasSeenDigit && (character.isLetter || ",;#".contains(character)) {
                let digits = raw[index...].filter { $0.isASCII && $0.isNumber }
                return (raw[..<index], String(digits))
            }
        }
        return (raw[...], "")
    }
}
