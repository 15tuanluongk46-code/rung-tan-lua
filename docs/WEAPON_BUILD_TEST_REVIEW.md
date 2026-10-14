# WeaponPolish fresh test review — 12/10/2026

Scope: run current tests, graphical input/journeys, diagnostic edge cases and the
existing Windows executable. No production source changes or fixes in this pass.
Added `tests/test_release_review.gd` only; diagnostic fixture prints observations,
not a regression PASS claim. Save/settings use isolated existing test workflows.

## Fresh results

Task `2619adcf-92f4-476f-956a-32fc74f12831`: weapon 30/30, depth 38/38,
quality 17/17, expansion 38/38, gameplay 71/71, integration 37/37, runtime 18/18,
world/audio 3989/3989, autosave 7/7 + independent restart 1/1, visual 16/16,
play 24/24, delivery zero failures, UI input 18/18, Python 11 tests pass.

Task `b4d88918-9107-49f0-b9ef-01cf3f140311`: graphical ability/UI 10/10,
chapter-I journey 22/22 (0 deaths), chapter-II 25/25. No runtime/shader stderr.
Chapter-II starts from unlocked fixture, not a human continuous two-chapter test.

Task `09b43800-fd9d-4221-bb64-ee2af3a7046d`: graphical accessibility 11/11,
standalone forest/ash mode=playing, stderr empty, current executable and archives
match published SHA256. Samples: forest 119.99FPS/p95 9.92ms; ash
120.03FPS/p95 10.17ms. Short GTX1050Ti samples, not sustained FPS guarantee.

## Confirmed issues

### P2 Visual aim differs from damage aim
`weapon_rig.gd:105–124` quantizes to eight octants while `main.gd:spear_attack`
uses exact facing. Diagnostic 22.5-degree aim produced 21.927-degree difference.
Boss sweep at contact displays weapon at 45 degrees while damage axis is 0 degrees.
This does not imply the whole sector hit test is wrong; displayed shaft cannot be
treated as the exact attack axis. Fix by sharing visual/damage direction design,
or improve directional art/continuous rig while retaining pixel look.

### P2 Simultaneous spear/throw silently replaces spear
`player_actor.gd:58–75`, `weapon_rig.gd:start`: both start in one physics tick;
throw cancels pending thrust while spear cooldown is still set. Reproduced current
animation=throw, spear cooldown 0.44, throw cooldown 0.55, one stone/projectile.
Fix explicit priority or short action queue, with exactly one committed action.

### P2 Attack remains pending through NPC dialogue
`player_actor.gd:82–90` continues current physics movement after interaction opens
dialogue. Diagnostic at An: mode dialogue, rig_active true and moved 1.06668px in
same tick. Manual clock pauses during dialogue but pending attack can resume after
closing it. Fix defined interaction policy (cancel attack / disallow interaction
until safe) and return immediately after modal mode change.

### P3 Large physics delta contact fires after peak pose
`weapon_rig.gd:76–85`: advance(0.2) crosses contact and retracts before callback.
Observed one callback with extension 5.037, versus intended 17 at 0.08 contact.
Normal 60Hz operation passes; this is a low-FPS/stall edge. Split at event boundary
or evaluate/commit at contact pose before advancing remainder.

### P3 Heavy visual reach exceeds damage reach
Normal heavy contact visual estimate: 30 extension + 32 shaft-tip + ~4.9 body push
=66.9px while heavy damage reach is 62px. This is roughly 5px visual discrepancy,
not evidence all heavy attacks fail. Align tip reach/body origin with hit geometry.

### P3 Human NPC hands use goblin tint
`weapon_rig.gd:133`: only player gets human skin; hunter/smith use green default.
This is code-supported visual defect; diagnostic confirms human bow NPC uses rig.
Choose skin palette by actor kind / source definition.

## Additional polish observations

- Eight-direction weapon paired with four-direction body reads better than arc-only
  animation, but diagonal grips/arm silhouettes and back-facing hands still deserve
  human art review. Small pixels cannot be judged by test assertions alone.
- Review clip remains sampled pose montage, not an uninterrupted animation recording.
- Tests cover primary valid routes, not all combinations of attack/throw/interact;
  edge-case diagnostic demonstrates missing coverage despite aggregate PASS.
- No blocker/crash/quest/save loss observed in the tested routes. Human feel/long-run
  stress and other hardware remain untested.

Recommended order: action priority and modal cancel → shared aim/reach →
stall-safe contact event → NPC hand palette and diagonal grip polish.
