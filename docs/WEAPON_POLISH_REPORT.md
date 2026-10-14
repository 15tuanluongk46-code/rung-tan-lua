# Weapon / animation polish — 12/10/2026

Source: `C:/Users/ADMIN/AI-Home/projects/rung-tan-lua`.

## Implemented

- Eight original body-only sheets player/melee/archer/shaman/hunter/smith/guardian/
  coal under assets/layers. Original combined sprite masters preserved. Python AST
  extracts authored actor function only, removing exact weapon/arm drawing nodes;
  terrain/audio/fonts generators are not run or overwritten.
- Six transparent 8-direction weapon sheets: spear, boss spear, hammer, staff, bow,
  stone (96px cell). Directional masters rendered at native pixel resolution, no
  rotating a low-resolution raster through arbitrary angles. Body retains 4 facing
  rows; weapon/hands use 8 octants and back/front depth.
- `weapon_rig.gd`: actual AnimationPlayer manually advanced by actor physics. Value
  tracks extension/body push/lift/bow draw/glow/sweep and call-method contact share
  clock. Delayed gameplay commit dispatched after applying tracks, once per action.
- Spear pulls back, thrusts forward and retracts. Normal 0.24s animation, contact
  0.08s; heavy 0.38s, contact 0.13s and longer extension. Cooldown/damage/range
  remain as prior gameplay. Direction locks per attack and charges cancel on dodge.
- Old player crescent trail/burst removed. Light linear tip streak is secondary;
  review captures disable effects/trails so actual weapon movement must remain clear.
- Articulated shoulders/elbows/hands follow grip. Body pushes with strike; hurt/
  dodge pose squash and idle/run weapon follow support movement.
- Throw: stone held then released at 0.06s; inventory deducted only at release so
  cancellation retains item. Ranged enemy bow/cast and melee/coal attack contact at
  0.10s, boss sweep/slam at 0.10s. Player impact occurs when extended, not on click.
- Bow string draws separately and bends with draw-back track, arrow leaves bow at
  contact. Staff crystal gathers glow and releases magic; hammer lifts then strikes;
  guardian sweeps through directional frames or nent. Projectile appearance starts
  from grip/muzzle height while gameplay continues using original foot-plane queries.
- Pause/hit-stop freeze AnimationPlayer manual clock. Death, player damage/dodge,
  ordinary enemy interrupt and boss disengage cancel pending callbacks. Save stays
  version 2; no transient animation stored. No map/content reduction.

## Verification

- Animation regression 30/30: actual rig, no early contact, one commit, extension,
  all 8 directions/depth, full recovery, pause/hit-stop, cancel no projectile,
  bow release dedupe, held/cancelled/released stone consumption.
- Existing aggregate: gameplay depth 38/38, quality 17/17, expansion 38/38,
  gameplay 71/71, integration 37/37, runtime 18/18, world/audio 3989/3989,
  autosave 7/7, visual 16/16, play 24/24, delivery zero failures, UI headless 18/18.
- Controlled graphical charge/UI 10/10: updated test waits the real 0.13s contact
  rather than demanding damage in one frame. No damage/skill buff to force pass.
- Graphical chapter I 22/22 and chapter II 25/25 task
  `faa9b421-7793-4cbc-b948-4abff7d05ea6`; no stderr. Chapter-II runner resumes
  legitimate focus auto-pauses through UI. Bot results not human playtime/fun evidence.
- Python 11 tests pass including layered asset dimensions/alpha/master preservation.
- Actual Godot PNG captures: eight directions × pull/extend/return, charged thrust,
  bow/staff/hammer pull/release and stone windup/release. `docs/screenshots/weapons/`.
- `spear-eight-directions.png` is assembled from real captured frames.
  `weapon-motion-review.mp4` is a sampled-pose review montage (~7s), beginning with
  a historical pre-polish screenshot; not an uninterrupted runtime recording.
- Final UI input release-aware checks: headless 18/18, graphical 23/23.
  Updated assertion waits 4 extra physics frames because inventory consumption now
  occurs on release, rather than weakening the inventory expectation.
- Short current-machine samples (180 frames after 60 warmup), all mode=playing:
  camp 120.03FPS/p95 10.36ms; forest 120.04/10.39ms; ash 119.99/10.89ms.
  GTX1050Ti/Windows Compatibility, not sustained/multi-machine FPS guarantees.

## Limits / delivery

Human feel/difficulty not yet measured; added anticipation changes when damage is
registered and needs user playtest. Tall scene/object and pixel depth inspected on
current machine; no claim multi-hardware acceptance. Godot live-control MCP absent,
verification uses bounded Godot CLI, in-engine input and real render readback.
No new AI-generated images used: these are exact pixel assets from original drawing
source plus new directional weapon masters. No commit/push/publish.

Latest package name: WeaponPolish-20261012; previous GameplayDepth/QualityFix
archives preserved. Windows executable embeds PCK; source+Windows ZIP and SHA256.
Export/pack task `58b6ff23-c7da-45fd-a059-a200bb68a16f` exit 0, no stderr;
executable 115,312,896 bytes. SHA256 and both ZIP CRC validated.
Standalone smoke `c8b1855f-c63f-4cd8-b090-07e873e63dbd` both captures playing,
no runtime stderr: forest 119.57FPS/p95 9.96ms; ash 120.00/10.21ms.
