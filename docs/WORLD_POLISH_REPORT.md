# WorldPolish — 13/10/2026

Approved follow-up to DetailPolish: user rejected the left sleeve covering the red
cloak and requested review/polish of roads and small assets.

## Changes

- Player shoulder drape extracted into aligned idle/8-direction pose sheets and
  drawn above arms. Cape material remains one contiguous red silhouette; the hand
  emerging beyond the cloth still follows the weapon grip. Pullback elbow constrained
  near ribs. No damage/range/contact/input modifications.
- `assets/world_routes.json` is the canonical road/creek source for runtime
  clearance and developer terrain painter. Six crops come from a single 2400² canvas;
  unioned path masks eliminate triangular gaps at bends and intersection seams.
  Northern connections into Chapter II are painted as well as reserved for walking.
- Distinct marsh/ash dirt, stone chips, shoulder grass and route wear. Creek banks
  and pond rims are continuous. Courts have varied/chipped stones and cracks.
  Biome boundary bands use a palette ramp rather than an abrupt straight color cut.
- Chapter-II bridge gains wet banks and an approach connector; bridge deck is
  ground-layered below actors in both broken/repaired states.
- Materials added inside existing silhouettes for hut, tower, well, valve, bell,
  burnt tree, reed, bridge, broken bridge, sign and herb. Four vegetation variants.
  Random base foliage uses 1:1 scaling; landmark-specific scales remain.
- Three additional route signs with near-only Vietnamese direction captions.

## Verification and visual evidence

Engine 4.7.2 Compatibility, GTX 1050 Ti. Test aim stays virtual: no desktop mouse
warp. No player save writes. Original chapter content/actors, save v2 retained.

| Suite | Result |
|---|---|
| Detail / ActionSync / weapons | 39/39 · 37/37 · 30/30 |
| Depth / quality / expansion | 38/38 · 17/17 · 38/38 |
| Gameplay / integration / runtime | 71/71 · 37/37 · 18/18 |
| Delivery regressions | 0 failures |
| World/audio (route clearance + assets) | 4083/4083 |
| Autosave / visual contract / play | 7/7 · 16/16 · 24/24 |
| Headless UI / accessibility | 18/18 · 6/6 |
| Python, including painted route and cloak tests | 13 tests OK |
| Virtual aim Chapter I / II journeys | 21/21 · 24/24 |

Receipts: `620e8fdc-90c7-480c-a7d1-1b9ed6b7b0c5` for Godot regressions;
`4d546bc6-5191-46ec-b5c4-329df39ed615` for Python/journeys/192 sequential frames.
First screenshot fixture used append on events Dictionary and stranded its window;
user approved stopping only exact verified Godot PID 22776. Fixed fixture now has
a bounded watchdog, and subsequent capture succeeded. Earlier color-threshold tests
were refined to recognize green-grey paving/wet bridge banks, not mislabeled as holes.

`docs/screenshots/world-polish/` includes 16 actual runtime route/structure frames,
eight 3× pixel pose sheets, terrain overview/junction crops, HUDs and a 192-frame
60fps spear clip. Inspected cloak pull/contact/recovery, diagonal and throw poses;
road turns, bridges, north/south connections, marsh/ash seam, well, hut and courts.
Images show intact red drape, continuous road joins and differentiated material.

Tests verify clearance/connectivity/contact, not beauty, full animation smoothness
or difficulty. Fixture shots deliberately place actors near structures; translucent
tower layering remains stylized. Journeys are fixed-fps bots, not human playtime or
boss-difficulty acceptance. Current native render QA does not measure Android/Web.

## Delivery

`build/RungTanLua-Windows-WorldPolish-20261013.zip` and corresponding Source ZIP;
`build/windows/RungTanLua.exe`. SHA256 receipt at
`build/SHA256SUMS-WorldPolish-20261013.txt`. Old versioned ZIPs retained.
No Git commit/push/publication. Final EXE smoke uses `--no-save --quit-after 90`.
Final render review refined biome palette bands with local grit to preserve the
pixel-ground material. Native capture jobs exit and all game edit claims release.
