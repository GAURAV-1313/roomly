// Why: the index lists every burst frame, but Photos' default fetch shows only a burst's representative and
// picked frames. Fetching by id with the default could leave every other frame unhashed, unsized and
// undeletable, so every fetch by id uses the same view of the library as the index.
import Photos

nonisolated extension PHFetchOptions {
    /// Options for fetching assets by id that match what the index enumerates.
    static func matchingIndex() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.includeHiddenAssets = false
        return options
    }
}
