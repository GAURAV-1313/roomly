// Why: items in the basket that can't run yet are said plainly instead of listed with invented names or
// counted in the confirmation: what is waiting, why, and the two ways out — fix the cause, or take them out
// of Review. They stay saved, so they come back on their own once they can run.
import SwiftUI

struct ReviewHoldNotes: View {
    @Environment(AppState.self) private var app
    let review: BasketReview

    var body: some View {
        if !review.waitingForPhotos.isEmpty {
            HoldNote(
                title: "\(review.waitingForPhotos.count.counted("item")) on hold",
                message: "Roomy can't reach your photos right now, so these can't be deleted.",
                action: photosAction, onRemove: { remove(review.waitingForPhotos) })
        }
        if !review.waitingForComparison.isEmpty {
            HoldNote(
                title: "\(review.waitingForComparison.count.counted("similar photo")) on hold",
                message: comparisonMessage, action: comparisonAction,
                onRemove: { remove(review.waitingForComparison) })
        }
        if !review.waitingForContacts.isEmpty {
            HoldNote(
                title: "\(review.waitingForContacts.count.counted("contact merge")) on hold",
                message: contactsMessage, action: contactsAction, onRemove: { remove(review.waitingForContacts) })
        }
    }

    private func remove(_ items: [BasketItem]) {
        app.basket.remove(items.map(\.id))
    }

    private var photosAction: EmptyStateAction? {
        switch app.photoAccess.state {
        case .notDetermined: EmptyStateAction(title: "Allow Photos") { Task { await app.requestPhotoAccess() } }
        case .denied: EmptyStateAction(title: "Open Settings", perform: SystemSettings.open)
        case .restricted, .limited, .authorized: nil
        }
    }

    private var comparisonMessage: String {
        guard !app.scan.isScanning else {
            return "Roomy is comparing your photos to make sure each group keeps one. They'll be ready when it's done."
        }
        return "Roomy needs to compare your photos again to make sure each group keeps one."
    }

    private var comparisonAction: EmptyStateAction? {
        app.scan.isScanning ? nil : EmptyStateAction(title: "Scan now", perform: app.rescan)
    }

    private var contactsMessage: String {
        switch app.contactAccess.state {
        case .notDetermined: return "Merging needs access to your contacts."
        case .restricted: return "Access to contacts is managed on this phone, so these can't be merged."
        case .denied, .limited: return "Merging needs full access to Contacts. Turn it on in Settings to merge them."
        case .authorized: break
        }
        switch app.contacts.phase {
        case .idle, .scanning: return "Roomy is still reading your contacts. They'll be ready in a moment."
        case .failed: return "Roomy couldn't read your contacts, so these can't be merged right now."
        case .done: return "These groups weren't found in your contacts anymore."
        }
    }

    private var contactsAction: EmptyStateAction? {
        switch app.contactAccess.state {
        case .notDetermined: EmptyStateAction(title: "Allow Contacts") { Task { await app.requestContactAccess() } }
        case .denied, .limited: EmptyStateAction(title: "Open Settings", perform: SystemSettings.open)
        case .restricted: nil
        case .authorized:
            app.contacts.phase == .failed ? EmptyStateAction(title: "Try again", perform: app.contacts.scan) : nil
        }
    }
}

/// On hold is not a warning, so the icon sits on a neutral chip, never amber. Both actions are quiet capsules
/// that wrap onto their own lines when they don't fit side by side; at accessibility sizes the icon moves above.
private struct HoldNote: View {
    let title: String
    let message: String
    let action: EmptyStateAction?
    let onRemove: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Space.s12))
        layout {
            icon
            VStack(alignment: .leading, spacing: Space.s4) {
                Text(title).font(RoomyFont.headline).foregroundStyle(RoomyColor.textPrimary)
                Text(message).font(RoomyFont.footnote).foregroundStyle(RoomyColor.textSecondary)
                actions.padding(.top, Space.s4)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Space.s16)
        .padding(.vertical, Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
    }

    private var icon: some View {
        Image(systemName: "pause.circle")
            .font(RoomyFont.subheadlineSemibold)
            // The square has a fixed size, so its glyph stops growing where it would spill out.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .foregroundStyle(RoomyColor.textSecondary)
            .frame(width: Layout.noticeIcon, height: Layout.noticeIcon)
            .background(RoomyColor.chip, in: RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous))
            .accessibilityHidden(true)
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Space.s8) { buttons }
            VStack(alignment: .leading, spacing: Space.s8) { buttons }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        Group {
            if let action {
                Button(action.title, action: action.perform)
            }
            Button("Remove from Review", action: onRemove)
        }
        .buttonStyle(.roomySecondary)
        .controlSize(.small)
    }
}
