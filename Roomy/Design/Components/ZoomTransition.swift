// Why: a category screen grows out of the tile the person tapped, and a swipe back shrinks it into the tile, so
// the hub-and-spoke shape is felt. The zoom exists from iOS 18; on iOS 17 both modifiers do nothing and the
// standard push stays. With Reduce Motion the system turns the zoom into a fade on its own.
import SwiftUI

extension View {
    /// Marks this view as where the screen for `id` zooms out of.
    @ViewBuilder
    func zoomSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Pushes this screen with a zoom from the source marked with the same `id`.
    @ViewBuilder
    func zoomDestination(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
