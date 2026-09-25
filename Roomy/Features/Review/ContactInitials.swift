// Why: a merge row shows the person's initials, like the Contacts app, so the list can be scanned by face as well
// as by name. They come only from the name the contact scan already has; with no letters to use there are no
// initials, and the row shows a generic person glyph instead of made-up letters.
import Foundation

nonisolated enum ContactInitials {
    /// Up to two letters: the first letter of the first and the last word, uppercased. Nil when the name has none.
    static func of(_ name: String) -> String? {
        let words = name.split(whereSeparator: \.isWhitespace)
        let letters = [words.first, words.count > 1 ? words.last : nil]
            .compactMap { $0?.first(where: \.isLetter) }
        guard !letters.isEmpty else { return nil }
        return String(letters).uppercased()
    }
}
