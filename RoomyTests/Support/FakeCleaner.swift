// Why: the cleanup flow is tested against a cleaner that deletes nothing and answers the way Photos and
// Contacts would — including "Don't Allow" — so every result the person can see has a test.
import Foundation
import os

@testable import Roomy

final class FakeCleaner: Cleaner {
    private let removal: AssetRemoval?
    private let failingGroups: Set<String>
    private let missing: Set<String>
    private let calls = OSAllocatedUnfairLock(initialState: [String]())

    /// `removal` nil runs the real accounting against a library holding every id except `missing`, and
    /// removes every asset asked for; groups in `failingGroups` fail to merge.
    init(removal: AssetRemoval? = nil, failingGroups: Set<String> = [], missing: Set<String> = []) {
        self.removal = removal
        self.failingGroups = failingGroups
        self.missing = missing
    }

    var callLog: [String] { calls.withLock { $0 } }

    func merge(_ groups: [ContactGroup]) async -> ContactMergeResult {
        calls.withLock { $0.append("merge") }
        var result = ContactMergeResult(backupFile: URL(fileURLWithPath: "/tmp/backup.vcf"))
        for group in groups {
            if failingGroups.contains(group.id) {
                result.failedGroupIDs.append(group.id)
            } else {
                result.mergedGroupIDs.append(group.id)
                result.removedCardCount += group.extras.count
            }
        }
        return result
    }

    func removeAssets(_ ids: [String], keepingOneOf groups: [[String]]) async -> AssetRemoval {
        calls.withLock { $0.append("remove") }
        if let removal { return removal }
        var deleted = missing
        return await RemovalRun.run(
            ids, keepingOneOf: groups, batchSize: CleanupPlan.assetsPerPrompt,
            existing: { Set($0).subtracting(deleted) },
            delete: { batch in
                deleted.formUnion(batch)
                return nil
            })
    }

    func backups() -> [URL] { [] }
}

struct FakeContactSource: ContactSource {
    let cards: [ContactCard]
    var delay: Duration = .zero

    func cards() async throws -> [ContactCard] {
        try await Task.sleep(for: delay)
        return cards
    }
}

extension ContactCard {
    static func fixture(
        _ id: String, _ name: String, phones: [String] = [], emails: [String] = [], hasImage: Bool = false,
        isInDefaultContainer: Bool = false
    ) -> ContactCard {
        ContactCard(
            id: id, name: name, phones: phones, emails: emails, hasImage: hasImage,
            isInDefaultContainer: isInDefaultContainer)
    }
}
