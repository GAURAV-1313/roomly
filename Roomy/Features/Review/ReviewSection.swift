// Why: one kind of item in Review. The first rows show at once and the rest open on request, in a lazy stack,
// so a selection of thousands stays quick while every item that will go can still be seen and taken out one
// by one. A merge row is drawn only from a group the contact scan knows, so its name and count are real.
import SwiftUI

struct ReviewSection: View {
    @Environment(AppState.self) private var app
    let kind: BasketItem.Kind
    let items: [BasketItem]

    @State private var isExpanded = false

    var body: some View {
        if !items.isEmpty {
            let rows = ReviewSectionRows(total: items.count, isExpanded: isExpanded)
            let groups = kind == .contactGroup ? app.contacts.groupsByID : [:]
            VStack(spacing: Space.s8) {
                ReviewSectionHeader(kind: kind, count: items.count) { app.basket.remove(items.map(\.id)) }
                rowsCard(rows: rows, groups: groups)
            }
        }
    }

    private func rowsCard(rows: ReviewSectionRows, groups: [String: ContactGroup]) -> some View {
        VStack(spacing: 0) {
            LazyVStack(spacing: 0) {
                ForEach(Array(items.prefix(rows.visibleCount).enumerated()), id: \.element.id) { index, item in
                    row(for: item, groups: groups, isFirst: index == 0)
                }
            }
            if let title = rows.toggleTitle {
                separator
                toggleButton(title)
            }
        }
        .padding(.leading, Space.s12)
        .padding(.trailing, Space.s8)
        .padding(.vertical, Space.s4)
        .frame(maxWidth: .infinity)
        .dashboardCard()
    }

    private var separator: some View {
        Rectangle().fill(RoomyColor.separator).frame(height: 1)
    }

    private func toggleButton(_ title: String) -> some View {
        Button(title) { isExpanded.toggle() }
            .font(RoomyFont.subheadlineSemibold)
            .foregroundStyle(RoomyColor.accent)
            .frame(maxWidth: .infinity, minHeight: Layout.tapTarget)
    }

    /// A row carries the separator above it, so a merge the scan no longer knows leaves no stray line.
    @ViewBuilder
    private func row(for item: BasketItem, groups: [String: ContactGroup], isFirst: Bool) -> some View {
        let remove = { app.basket.remove([item.id]) }
        if item.kind == .contactGroup {
            if let group = groups[item.id] {
                VStack(spacing: 0) {
                    if !isFirst { separator }
                    ContactReviewRow(
                        name: app.contacts.preview(for: group)?.name ?? "", cardCount: group.members.count,
                        onRemove: remove)
                }
            }
        } else {
            VStack(spacing: 0) {
                if !isFirst { separator }
                AssetReviewRow(item: item, snapshot: app.scan.snapshot(item.id), onRemove: remove)
            }
        }
    }
}
