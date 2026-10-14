# ActionSync — input / weapon / combat fixes, 12/10/2026

Canonical source: `C:/Users/ADMIN/AI-Home/projects/rung-tan-lua`.
Scope approved from WEAPON_BUILD_TEST_REVIEW.md; six regions/two chapters retained.

## Changes

- One weapon action owns its animation until recovery ends. Queued throw (0.15s)
  has priority over held normal spear; rejected spear never receives cooldown.
  Queued input expires without spending items. Charge/release remains distinct,
  normal held LMB resumes after accepted action/recovery. No unbounded queue.
- Dodge cancellation precedes actor animation advancement, so a dodge requested
  before release can cancel the pending projectile without spending stone.
- Dialogue entry cancels pending weapon action and charge, clears one-shot input,
  zeros velocity/action pose and requires weapon-button release before rearming.
  Interaction is processed before contact/movement, returns immediately if modal
  opens. Esc pause preserves pending animation rather than treating it as dialogue.
- attack_spec.gd owns 8-direction snapping, contact/duration, shaft length/reach.
  Normal/heavy player hit directions lock to the shown octant (free movement/mouse
  remain). Reach remains 49/62 pixels. Body push is included when computing weapon
  extension; all eight heavy tip checks agree within pixel-rounding tolerance.
- Boss sweep runs an active angular window 0.10–0.22s, matches full warning sector
  and 74px tip radius. Signal sweeps across angular intervals, deduplicated by one
  attack ID. Fractional rotation within directional raster for boss sweep is
  deliberate: continuous damaging path and shaft stay consistent during sweep.
- Animation advance splits at contact and sweep boundaries, commits at contact pose
  before recovery. Large deltas 0.1/0.2/0.5s do not fire damage from retracted pose.
  Contact-triggered hit-stop keeps remaining time pending; resumes once after freeze.
  Cancellation generation prevents obsolete callbacks advancing a replacement action.
- Hunter/smith hands use human palette; goblin and glove palettes remain distinct.
  Existing foot-plane collision and projectile-height rendering retained.

## Tests / evidence

- New `test_action_sync.gd` 37/37: contact across 120/60/30Hz and stall steps,
  direction/62px tip checks in eight octants, simultaneous attack priority, dodge
  before release, modal no extra movement/late hit, held-button release gate,
  queue expiration/no cooldown, hit-stop carry, human hands, sweep path/radius/dedupe.
- Existing suite aggregate passed: weapon 30/30, depth 38/38, quality 17/17,
  expansion 38/38, gameplay 71/71, integration 37/37, runtime 18/18,
  world/audio 3989/3989, autosave 7/7, visual 16/16, play 24/24,
  delivery zero failures, UI headless 18/18.
- Graphical chapter I 22/22 and chapter II 25/25, task
  `86f3ee6e-b785-4a2a-b350-a3f420d63eb1`; no runtime stderr. Chapter-II fixture
  unlock remains explicit; bot journey not human time/difficulty acceptance.
- Controlled graphical charge/UI 10/10. Capture is 192 sequential Godot rendered
  frames with 1/60 fixed animation advance, not a montage of repeated still poses.
  `docs/screenshots/action-sync/spear-continuous-eight-directions.mp4` is a continuous
  scripted action preview, not an OS recording of manual gameplay.
- Actual PNGs show contact-east and hunter/smith palettes; vision reviewed in-session.
- Human feel of octant locking still requires playtest; do not claim all diagonal
  pixel silhouettes equivalent to hand-drawn eight-direction body sheets.
- Final aggregate `20a9b6cd-6be6-4cd6-8dd4-23ad19587553`: all above pass,
  UI graphical 23/23, production autosave restart 1/1, Python 11 tests passed.
  No Godot runtime stderr errors. Sequential capture/ability task
  `5695da17-6d77-4ecb-ab25-d98fe793aad7`: action 37/37, graphical ability 10/10.

## Delivery / persistence

Save version 2 and existing migration unchanged; no transient action queue/timeline
stored. Existing archive names preserved. New Windows/source archives ActionSync-
20261012 and matching SHA256; latest executable at build/windows/RungTanLua.exe.
No commit/push/publish. No unrelated process cleanup performed.

Export task `4b4b7a4b-3bb5-4de1-be2d-779a14ef05b1`: exit 0, stderr empty,
executable 115,319,736 bytes/PCK embedded; Windows/source ZIP SHA256/CRC pass.
Standalone smoke `080bee6e-e681-454b-b49d-b0431f59cdee` exit 0, both playing,
no runtime stderr: forest 119.80FPS/p95 10.46ms, ash 120.00/10.39ms. Short
180-frame current-machine measurements after warmup, not sustained/multi-device FPS.
