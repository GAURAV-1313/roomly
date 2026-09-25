// Why: most waits are shorter than a second. A loading state that flashes on and off for 200 ms is noise, so it
// shows only once the wait has lasted `delay`, and then fades in. The wait runs in the view's own task, which
// SwiftUI cancels when the view goes away, so a reveal never lands on a screen that has moved on.
import SwiftUI

struct DelayedReveal<Content: View>: View {
    let delay: Duration
    @ViewBuilder let content: Content

    @State private var isShown = false

    var body: some View {
        ZStack {
            if isShown {
                content.transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            // try? is deliberate: sleep only throws on cancellation, and the check below handles that.
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            withAnimation(Motion.quick) { isShown = true }
        }
    }
}
