# Roomy — design

Figma (Foundations · Components · Screens · Icon): https://www.figma.com/design/vkLwPMTONVGAW83m8B1oK8

- `screens-overview.png` — every v5 screen from Figma (393×852): launch, onboarding, dashboard, the four categories, Review, deleting, result, Settings.
- `app-dashboard.png`, `app-dashboard-dark.png` — the dashboard as built, light and dark, in the simulator with a
  synthetic test library.
- `AppIcon-1024.png` — unmasked master (background + halo + mascot layers) for Icon Composer / the asset catalog.
- Tokens in Figma (`Roomy/Color`, `Roomy/Space`) mirror `Roomy/Design/Tokens/` (Colors, Layout, Typography) 1:1.
- The cleanup result's hero (`StorageHero` v6 in Figma and in `Roomy/Design/Components/`): the amount with Roomy
  beside it over the same tick bar as the dashboard. `StorageBar` marks the moved space by raising the last used
  tick into a marker (Figma "Premium details — notice icon & result pin"): an amber outline while it is in Recently
  Deleted, solid green with a check once free space is measured again. It replaced the storage ring.
- Dashboard v5 ("Dashboard v5 (redesign)" in Figma), as built:
  - `AppHeader v5` → the header row in `DashboardView`: "Roomy" and the glass Settings button share one row and
    scroll away together (the navigation bar is hidden on the dashboard only).
  - `StorageHeroCard v5` → `StorageCard`: a navy-to-parchment card with the headline and Roomy perched on a white
    card holding "92% full", used and free in words, the barcode `UsageBar` (used vs free only), then what can be
    cleaned up and, while scanning, the photo count in words. It holds no action and no progress bar.
  - `Dashboard v5 — option A` → `DashboardActionBar` + `DashboardBottomAction`: one state-driven bottom capsule
    (Scan for space / Cancel scan with a progress fill / Resume scan / Scan again / Review). With items saved and a
    scan action available it splits into a round glass scan button and the Review capsule.
  - `CategoryTile v5` → `CategoryCard` + `ThumbStack`: a 2×2 grid of tiles, each with a well tinted in its
    category's colour showing real items (or a glyph saying why not), one column at accessibility text sizes.
  - `NoticeRow v5` → `NoticeRow` in `Roomy/Design/Components/`: one compact row per notice, the whole row the
    button. Its icon is an ink glyph on a neutral chip; colour appears only as a small status dot (amber for
    Recently Deleted, green for space freed).
  No tab bar: the categories feed one shared Review, so they are drill-downs.
- Dark mode is its own palette ("Dark mode v2 — premium palette" in Figma, variable mode "Dark v2"): warm
  near-black surfaces stepping up in lightness, a faint edge instead of shadows, solid deep category wells with
  brighter glyphs, a cleaner accent and a separate `sheet` tone so sheets stand clear of the dimmed page. Light
  mode is unchanged. The app icon has dark and tinted versions.
- Other Figma sections: "v5 — Category screens & Settings", "v5 — Sheets & delete flow", "v5 — Onboarding, loading
  & motion" (flow, loading-state audit, launch screen, motion spec with Reduce Motion fallbacks).
- Figma renders Inter; the app uses SF Pro. Inter matches SF Pro metrics closely.
