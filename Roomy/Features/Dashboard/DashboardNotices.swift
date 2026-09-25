// Why: the dashboard never hides why its numbers look the way they do. If Photos access is missing or
// limited it says so with the way to fix it; if space is waiting in Recently Deleted it says how to finish,
// and only that it may be there once Roomy can no longer tell (`PendingSpaceNotice`);
// when free space rises by about that much it says what was measured — never more than was moved, and never
// that the space "is back", a cause Roomy didn't see. Each notice is one short row. A row slides down from the
// top as it arrives and back up as it goes, and the dashboard moves with it; with Reduce Motion rows only fade.
import SwiftUI

struct DashboardNotices: View {
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Which rows show. The dashboard animates its stack when this changes, so the content below moves too.
    struct Kind: Equatable {
        let photoAccess: AccessState
        let hasReclaimed: Bool
        let hasPending: Bool

        @MainActor init(app: AppState) {
            photoAccess = app.photoAccess.state
            hasReclaimed = app.cleanup.reclaimedBytes != nil
            hasPending = app.cleanup.pending != nil
        }
    }

    /// A Group, not a stack: its rows join the dashboard's own stack, and no notice leaves no gap.
    var body: some View {
        Group {
            photoAccessNotice
            reclaimNotice
        }
    }

    private var rowTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity)
    }

    @ViewBuilder
    private var photoAccessNotice: some View {
        switch app.photoAccess.state {
        case .notDetermined:
            NoticeRow(
                tone: .info, systemImage: "photo.on.rectangle", title: "Let Roomy look at your photos",
                message: "It scans on this phone to find space.",
                accessory: .action("Allow", { Task { await app.requestPhotoAccess() } })
            )
            .transition(rowTransition)
        case .limited:
            NoticeRow(
                tone: .info, systemImage: "photo.on.rectangle", title: "Roomy sees only some photos",
                message: "Results cover just the photos you picked.",
                accessory: .action("Change", { Task { await app.manageLimitedPhotos() } })
            )
            .transition(rowTransition)
        case .denied:
            NoticeRow(
                tone: .info, systemImage: "lock.fill", title: "Roomy can't see your photos",
                message: "Turn on Photos access in Settings.", accessory: .action("Settings", SystemSettings.open)
            )
            .transition(rowTransition)
        case .restricted:
            NoticeRow(
                tone: .info, systemImage: "lock.fill", title: "Photos access is restricted",
                message: "Access is managed on this phone."
            )
            .transition(rowTransition)
        case .authorized:
            EmptyView()
        }
    }

    @ViewBuilder
    private var reclaimNotice: some View {
        if let reclaimed = app.cleanup.reclaimedBytes {
            NoticeRow(
                tone: .success, systemImage: "checkmark", title: "\(reclaimed.byteString) more free space",
                message: "Measured just now.",
                hint: "About what your cleanup moved to Recently Deleted.",
                accessory: .dismiss(app.cleanup.dismissReclaimed)
            )
            .transition(rowTransition)
        } else if let pending = app.cleanup.pending {
            let notice = PendingSpaceNotice(pending)
            NoticeRow(
                tone: .warning, systemImage: "trash", title: notice.title, message: notice.message, hint: notice.hint,
                accessory: .action("Open", PhotosApp.open)
            )
            .transition(rowTransition)
        }
    }
}
