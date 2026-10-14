# SmoothMotion — 14/10/2026

User reports judder most evident during walking/dashing. Approved diagnosis and UI
polish, maintaining forward spear/no arm motion and existing combat/save semantics.

## Measured before edits

Real-time movement input, horizontal out/back and four dodge inputs per 4s case.
Test actors except Player held stationary to remove combat noise; physics remains60Hz.
No screenshots or per-frame disk writes in timing run; samples buffered in RAM.
GTX1050Ti, Compatibility, display reports59.79Hz. Baseline120-off: p95 9.132ms,
p99 9.775ms,0 frames>33.33ms; raw physics positions unchanged on50% render samples.
60-off: p99 17.558ms. Disable decorative FX/shadows:120 p99 9.422ms; no compelling
evidence decorative effects are the main walking-judder cause on this short route.

## Changes

- Enable2D physics interpolation; Camera2D follows physics callback with no extra
  lagging smoothing. Pixel nearest filtering/snapping and1.4zoom preserved. Spawn,
  load and checkpoint teleport call reset_physics_interpolation after reposition.
  Physics60Hz, Player108 movement/300 dodge and combat timing untouched.
- Cache font override only when text setting changes; cache tower reference instead
  of scanning all props each frame. HUD expensive layout refresh30Hz, with shared
  actor rectangles; interaction selection/validation behavior retained.
- Hitstop option0/off,1/light40%,2/existing retained default. New explicit60Hz smooth
  preset sets60cap+VSync. Does not silently overwrite the user's existing settings.
- Map route contrast/width increased, markers above roads; known objective marker.
  Ending visible compact stats outside lore scroll. Boss sector/ring fill opacity
  reduced to.045 while edge geometry/width unchanged. Prompt scores big scenery.
  Settings options scroll when needed, fixed return button, large-text panel fits.

## Results / limits

Separate magenta8px raster diagnostic120render/60physics: no interpolation39 repeated
positions/80 samples; interpolation8/80 (1px quantization persists intentionally).
Readback samples NOT used for frame-performance comparison. This simple fixture is
evidence interpolation works, not proof every Player/camera frame is perceived smooth.

Final same-route120-interp-direct: p95 8.878ms,p99 9.556ms,0>33.33ms;
60-VSync-interp:p99 17.657ms,0>33.33ms. CPU monitor mixed/time snapshots not used as
exclusive profiler attribution. One outlier>33ms in final120-off control; machine
background load varies. Short tests, not sustained/full-world or guaranteed FPS.
Twelve isolated snapshot writes:p50 3.103ms,p95 4.345ms; synchronous saver retained
rather than unnecessary threading/backup risk. Save spikes on other disks unproven.

Baseline receipt0b98fdf1; raster/timing8b3003a5. First settings overflow caught by
test and fixed with scroll container. Native evidence and timing JSON under
docs/screenshots/SmoothMotion-20261014. Further regression/journey receipts in logs.
No cursor warp, no user save/settings writes, no process termination/commits.

Regression: Smooth8/8, gameplay71/71, integration37/37, runtime19/19, UI18/18,
world/audio4112/4112, autosave7/7, quality17/17, depth38/38, expansion38/38,
play24/24, PlayerMotion121/121, weapons30/30, detail39/39, visual16/16,
accessibility6/6 (graphical11/11), audit17/17, ActionSync37/37; Python18 tests OK.
ChapterI21/21 and ChapterII24/24, with one boss death/normal UI recovery. Tests are
fixed-fps bots, not human play/difficulty sign-off. A cached supply prompt near well
required runner to wait8physics ticks for80ms target selection; production E semantics
not bypassed. Canopy test fixture reset interpolation/update camera after teleport.
