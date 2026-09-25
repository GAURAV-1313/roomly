# Performance

Every scan logs its timings (Console → subsystem `com.gauravsingh.roomy`, category `scan`):
`indexed N assets in …` and `scan done: G groups from P photos in …`.

## Measured (iPhone 17 Pro simulator, Debug build, M-series Mac, 25 Sep 2026)

Library: 1,012 synthetic photos with 50 planted exact copies and 50 planted near-duplicates taken 2 s apart.

| | Time | Result |
|---|---|---|
| Index 1,015 assets | 0.15 s | — |
| First scan (every photo decoded and hashed) | 2.7 s | exactly the 100 planted groups, no false ones |
| Rescan (hash cache warm) | 0.7 s | same 100 groups |
| Grouping 20,600 photos (unit test, hashes given) | 0.09 s | exactly the 300 planted groups |

### After the audit fixes (same library)

A rescan now reports 101 groups: the 100 planted ones plus one pair of different synthetic images whose hashes
are exactly 10 bits apart, the edge of the "same moment" limit. The simulator ignores the photos' own capture
dates, so all 1,012 carry the same import minute and count as one moment; the fixed sliding window (audit
SIM-3) now compares every neighbour in such a run, as it must for real bursts. With real capture times these
images are 37 minutes apart and never compared. Planted copies keep their "Exact duplicate" label (a pair's
strongest evidence wins; a regression test pins it).

## What was fixed

- Indexing took 3.0 s for 1,015 assets because the simulator-only screenshot check looked up file resources
  for every photo. It now runs only for portrait images: **0.15 s, 20× faster**. (The check isn't compiled
  for devices.)
- The hash cache kept entries for deleted photos; it now keeps only photos still in the library.

## Why it scales

- **One pass over the library** reads only cheap fields. File sizes are read for videos and screenshots,
  and for photos only once they land in a group.
- **Hashing is the only pixel work**, with four image requests in flight (Photos serialises them anyway).
  Each hash is cached by asset id and modification date, so a rescan decodes only new or edited photos.
- **Grouping is close to linear**: duplicates are found through 5 LSH bands (a crowded band is split again),
  never by comparing all pairs; near-duplicates are compared only within one moment (≤ 60 s), each photo with
  at most the next 40.
- **Nothing blocks the UI**: the scan runs off the main actor and streams progress; the dashboard fills in
  while it runs, and a newer scan cancels an older one.

## Still to measure on the iPhone 16

Real libraries add iCloud-only originals (skipped, never downloaded), HEIC decoding and Photos' own
thumbnail cache. Extrapolating the simulator numbers gives roughly 45 s for a first scan of 20,000 photos
and a few seconds to rescan. Record the real numbers from Console on the device run.

## Sizes and iCloud: check on the device

Sizes come from two undocumented `PHAssetResource` keys: `fileSize` and `locallyAvailable`. With iCloud Photos
and "Optimize iPhone Storage" on, an original can live only in iCloud while Photos still reports its full
size. The rule is in `AssetSize.measure` and is unit-tested: a file Photos marks as not on the phone is
labelled "in iCloud" and left out of Reclaimable, the Review total and the Recently Deleted check; a file whose
availability Photos doesn't report counts as on the phone. The simulator has no iCloud library, so on the
iPhone 16 with Optimize Storage on:

1. Find a large video that Photos shows downloading when you open it (an iCloud-only original).
2. In Roomy, its row should read "in iCloud", and the Large Videos and Reclaimable totals should not include it.
3. If it reads as a normal size instead, Photos no longer reports the key: record that here, because sizes
   then count iCloud originals again.

## Burst frames: check on the device

The index enumerates every burst frame (`includeAllBurstAssets`), and every fetch by id (sizes, hash tiles,
thumbnails, the deleter's before-and-after checks) uses the same options through `PHFetchOptions.matchingIndex`.
The simulator has no bursts, so on the iPhone 16:

1. Shoot a burst of about ten frames and pick two of them in Photos.
2. In Roomy, the burst should appear as one "Burst" group with a picked frame as the keeper, the other picked
   frame not selected by "Select extras", and every frame showing a size.
3. Delete two unpicked frames through Review and check in Photos that exactly those two are in Recently Deleted.
4. While Roomy scans, watch Console (subsystem = the app's bundle id, category `scan`). A line
   "sizes: N of M ids not found" right after a fresh burst means fetching by id ignores `includeAllBurstAssets`;
   until this check passes, unpicked burst frames may still show no size and fail to delete (they are reported
   as unavailable, never deleted by mistake).
