// Why: the full-screen decision view. Photos sit on black, and controls are clear glass over dark scrims at
// the top and bottom so they read on any image; the pager's arrows sit inside its glass capsule without glass
// of their own, because glass on glass blurs. Swipe between shots; each photo says whether it is queued, apart
// from the buttons that change that, and any photo can be made the keeper. The group is read live from the
// scan store by id, so a new keeper shows at once.
import SwiftUI

struct CompareView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    /// The group as it was when Compare opened; used only if it has since left the store.
    let openedGroup: SimilarGroup
    @State private var page: String

    init(group: SimilarGroup) {
        openedGroup = group
        _page = State(initialValue: group.best)
    }

    private var group: SimilarGroup { app.scan.similarGroup(openedGroup.id) ?? openedGroup }
    private var position: Int { (group.members.firstIndex(of: page) ?? 0) + 1 }
    private var state: ComparePage {
        ComparePage(isKeeper: page == group.best, isQueued: app.basket.contains(page))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $page) {
                ForEach(group.members, id: \.self) { id in
                    AssetThumbnail(id: id, pixelSize: Layout.comparePhotoPixels, contentMode: .fit).tag(id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            VStack(spacing: 0) {
                topBar
                    .padding([.horizontal, .top], Space.margin)
                    .padding(.bottom, Layout.compareScrimOverhang)
                    .background(scrim(edge: .top))
                Spacer(minLength: 0)
                bottomBar
                    .padding([.horizontal, .bottom], Space.margin)
                    .padding(.top, Layout.compareScrimOverhang)
                    .background(scrim(edge: .bottom))
            }
        }
    }

    private var topBar: some View {
        HStack {
            iconButton("xmark", label: "Close") { dismiss() }
                .roomyGlass(in: Circle(), style: .clear)
            Spacer()
            CompareStatusBadge(page: state)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: Space.s8) {
            Text(metadata).font(RoomyFont.footnote).foregroundStyle(.white.opacity(0.9))
            if state.canBecomeKeeper || state.toggleTitle != nil {
                actionRow
            }
            HStack {
                iconButton("chevron.left", label: "Previous") { move(by: -1) }
                Spacer()
                Text("\(position) of \(group.members.count)\(page == group.best ? " · keeper" : "")")
                    .font(RoomyFont.headline)
                    .foregroundStyle(.white)
                Spacer()
                iconButton("chevron.right", label: "Next") { move(by: 1) }
            }
            .padding(.horizontal, Space.s8)
            .frame(minHeight: Layout.bottomBarHeight)
            .roomyGlass(in: Capsule(), style: .clear)
        }
    }

    /// Side by side when they fit, stacked at large text sizes.
    private var actionRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Space.s8) { actionButtons }
            VStack(spacing: Space.s8) { actionButtons }
        }
    }

    @ViewBuilder private var actionButtons: some View {
        if state.canBecomeKeeper {
            Button(action: makeKeeper) {
                actionLabel("Make keeper", systemImage: "checkmark.seal")
            }
            .roomyGlass(in: Capsule(), style: .clear)
            .accessibilityHint("Keeps this photo and offers the others for removal instead")
        }
        if let toggleTitle = state.toggleTitle {
            Button(action: toggleCurrent) {
                actionLabel(toggleTitle, systemImage: state.toggleIcon)
            }
            .roomyGlass(in: Capsule(), style: state.isQueued ? .clear : .prominent(RoomyColor.accent))
            .accessibilityValue(state.status)
        }
    }

    private var metadata: String {
        guard let snapshot = app.scan.snapshot(page) else { return "" }
        let parts = [
            snapshot.creationDate?.formatted(date: .abbreviated, time: .shortened),
            "\(snapshot.pixelWidth)×\(snapshot.pixelHeight)",
            SizeLabel.text(snapshot.size),
        ]
        return parts.compactMap { $0 }.joined(separator: " · ")
    }

    private func actionLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(RoomyFont.subheadlineSemibold)
            .foregroundStyle(.white)
            .padding(.horizontal, Space.s16)
            .frame(maxWidth: .infinity, minHeight: Layout.tapTarget)
    }

    /// The dark band behind a control bar, reaching to the screen edge. It never takes a swipe from the photos.
    private func scrim(edge: Edge.Set) -> some View {
        RoomyColor.dim.ignoresSafeArea(edges: edge).allowsHitTesting(false)
    }

    /// A round glyph button; the caller decides whether it stands on its own glass.
    private func iconButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: Layout.compareGlyph, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Layout.tapTarget, height: Layout.tapTarget)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// A queued keeper can only be taken out; any other photo flips.
    private func toggleCurrent() {
        Haptics.success()
        if state == .keeperQueued {
            app.basket.remove([page])
        } else if let snapshot = app.scan.snapshot(page) {
            app.basket.toggle(snapshot)
        }
    }

    private func makeKeeper() {
        Haptics.success()
        app.makeKeeper(page)
    }

    private func move(by offset: Int) {
        guard let index = group.members.firstIndex(of: page) else { return }
        let count = group.members.count
        withAnimation { page = group.members[(index + offset + count) % count] }
    }
}
