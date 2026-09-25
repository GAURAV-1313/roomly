// Why: one place for loggers, so every layer reports failures the same way instead of swallowing them.
import Foundation
import os

nonisolated enum Log {
    /// The bundle id, so logs follow the app's identity instead of a string that can drift from it.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "roomy"

    static let scan = Logger(subsystem: subsystem, category: "scan")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let media = Logger(subsystem: subsystem, category: "media")
    static let permissions = Logger(subsystem: subsystem, category: "permissions")
    static let contacts = Logger(subsystem: subsystem, category: "contacts")
    static let cleanup = Logger(subsystem: subsystem, category: "cleanup")
}
