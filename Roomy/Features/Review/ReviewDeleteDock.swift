// Why: the one red button, and the guard around it. Review rises under the finger that tapped the Review capsule,
// so a quick second tap used to land on Delete. Under the button sits a note — the first sentence of the
// confirmation — in a slot exactly as tall as that capsule, with its bottom padding, so it covers the capsule's
// footprint at both detents and a second tap lands on text. The note only grows downward at large text sizes,
// so the button only moves further away. The button still asks once more, in words taken from the list at the
// moment it was tapped, and the cleanup runs exactly that list.
import SwiftUI

struct ReviewDeleteDock: View {
    let ready: [BasketItem]
    @Binding var isConfirming: Bool
    let onConfirm: ([BasketItem]) -> Void

    /// What Review listed when the red button was tapped: the confirmation's words and the cleanup both use it.
    @State private var confirmed: [BasketItem] = []

    var body: some View {
        let summary = ReviewSummary(items: ready)
        VStack(spacing: Space.s12) {
            deleteButton(title: summary.actionTitle)
            note(summary.dockNote)
        }
        .padding(.horizontal, Space.margin)
        .padding(.top, Space.s16)
        .background {
            // The dock keeps a stray second tap to itself, so it can't reach a row scrolled underneath.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {}
                .accessibilityHidden(true)
        }
    }

    private func deleteButton(title: String) -> some View {
        let confirmation = ReviewSummary(items: confirmed)
        return Button {
            Haptics.tap()
            confirmed = ready
            isConfirming = true
        } label: {
            Text(title).multilineTextAlignment(.center)
        }
        .buttonStyle(.roomyDestructive)
        .confirmationDialog(confirmation.confirmTitle, isPresented: $isConfirming, titleVisibility: .visible) {
            Button(confirmation.confirmButton, role: .destructive) { onConfirm(confirmed) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(confirmation.confirmMessage)
        }
    }

    /// The Review capsule's footprint: its height as a minimum, and the same bottom padding as the bottom bar.
    private func note(_ text: String?) -> some View {
        Text(text ?? "")
            .font(RoomyFont.footnote)
            .foregroundStyle(RoomyColor.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Space.s12)
            .padding(.top, Space.s4)
            .frame(maxWidth: .infinity, minHeight: Layout.bottomBarHeight, alignment: .top)
            .padding(.bottom, Space.s12)
    }
}
