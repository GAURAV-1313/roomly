// Why: the dashboard summary is a pure value built from plain inputs so its rules can be unit-tested. This is the
// one place that reads those inputs from the live stores, kept apart from the view so the view stays layout. It
// reads the scan's scoped views, so the tiles and the storage card count exactly what the category screens list.
import Foundation

extension DashboardSummary {
    @MainActor init(app: AppState) {
        let scan = app.scan
        let similarSize = scan.similarSize
        let screenshotSize = scan.screenshots.sizeTotal
        let videoSize = scan.videos.sizeTotal
        self.init(
            phase: scan.phase, volume: app.volume, canUseLibrary: app.photoAccess.state.canUse,
            indexProgress: scan.indexProgress, hashProgress: scan.hashProgress,
            reclaimableBytes: scan.reclaimableBytes,
            similar: CategoryTotals(
                count: scan.suggestedExtras.count, bytes: similarSize.knownBytes,
                unsizedCount: similarSize.unknownCount, inCloudBytes: similarSize.inCloudBytes,
                groups: scan.similarGroups.count,
                unchecked: scan.uncheckedPhotoCount, previewIDs: scan.similarGroups.prefix(3).map(\.best)),
            screenshots: CategoryTotals(
                count: scan.screenshots.count, bytes: screenshotSize.knownBytes,
                unsizedCount: screenshotSize.unknownCount, inCloudBytes: screenshotSize.inCloudBytes,
                previewIDs: scan.screenshots.prefix(4).map(\.id)),
            videos: CategoryTotals(
                count: scan.videos.count, bytes: videoSize.knownBytes, unsizedCount: videoSize.unknownCount,
                inCloudBytes: videoSize.inCloudBytes, previewIDs: scan.videos.prefix(2).map(\.id)),
            contacts: ContactTotals(
                access: app.contactAccess.state, phase: app.contacts.phase, groups: app.contacts.groups.count,
                extraCards: app.contacts.extraCardCount, initials: Self.contactInitials(app.contacts)))
    }

    @MainActor private static func contactInitials(_ contacts: DuplicateContactsStore) -> [String] {
        contacts.groups.prefix(3).compactMap { contacts.preview(for: $0)?.name.first.map { String($0).uppercased() } }
    }
}
