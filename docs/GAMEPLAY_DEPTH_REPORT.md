# Gameplay Depth — 12/10/2026

Project: `C:/Users/ADMIN/AI-Home/projects/rung-tan-lua`. Six existing regions retained.

## Implemented mechanics

- First ember, in any order, unlocks charged thrust: Shift + LMB held 0.55s,
  release for 45 base damage/62 reach versus normal 25/49; slower charging movement,
  0.8s recovery cooldown, dodge/hurt cancellation. Normal held LMB stays unchanged.
- Well unlocks perfect dodge: a real incoming sourced attack inside first 0.12s of
  dodge grants a 1.2s counter window, +10 damage once. No reward for empty dodge,
  already-hit/deduplicated attacks, ground fire or persistent trails. Attack history
  bounded; all charge/counter windows transient and reset on respawn/replay.
- Tùng/point-rest UI offers switchable spear (+8 perfect counter), stone (0.35s
  stagger ordinary enemies), survival (50HP potion). Choose at stage>=4, safe rest
  or Tùng and outside combat; no unconditional all-stat buff.
- Stalker circles, shows footprints, locks windup and timed 0.38s rush at 190 speed,
  then 0.85s recovery. Active lamps reveal its silhouette and extend warning time.
- Coal enemy nent leaves max two 21px hazards with 0.6s warmup, 2.2s lifetime.
  Charged thrust interrupts ordinary enemies; boss only extends recovery, never
  erases windup. Ranged enemies actually retreat before selecting point-blank windup.
- Six authored encounter zones/hints plus six safe rock covers and reed placement
  for forest cover, bear luring, creek mage, marsh light, ash valve, optional branch.
  Use existing actors/factions; no forced waves or extra world-size expansion.
- Lit marsh lantern exposes optional cache trail and potion. Cache spawns only after
  light unlock and respects pickup ledger. Village fire warms with ember progress;
  An acknowledges progress. No draining fuel meter.
- Construction completion is independent of consumable capacity. Full pouch stores
  bridge/bell rewards pending; later UI/NPC/rest claim delivers once, saved to disk.
- M map offers return to known activated checkpoints outside combat, no automatic
  heal/granted inventory. New-run known list starts with camp only.
- Boss phase II has bounded two-attack combos, each new 0.9s warning, then extended
  1.35s recovery, allowing learned charge/counter timing. Phase I remains a tutorial
  cycle. Three effects/telegraphs retained.
- One-shot actions buffered 0.15s across hit-stop so E/heal/throw/dodge are not lost.

## Persistence

Save envelope version 2 with explicit version-1 migration. Unlocks inferred from
embers/well; prior completed construction rewards marked received (no duplication),
known checkpoints inferred conservatively. Source primary is read-only during load;
first successful v2 write rotates actual v1 to backup. New saves validate skills,
specialization stage, received reward ownership, checkpoint IDs, encounter IDs.
Existing dirty/retry/temporary-file validation stays in production pipeline.

## Verification

- Gameplay-depth state/behavior regression: final 38/38 including version-1 backup,
  no reissued legacy reward, hazard bounds, rush, combo and combat-travel assertions.
  Controlled graphical ability test 10/10: InputMap
  charge/release damage, UI specialization, pause layout, five real screenshots.
- Full baseline suites passed: quality 17/17, expansion 38/38, gameplay 71/71,
  integration 37/37, runtime 18/18, autosave 7/7, visual 16/16, play 24/24,
  delivery 0 failures, UI headless 18/18. World/audio with authored cover 3989/3989.
- Graphical chapter I 22/22 and chapter II 25/25 task
  `2598ec16-d72b-4439-96d4-99d7ad9f1138`: unmodified quest progression, input/UI
  combat. Chapter II starts from declared unlock fixture. Journey uses normal spear,
  stones and dodge, not charge or specialization—new skills are not mandatory in
  that bot run. No claim this proves human difficulty or enjoyment.
- Input buffering fixed a real E-lost-during-hitstop scenario. Bot navigation now
  approaches reachable grid cell around cover and stops pursuing a defeated target;
  no production collider edits or invulnerability used to force journey success.
- Short 180-frame samples after 60 warmup: forest 120.01FPS/p95 9.86ms,
  marsh 120.01/10.30ms, ash 119.97/10.13ms; Windows/GTX1050Ti, mode playing.
- Graphics readback in `docs/screenshots/depth/`; reviewed charge ready, lối chiến
  đấu, light-revealed stalker and boss. Screenshots use controlled fixtures and
  are not represented as an uninterrupted player run.
- Final aggregate `3d6ad64b-7142-46e0-b0b8-c72f8d9cea7d`: all Godot suites
  passed, production autosave restart 1/1, Python 9/9; no Godot stderr errors.

## Human playtest handoff — required for engagement acceptance

No humans have been recruited or tested in this build session. See PLAYTEST_GUIDE.md.
The playable build and observation sheet are ready for 5–8 testers. Balance numbers
are starting values, not validated fun/retention metrics. Obtain real feedback before
adding more areas or asserting the game is engaging.

## Deliverables

Windows/source `GameplayDepth-20261012.zip`, SHA256SUMS-GameplayDepth-20261012.txt.
Export task `2937d2b2-5fc8-43d3-af62-6f6ef5b63f8c` exit 0, no stderr;
Windows executable 115,266,160 bytes with embedded PCK. Both ZIP CRC and hashes
verified. Standalone smoke `f769939f-4ce3-484c-8821-1f6d9b934579` exit 0,
both mode=playing: marsh 120.01FPS/p95 10.29ms, ash 119.98/10.14ms;
no runtime stderr. This is independent executable rendering, not editor launch.
No commit/push/publish. Previous QualityFix/ChapterII archives preserved.
