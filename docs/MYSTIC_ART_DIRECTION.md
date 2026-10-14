# Rừng huyền bí — ánh lửa ấm

Implemented locally 2026-10-08; visual polish pass completed 2026-10-11. Palette: deep teal #102a30, jade #6a9c87,
amber #e7be7b, ember #ed9853, parchment #f6daa2. Retains all 13 actor designs,
28 initial actors, collision geometry, quests, input bindings and previous fixes.

## Visual changes

- Camp: warmer ground/light, cosmetic lanterns, faint smoke around rest fires.
- Forest: cooler jade/teal treatment, moon shafts, sparse luminous mushrooms.
- Creek: cooler turquoise grade and locally animated water ripples.
- Ruins: lilac stone grading, subtle mist, dormant runes that warm when altar lights.
- Player/actors: one-pixel outline shader; stronger warm top rim on player,
  subtle ground locator; melee attack arcs / ranged aiming marks during windup.
- Bounded pooled cosmetic hit/heal/dodge/pickup bursts (max 48); never deal damage.
- Combat readability pass: pooled impact/projectile/wall/death bursts, short hit-stop, damage-scaled shake, spear arcs, projectile trails, dodge streaks, hurt flash and low-health vignette.
- Floating ember collectibles, local sparks/glow; flame above activated altar.
- Compact HUD: health, potion/stone icons, three individually lit ember slots,
  concise main objective, regional entrance title, E prompt near selected target.
- NPC portraits use the actual directional actor sheets; dialogue and keyboard
  buttons retain their existing behavior.
- Menu/ending use an original generated forest/camp background with translucent
  teal/brass panels. Shared backdrop does not depict dynamic gameplay state;
  the world altar/runes separately reflect real authoritative quest state.
- HUD polish keeps acquired ember slots structurally white while adding pulse scale, shortens the control footer, adds a damage vignette and button hover feedback.

## Generated media provenance

`assets/ui/mystic-forest.png`: generated with Cockpit GPT Image 2.5 on 2026-10-08,
1536x1024 requested, opaque, saved 2,395,388 bytes. Prompt: pixel-art ancient
Vietnamese forest at twilight, amber campfire, humble shelter, teal-cloaked traveler,
rust-red scarf, mossy ruins, turquoise creek, no text or logos. Used as static
menu/ending artwork, aspect-cover scaled to the native viewport. Existing pixel
sprite masters and Pillow generator are preserved.

## Verification

Godot 4.7.2 / Windows / OpenGL Compatibility / GTX 1050 Ti.

- Import task `2ad5c26d-de04-400b-8cd9-f65f2cc92260`: no stderr.
- Headless suites task `3da7bff0-8931-4f00-b5a5-6b270b8eaaad`:
  visual contract 16/16, gameplay 71/71, integration 37/37, runtime 18/18,
  delivery regressions zero failures, UI input 18/18, world/audio 3164/3164,
  play regressions 24/24. No stderr.
- Graphical task `97edc555-961e-46ff-ac9e-8a5166a1ddff`: UI input 23/23;
  complete input/UI journey 22/22 including rendered ending and clean replay.
  Final journey recorded 14 hostile deaths, 0 player deaths, 106 damage received,
  both side quests, all three embers, no focus interruptions. Bot runtime is not
  human playtime. No runtime/shader error output.

### Short measured samples (180 frames after 60-frame warmup)

| Region | FPS | p95 frame time |
|---|---:|---:|
| Camp | 74.61 | 21.57 ms |
| Forest | 120.00 | 9.73 ms |
| Creek | 120.00 | 10.31 ms |
| Ruins | 120.02 | 9.91 ms |

All reported mode=playing on Windows / OpenGL Compatibility / GTX 1050 Ti. These are
short current-machine samples, not sustained performance guarantees or an old/new
A/B benchmark. No new shadow-casting lights; environment accents culled against
camera view and refreshed at ~12.5 Hz.

## Captures and limits

Real captures in `%APPDATA%\Godot\app_userdata\Rừng Tàn Lửa\captures\`:
`menu.png`, `pause.png`, `settings.png`, `gameplay-input.png`, `camp.png`,
`forest.png`, `creek.png`, `ruins.png`, `journey-ending.png`.

The 2026-10-11 capture pass regenerated `camp.png`, `forest.png`, `creek.png` and
`ruins.png` after the polish pass. Rendered checks show combat windups/arcs,
ember glow, camp flames, creek ripples, ruins mist/runes and the compact HUD.

The capture files were inspected in-session. They confirm the intended effects are
visible; final taste acceptance remains a user decision. Native viewport layout
checks and gameplay tests remain structural rather than a substitute for human
playtime/balance review.

The graphical InputMap/UI journey was attempted twice after the polish pass. Both
runs completed menu/quest setup and the first two pickups, then hit the existing
bot travel deadline while navigating the forest obstacle route. This is recorded
as a bot-navigation limit, not as a parser/runtime failure; all gameplay,
integration, runtime, regression and world/audio suites pass.

No GitHub push or release publication. Launch updated source with `CHOI-GAME.cmd`.
