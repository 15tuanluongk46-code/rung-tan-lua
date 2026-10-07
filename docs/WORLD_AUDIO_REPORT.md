# World / audio handoff — 2026-10-07

## Scope and status

Implemented only the assigned production sources:

- `scripts/world_art.gd`
- `scripts/audio_director.gd`
- `tools/generate_audio.py`

Added `tests/test_world_audio.gd`, `tests/test_generate_audio.py`, and this report.
Ran the audio generator, producing **21 original OGG files** and
`assets/audio_manifest.json`. Godot created normal import caches/UID sidecars.
No image generation, actor-visual changes, gameplay/config changes, subagents,
commits, purchases, downloads or external audio sources.

**Verdict: implementation/API/physics and synthesized audio verified;
visual/listening acceptance partially verified, pending primary art integration.**
PNG terrain/props, actor visuals and font were absent during these tests. Nothing
was substituted with placeholder terrain or pretend sprites. Missing art emits
one descriptive warning per world build and does not prevent geometry tests.

## World implementation

### Integration

`extends Node2D`; public contract:

```gdscript
build(world: Node2D) -> void
var obstacles: Array[Rect2]
is_blocked(point: Vector2, margin: float = 0.0) -> bool
set_region(region: String) -> void
set_listener(node: Node2D) -> void # optional; Main.player discovered otherwise
```

`build` is idempotent. WorldArt stays at `(0,0)`. All standing props are **direct
children of the same y-sorted world as actors**, with their sort origin at the
bottom-center root. No giant prop container flattens their y ordering. WorldArt
owns lighting/atmosphere, while `world` owns terrain and prop lifetimes.

- Terrain: `assets/terrain/{camp,forest,creek,ruins}.png`, four unscaled
  **1200×800** quadrants at `(0,0)`, `(1200,0)`, `(0,800)`, `(1200,800)`, z=-20.
- Sprite dimensions match `tools/generate_assets.py`: trees112×136,
  pine80×132, bush48×32, rock48×40, tent112×94, table64×48, forge64×60,
  sign48×56, bridge128×78, column48×94, wall96×58.
- Deterministic local seed641270; **200 trees**, using all three broadleaf
  textures plus pine, and **250 bushes/rocks**. Conservative scale and tint
  variation; biome-weighted pine frequency; no texture copies/recolors added.
- Final collision census: **332** StaticBody2D rectangle colliders, layer1,
  mask0. Exactly one matching `Rect2` per collider. Bushes, shadows and bridge
  decks are non-solid. Negative query margins clamp to zero. Main remains
  responsible for outer map bounds, as in its existing `point_blocked` API.

### Clearance and authored landmarks

Road polylines reproduce the image generator's connected painted paths.
All actor/item positions, region centers, checkpoints and altar location come
from `world_content.gd`. Every spawn gets a protected straight connector to its
nearest road, not merely a clear disk surrounded by blocked foliage. The creek
channel is reserved from random solids and remains walkable.

- Camp clearing excludes random trees/rocks; tents for chief/healer/hunter,
  forge by smith, work table and route signs.
- **Four tents, one forge, two tables, two signs** in total. Content places
  gatherer Nhi at `(600,1120)`, not in the camp: her smaller shelter is near
  `(664,1090)` and her worktable at `(620,1050)`. No duplicate NPC was created.
- Authored placement checks content clearance and searches nearby safe shoulders
  before giving up; there are **no unresolved placement warnings** in final run.
- **Eight ruined pillars and eight wall sections**, leaving altar court, guards,
  item connectors and roads accessible.
- Two bear dens near `(1500,720)` and `(1080,1010)`, assembled from **12 actual
  shaded rock sprites** around dark ground recesses, open mouths/no entrance
  blocker. These are sprite-rock compositions, not an unprovided cave texture.
- Two bridge decks centered near `(337,1201)` and `(297,980)`, z=-2, below actors;
  shallow water never becomes an invisible wall.

Tests sample every road segment at41 positions with24px margin, every
actor/item connector at21 positions with18px margin, all authored spawn
positions, all obstacle centers/margins, and an actual physics ray.

### Lighting, fading, performance

- Moderate CanvasModulate palette, approximately0.78–0.96 RGB rather than black;
  smoothly interpolated warm camp / cool forest-creek-ruins.
- Five sparse PointLight2D accents: camp/creek fires, forge, two cool ruins.
  Only **two lights cast shadows**, with small trunk/base occluders and no costly
  filtered shadow maps. Existing player light remains owned by gameplay.
- Tree texture split into canopy atlas and bottom bark strip. Player behind a
  tree fades canopy smoothly to0.27 alpha; trunk/collider remains fully present.
  Foreground trees recover full opacity. Pixel-nearest filtering is explicit.
- Ground shadows use shared radial textures, not hundreds of unique images.
-92 tiny leaf/firefly/spark records total. One bounded immediate-drawing node,
  viewport filtering and10Hz redraw; no large GPU particle systems or per-mote
  nodes. Fire flicker is restrained.
- Sprite roots and lights culled from camera viewport+180px, refreshed10Hz.
  Only nearby canopies animate each frame. Collisions are never culled, so
  off-screen AI/projectiles remain consistent. Static terrain uses renderer
  culling. No GPU/FPS performance claim without real art/render review.

## Audio implementation

### Generator / provenance

`python3 tools/generate_audio.py` works from any working directory; optional
`--output /path/to/assets`. Python3+numpy+standard `wave` and ffmpeg/libvorbis.
Module import has no filesystem side effects. Fixed local PCG64 seeds and
original note sequences; no samples, scraping, API, account or cost.

Output:

| Directory | Files | Format |
|---|---|---|
| `assets/music/` | camp, forest, creek, ruins | stereo,44100Hz,28s each |
| `assets/ambient/` | wind, water, birds, fire | stereo,44100Hz,28s each |
| `assets/sfx/` | step, attack, hit, dodge, stone, pickup, heal, quest, death, click, bow, magic, bear | mono,44100Hz,~0.06–2.2s |

Music: eight3.5-second bars, related D Dorian/Aeolian/suspended miniatures,
soft pads, bass, wood/bell melody, stereo echoes. Note/reverb tails wrap on a
circular buffer. Ambience uses FFT-periodic shaped noise, synthesized bird
chirps, water drops and fire crackles; a15ms boundary correction preserves
continuous noise rather than fading each28-second loop to silence.

Static RMS normalization avoids pumping; PCM peak<=0.70. Every encoded OGG is
decoded again, checked for finite samples, boundary discontinuity, sample peak
and **4× oversampled true peak** before publication. This is a practical
intersample headroom check, not a claim of certified broadcast metering.

Measured final delivery:

- Music RMS around **−18.77dBFS**, music peaks −8.19 to−7.19dBFS.
- Maximum decoded sample peak across all files: **−2.538dBFS** (`attack`).
- Maximum4× oversampled true peak: **−2.520dBFS** (`attack`), below−1.5dBFS gate.
- Largest music loop endpoint delta:0.011876; largest ambience delta:0.004727.
- Music files ~163–189KB each; largest ambience ~441KB; SFX ~4–22KB each.
- Exact per-file duration/channels/peak/RMS/seam/size recorded in
  `assets/audio_manifest.json`. Short Vorbis effects may decode with small
  encoder padding; all music/ambience decode to28.000s.
- Numerical seam/headroom tests pass. **No human listening session claimed.**

### Runtime integration

`extends Node`; existing Main works without modification:

```gdscript
play_sfx(key: String, world_position: Vector2 = Vector2.ZERO)
set_region(region: String)
set_volume(bus: String, value: float)
set_listener(node: Node2D) # optional
```

- Master built-in; Music/Ambient/SFX created if absent and routed to Master.
  Independent existing settings honored. Volume clamps0..1;0 mutes and
  subsequent positive value unmutes. Invalid bus/key/region safely ignored.
- Two music decks, equal-power **2.8s crossfade**, region identity guard,
  reversible in-flight transitions; inactive deck stops after fade. Third-region
  interruption replaces quieter deck. Loops use `AudioStreamOggVorbis.loop=true`
  directly on the actual resource and `loop_offset=0` after loading; no reliance
  on filename or default `.import` checkbox. SFX explicitly `loop=false`.
- Four independently mixed ambience layers route to **Ambient**, not Music.
  Smooth regional weights, silent layers stop decoding.
- Exactly **eight preallocated SFX voices**; no per-event allocations.
  Key-based throttles, quiet footsteps, priority-aware oldest-voice stealing;
  death/quest/heal cannot be stolen by footsteps. Modest repeat pitch variation.
- Spatial events attenuate against current Main.player, including after respawn;
  sounds>=620px culled before consuming a voice or throttle timestamp.
  Vector2.ZERO is the integration contract's non-spatial UI/event sentinel.
  Optional explicit listener setter supports other scenes/tests.
- Runtime resource loading uses exported/imported resources first, with direct
  OGG fallback before editor import. Missing assets warn rather than crash.
- Exit hook stops voices, releases streams. Own test waits150ms for AudioServer
  decoder cleanup after queue_free. See rapid-test teardown caveat below.

## TDD and verification record

Working directory: `/home/sss/Projects/rung-tan-lua`.

```sh
GODOT=/home/sss/Applications/Godot_v4.7.2-stable_linux.x86_64
```

Observed RED before production code: Python4 failures because generator absent;
Godot2 failures because world/audio modules absent. Added authored-furniture
checks caught missing tent/table caused by clearance rejection; fixed layout
without reducing road/spawn protection. Added encoded true-peak regression
failed on missing measurements before implementing4× measurement.

| Exact command (using GODOT above) | Result |
|---|---|
| `python3 -m unittest discover -s tests -p test_generate_audio.py` | PASS,5 tests |
| `python3 tools/generate_audio.py` | PASS,21 files encoded, decoded and validated |
| `$GODOT --headless --path . --editor --import --quit` | PASS, audio imported, no parse errors |
| `$GODOT --headless --path . --check-only --script res://scripts/world_art.gd` | PASS, no parse/Variant inference warnings |
| `$GODOT --headless --path . --check-only --script res://scripts/audio_director.gd` | PASS, no parse/Variant inference warnings |
| `$GODOT --headless --path . --script res://tests/test_world_audio.gd` | PASS,2789 checks/0 failures; expected missing-art warning |
| `$GODOT --headless --path . --script res://tests/test_gameplay.gd` | PASS,71 checks/0 failures |
| `$GODOT --headless --path . --script res://tests/test_integration.gd` |37 checks/0 assertion failures; see shutdown warning below |
| `$GODOT --headless --path . --script res://tests/test_runtime.gd` | PASS,18 checks/0 failures; cleanup warning intermittent in earlier run |
| `$GODOT --headless --path . --quit-after 60` | PASS, menu startup; expected primary art/actor dependency warnings |

**2915 Godot assertions plus5 Python tests.** Missing image texture dimensions
and visual atlas contents are intentionally not counted as verified. New tests
also exercise idempotent/deterministic build, actual collision layer, canopy
fade/recovery, attenuation/cull/throttle, resource looping, equal-power overlap,
deck stop and independent Ambient routing.

### Known verification caveats / primary follow-up

1. **Primary art still missing:** all terrain/prop PNGs and actor_visual were
   absent. Do not treat headless geometry checks as completed art acceptance.
   After primary runs image generator and imports, run the strict gate:

   ```sh
   "$GODOT" --headless --path . --editor --import --quit
   "$GODOT" --headless --path . --script res://tests/test_world_audio.gd -- --require-assets
   ```

   Strict mode refuses absent prop/terrain/audio resources. It has not been run
   as an acceptance pass because required primary image assets do not exist yet.
2. **Rapid integration-test shutdown:**37 assertions pass/exit0, but immediate
   exit after freeing playing Vorbis streams reports28 leaked AudioServer
   playback/packet objects and14 resources. Verbose diagnosis identifies
   decoder resources, not world/physics nodes. Own test with150ms mix-drain
   wait and normal60-frame startup exit has clean decoder teardown. Existing
   integration/runtime tests were not edited; primary should add a post-free
   audio drain before quitting if clean stderr is required. This run is not
   represented as a warning-free integration pass.
3. **Visual pass not run:** review camp furniture spacing, rock-den silhouette,
   bridge placement, tree-root alignment and y-sort with actual sprites. Check
   faint lights/occluders on the graphical renderer. Nearby authored props may
   shift by<=96px to respect authoritative content connectors.
4. **Listening pass not run:** audition loop boundary, crossfade on rapid region
   changes, all SFX and independently mute each bus. Synthesized birds/water are
   designed textures, not recordings; aesthetic acceptance needs listening.
5. Extra bow/magic/bear sounds are supplied but existing gameplay chooses its
   own keys; no new gameplay triggers were added outside assigned scope.
6. No export, GPU benchmark, screenshots or human playthrough claimed. The
   existing capture harness and gameplay suites remain primary's integration
   tools after images/font/actor visuals land.

Context7 was attempted but quota-exhausted; official Godot AudioStreamOggVorbis
documentation was consulted for actual resource looping/load behavior.
