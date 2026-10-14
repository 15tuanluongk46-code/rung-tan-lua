extends Node2D
## Sibling layers keep the far sleeve behind the body and gripping hands in front.
var rig: Node2D
var front: bool = false

func _draw() -> void:
	if rig != null and rig.arms_visible: rig.draw_arms(self,front)
