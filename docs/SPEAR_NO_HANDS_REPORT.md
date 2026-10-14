# SpearOnlyNoHands — 13/10/2026

User refinement: hide BOTH small reference hands during spear motion. Generator
now omits original arm/skin drawing for thrust, heavy and charge, including the
initial active frame. Body/cloak stay fixed; only spear moves. Recovery completion
restores the original reference with hands. Throw/dodge/hurt/dead unchanged.

Regression checks every opaque fixed-body pixel and absence of both original skin
blocks across all active frames/eight octants; endpoint retains original pixels.
Existing contact .08/.13 seconds and reach 49/62 preserved by nonvisual clock.

Preview: docs/screenshots/spear-only-no-hands/player-motion-60fps.mp4 and native
horizontal/cardinal/diagonal render crops. Windows/source stamp:
SpearOnlyNoHands-20261013, SHA256 receipt in build. Save not used by captures/tests.
