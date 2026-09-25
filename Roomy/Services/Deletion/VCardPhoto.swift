// Why: Contacts' vCard writer is widely reported to leave photos out on some devices, so a backup of a card
// with a photo might not bring the photo back. When the written vCard has no photo, it is added as a base64
// PHOTO property, folded into short lines as the vCard format requires; a vCard that has one is left alone.
import Foundation

nonisolated enum VCardPhoto {
    /// vCard lines are folded at 75 octets; each continuation line starts with one space.
    static let foldedLineLength = 74

    /// The vCard with `image` added, or unchanged when there is no image or it already has a photo.
    static func adding(_ image: Data?, to vCard: Data) -> Data {
        guard let image, !image.isEmpty, let text = String(data: vCard, encoding: .utf8), !hasPhoto(text),
            let end = text.range(of: "END:VCARD", options: .backwards)
        else { return vCard }
        var withPhoto = text
        withPhoto.insert(contentsOf: property(for: image), at: end.lowerBound)
        return Data(withPhoto.utf8)
    }

    /// Lines end in CRLF, which Swift reads as one character, so the check is per line, not a search for "\n".
    private static func hasPhoto(_ vCard: String) -> Bool {
        vCard.split(whereSeparator: \.isNewline).contains { $0.uppercased().hasPrefix("PHOTO") }
    }

    private static func property(for image: Data) -> String {
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        let type = image.starts(with: pngSignature) ? "PNG" : "JPEG"
        var lines = ["PHOTO;ENCODING=b;TYPE=\(type):"]
        var remaining = Substring(image.base64EncodedString())
        while !remaining.isEmpty {
            lines.append(" " + remaining.prefix(foldedLineLength))
            remaining = remaining.dropFirst(foldedLineLength)
        }
        return lines.joined(separator: "\r\n") + "\r\n"
    }
}
