// Why: the honest place to see what Roomy can access, rescan, reset the cache, get back contact backups,
// and read how deletion actually works on iOS. Nothing here deletes anything, so nothing here is red.
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.settingsSectionSpacing) {
                accessSection
                scanSection
                backupsSection
                deletionSection
            }
            .padding(.horizontal, Space.margin)
            .padding(.bottom, Space.s32)
        }
        .background(RoomyColor.bg)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var accessSection: some View {
        SettingsSection("Access") {
            SettingsRow(
                systemImage: "photo.stack", title: "Photos", kind: .value(app.photoAccess.state.displayName))
            SettingsRow(
                systemImage: "person.crop.rectangle.stack", title: "Contacts",
                kind: .value(app.contactAccess.state.displayName), showsSeparator: true)
            Button {
                SystemSettings.open()
            } label: {
                Text("Open Settings").frame(maxWidth: .infinity)
            }
            .buttonStyle(.roomySecondary)
            .controlSize(.small)
            .padding(.horizontal, Space.s16)
            .padding(.top, Space.s4)
            .padding(.bottom, Space.s16)
        }
    }

    private var scanSection: some View {
        SettingsSection("Scan") {
            Button(action: app.rescan) {
                SettingsRow(systemImage: "arrow.clockwise", title: "Rescan now", kind: .action)
            }
            .buttonStyle(.plain)
            Button(action: app.clearScanCache) {
                SettingsRow(systemImage: "trash.slash", title: "Clear hash cache", kind: .action, showsSeparator: true)
            }
            .buttonStyle(.plain)
        }
    }

    private var backupsSection: some View {
        SettingsSection(
            "Contact backups",
            footer: "Written before every merge that changes a card; the last 10 are kept. Share a backup to "
                + "Contacts to bring the original cards back, without their notes."
        ) {
            if app.cleanup.backups.isEmpty {
                SettingsRow(title: "No backups yet", kind: .placeholder)
            }
            ForEach(Array(app.cleanup.backups.enumerated()), id: \.element) { index, url in
                ShareLink(item: url) {
                    SettingsRow(
                        systemImage: "clock.arrow.circlepath", title: url.deletingPathExtension().lastPathComponent,
                        kind: .share, showsSeparator: index > 0)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shares this backup")
            }
        }
    }

    private var deletionSection: some View {
        SettingsSection("How deletion works") {
            VStack(alignment: .leading, spacing: Layout.deletionPointSpacing) {
                ForEach(DeletionPoint.all) { point in
                    DeletionPointRow(point: point)
                }
            }
            .padding(Space.s16)
        }
    }
}

/// One idea of "How deletion works": its icon, then the sentence.
private struct DeletionPointRow: View {
    let point: DeletionPoint

    var body: some View {
        HStack(alignment: .top, spacing: Space.s12) {
            SettingsIcon(systemImage: point.systemImage)
            Text(point.text)
                .font(RoomyFont.subheadline)
                .foregroundStyle(RoomyColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }.environment(AppState())
}
