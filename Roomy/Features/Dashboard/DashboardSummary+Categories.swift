// Why: each category tile says what it holds in one short line and shows a few of the actual items, so people
// recognise their own photos before they tap and two tiles fit a row without wrapping. The short line is a number
// and a size, or a word or two saying why there are no numbers — no access, not scanned yet — with a glyph that
// matches, instead of an endless skeleton. VoiceOver hears the same facts as a full sentence, so nothing the short
// line leaves out ("at least", what is in iCloud, "photos not checked") is lost.
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
    /// One short line; nil while loading.
    let detail: String?
    let preview: Preview
    /// The detail as VoiceOver says it, in full words; nil when the short line already says everything.
    var spokenDetail: String? = nil

    var id: Route { route }
    /// What VoiceOver reads after the name.
    var accessibilityDetail: String? { spokenDetail ?? detail }
}

nonisolated extension DashboardSummary {
    /// What an empty photo category says instead of "0 KB".
    static let allClear = "All clear"
    /// Contacts are matched on shared numbers and emails only, so an empty result is not a promise.
    static let noLikelyDuplicates = "No likely duplicates"

    var tiles: [CategoryTile] {
        [
            similarTile,
            photoTile(
                .screenshots, "Screenshots", ready: isIndexed, totals: screenshots,
                shown: (screenshots.count, "screenshot"), preview: CategoryTile.Preview.screenshots),
            photoTile(
                .largeVideos, "Large videos", ready: isIndexed, totals: videos, shown: (videos.count, "video"),
                preview: CategoryTile.Preview.videos),
            contactTile,
        ]
    }

    /// Groups are known only once comparing finishes; a stopped comparison says so instead of "All clear",
    /// and photos that couldn't be compared are counted rather than treated as checked.
    private var similarTile: CategoryTile {
        let name = "Similar photos"
        if canUseLibrary && phase == .stopped {
            return CategoryTile(
                route: .similarPhotos, name: name, detail: "Paused", preview: .status(.paused),
                spokenDetail: Self.comparisonNotFinished)
        }
        // Groups whose extras are all ones the person marked are still listed, so the card never says "All clear".
        if canUseLibrary && phase == .done && similar.count == 0 && similar.groups > 0 {
            return CategoryTile(
                route: .similarPhotos, name: name, detail: "All kept", preview: .photos(similar.previewIDs),
                spokenDetail: "\(similar.groups.counted("group")), nothing suggested")
        }
        let tile = photoTile(
            .similarPhotos, name, ready: phase == .done, totals: similar, shown: (similar.groups, "group"),
            preview: CategoryTile.Preview.photos)
        guard tile.detail == Self.allClear, similar.unchecked > 0 else { return tile }
        return CategoryTile(
            route: .similarPhotos, name: name, detail: "\(similar.unchecked.formatted()) not checked",
            preview: .status(.clear), spokenDetail: "None found, \(similar.unchecked.counted("photo")) not checked")
    }

    /// `shown` is the number on the tile and the noun VoiceOver says with it.
    private func photoTile(
        _ route: Route, _ name: String, ready: Bool, totals: CategoryTotals, shown: (count: Int, noun: String),
        preview: ([String]) -> CategoryTile.Preview
    ) -> CategoryTile {
        if !canUseLibrary {
            return CategoryTile(
                route: route, name: name, detail: "Allow access", preview: .status(.locked),
                spokenDetail: "Needs Photos access")
        }
        if phase == .idle {
            return CategoryTile(
                route: route, name: name, detail: "Not scanned", preview: .status(.notScanned),
                spokenDetail: "Not scanned yet")
        }
        guard ready else { return CategoryTile(route: route, name: name, detail: nil, preview: .loading) }
        guard totals.count > 0 else {
            return CategoryTile(route: route, name: name, detail: Self.allClear, preview: .status(.clear))
        }
        return CategoryTile(
            route: route, name: name, detail: "\(shown.count.formatted()) · \(totals.shortSizeText)",
            preview: preview(totals.previewIDs),
            spokenDetail: "\(shown.count.counted(shown.noun)), \(totals.spokenSizeText)")
    }

    private var contactTile: CategoryTile {
        let (detail, spoken, preview) = contactState
        return CategoryTile(
            route: .duplicateContacts, name: "Duplicate contacts", detail: detail, preview: preview,
            spokenDetail: spoken)
    }

    /// The short line, its spoken form and the well, by access and scan.
    private var contactState: (String?, String?, CategoryTile.Preview) {
        switch (contacts.access, contacts.phase) {
        case (.notDetermined, _): ("Allow access", "Needs Contacts access", .status(.locked))
        case (.limited, _): ("Allow full access", "Needs full Contacts access", .status(.locked))
        case (.denied, _), (.restricted, _): ("Access off", "Contacts access is off", .status(.locked))
        case (.authorized, .idle), (.authorized, .scanning): (nil, nil, .loading)
        case (.authorized, .failed): ("Couldn't read", "Couldn't read contacts", .status(.failed))
        case (.authorized, .done) where contacts.groups == 0:
            ("None found", Self.noLikelyDuplicates, .status(.clear))
        case (.authorized, .done):
            (
                contacts.extraCards.counted("extra card"),
                "\(contacts.groups.counted("group")), \(contacts.extraCards.counted("extra card"))",
                .initials(contacts.initials)
            )
        }
    }
}
