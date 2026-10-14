# Windows gameplay audit — 2026-10-08

## Scope and result

Canonical source: `C:\Users\ADMIN\AI-Home\projects\rung-tan-lua`.
Downloaded main snapshot: `33e3537c31c61dc926c67484aa3b2eb1a2dc45b5`.
Local fixes below are not published to GitHub. This game is local single-player,
not a server/API backend. Godot 4.7.2, Windows, OpenGL / GTX 1050 Ti.

**Result:** the automated InputMap + UI journey completes the main quest and both
side quests, verifies visible ending statistics, then successfully starts a clean
replay. Both headless traversal and the graphical journey passed. This is a bot
using runtime state to navigate/aim, not human visual QA or a difficulty benchmark.

## Reproduced and fixed

1. **Blocking quest dialogue:** `main.ui` was declared as generic `CanvasLayer`;
   the dynamically called `dialogue()` received an untyped literal Array where
   `Array[Dictionary]` was required. First actual E interaction with An failed at
   runtime. Declaring `ui: Interface` supplies the real method signature and typed
   options at compile time. Three initial quest dialogues have regression checks.
2. **Repeated exit confirmation:** a second OS-close request replaced the saved
   dead/ending return context with paused. Repeated requests are now idempotent;
   clearing the sheet clears the confirmation flag. Both checkpoint death paths
   and the ending screen are covered.
3. **Projectile hits through wall edge:** target radius could reach backwards over
   the wall stop point. Target selection now requires unobstructed sight and rejects
   target centers at/behind the obstruction's forward projection. Fixed radius
   remains 10 px; a more elaborate swept-shape collider was not introduced.
4. **Interaction through obstacles:** NPCs, pickups, checkpoints and altar now require
   unobstructed interaction sight. Positive and wall-blocked NPC cases tested.
5. **Herb journal:** separate not-accepted, collecting, ready, claimed states.
6. **Stone bag partial loss:** requires space for all four stones (at most 26 held);
   otherwise bag stays available and UI explains the four-slot requirement.

## Test defects / environment observations

- Survivor reset test formerly awaited a process frame after respawn resumed AI,
  then expected less than 1 px movement. Reset is now asserted synchronously;
  gameplay patrol was not disabled to force a pass.
- Initial graphical smoke failed 4 assertions; it passed unchanged on reproduction.
  Added failure diagnostics, initial focus verification and process-frame input
  injection. Three final graphical smoke runs each passed 23 checks.
- Graphical long journey directly observed two legitimate auto-pauses with
  `window_focus=false`; test resumes using the real Continue UI, logs interruptions,
  and leaves production auto-pause intact. A prior run failed on this condition.
- Fixed-FPS test teardown initially emitted OGG resource warnings. Verbose logs
  identified pending audio streams, not retained actor sessions. Replaced its
  simulated 0.3 s wait with 350 ms wall-clock frame yielding. Final aggregate and
  graphical journey logs have no Godot error/warning output.

## Evidence

Logs live in `C:\Users\ADMIN\AI-Home\agents\task-operations\logs\`.

| Task ID | Result |
|---|---|
| `0cd18420-2c3e-4e08-a77a-0657cc5cadc8` | RED: 8 failing assertions in 15 checks; graphical input 22/22 already passed |
| `382c06a9-449f-455a-a1d6-68c5ba8120d0` | RED: real first quest interaction produced Array type runtime error |
| `27c30bcd-4f3a-4ddb-b49d-8e7eede1be01` | Initial fixes: regressions 15/15, integration 37/37 |
| `f722f8f9-5d71-4f03-9505-6047c9ffc406` | Editor import after fixes; stderr empty |
| `939becaf-cda0-40d4-9368-e58f70556db7` | Aggregate exit 0: all original Godot suites, new regressions, headless journey, 7 Python tests, 3 graphical input runs |
| `e612c45a-1079-4a9a-a8e3-03ca15ea8211` | Expanded regressions 24/24; first graphical journey stopped on focus loss |
| `bae361e7-6209-4a66-8f89-76d67db777a0` | Final graphical journey 22/22, ending screenshot, complete replay reset |

Original Godot suite counts: gameplay 71, integration 37, runtime 18, input headless
18, world/audio 3164; delivery regressions report zero failures without a count.
New regression suite final count: 24. Python: 7 tests with Python 3.10.11,
Pillow 12.2.0, numpy 2.2.6 from installed interpreter (no new environment install).

### Full journey

Menu button → walk to An/Mai/Lam → accept dialogue buttons → pathfind using WASD →
aim via mouse-motion events / spear / stones / dodge / heal → collect five herbs,
hunter bag and three guarded embers using E → claim both rewards → walk to altar,
E → walk back to An, E → verify ending Label text → activate replay button.

No teleports, granted items, direct quest completion, direct damage calls or
invulnerability in the journey test. Separate targeted regression fixtures do use
direct state setup and damage to deterministically reproduce boundary cases.

Final graphical result: all 14 hostile actors recorded killed, 0 deaths, 42 damage,
2/2 side quests, 3/3 embers. Visible ending strings match run state. Reported game
clock 03:53 is a fixed-FPS bot run, not an expected human play duration. The kill
ledger counts enemy deaths, including NPC faction combat, not player-only kills.

Replay assertions: HP 100, potions 3, stones 12, 28 actors, 15 pickups, cleared
accepted/claimed/picked/killed, ended false, altar false, checkpoint camp, zero
deaths/damage and reset elapsed time. Separate regressions verify both camp and
creek deaths preserve picked/killed state and clear projectiles.

Screenshot: `%APPDATA%\Godot\app_userdata\Rừng Tàn Lửa\captures\journey-ending.png`.
It is actual rendered output; the assistant could not inspect images in this
session and does not claim a visual quality review.

## Remaining boundaries

- No human playthrough, OS-level physical keyboard/mouse test, or long-session
  stress/performance acceptance. InputMap events are injected inside the engine.
- No progress save on exit, by existing design; settings remain persistent.
- Main journey's final successful run had no deaths; death coverage comes from
  targeted fixtures (and earlier bot runs which died), not the final victory run.
- Existing Linux release and GitHub snapshot are unchanged. Windows source launch
  uses the local fixes. Test file naming is excluded by the existing export preset.

## Commands

```powershell
game-godot --headless --path "C:\Users\ADMIN\AI-Home\projects\rung-tan-lua" --editor --import --quit
game-godot --headless --path "C:\Users\ADMIN\AI-Home\projects\rung-tan-lua" --script res://tests/test_play_regressions.gd
game-godot --path "C:\Users\ADMIN\AI-Home\projects\rung-tan-lua" --script res://tests/test_user_journey.gd --fixed-fps 60
```
