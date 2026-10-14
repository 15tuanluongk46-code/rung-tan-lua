# Virtual test aim — 13/10/2026

The visible journey runner formerly used Viewport.warp_mouse to aim. That API
moved the user's Windows pointer; the user reported interference. The owned runner
had already self-exited (task 4a09adf6-62a6-477a-a1eb-aed94c20843c); no process
termination or browser actions were performed.

## Change and verification

- Removed warp_mouse and synthetic mouse motion from journey aim().
- Added player.set_test_aim(world_position), enabled only with a res://tests/
  script argument and rejected in release feature builds. It supplies an alternative
  pointer position to the ordinary player aiming calculation, not direct damage,
  inventory, quest, target-facing assignment or invulnerability.
- Source search found no warp_mouse or mouse_set_mode calls remaining.
- Parser-only checks passed. Then task d2754808-9022-415a-b0d6-5792e3b28992
  ran entirely headless, exited 0 with empty stderr: ActionSync 37/37, weapon 30/30,
  runtime 18/18, autosave 7/7, controlled ability/UI 5/5 (no capture checks),
  chapter-I 21/21, chapter-II 24/24. Chapter II recorded one death and recovered
  through the normal UI. Counts exclude graphical screenshot checks.
- No visible graphical bot relaunched after the user's pointer complaint. No
  executable export/archive repack in this follow-up; latest executable remains
  ActionSync, while source now includes this isolated test-hook change.

## Earlier real-time test findings remain open

- Chapter-I real-time graphical run 22/22.
- Chapter-II failed at Well interaction twice. Diagnostic showed E picked up the
  adjacent stone supply first; stage=2, all lamps and guard ledger correct. Moving
  closer (test target tolerance 18->8px) allowed progression. Production interaction
  code unchanged; nearest-target UX remains a potential improvement.
- Subsequent real-time runner reached boss but repeatedly died and exceeded travel
  deadline. Do not relabel this as a pass just because fixed-fps headless passed.
  Human difficulty/real-time runner strategy still needs inspection.

This change prevents cursor warping by these source tests; it does not claim that
general automation cannot affect the desktop. Future graphical demos should use
virtual aim only; manual play must not run concurrently with a bot.
