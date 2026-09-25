// Why: each category tile says what it holds in words and shows a few of the actual items, so people
// recognise their own photos before they tap. When a tile can't have numbers — no access, not scanned yet —
// it says why, with a glyph that matches, instead of showing an endless skeleton.
import Foundation

nonisolated struct CategoryTile: Identifiable, Equatable {
    enum Preview: Equatable {
        /// Numbers are still coming: skeleton line and thumbnails.
        case loading
        /// No items to show; a glyph says why.
        case status(Status)
        case photos([String])
        case screenshots([String])
        case videos([String])
        case initials([String])
    }

    enum Status: Equatable {
        /// Checked and nothing to clean.
        case clear
        /// Roomy isn't allowed to look.
        case locked
        case notScanned
        /// A comparison was stopped part-way.
        case paused
        case failed
    }

    let route: Route
    let name: String
    /// nil while loading.
    let detail: String?
    let preview: Preview

    var id: Route { route }
}

nonisolated extension DashboardSummary {
    /// What an empty category says instead of "0 KB".
    static let allClear = "All clear"
    /// Contacts are matched on shared numbers and emails only, so an empty result is not a promise.
    static let noLikelyDuplicates = "No likely duplicates"

    var tiles: [CategoryTile] {
        [
            similarTile,
            photoTile(
                .screenshots, "Screenshots", ready: isIndexed, totals: screenshots,
                preview: CategoryTile.Preview.screenshots
            ) {
                "\($0.count.counted("screenshot")) · \($0.sizeText)"
            },
            photoTile(
                .largeVideos, "Large videos", ready: isIndexed, totals: videos, preview: CategoryTile.Preview.videos
            ) {
                "\($0.count.counted("video")) · \($0.sizeText)"
            },
            contactTile,
        ]
    }

    /// Groups are known only once comparing finishes; a stopped comparison says so instead of "All clear",
    /// and photos that couldn't be compared are counted rather than treated as checked.
    private var similarTile: CategoryTile {
        if canUseLibrary && phase == .stopped {
            return CategoryTile(
                route: .similarPhotos, name: "Similar photos", detail: Self.comparisonNotFinished,
                preview: .status(.paused))
        }
        // Groups whose extras are all ones the person marked are still listed, so the card never says "All clear".
        if canUseLibrary && phase == .done && similar.count == 0 && similar.groups > 0 {
            let detail = "\(similar.groups.counted("group")) · nothing suggested"
            return CategoryTile(
                route: .similarPhotos, name: "Similar photos", detail: detail, preview: .photos(similar.previewIDs))
        }
        let tile = photoTile(
            .similarPhotos, "Similar photos", ready: phase == .done, totals: similar,
            preview: CategoryTile.Preview.photos
        ) {
            "\($0.groups.counted("group")) · \($0.sizeText)"
        }
        guard tile.detail == Self.allClear, similar.unchecked > 0 else { return tile }
        let detail = "None found · \(similar.unchecked.formatted()) not checked"
        return CategoryTile(route: .similarPhotos, name: tile.name, detail: detail, preview: .status(.clear))
    }

    private func photoTile(
        _ route: Route, _ name: String, ready: Bool, totals: CategoryTotals,
        preview: ([String]) -> CategoryTile.Preview, detail: (CategoryTotals) -> String
    ) -> CategoryTile {
        if !canUseLibrary {
            return CategoryTile(route: route, name: name, detail: "Needs Photos access", preview: .status(.locked))
        }
        if phase == .idle {
            return CategoryTile(route: route, name: name, detail: "Not scanned yet", preview: .status(.notScanned))
        }
        guard ready else { return CategoryTile(route: route, name: name, detail: nil, preview: .loading) }
        guard totals.count > 0 else {
            return CategoryTile(route: route, name: name, detail: Self.allClear, preview: .status(.clear))
        }
        return CategoryTile(route: route, name: name, detail: detail(totals), preview: preview(totals.previewIDs))
    }

    private var contactTile: CategoryTile {
        let name = "Duplicate contacts"
        let detail: String?
        var preview = CategoryTile.Preview.status(.locked)
        switch (contacts.access, contacts.phase) {
        case (.notDetermined, _): detail = "Tap to allow"
        case (.limited, _): detail = "Needs full access"
        case (.denied, _), (.restricted, _): detail = "Access off"
        case (.authorized, .idle), (.authorized, .scanning):
            detail = nil
            preview = .loading
        case (.authorized, .failed):
            detail = "Couldn't read contacts"
            preview = .status(.failed)
        case (.authorized, .done) where contacts.groups == 0:
            detail = Self.noLikelyDuplicates
            preview = .status(.clear)
        case (.authorized, .done):
            detail = "\(contacts.groups.counted("group")) · \(contacts.extraCards.counted("extra card"))"
            preview = .initials(contacts.initials)
        }
        return CategoryTile(route: .duplicateContacts, name: name, detail: detail, preview: preview)
    }
}
