// Why: Apple's own duplicates idiom — groups, a marked keeper, a visible reason so people can check the
// grouping, and Compare for the full-screen decision. Nothing is selected until the person chooses:
// one tap selects every suggested extra, or they pick per group. A favourite or a burst frame the person
// picked is never selected in bulk; it can still be picked by hand. "Select all extras" stays in the summary
// card rather than the nav bar's Select All, because it never selects keepers.
import SwiftUI

struct SimilarPhotosView: View {
    @Environment(AppState.self) private var app
    @State private var comparing: SimilarGroup?

    var body: some View {
        content
            .navigationTitle("Similar Photos")
            .navigationBarTitleDisplayMode(.large)
            .reviewBar()
            .fullScreenCover(item: $comparing) { group in
                CompareView(group: group).environment(app)
            }
    }

    private var copy: SimilarPhotosCopy { SimilarPhotosCopy(uncheckedCount: app.scan.uncheckedPhotoCount) }

    private var content: some View {
        let groups = app.scan.similarGroups
        return PhotoScanGate(
            isEmpty: groups.isEmpty, emptyTitle: copy.emptyTitle, emptyMessage: copy.emptyMessage,
            needsComparison: true, tint: Route.similarPhotos.categoryTintSoft
        ) {
            groupList(groups)
        } placeholder: {
            SimilarGroupsSkeleton(copy: ScanProgressCopy(phase: app.scan.phase, hashProgress: app.scan.hashProgress))
        }
    }

    private func groupList(_ groups: [SimilarGroup]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Space.s12, pinnedViews: .sectionHeaders) {
                summaryCard(groups)
                ForEach(MonthSections.make(groups, date: \.date)) { section in
                    Section {
                        ForEach(section.items) { group in
                            SimilarGroupCard(group: group) { comparing = group }
                        }
                    } header: {
                        monthHeader(section)
                    }
                }
            }
            .padding(.horizontal, Space.margin)
            .padding(.bottom, Layout.bottomBarClearance)
        }
        .background(RoomyColor.bg)
    }

    private func summaryCard(_ groups: [SimilarGroup]) -> some View {
        let extras = app.scan.suggestedExtras
        let isAllSelected = app.basket.containsAll(extras)
        let summary = SimilarPhotosSummary(
            groupCount: groups.count, extraCount: extras.count, size: app.scan.similarSize)
        return CategorySummaryCard(
            route: .similarPhotos, systemImage: "photo.stack", value: summary.value, detail: summary.detail
        ) {
            Button(isAllSelected ? "Deselect all" : "Select all extras") {
                app.basket.toggleAll(app.scan.snapshots(extras))
            }
            .buttonStyle(.roomySecondary)
            .controlSize(.small)
            if let note = copy.uncheckedNote {
                Text(note)
                    .font(RoomyFont.footnote)
                    .foregroundStyle(RoomyColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func monthHeader(_ section: MonthSection<SimilarGroup>) -> some View {
        let extras = section.items.flatMap(\.suggestedExtras)
        let isAllSelected = app.basket.containsAll(extras)
        return SectionHeader(
            title: section.title, action: isAllSelected ? "Deselect" : "Select extras", style: .month
        ) {
            app.basket.toggleAll(app.scan.snapshots(extras))
        }
        .background(RoomyColor.bg)
    }
}
