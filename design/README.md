# Roomy — design

Figma (Foundations · Components · Screens · Icon): https://www.figma.com/design/vkLwPMTONVGAW83m8B1oK8

- `screens-overview.png` — the Figma screens (iPhone 15, 393×852), iOS 26 Liquid Glass in the navigation layer only.
- `app-dashboard.png` — the dashboard as built, in the simulator with a synthetic test library.
- `AppIcon-1024.png` — unmasked master (background + halo + mascot layers) for Icon Composer / the asset catalog.
- Tokens in Figma (`Roomy/Color`, `Roomy/Space`) mirror `Roomy/Design/Tokens/` (Colors, Layout, Typography) 1:1.
- The storage ring and Roomy the robin are one component (`StorageHero` in Figma and in `Roomy/Design/Components/`):
  216 pt ring, 14 pt stroke, 64 pt robin, on the cleanup result.
- Dashboard v5 ("Dashboard v5 (redesign)" in Figma), as built:
  - `AppHeader v5` → the header row in `DashboardView`: "Roomy" and the glass Settings button share one row and
    scroll away together (the navigation bar is hidden on the dashboard only).
  - `StorageHeroCard v5` → `StorageCard`: a navy-to-parchment card with the headline and Roomy perched on a white
    card holding "92% full", used and free in words, the barcode `UsageBar` (used vs free only), then what can be
    cleaned up beside the one action that fits the scan (Cancel / Rescan / Resume) and the scan's progress.
  - `CategoryTile v5` → `CategoryCard` + `ThumbStack`: a 2×2 grid of tiles, each with a well tinted in its
    category's colour showing real items (or a glyph saying why not), one column at accessibility text sizes.
  - `NoticeRow v5` → `NoticeRow` in `Roomy/Design/Components/`: one compact white row per notice, the whole row
    the button; amber only in the Recently Deleted icon.
  No tab bar: the categories feed one shared Review, so they are drill-downs.
- Figma renders Inter; the app uses SF Pro. Inter matches SF Pro metrics closely.
