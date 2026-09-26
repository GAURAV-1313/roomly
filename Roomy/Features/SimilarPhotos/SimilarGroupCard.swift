// Why: one group as a card — the reason they were grouped and Compare on top, the keeper first with its Best
// badge, the extras after it, and what keeping or removing would mean. Tapping a photo toggles it in the
// basket; a long press shows it large first. The footer and tiles come from `SimilarGroupSelection`, so a
// queued keeper is never hidden behind its badge. The group's own "Select extras" is a text-style toggle, not a
// filled pill, so it doesn't read as a repeat of the screen's bulk action (Figma "SelectToggle v5"). The reason
// chip wears the Similar colour (Figma "SimilarGroupCard v5"); at accessibility text sizes the chips and the
// footer stack instead of squeezing.
import SwiftUI

struct SimilarGroupCard: View {
    @Environment(AppState.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let group: SimilarGroup
    let onCompare: () -> Void

    private var selection: SimilarGroupSelection {
        SimilarGroupSelection(group: group) { app.basket.contains($0) }
    }

    var body: some View {
        let selection = selection
        VStack(alignment: .leading, spacing: Space.s12) {
            header
            filmstrip(selection)
            footer(selection)
        }
        .padding(Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
    }

    private var stackLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
    }

    private var header: some View {
        stackLayout {
            chips.frame(maxWidth: .infinity, alignment: .leading)
            compareButton
        }
    }

    @ViewBuilder private var chips: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s4))
            : AnyLayout(HStackLayout(spacing: Space.s4))
        layout {
            ReasonChip(text: group.reason.label, tint: Route.similarPhotos.categoryTintSoft)
            if group.members.count > 2 {
                ReasonChip(text: "\(group.members.count) shots")
            }
        }
    }

    /// The same Compare the keeper tile opens. Its tap area reaches past the short text row to a full target.
    private var compareButton: some View {
        Button(action: onCompare) {
            HStack(spacing: Space.s2) {
                Text("Compare")
                Image(systemName: "chevron.right")
                    .font(RoomyFont.footnoteSemibold)
                    .accessibilityHidden(true)
            }
            .font(RoomyFont.subheadlineSemibold)
            .foregroundStyle(RoomyColor.accent)
            .padding(.vertical, Space.s12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, -Space.s12)
        .accessibilityLabel("Compare")
    }

    private func filmstrip(_ selection: SimilarGroupSelection) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s8) {
                ForEach(group.members, id: \.self) { id in
                    Button {
                        tapped(id, selection: selection)
                    } label: {
                        PhotoTile(id: id, state: selection.tileState(for: id))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        menuButton(for: id, selection: selection)
                    } preview: {
                        preview(for: id)
                    }
                }
            }
        }
    }

    private func footer(_ selection: SimilarGroupSelection) -> some View {
        stackLayout {
            Text(selection.footer(queuedSize: app.scan.sizeTotal(of: selection.queued)))
                .font(RoomyFont.subheadline)
                .foregroundStyle(RoomyColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if selection.canSelectExtras {
                SelectToggle(
                    title: selection.extrasToggleTitle, state: selection.extrasToggleState,
                    accessibilityHint: selection.areAllExtrasQueued
                        ? "Takes the extras out of Review and keeps all" : "Adds the suggested extras to Review"
                ) {
                    app.basket.toggleAll(app.scan.snapshots(group.suggestedExtras))
                }
                // Like Compare: the full target reaches past the short text row without making the card taller.
                .padding(.vertical, -Space.s12)
            }
        }
    }

    private func menuButton(for id: String, selection: SimilarGroupSelection) -> some View {
        let title: String
        if id == group.best && !selection.isKeeperQueued {
            title = "Compare"
        } else {
            title = selection.queued.contains(id) ? "Remove from Review" : "Add to Review"
        }
        return Button(title) { tapped(id, selection: selection) }
    }

    private func preview(for id: String) -> some View {
        let snapshot = app.scan.snapshot(id)
        return AssetPreview(id: id, pixelWidth: snapshot?.pixelWidth ?? 0, pixelHeight: snapshot?.pixelHeight ?? 0)
            .environment(app)
    }

    /// The keeper opens Compare; if it is queued (the keeper changed after it was picked), a tap takes it out.
    private func tapped(_ id: String, selection: SimilarGroupSelection) {
        if id == group.best && !selection.isKeeperQueued {
            onCompare()
            return
        }
        Haptics.tap()
        if id == group.best {
            app.basket.remove([id])
        } else if let snapshot = app.scan.snapshot(id) {
            app.basket.toggle(snapshot)
        }
    }
}

extension SimilarityReason {
    var label: String {
        switch self {
        case .exactDuplicate: "Exact duplicate"
        case .nearDuplicate: "Near-duplicate"
        case .burst: "Burst"
        case .moment(let seconds) where seconds < 1: "Taken together"
        case .moment(let seconds): "Taken \(seconds)s apart"
        case .similar: "Similar shots"
        }
    }
}
