// Why: the hub. "Roomy" and Settings share the top row and scroll away with the content, so the title never
// sits a level below the button. Then one storage card (Roomy, how full, what can go), anything that needs
// attention, and the categories as a grid of tiles showing their own content, with the glass capsule as the
// one action. No tab bar: the categories feed one shared Review, so they are drill-downs, not separate places.
// All numbers come from DashboardSummary. On its first appearance the blocks fade up in order, and a tile
// opens its screen by zooming out of itself (iOS 18 and later; a standard push on iOS 17).
import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var zoom
    /// Flipped once, on the first appearance, so the fade-up never replays when the person comes back.
    @State private var isShown = false

    var body: some View {
        let summary = DashboardSummary(app: app)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s12) {
                    header
                    VStack(alignment: .leading, spacing: Space.s20) {
                        StorageCard(summary: summary, onAction: perform).staggeredAppear(0, isShown: isShown)
                        DashboardNotices().staggeredAppear(1, isShown: isShown)
                        Text("Clean up")
                            .font(RoomyFont.title3)
                            .foregroundStyle(RoomyColor.textPrimary)
                            .padding(.top, Space.s8)
                            .padding(.horizontal, Space.s4)
                            .accessibilityAddTraits(.isHeader)
                            .staggeredAppear(2, isShown: isShown)
                        categoryGrid(summary.tiles)
                    }
                    .animation(reduceMotion ? Motion.quick : Motion.standard, value: DashboardNotices.Kind(app: app))
                }
                .padding(.top, Space.s4)
                .padding(.horizontal, Space.margin)
                .padding(.bottom, Layout.bottomBarClearance)
            }
            .background(RoomyColor.bg)
            // With no bar, content would scroll under the status bar; a strip of the background keeps it legible.
            .overlay(alignment: .top) {
                GeometryReader { proxy in
                    RoomyColor.bg
                        .frame(height: proxy.safeAreaInsets.top)
                        .ignoresSafeArea(edges: .top)
                }
                .allowsHitTesting(false)
            }
            // Kept for the back button of the screens pushed from here; the bar itself is hidden.
            .navigationTitle("Roomy")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self, destination: destination)
            .bottomBar { scanButton }
            .reviewBar(isProminent: false)
            .onAppear { isShown = true }
            .task { app.startScansIfNeeded() }
            // Not the phase: a stopped comparison's index is read again without leaving `.stopped`.
            .onChange(of: app.scan.settledCount) { app.scanDidFinish() }
            .onChange(of: app.contacts.phase) { _, phase in
                if phase == .done {
                    app.contactScanDidFinish()
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Roomy")
                .font(RoomyFont.largeTitle)
                .foregroundStyle(RoomyColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            NavigationLink(value: Route.settings) {
                Image(systemName: "gearshape")
                    .font(RoomyFont.title3)
                    // Like the system's bar buttons, the glyph stays inside its circle at every text size.
                    .dynamicTypeSize(...DynamicTypeSize.xLarge)
                    .foregroundStyle(RoomyColor.textPrimary)
                    .frame(width: Layout.tapTarget, height: Layout.tapTarget)
                    .roomyGlass(in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    /// Two tiles a row; one a row at accessibility text sizes, where two would squeeze the words.
    @ViewBuilder
    private func categoryGrid(_ tiles: [CategoryTile]) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: Layout.tileSpacing) {
                ForEach(Array(tiles.enumerated()), id: \.element.id) { index, tile in link(tile, index: index) }
            }
        } else {
            Grid(horizontalSpacing: Layout.tileSpacing, verticalSpacing: Layout.tileSpacing) {
                ForEach(Array(stride(from: 0, to: tiles.count, by: 2)), id: \.self) { start in
                    GridRow {
                        ForEach(start..<min(start + 2, tiles.count), id: \.self) { index in
                            link(tiles[index], index: index)
                        }
                    }
                }
            }
        }
    }

    /// Tiles follow the heading in the first-appearance sequence, and each is where its screen zooms out of.
    private func link(_ tile: CategoryTile, index: Int) -> some View {
        NavigationLink(value: tile.route) {
            CategoryCard(tile: tile).zoomSource(id: tile.route, in: zoom)
        }
        .buttonStyle(.plain)
        .staggeredAppear(3 + index, isShown: isShown)
    }

    private func perform(_ action: DashboardSummary.CardAction) {
        switch action {
        case .cancel: app.scan.cancel()
        case .rescan, .resume: app.rescan()
        }
    }

    @ViewBuilder
    private var scanButton: some View {
        if app.review.ready.isEmpty && app.scan.phase == .idle && app.photoAccess.state.canUse {
            Button("Scan for space", action: app.rescan)
                .buttonStyle(.roomyPrimary)
                .padding(.horizontal, Space.margin)
                .padding(.bottom, Space.s12)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .similarPhotos: SimilarPhotosView().zoomDestination(id: route, in: zoom)
        case .screenshots: ScreenshotsView().zoomDestination(id: route, in: zoom)
        case .largeVideos: LargeVideosView().zoomDestination(id: route, in: zoom)
        case .settings: SettingsView()
        case .duplicateContacts: DuplicateContactsView().zoomDestination(id: route, in: zoom)
        }
    }
}

#Preview {
    DashboardView().environment(AppState())
}
