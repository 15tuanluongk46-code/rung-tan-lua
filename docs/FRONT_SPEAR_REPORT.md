# FrontSpear — 13/10/2026

Final user refinement: spear goes in front of Player and all independent arm motion
is removed in every Player action. Entire arm/hand animation code was removed from
the Player generator. Runtime build_arms/draw_arms refuse Player; NPC rigs unchanged.

- Thrust/heavy/charge use armless fixed body; spear painted afterward from a forward
  anchor. No rear shaft and no pivot behind the back. Retract never goes inside/back
  of body. Vertical weapon shifted beside the head, tip follows 49/62 reach at contact.
- Throw: upright spear + stone object only, no drawn arm. Dodge/hurt: whole-body
  movement with no arms. Death: whole armless body falls. Rest/walk retains the
  approved original small hands as static embedded artwork, not a separate rig.
- Recovery restores approved rest. Contact/damage/cooldown unchanged. Tests validate
  hand absence, fixed body, front tip and no rear tail, contact and bounds.

Native clip/crops: docs/screenshots/front-spear/. Package stamp FrontSpear-20261013,
SHA256 receipt in build. Captures/tests isolate save and do not warp desktop mouse.
