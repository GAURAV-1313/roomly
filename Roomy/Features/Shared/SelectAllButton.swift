// Why: every screen that lists many items offers the same toolbar control, worded the way Photos words it,
// and it acts on exactly the items the screen shows, never on ones a filter hides.
import SwiftUI

struct SelectAllButton: View {
    @Environment(AppState.self) private var app
    let items: [AssetSnapshot]

    var body: some View {
        let isAllSelected = app.basket.containsAll(items.map(\.id))
        Button(isAllSelected ? "Deselect All" : "Select All") {
            Haptics.tap()
            app.basket.toggleAll(items)
        }
        .disabled(items.isEmpty)
    }
}
