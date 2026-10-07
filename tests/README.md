# Gameplay checks

Run from the project directory with Godot 4.7.2:

```sh
GODOT="$(command -v godot)" # or your absolute Godot 4.7.2 binary path
"$GODOT" --headless --path . --editor --import --quit
"$GODOT" --headless --path . --script res://tests/test_gameplay.gd
"$GODOT" --headless --path . --script res://tests/test_integration.gd
"$GODOT" --headless --path . --script res://tests/test_runtime.gd
```

The first suite is deterministic state/combat/census validation. The second
instantiates the real scene, drives interactions through the public gameplay API,
and completes the main quest. The third exercises real physics projectile
blocking, AI target stability, noise, dodge input, pause/death and UI bounds.
They are **not** evidence of a human playthrough or a 15–20 minute first run.
State/runtime tests do not write settings or save run progress. `test_ui_input.gd`
does temporarily change volume settings via real sliders and restores them at the
end; a forced termination can leave test volume settings behind.

Initial RED results were recorded before implementation: three missing gameplay
modules, then missing main orchestration. A later regression failed when pause
incorrectly consumed invulnerability time, and passes after the pause gate fix.

## Real viewport capture

```sh
"$GODOT" --path . -- --capture-region=camp
"$GODOT" --path . -- --capture-region=forest
"$GODOT" --path . -- --capture-region=creek
"$GODOT" --path . -- --capture-region=ruins
```

The optional CLI harness lives in `tests/capture_region.gd`, loaded only when its
flag is supplied. It starts a normal fresh run and positions the player/camera
at the named region center. It does not award items, grant health or disable
combat. It warms up for 60 frames, measures frames 61–240 with a monotonic clock,
prints FPS/median/p95 and renderer, then captures the real viewport to
`user://captures/<region>.png` AFTER measurement. PNG readback is excluded from
timing. It then releases the scene and quits. Measurements include the configured
120 FPS cap and are short samples, not maximum GPU throughput.

Headless mode intentionally skips PNG saving and labels timing as **not GPU
performance**. Complete visual assessment requires the primary-owned art files
and a graphical renderer. Invalid region exits with status 2.
