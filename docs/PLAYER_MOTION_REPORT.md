# PlayerMotion — 13/10/2026

Approved redesign after user rejected PlayerHands: ALL Player motion must be derived
from `assets/sprites/player.png`, not reference rest followed by a different arm rig.

## Implementation

- Composite Player pose sheets contain body, cloak, compact pixel arms/hands, spear
  and held stone together. Authored preparation/contact/recovery/tuck keys, baked at
  120Hz plus exact contact timestamps; seven actions × eight directions. Body/head
  originate from the approved original actor source, not a new character design.
- Thrust/heavy moves carried upright spear into aim, retracts, plants foot/body,
  extends at contact, retracts and uprights. Normal .08/.24s and heavy .13/.38s contact/
  duration retained; physical tip at contact uses 32px blade reach and 49/62 total.
- Throw keeps upright spear in the support hand while the other takes/releases
  stone; exact .06s release, no visual spear disappearance. Charge lowers stance,
  dodge crouches with carried spear, hurt recoils, death settles sideways.
- Player runtime procedural arm/weapon/cloak overlays are suppressed. Existing
  manual AnimationPlayer rig remains a nonvisual contact clock and geometry probe;
  current composite frame is applied BEFORE contact callback, including large delta.
- Original idle/walk frames and small hands stay; action endpoints match original
  pixels exactly. Octant-to-original-facing mapping is shared for consistent recovery.
  NPC/enemy rig remains unchanged. No gameplay damage/range/cooldown changes.

## Evidence

`docs/screenshots/player-motion/player-motion-60fps.mp4`: 896 native render frames,
14.93s at 60fps. Eight idle/walk/spear cycles followed by cardinal heavy, throw,
charge, dodge, hurt, death. Labeled nearest-neighbor phase crops and horizontal
design strip included. Inspect horizontal continuity, cardinals/diagonals, throw,
dodge/hurt/dead; no trails needed to read the spear.

Observed: compact hands and intact cloak throughout; spear no longer jumps directly
from carried vertical sprite into an unrelated arm style. Transfer/inversion for
downward attack remains highly stylized within the unchanged 80ms anticipation;
no realistic 3D foreshortening or human smoothness acceptance is claimed.

## Verification

Receipt `e983539c-9b65-45c3-9251-56f5a01c4e74`: PlayerMotion 121/121, ActionSync
37/37, weapon 30/30, Detail39/39, gameplay71/71, integration37/37, runtime18/18,
quality17/17, depth38/38, expansion38/38, world/audio4083/4083, autosave7/7,
play24/24, visual16/16, UI18/18; delivery0 failures. Python15 tests OK, including
exact approved endpoints and all pose-cell bounds; native sequence captured.
One generator ordering error was fixed before successful regeneration; no stranded
game process or mouse warp. Tests/captures isolate player save.

Final targeted tests/journeys and Windows export receipts are in task logs; Windows
EXE smoke `--no-save --quit-after 90`. Package stamp PlayerMotion-20261013, SHA256
receipt in build. Previous ZIPs retained. No publication/commit.
