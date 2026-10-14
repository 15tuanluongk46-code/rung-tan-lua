# Quality fix — 12/10/2026

Canonical project: `C:/Users/ADMIN/AI-Home/projects/rung-tan-lua`.

## Fixed

- Combat sectors share `combat_geometry.gd`: warning angle/radius matches actual
  melee/bear/boss sweep damage, with translucent sector and outline.
- Version-1 saves remain supported. Validation rejects killed player/nonhostile IDs,
  unknown pickups/lore/landmarks, inconsistent ending/stage/construction states.
  Player creation cannot be skipped by the killed ledger.
- Autosave keeps dirty state after failure; retries at 2,4,8,16,30-second intervals,
  rate-limits notification, displays saving/saved/retry status. Existing backup slot
  and temporary-file verification preserved; no user save deletion/migration.
- Bridge replay restores both incomplete texture and offset. Southern event props
  y-sort from foot positions. Tower sides extend to world boundary, meeting gate;
  complete arena access unlocks at stage 5.
- Mud affects input velocity before physics movement (75% speed, dodge unaffected).
- Bridge/bell reject reward while capacity insufficient, preserving materials and
  one-time claim; notifications explain required space instead of discarding loot.
- Boss releases combat music on same-region disengage; cancels leftover hazards,
  redraws on death. Trail direction, throw-to-spear tint and outline modulation fixed.
- Correct region-indexed ember HUD pulse; localized rereadable lore and event names.
- Real hit-stop freezes actor/projectile updates while its release clock/UI continue.
  Reduced-motion mode disables hit-stop/camera shake; reduced-flash uses steady cues.
- UI fade transitions keep focus/input responsive. Hidden HUD preserves notifications
  and stops interaction queries; playing queries bounded to 12.5 Hz. Empty FX do not
  redraw, marker updates culled/throttled. Tall tower fades when covering player.
- Text-large (+2 px body/HUD), PageUp/PageDown reader navigation and focusable readers,
  separate accessibility screen, reduced flash/motion, VSync and 60/120 FPS settings.
- Volume applies only the changed bus; settings writes debounced 0.5 sec. Main
  settings still has four sliders, and new display options live in a separate panel.

## Regression methodology

Before fixes, quality regression reproduced 9 failing cases. Tests now additionally
cover damaging sector boundaries, effective mud velocity, arena sides, real hit-stop
release, fake ending/killed-player/unknown-lore rejection, complete capacity reward,
bridge texture reset, directional trails and hidden-toast lifetime.
Autosave pipeline explicitly re-enables production autosave at a unique test slot:
temporary write failure → dirty retained → bounded retry → save → event persists →
new scene Continue. User journey slot is never used by tests/capture.
Original synchronous runtime/phase tests now advance real hit-stop release instead
of expecting a physics update during the intentional freeze.

## Evidence so far

- Headless quality regression 17/17; autosave pipeline 7/7; expansion 38/38.
- Original suites: runtime 18/18, world/audio 3928/3928, visual 16/16,
  gameplay 71/71, integration 37/37, play regression 24/24, delivery 0 failures,
  UI input headless 18/18.
- Graphical chapter I 22/22; chapter II 25/25. Chapter II starts from a declared
  unlocked-chapter fixture; subsequent progress/combat uses input/UI. Bot now uses
  boss-specific warning distance, dodge timing and recovery attacks, not weaker boss.
- Graphical accessibility 11/11 (large layout, paging, lore, music disengage, captures).
- Graphical UI input 23/23; save restart WRITE/READ passed; Python 9 tests passed.
- Captures in `docs/screenshots/quality/`; current session uses CLI rendering, no
  Godot live MCP exposed. Real PNGs inspected, including localized lore and large UI.

Short current-machine samples (180 frames after 60 warmup), all mode=playing:
camp 120.01 FPS / p95 9.79 ms; forest 119.67 / 9.78 ms;
marsh 120.07 / 11.29 ms; ash 120.03 / 9.88 ms. Not sustained FPS guarantees.

Final production-autosave cross-process check: 7/7 pipeline + 1/1 independent
process read, task `f3d3e3c1-4d1c-4932-bbce-95e5d6726227`; import/export exit 0,
stderr empty. Standalone Windows smoke `f38a06ac-6b9f-4584-8e94-02ac140afd60`
rendered ash mode=playing, 119.97 FPS / p95 10.09 ms; no runtime error.
An earlier standalone sample auto-paused on focus loss and is not treated as
gameplay performance evidence. SHA256 + both ZIP CRC checks passed.

## Boundaries

- No measured human duration/difficulty acceptance or multi-hardware long stress run.
- Visual fade transition is modest and reduced-motion aware; not a cinematic scene.
- Large text is a compact large-text layout at 640×360, not a separate high-resolution
  UI viewport. Strict integer-scaling/renderer architecture remains future design work.
- Save version unchanged; validator accepts legitimate prior gameplay snapshots.
- No commit/push/publish. Previous ChapterII-20261011 ZIPs remain untouched; new
  Windows/source packages are named QualityFix-20261012 and have SHA256 verification.
