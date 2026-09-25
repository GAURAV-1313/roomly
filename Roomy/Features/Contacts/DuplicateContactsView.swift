// Why: duplicates are spread across the whole address book, so this screen needs full access and says so
// plainly in every other state, on a card tinted like the contacts tile, instead of showing a misleadingly
// short list. Selecting a group only stages the merge; it happens after Review, with a backup first. Select All
// lives in the bar, like every other category screen, and only while there are groups to select.
import SwiftUI

struct DuplicateContactsView: View {
    @Environment(AppState.self) private var app

    private var tint: Color { Route.duplicateContacts.categoryTintSoft }

    var body: some View {
        content
            .navigationTitle("Duplicate Contacts")
            .navigationBarTitleDisplayMode(.large)
            .reviewBar()
    }

    @ViewBuilder
    private var content: some View {
        switch app.contactAccess.state {
        case .notDetermined:
            EmptyStateView(
                mood: .curious, title: "Find duplicate contacts",
                message: "Roomy reads the contacts on this phone to find cards for the same person. Nothing leaves it.",
                primary: EmptyStateAction(title: "Allow Contacts") { Task { await app.requestContactAccess() } },
                tint: tint)
        case .limited:
            EmptyStateView(
                mood: .concerned, title: "Roomy sees only some contacts",
                message: "Duplicates hide across the whole address book, so finding them needs full access.",
                primary: EmptyStateAction(title: "Open Settings", perform: SystemSettings.open), tint: tint)
        case .denied:
            EmptyStateView(
                mood: .concerned, title: "Roomy can't see your contacts",
                message: "Turn on Contacts for Roomy in Settings to look for duplicate cards.",
                primary: EmptyStateAction(title: "Open Settings", perform: SystemSettings.open), tint: tint)
        case .restricted:
            EmptyStateView(
                mood: .concerned, title: "Contacts are restricted",
                message: "Access to contacts is managed on this phone, so Roomy can't look for duplicates.", tint: tint)
        case .authorized:
            results
        }
    }

    private var results: some View {
        Group {
            phaseContent
        }
        .transition(.opacity)
        .animation(Motion.quick, value: app.contacts.phase)
    }

    /// Reading usually takes under a second, so its card waits a moment before showing and never flashes.
    @ViewBuilder
    private var phaseContent: some View {
        switch app.contacts.phase {
        case .idle, .scanning:
            DelayedReveal(delay: Motion.contactsLoadingDelay) {
                EmptyStateView(
                    mood: .thinking, title: "Reading your contacts", message: "This only takes a moment.", tint: tint)
            }
        case .failed:
            EmptyStateView(
                mood: .error, title: "Couldn't read contacts",
                message: "Something went wrong reading the address book.",
                primary: EmptyStateAction(title: "Try again", perform: app.contacts.scan), tint: tint)
        case .done where app.contacts.groups.isEmpty:
            EmptyStateView(
                mood: .resting, title: "No likely duplicates found",
                message: "Roomy links cards that share a phone number or email. None look like the same person.",
                tint: tint)
        case .done:
            groupList
        }
    }

    private var groupList: some View {
        let groups = app.contacts.groups
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: Space.s12) {
                summaryCard(groups)
                ForEach(groups) { group in
                    if let preview = app.contacts.preview(for: group) {
                        ContactGroupCard(
                            group: group, preview: preview, isSelected: app.basket.contains(group.id),
                            onToggle: { app.basket.toggle(group) })
                    }
                }
            }
            .padding(.horizontal, Space.margin)
            .padding(.bottom, Layout.bottomBarClearance)
        }
        .background(RoomyColor.bg)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { SelectAllGroupsButton(groups: groups) }
        }
    }

    private func summaryCard(_ groups: [ContactGroup]) -> some View {
        let summary = ContactsSummary(groups: groups, extraCardCount: app.contacts.extraCardCount)
        return CategorySummaryCard(
            route: .duplicateContacts, systemImage: "person.crop.rectangle.stack", value: summary.value,
            detail: summary.detail
        ) {
            Text(
                "Merging keeps every number, email and address, and saves a backup first. "
                    + "Notes can't be read by apps, so notes on removed cards aren't carried over."
            )
            .font(RoomyFont.footnote)
            .foregroundStyle(RoomyColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The bar's Select All for merges, worded like the one on the photo screens, acting on every group shown.
private struct SelectAllGroupsButton: View {
    @Environment(AppState.self) private var app
    let groups: [ContactGroup]

    var body: some View {
        let isAllSelected = app.basket.containsAll(groups.map(\.id))
        Button(isAllSelected ? "Deselect All" : "Select All") {
            Haptics.tap()
            app.basket.toggleAll(groups)
        }
        .disabled(groups.isEmpty)
    }
}
