# Live QA — 13/10/2026, FullAudit source

Requested opening and self-testing, not another cosmetic rebuild. No gameplay,
production assets or EXE changes in this QA follow-up. Added observation fixture,
evidence copier and this report. Player save/settings isolated by test path guards.

## Runs and evidence

- Exported EXE opened with OpenGL/GTX1050Ti, --no-save/--quit-after360. Its launch
  shell exited before identity registration and the chained source tests did NOT
  execute. Task06851669 retained a claim. Do not label its exit0 a full test pass.
  User explicitly approved narrow coordination repair. Matching fast-launch receipt,
  owner lineage and two empty process-window checks recovered the claim; no killing
  or manual registry edits. Recovery tests8/8. Restart OpenCode to load module change
  into future MCP process; standalone reviewed CLI was function-tested this session.
- Task387afc24: visible real-time UI23/23, accessibility11/11, empty stderr.
- Task9d3051f2: Chapter I, visible real-time (NO --fixed-fps),22/22; wall-clock launch
  08:36:34Z to08:43:29Z (~6m55). Recorded simulation elapsed02:11,13 kills,0 deaths,
  damage40,3 legitimate focus auto-pauses/resume through UI. Times are distinct and
  not a human playtime claim.
- Taskac0ec39c: Chapter II unlocked fixture, visible real-time,25/25;08:46:25Z to
  08:49:28Z (~3m03), final displayed elapsed02:57,14 kills,0 deaths,damage270,
  side quests2/4 (ChapterI optional quests not completed by this targeted fixture),
  memories3/3. Boss beaten using ordinary spear/stone/dodge input; no godmode.
- Task2682394d: native death/map/settings captures, autosave7/7, independent
  restart read1/1, audit17/17; empty stderr.
- Task30c9f986: targeted pose/atlas/repeat-hurt/dodge observation; native renders and
  logs, empty stderr. A previous QA-only fixture held a freed visual after rebuilding
  ChapterII; watchdog exited2, then fixed fixture reacquired new visual and completed.

No desktop cursor warping. Tests use Player.set_test_aim for ordinary world aim and
InputMap/UI injection. These are automated bots/fixtures, not manual human play.
Source gameplay is tested interactively; exported EXE only opening/menu smoke tested,
since release build disables virtual-aim test hooks.

## Findings

No runtime script errors/crashes/progression stalls established in successful runs.
Save persists/recovers via isolated pipeline. Atlas native render shows expected
Player silhouette: upright carry at rest, forward horizontal spear/contact, no
animated hand clusters on action. Repeat dodge restarts; production second hurt
starts motion_time0 after actual first hurt expires. Synthetic consecutive hurt label
without idle gave final frame, but did not reproduce through production damage path.

Native read image transport now worked: observed illustrated forest menu and four
menu actions; six-region map roads/checkpoints; pause scroll/stat text; full settings
sliders/toggles; recovered bridge spanning water and laid-out death sprite. This is
current image evidence, superseding the prior session's attachment limitation only
for the files actually read.

Polish recommendations, not blockers:
1. Map route lines low contrast/thin; increase contrast and add current objective
   landmark label. Region names/checkpoint legend remain readable.
2. ChapterI ending stats live below the initial scroll view; show compact key stats
   above actions with remaining lore scrollable. No lost text proven.
3. Boss amber cone overlay can visually overlap Player and faded Tower architecture;
   reduce filled opacity, keep perimeter strong. Only fixture image observed, no
   claim of unfair damage from the still.
4. Prompt E may occupy a low screen lane near scenery; scoring avoids actors but
   not all non-fire props. Assess during manual exploration rather than moving every
   prompt globally.

Evidence frozen in docs/screenshots/live-qa-20261013. QA windows/tasks self-exited;
game edit claims released. Old ai-vision-tools unresolved claim was not touched.
