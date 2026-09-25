// Why: small app state (the basket, the hash cache) is saved as JSON in Application Support. Failures are
// logged, never thrown: a missing or unreadable file means "start fresh", which is always safe here.
import Foundation

nonisolated struct JSONFileStore<Value: Codable>: Sendable {
    let url: URL

    init(filename: String) {
        let directory = URL.applicationSupportDirectory
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            Log.storage.error("create \(directory.path, privacy: .public): \(error.localizedDescription)")
        }
        url = directory.appendingPathComponent(filename)
    }

    func load() -> Value? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            return try JSONDecoder().decode(Value.self, from: Data(contentsOf: url))
        } catch {
            Log.storage.error("load \(url.lastPathComponent, privacy: .public): \(error.localizedDescription)")
            return nil
        }
    }

    func save(_ value: Value) {
        do {
            try JSONEncoder().encode(value).write(to: url, options: .atomic)
        } catch {
            Log.storage.error("save \(url.lastPathComponent, privacy: .public): \(error.localizedDescription)")
        }
    }

    func delete() {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            Log.storage.error("delete \(url.lastPathComponent, privacy: .public): \(error.localizedDescription)")
        }
    }
}
