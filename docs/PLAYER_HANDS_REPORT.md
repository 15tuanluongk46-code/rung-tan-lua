# PlayerHands — 13/10/2026

User selected the original `assets/sprites/player.png` as the exact compact-hand
reference. Native supplied image and local sheet match.

- Player resting/walking/dodge/hurt/dead uses the approved original combined sheet;
  suppress dynamic weapon/arm/cloak overlays to prevent duplicate hands or spear.
  Charge/windup and active attacks use the layered body with original drape occlusion.
- Player action arm has a short dark cuff, narrow forearm and 2×2px hand, replacing
  the long turquoise sleeve. Shoulder anchor is closer to the reference; physical
  animated grip/contact remains unchanged. Other actor arms are unchanged.
- Idle/run native render evidence for four cardinal directions is visually identical
  in shape to the approved sheet (scene lighting/readability rim still applies).
  Eight-direction spear and four-direction throw phase crops were inspected.
  Action hands necessarily extend during contact, then restore the reference rest.

Evidence: `docs/screenshots/player-hands/idle-run-reference.png`, `spear.png`,
`throw.png`, `approved-reference.png` plus 24 native idle/run/charge frames.
First verification receipt `d4cce27b-ed0f-4a6c-8056-50bf1637851d`: import,
Detail 39/39, ActionSync 37/37, weapons 30/30, visual contract 16/16; empty stderr.
No pointer warp or save writes. Frame sampling does not prove subjective smoothness.

Delivery: Windows/source `PlayerHands-20261013`, SHA256 receipt in build/.
Previous versioned archives retained. Source launch uses the current project.
