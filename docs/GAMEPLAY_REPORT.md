# Gameplay implementation handoff

Date: 2026-10-07. Binding source: `docs/SPEC.md`, read before implementation.
No subagents, commits, Git initialization, asset generation, downloads, Godot MCP
scene editing, or changes to primary-owned files were performed.

## Delivered modules

| Path | Responsibility |
| --- | --- |
| `scripts/main.gd` | Scene orchestration, session/reset, actual interactions, spawning, combat routing, four regions, camera/light, optional capture entry |
| `scripts/run_state.gd` | Session-only quest/inventory/death authority; idempotent pickups and one-time rewards |
| `scripts/combat_health.gd` | HP, bounded attack-ID deduplication, temporary invulnerability, reset |
| `scripts/world_content.gd` | Exact actor census, fixed region centers, start/checkpoints, items/guards |
| `scripts/actor_base.gd` | Shared CharacterBody2D collision, damage/death, runtime visual API |
| `scripts/player_actor.gd` | Input, aim, spear/stone/dodge/heal/interact, footstep noise |
| `scripts/enemy_actor.gd` | Patrol/investigate/chase/windup/recovery/leash states, stable targets, bear hostility |
| `scripts/peaceful_actor.gd` | Five NPC activities/dialogue proximity; wildlife wander/flee, noncombat immunity |
| `scripts/projectile.gd` | Swept obstacle/target checks, lifetime, damage, noise |
| `scripts/game_ui.gd` | Vietnamese menu/help/settings/credits/HUD/dialogue/pause/death/ending/exit confirmation |
| `scripts/game_settings.gd` | Persistent settings only, four independent volume buses, fullscreen/screenshake |
| `tests/test_gameplay.gd` | State/combat/census suite |
| `tests/test_integration.gd` | Real-scene/API quest completion/reset suite |
| `tests/test_runtime.gd` | Physics, AI, input, pause/death/UI bounds suite |
| `tests/capture_region.gd` | CLI-only screenshot and measured-frame timing harness |
| `tests/README.md` | Repeatable tests and capture commands |

Attached the script to the **existing** root in `scenes/Main.tscn` (root remains
Node). Configured `project.godot` input actions, 640×360 viewport rendering,
1280×720 window override, nearest filtering and transform pixel snapping.

## Implemented behavior

- Continuous 2400×1600 world; region centers and player start match SPEC.
  World `Node2D.y_sort_enabled = true`, world-art build called once if present.
  Player-parented Camera2D uses zoom 1.4 and map limits; procedural radial
  PointLight2D supplies warm player light (not placeholder art).
- Exact initial 28 actors / 13 kinds: player; An/chief, Lâm/hunter,
  Mai/healer, Bình/smith, Nhi/gatherer; 6 melee, 4 archers, 2 shamans,
  2 bears, 3 deer, 3 rabbits, 2 birds.
- Runtime visual integration calls `setup(kind)` and `pose(...)`; action and
  facing state are supplied every active frame, including idle/movement.
  Dead pose is applied immediately when death pauses gameplay.
- WASD, mouse aim, LMB spear25, RMB stone20, Space dodge, E interact,
  Q heal40, Esc pause. Player100 HP; potion cap6, stone cap30.
  Dodge0.8s cooldown/0.25s protection; damage invulnerability0.38s.
- Melee75 HP, archers50, shamans100, bears175. Visible Vietnamese windup
  warning and locked attack direction; melee16, bear28, arrow20, magic22 damage.
  Projectile sweeps test obstacle collision before targets, avoiding tunnelling.
  Walls block sight and spear damage. Attack history bounded to128 IDs/target.
- Stable hostile targets; bears attack player/goblins, goblins can retaliate.
  Sound/noise triggers investigation and wildlife fleeing. Enemy local steering
  avoids primary-provided obstacles; home leashes prevent indefinite pursuit.
- Three unique, guarded ember pickups; quest acceptance + all three required
  for altar. Return to chief ends the run. Two optional one-time quests:
  five herbs → two potions, hunter bag → eight stones + one potion.
- Rewards are **atomic**: insufficient capacity leaves quest/reward available
  rather than truncating it. Full pickup capacity leaves item in the world.
- Camp/creek E checkpoints restore HP and set respawn location. Death retains
  accepted/completed quests, unique pickups, consumables and killed enemies;
  resets living actors, HP, position and projectiles. No endless item respawn.
- Replay constructs a fresh session. Run state is never written to disk.
  Settings use `user://settings.cfg`; visible exit warning explains lost runs.
- Deliberate dark parchment/ember theme, Vietnamese content, keyboard-focused
  buttons, readable generous spacing, scrolling long help/dialogue paragraphs.
  HUD gives HP/supplies, region, objective, interaction prompt and event toast.
  Pause journal shows side quests/checkpoint/time/deaths; ending gives measured
  session time, kills, deaths, completed optional quests and damage received.
- Pausing freezes AI/projectiles/player and combat timers. Focus loss pauses.
  Window close invokes confirmation rather than silently losing progress.

## Primary integration: dependencies still missing at verification

The following primary-owned modules were absent, intentionally not edited or
replaced. Runtime logs explicit warnings and allows logic tests to proceed:

1. `scripts/world_art.gd`: `build(world)`, `is_blocked(point,margin)`.
   Obstacles must use physics collision layer1. Its terrain/props/canopies and
   ambient lighting remain primary work. Optional `set_region(region)` called
   only if present. Root stays at origin; all region centers should be clear.
2. `scripts/actor_visual.gd`: `setup(kind)`, `pose(facing,moving,action,elapsed)`.
   Must supply actual 13 designs and sprite animation. No substitute shapes.
3. `scripts/audio_director.gd`: `play_sfx`, `set_region`, optional `set_volume`.
   Gameplay creates/checks Master/Music/**Ambient**/SFX independently. Route
   ambient audio to Ambient bus, not Music, for independent slider behavior.
4. `assets/fonts/DejaVuSans.ttf` and actor sheets under `assets/sprites/`.
5. Additional runtime item/projectile lookups under `assets/props/`:
   `ember.png`, `herb.png`, `bag.png`, `potion.png`, `stone.png`, `checkpoint.png`,
   `altar.png`, `arrow.png`, `magic.png`. These paths are **gameplay additions**
   beyond SPEC's actor paths; primary should supply matching files or align the
   lookup. Missing item art leaves only functional interaction labels; missing
   projectile art produces invisible projectiles until integrated. Do not ship
   before this is resolved. No placeholder geometry was added.

The spawn helper checks primary obstacle occupancy and searches a short radial
neighborhood for free positions. Verify visual/physics overlap after art lands;
authored roads and region centers should stay clear. Captures and UI styling
still require a graphical review with the actual font and art.

## Verification evidence

Godot: `/home/sss/Applications/Godot_v4.7.2-stable_linux.x86_64`.

TDD RED before implementation:

- `test_gameplay.gd`: **3 checks / 3 failures**, explicitly missing state,
  combat and content modules.
- `test_integration.gd`: **FAIL**, explicitly missing main orchestration.
- Later regression: pause consumed invulnerability time; runtime suite
  **18 checks / 1 failure** before the early pause gate; now passes.

Final automated results before this report:

| Command suffix (with `--headless --path <project>`) | Result |
| --- | --- |
| `--editor --import` | PASS; no parse errors |
| `--script res://tests/test_gameplay.gd` | PASS: 71 checks / 0 failures |
| `--script res://tests/test_integration.gd` | PASS: 37 checks / 0 failures |
| `--script res://tests/test_runtime.gd` | PASS: 18 checks / 0 failures |
| `--quit-after 60` | PASS: menu startup |
| `-- --capture-region=camp` | PASS: 180-frame auto-exit, headless screenshot skip |
| `-- --capture-region=forest` | PASS: 180-frame auto-exit, headless screenshot skip |
| `-- --capture-region=creek` | PASS: 180-frame auto-exit, headless screenshot skip |
| `-- --capture-region=ruins` | PASS: 180-frame auto-exit, headless screenshot skip |

Expected warnings: the three missing primary module paths above. A deferred
focus warning from rapidly replaced UI panels was found and fixed by checking
node validity/tree membership before grabbing focus; subsequent runs clean
except dependency warnings.

126 total automated assertions include duplicate pickup/reward prevention,
three unique embers, altar rejection/acceptance, full quest completion through
interaction API, inventory capacity, health/heal bounds, death preservation,
survivor/projectile reset, replay, exact actor census, input bindings, stable
targets, neutral immunity, bear hostility, wall/projectile interaction,
invulnerability, dodge, noise, audio buses and native-viewport modal bounds.

**This is an automated API/physics simulation, not a real playtest.**

## Capture/performance support

With actual dependencies and a graphical session:

```sh
/home/sss/Applications/Godot_v4.7.2-stable_linux.x86_64 \
  --path /home/sss/Projects/rung-tan-lua -- --capture-region=camp
```

Use `camp`, `forest`, `creek`, `ruins`. The harness starts fresh gameplay,
positions player/camera, takes a viewport PNG after frame65 if non-headless,
writes `user://captures/<region>.png`, then exits after at least180 frames.
Measured FPS uses120 frames following the first60 warmup frames and monotonic
wall time. Tool flags do not change normal play, reward state or persistence.

Observed headless diagnostic samples: camp144.23, forest145.47, creek144.85,
ruins144.58 frames/s. **These are not GPU/display performance results** and
exclude all currently missing art/audio. No real screenshots were generated or
claimed. No first-run duration measurement has been performed.

## Remaining acceptance work / risks

- Integrate primary art/audio/font/extra item paths; rerun all suites and four
  graphical captures. Confirm audio bus routing, pixel art silhouette/actions,
  canopy fading, warm/cool environment lights, windup/projectile readability.
- Run a human first-play session; measure rather than claim the 15–20-minute
  target. Combat/travel parameters are implemented but not human-balanced.
- Local obstacle steering is intentionally lightweight, not navigation-mesh
  pathfinding; review tricky primary prop clusters for stuck enemies.
- Confirm all resource spawns, player start, both checkpoints and the altar are
  unobstructed after art generation. Existing tests use no primary art fixture.
- Native-size headless UI bounds passed, but no graphical typography/control
  review has occurred with the supplied font or unusual aspect ratios.
- Settings serialization code is implemented; disk persistence/fullscreen and
  actual audible slider changes were not manually tested.
- Linux export/templates, licenses, overall README and distribution remain
  primary responsibility. No executable export is claimed here.
