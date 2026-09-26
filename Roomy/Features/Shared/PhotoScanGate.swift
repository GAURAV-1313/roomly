// Why: a photo category can only say "all clear" after a scan that could see the library. This gate shows
// the honest state first — no access, not scanned yet, still scanning, comparison stopped — and the category
// only after that. While the scan runs, the screen's own skeleton in its final layout shows, but only once the
// wait has lasted a moment, and the content fades in over it. With limited access it says the results cover only the picked photos and offers to change
// them, because an empty result there says nothing about the rest of the library. The rules live in
// PhotoScanGateState.
import SwiftUI

struct PhotoScanGate<Content: View, Placeholder: View>: View {
    @Environment(AppState.self) private var app
    let isEmpty: Bool
    let emptyTitle: String
    let emptyMessage: String
    /// True for categories that exist only once photos are compared, so a stopped comparison matters.
    var needsComparison = false
    /// The category's soft colour, for the well behind Roomy on every gate card.
    var tint: Color = RoomyColor.chip
    @ViewBuilder let content: Content
    /// What the screen shows while the scan runs and nothing is found yet: skeletons, never made-up numbers.
    @ViewBuilder let placeholder: Placeholder

    private var state: PhotoScanGateState {
        .make(access: app.photoAccess.state, phase: app.scan.phase, isEmpty: isEmpty, needsComparison: needsComparison)
    }

    var body: some View {
        let state = state
        Group {
            switch state {
            case .content(let note): noted(note)
            case .askForAccess, .denied, .restricted: accessMessage
            case .scanning: DelayedReveal(delay: Motion.loadingDelay) { placeholder }
            case .notScanned, .comparisonNotFinished, .empty: scanMessage
            }
        }
        .transition(.opacity)
        .animation(Motion.quick, value: state)
    }

    @ViewBuilder
    private var accessMessage: some View {
        switch state {
        case .askForAccess:
            EmptyStateView(
                mood: .curious, title: "Let Roomy look at your photos",
                message: "It scans on this phone to find what can go. Nothing leaves it.",
                primary: EmptyStateAction(title: "Allow Photos") { Task { await app.requestPhotoAccess() } }, tint: tint
            )
        case .denied:
            EmptyStateView(
                mood: .concerned, title: "Roomy can't see your photos",
                message: "Turn on Photos access for Roomy in Settings to scan.",
                primary: EmptyStateAction(title: "Open Settings", perform: SystemSettings.open), tint: tint)
        case .restricted:
            EmptyStateView(
                mood: .concerned, title: "Photos access is restricted",
                message: "Access is managed on this phone, so Roomy can't scan photos.", tint: tint)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var scanMessage: some View {
        switch state {
        case .notScanned:
            EmptyStateView(
                mood: .idle, title: "Not scanned yet", message: "Scan to see what can go.",
                primary: EmptyStateAction(title: "Scan now", perform: app.rescan), tint: tint)
        case .comparisonNotFinished:
            EmptyStateView(
                mood: .idle, title: DashboardSummary.comparisonNotFinished, message: Self.resumeMessage,
                primary: EmptyStateAction(title: "Resume", perform: app.rescan), tint: tint)
        case .empty(isLimited: true):
            EmptyStateView(
                mood: .resting, title: "Nothing in the photos you picked", message: Self.limitedMessage,
                primary: EmptyStateAction(title: "Change selection", perform: changeSelection), tint: tint)
        case .empty(isLimited: false):
            EmptyStateView(mood: .resting, title: emptyTitle, message: emptyMessage, tint: tint)
        default:
            EmptyView()
        }
    }

    // Computed, because a generic type can't hold static stored properties.
    private static var resumeMessage: String {
        "Roomy stopped before comparing every photo. Resume to finish; photos already compared are kept."
    }
    private static var limitedMessage: String {
        "Roomy can only see the photos you picked, so there may be more in your library."
    }

    /// One stable stack whatever the note: the banner comes and goes above `content`, which keeps its identity, so
    /// the list's folding and scroll position survive a note appearing or clearing (for example after Resume).
    private func noted(_ note: PhotoScanGateState.Note?) -> some View {
        VStack(spacing: 0) {
            switch note {
            case .limitedAccess:
                banner(
                    NoticeRow(
                        tone: .info, systemImage: "photo.on.rectangle", title: "Roomy sees only some photos",
                        message: "Results cover just the photos you picked.",
                        accessory: .action("Change", changeSelection)))
            case .comparisonNotFinished:
                banner(
                    NoticeRow(
                        tone: .info, systemImage: "pause.fill", title: DashboardSummary.comparisonNotFinished,
                        message: "These groups are from an earlier scan.",
                        hint: "Resume to compare the rest; photos already compared are kept.",
                        accessory: .action("Resume", app.rescan)))
            case nil:
                EmptyView()
            }
            content
        }
    }

    private func banner(_ notice: NoticeRow) -> some View {
        notice
            .padding(.horizontal, Space.margin)
            .padding(.vertical, Space.s8)
            .frame(maxWidth: .infinity)
            .background(RoomyColor.bg)
    }

    private func changeSelection() {
        Task { await app.manageLimitedPhotos() }
    }
}
