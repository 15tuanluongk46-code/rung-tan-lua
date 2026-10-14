# DetailPolish — 13/10/2026

User-approved small-detail pass; same pixel-art direction, chapters, actors and save v2.

## Implementation

- New sibling arm layers: far sleeve/forearm behind the body, near sleeve/forearm
  in front; both hands over the shaft except upward poses, where body occludes them.
  Shoulders now attach at the upper torso rather than the belt. Colored sleeves,
  outlined elbows and compact grip hands replace the two parallel skin lines.
- Eight directional body silhouettes × anticipation/contact/recovery for each of
  the eight weapon-bearing designs. Original identity pixels and walk sheets remain.
  Torso/head shifts and planted feet supplement the physical weapon animation.
- Vertical spear grip shifted beside the head. No combat timing/damage/range change;
  ActionSync tests still validate normal/heavy reach and boss swept contact.
- Bow: extended support hand and separate draw hand/string anchor. Staff: upright
  idle carry and separate free casting hand. Hammer: low diagonal carry, lifted
  anticipation and angular swing/recovery; shaded metal faces and handle wraps.
- Throw: dominant hand follows held stone/release; free hand balances; mirrored hand
  selection for left/right aim. Released stone disappears at the existing contact.
- Discrete two-tone pixel foot shadow; scale resets after dodge/death.
- E prompt measures actual font/text width and ranks placements against actor/head
  caption overlap and toast. Region banner yields to combat/actors. Toast ranks four
  positions against actors and rest-fire focal areas. Removed duplicate item/rest
  captions and permanent charge-help line. New session clears stale toast, while
  pause/dialogue preserve pending notifications.

## Verification

Engine 4.7.2, Compatibility, GTX 1050 Ti. No Godot MCP exposed in this session;
checks use the installed engine through owned ops tasks. No Windows mouse warp.

| Suite | Result |
|---|---|
| Detail polish | 39/39 final, including gameplay item/rest caption persistence |
| ActionSync | 37/37 |
| Weapon animation | 30/30 |
| Gameplay depth | 38/38 |
| Quality regressions | 17/17 |
| Expansion | 38/38 |
| Gameplay / integration / runtime | 71/71 · 37/37 · 18/18 |
| Delivery regressions | 0 failures |
| World/audio | 3989/3989 |
| Autosave / visual contract / play regressions | 7/7 · 16/16 · 24/24 |
| UI Input | headless 18/18; graphical 23/23 |
| Accessibility | headless 6/6; graphical 11/11 |
| Python | 11 tests OK |
| Chapter I virtual-aim journey | 21/21, no deaths |
| Chapter II virtual-aim journey | 24/24, one death, normal UI recovery |

Key task receipts: `01ad9997-d491-4ee3-9f7a-60ab3ed30091` (regressions,
Python and final detail captures), `5f661660-fb9e-42c5-8049-725cf750356e`
(journeys, graphical UI/accessibility, 192 sequential render frames).
Earlier test failures were fixed before final verification: diagonal reach drift
from lateral offsets, and notification loss when entering pause. A QA-only Python
stdout encoding failure was addressed with `-X utf8`.

## Visual evidence and judgment

`docs/screenshots/detail-polish/`: 132 rendered stills (eight-direction spear/throw,
four-direction bow/staff/hammer/NPC poses and HUD), eight nearest-neighbor 3× crop
sheets, four regional renders and a 192-frame/60fps spear clip.

Observed: horizontal spear now has sleeve/elbow/grip; vertical shaft is beside the
head; rear hands no longer paint over the face. Hammer has different silhouette
between lift/contact/recovery; staff idle and casting differ; bow support/pull hands
are separated. HUD ordinary/large-text captures keep rest fire and player clear.
Diagonals have a planted-foot/torso change, while retaining the authored four-facing
head identity. Perspective remains stylized: down-facing thrust projects along the
screen ground plane; this is not a realistic foreshortened 3D animation.

Frame/crop inspection is visual evidence, not a human smoothness/difficulty sign-off.
Fixed-fps headless journeys do not resolve the earlier real-time boss-strategy
finding or prove play duration/fun. Nearest-target E behavior is unchanged.

## Delivery

Windows/source package stamp: `DetailPolish-20261013`; SHA256 receipt under `build/`.
Source shortcut launches the current official project. Old versioned ZIPs retained.
No commits, uploads or publication were requested. Player save is not used by tests.

Final regional visual review caught the gameplay proximity loop restoring labels;
the loop now respects landmark-only metadata. This is covered by the final detail
regression. Exported EXE is smoke-launched with `--no-save --quit-after 90`.
Save restart write/read passed in two independent processes with an isolated fixture.
Final export/smoke/evidence receipt: `9e437127-8c60-4b86-bd0e-635d7816c6b6`,
exit 0, empty stderr. Four 180-frame samples near the 120 FPS cap (1.5s each),
p95 10.44–11.31ms on this machine; not a sustained performance guarantee.
