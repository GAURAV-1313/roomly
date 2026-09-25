// Why: a permission is a white card that always says what Roomy can see and offers the one fix that works
// (Figma "PermissionCard v5"). The fix is its own quiet capsule, not the whole card, so a card with nothing to fix
// — allowed, or restricted by the phone — has nothing to tap. A state change crossfades, and a footer that
// appears grows the card (motion row 4). At accessibility sizes the state and fix stack under the text.
import SwiftUI

struct PermissionCard: View {
    let kind: PermissionKind
    let state: AccessState
    let perform: (PermissionAction) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var status: PermissionStatus { PermissionStatus(state, kind: kind) }
    private var isStacked: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            top
            if let footer = status.footer {
                Divider().overlay(RoomyColor.separator)
                footerRow(footer).transition(.opacity)
            }
        }
        .padding(Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
        .animation(reduceMotion ? Motion.quick : Motion.standard, value: state)
    }

    private var top: some View {
        let layout =
            isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        return layout {
            icon
            text
            statusView.transition(.opacity)
        }
    }

    private var icon: some View {
        Image(systemName: kind.systemImage)
            .font(RoomyFont.title3)
            // The square has a fixed size, so its glyph stops growing where it would spill out.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .foregroundStyle(RoomyColor.accent)
            .frame(width: Layout.permissionIcon, height: Layout.permissionIcon)
            .background(RoomyColor.accentSoft, in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
            .accessibilityHidden(true)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            titleRow
            Text(kind.purpose)
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // The page is tight on height; the purpose must wrap, never truncate.
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityValue(status.accessibilityValue)
    }

    private var titleRow: some View {
        let layout =
            isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s4))
            : AnyLayout(HStackLayout(spacing: Space.s8))
        return layout {
            Text(kind.title).font(RoomyFont.headline).foregroundStyle(RoomyColor.textPrimary)
            Text(kind.tag)
                .font(RoomyFont.caption)
                .foregroundStyle(RoomyColor.textSecondary)
                .padding(Layout.tagPadding)
                .background(RoomyColor.chip, in: Capsule())
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if let action = status.action, status.isActionInline {
            actionButton(action)
        } else if let label = status.label {
            HStack(spacing: Space.s4) {
                Text(label).font(RoomyFont.footnoteSemibold).foregroundStyle(RoomyColor.textSecondary)
                if status.isGranted {
                    SelectionCheck(isSelected: true, surface: .card, size: Layout.permissionCheck)
                }
            }
            // The label is already read as the card's value.
            .accessibilityHidden(true)
        }
    }

    private func footerRow(_ footer: String) -> some View {
        let layout =
            isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        return layout {
            Text(footer)
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let action = status.action, !status.isActionInline {
                actionButton(action)
            }
        }
    }

    private func actionButton(_ action: PermissionAction) -> some View {
        Button(action.title) { perform(action) }
            .buttonStyle(.roomySecondary)
            .controlSize(.small)
            .frame(maxWidth: isStacked ? .infinity : nil)
            .accessibilityHint("\(kind.title): \(kind.purpose)")
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Space.s12) {
            PermissionCard(kind: .photos, state: .notDetermined) { _ in }
            PermissionCard(kind: .photos, state: .authorized) { _ in }
            PermissionCard(kind: .photos, state: .limited) { _ in }
            PermissionCard(kind: .contacts, state: .limited) { _ in }
            PermissionCard(kind: .photos, state: .denied) { _ in }
            PermissionCard(kind: .photos, state: .restricted) { _ in }
        }
        .padding()
    }
    .background(RoomyColor.bg)
}
