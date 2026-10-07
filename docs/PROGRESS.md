# Build ledger — Rừng Tàn Lửa

Environment verified: Godot 4.7.2.stable.official.ed1daf0bf. Empty destination created safely; no existing project overwritten. User explicitly approved full implementation. Read SPEC.md for authoritative scope and interfaces.

Tasks: assets/world/audio; gameplay/UI/quests/tests; integration/visual QA; independent review; Linux export/docs.

Interface preflight: actor visual kind names and frame dimensions shared by generator and gameplay; world build owns colliders while actors own movement; audio owns buses while UI owns saved settings. No overlapping writer files. New-game reset must rebuild world and actors, not retain stale references.

Ruling: generate original pixel assets from deterministic source rather than mix mismatched packs — coherent palette and legal provenance, but visual adequacy requires actual screenshot review.
Ruling: one separate worker implements gameplay and tests while primary authors independent asset/world/audio files — fixed interface avoids collisions; integration tests must catch mismatches.

Implementation and integration complete: 28 initial actors/13 kinds, four regions, combat/AI/quests/UI, original art/audio. Regression fixes: gatherer moved into camp, bag moved to creek, five herbs, explicit audio/art listener, effective damage statistics, exit dialog Escape, enemy windup and distinct attack SFX. Review re-check confirmed nine fixes, no new Critical/High.

Ruling: keep the optional `--capture-region` harness in the Linux export — enables reproducible verification of the exact standalone release; it only runs when explicitly requested and quits after measurement, costs a small development script in the package. README documents it. Other tests excluded.
Ruling: disable VSync and cap 120 FPS — A/B profiling found an X11/NVIDIA synchronization stall (10.56 FPS vs 357.60 uncapped without VSync); no graphics stripped. Cost: possible tearing on other desktop configurations.

Verification: full headless suites pass assertions; integration/runtime test teardown adjusted to allow asynchronous OGG release. Real GPU input smoke passed 22 checks, captures saved. Four region captures measured 98.83–108.99 FPS short samples with p95 22–24ms; not a sustained 60 FPS guarantee. Linux export created from official release template, not editor launcher.

Known validation limits: no full human 15–20 minute playthrough; local vision reports are terse/inconsistent and cannot certify professional art quality. Actual captures supplied for inspection. Read docs/TEST_REPORT.md for delivery evidence and residual minor risks.
