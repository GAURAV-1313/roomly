// Why: a cleanup is described as data before and after it runs. The plan is what the person confirmed in Review,
// less anything that can't run safely now; the report is what really happened, measured afterwards rather than
// assumed from what was asked.
import Foundation

/// What the person approved in Review, less anything that can't run safely now.
nonisolated struct CleanupPlan: Sendable, Equatable {
    /// iOS shows its own prompt for every delete request, and one request carries at most this many assets.
    /// Large enough that most cleanups need one prompt; a limit so one stuck request can't hold everything.
    static let assetsPerPrompt = 1_000

    var assetIDs: [String] = []
    /// Known sizes; assets whose size is unavailable are absent and count as zero.
    var bytesByID: [String: Int64] = [:]
    var contactGroups: [ContactGroup] = []
    /// Members of every similar group the photos belong to, keeper first. A cleanup never empties one.
    var similarGroups: [[String]] = []
    /// Similar photos left out of the plan because deleting them would leave their group with no photo.
    var sparedIDs: [String] = []
    /// Confirmed items left out because they can't run safely now, so the result can say why.
    var held = HeldItems()

    var isEmpty: Bool { assetIDs.isEmpty && contactGroups.isEmpty }
    var assetBytes: Int64 { bytesByID.values.reduce(0, +) }

    /// How many iOS prompts deleting this many assets takes.
    static func promptCount(forAssets count: Int) -> Int {
        (count + assetsPerPrompt - 1) / assetsPerPrompt
    }

    /// Builds the plan from exactly what the person confirmed, never from what joined the basket since. Whatever of
    /// it can't run safely now — Photos access is off, a rescan is comparing the library, a merge's group is
    /// gone — is held.
    static func make(
        confirmed review: BasketReview, contactGroups: [String: ContactGroup], similarGroups: [SimilarGroup]
    ) -> CleanupPlan {
        var plan = make(items: review.ready, contactGroups: contactGroups, similarGroups: similarGroups)
        plan.held.waitingForPhotos += review.waitingForPhotos.count
        plan.held.waitingForComparison += review.waitingForComparison.count
        plan.held.waitingForContacts += review.waitingForContacts.count
        return plan
    }

    /// Builds the plan from basket items. A merge whose group no longer exists is held, never guessed at. A similar
    /// photo whose deletion would leave its group with no photo — a queued keeper, or a photo no longer in any
    /// group — is dropped into `sparedIDs`, so the plan itself can never empty a group.
    static func make(
        items: some Sequence<BasketItem>, contactGroups: [String: ContactGroup], similarGroups: [SimilarGroup] = []
    ) -> CleanupPlan {
        var plan = CleanupPlan()
        var photoIDs: Set<String> = []
        for item in items.sorted(by: { $0.id < $1.id }) {
            if item.kind == .contactGroup {
                if let group = contactGroups[item.id] {
                    plan.contactGroups.append(group)
                } else {
                    plan.held.waitingForContacts += 1
                }
            } else {
                plan.assetIDs.append(item.id)
                plan.bytesByID[item.id] = item.bytes
                if item.kind == .photo {
                    photoIDs.insert(item.id)
                }
            }
        }
        plan.similarGroups = groups(of: photoIDs, in: similarGroups)
        let known = Set(plan.similarGroups.flatMap { $0 })
        let spared = SurvivorRule.spared(queued: photoIDs, groups: plan.similarGroups, existing: known)
        plan.sparedIDs = plan.assetIDs.filter(spared.contains)
        plan.assetIDs.removeAll(where: spared.contains)
        for id in spared {
            plan.bytesByID[id] = nil
        }
        return plan
    }

    /// The group of every queued photo, keeper first. A photo in no group stands alone: the last of its moment.
    private static func groups(of photoIDs: Set<String>, in similarGroups: [SimilarGroup]) -> [[String]] {
        var groups =
            similarGroups
            .filter { $0.members.contains(where: photoIDs.contains) }
            .map { [$0.best] + $0.extras }
        let grouped = Set(groups.flatMap { $0 })
        groups += photoIDs.subtracting(grouped).sorted().map { [$0] }
        return groups
    }
}

/// The outcome of asking Photos to delete assets.
nonisolated struct AssetRemoval: Sendable, Equatable {
    enum Stop: Sendable, Equatable {
        /// The person chose Don't Allow in the Photos prompt.
        case declined
        /// Photos never answered.
        case timedOut
        case failed(String)
        /// Photos access is off, so nothing was asked.
        case noAccess
    }

    /// Assets that are gone from the library, checked after the request rather than trusted from it.
    var removedIDs: [String] = []
    /// Assets that were not in the library Roomy can see when the cleanup started. Nothing was done to them.
    var unavailableIDs: [String] = []
    /// Queued photos that were kept so their similar group still has one photo left.
    var sparedIDs: [String] = []
    /// Why removal stopped early; nil when every batch went through.
    var stop: Stop?
}

/// Every group ends in exactly one of the four lists.
nonisolated struct ContactMergeResult: Sendable, Equatable {
    var mergedGroupIDs: [String] = []
    /// Not merged for a passing reason (the address book was busy, the backup could not be written); these
    /// stay in Review.
    var failedGroupIDs: [String] = []
    /// A card was edited or removed after the scan, so the approved preview no longer held. Nothing was
    /// written; the groups are found again by a fresh scan.
    var changedGroupIDs: [String] = []
    /// Contacts refused the change, usually because a card is in a read-only account. Not offered again.
    var refusedGroupIDs: [String] = []
    /// The vCard file written before any card was changed. No backup means no merge.
    var backupFile: URL?

    var removedCardCount = 0

    var unmergedCount: Int { failedGroupIDs.count + changedGroupIDs.count + refusedGroupIDs.count }
}

nonisolated struct CleanupReport: Sendable, Equatable {
    var assets = AssetRemoval()
    var removedBytes: Int64 = 0
    var contacts = ContactMergeResult()
    /// Confirmed items that were left alone because they couldn't run safely when the cleanup started.
    var held = HeldItems()

    var removedCount: Int { assets.removedIDs.count }
    var mergedCount: Int { contacts.mergedGroupIDs.count }
    var didChangeAnything: Bool { removedCount > 0 || mergedCount > 0 }
}
