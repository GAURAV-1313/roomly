// Why: saving a contact change has no system prompt and no Recently Deleted, so Roomy writes every card it
// is about to change to a vCard file first, photos included. Sharing that file to Contacts restores the
// cards (notes excepted: apps cannot read them). No backup means no merge, and a run that merged nothing
// keeps no backup, so failed attempts never push a useful backup out of the retained set.
import Contacts

nonisolated enum VCardBackup {
    /// Backups hold names and numbers, so only the most recent ones are kept.
    static let retainedCount = 10

    static var directory: URL {
        URL.applicationSupportDirectory.appendingPathComponent("Contact Backups", isDirectory: true)
    }

    /// Keys that must be fetched for a card to be written as a vCard, photo included.
    static var requiredKeys: [CNKeyDescriptor] {
        [CNContactVCardSerialization.descriptorForRequiredKeys(), CNContactImageDataKey as CNKeyDescriptor]
    }

    /// Writes the backup. Call `keep` once something was merged, or `discard` when nothing was.
    static func write(_ contacts: [CNContact], at date: Date = .now) throws -> URL {
        let data = try vCardData(for: contacts)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("Roomy backup \(fileStamp(date)).vcf")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        Log.contacts.notice("backed up \(contacts.count) cards")
        return url
    }

    /// One vCard per card, each with its photo.
    static func vCardData(for contacts: [CNContact]) throws -> Data {
        var data = Data()
        for contact in contacts {
            let image = contact.isKeyAvailable(CNContactImageDataKey) ? contact.imageData : nil
            data.append(VCardPhoto.adding(image, to: try CNContactVCardSerialization.data(with: [contact])))
        }
        return data
    }

    /// The backup belongs to a run that changed cards: it joins the retained set, oldest ones go.
    static func keep(_ url: URL) {
        let others = all().filter { $0.lastPathComponent != url.lastPathComponent }
        for old in others.dropFirst(retainedCount - 1) {
            remove(old)
        }
    }

    /// The run changed nothing, so its backup would only crowd out a real one.
    static func discard(_ url: URL) {
        remove(url)
    }

    /// Every backup on this phone, newest first.
    static func all() -> [URL] {
        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        } catch {
            return []  // no directory yet means no backups
        }
        return urls.filter { $0.pathExtension == "vcf" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    private static func remove(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            Log.contacts.error("could not remove a backup: \(error.localizedDescription)")
        }
    }

    private static func fileStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return formatter.string(from: date)
    }
}
