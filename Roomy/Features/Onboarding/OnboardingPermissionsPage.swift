// Why: the last page says plainly what Roomy can see — Photos is required, Contacts is up to you — and each card
// offers only the fix that works. System prompts appear only when a card's button is tapped, never two in a row.
// The permission logic is the app's existing one: ask, change a limited Photos selection, or open Settings. Roomy
// on the hero card is curious until Photos can be used, then pleased.
import SwiftUI

struct OnboardingPermissionsPage: View {
    @Environment(AppState.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// At accessibility sizes Roomy moves above the text, as on the Figma AX2 frame.
    private var isLargeText: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        VStack(spacing: Space.s12) {
            heroCard
            PermissionCard(kind: .photos, state: app.photoAccess.state, perform: photosAction)
            PermissionCard(kind: .contacts, state: app.contactAccess.state, perform: contactsAction)
            Text("You can change either one later in Settings.")
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, Space.s4)
        }
    }

    private var heroCard: some View {
        let layout =
            isLargeText
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        return layout {
            if isLargeText { mascot }
            VStack(alignment: .leading, spacing: Space.s4) {
                Text("What Roomy can see")
                    .font(RoomyFont.title2)
                    .foregroundStyle(RoomyColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Photos is needed to scan. Contacts is up to you.")
                    .font(RoomyFont.subheadline)
                    .foregroundStyle(RoomyColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            if !isLargeText { mascot }
        }
        .padding(Space.s20)
        .background(
            LinearGradient(
                colors: [RoomyColor.heroTintTop, RoomyColor.heroTintBottom], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: Radius.heroCard, style: .continuous))
    }

    private var mascot: some View {
        MascotView(mood: app.photoAccess.state.canUse ? .pleased : .curious, size: Layout.permissionsMascot)
    }

    private func photosAction(_ action: PermissionAction) {
        switch action {
        case .allow: Task { await app.photoAccess.request() }
        case .changeSelection: Task { await app.manageLimitedPhotos() }
        case .openSettings: SystemSettings.open()
        }
    }

    private func contactsAction(_ action: PermissionAction) {
        switch action {
        case .allow: Task { await app.contactAccess.request() }
        case .changeSelection, .openSettings: SystemSettings.open()
        }
    }
}
