extends RefCounted
## Sprite pose selection shares the rig's manual contact clock, no wall-clock tween.
var timelines: Dictionary
var textures: Dictionary = {}
func _init() -> void:
	timelines = JSON.parse_string(FileAccess.get_file_as_string("res://assets/player_motion/timelines.json"))
	for name: String in timelines: textures[name] = load("res://assets/player_motion/"+name+".png")
func apply(sprite: Sprite2D, name: String, octant: int, clock: float) -> void:
	var entry: Dictionary = timelines[name]
	var index: int = 0
	for i: int in range(entry.times.size()):
		if float(entry.times[i]) <= clock+0.00001: index = i
		else: break
	var tile: int = entry.indices[octant*int(entry.columns)+index]
	var w: int = entry.cell[0]
	var h: int = entry.cell[1]
	sprite.texture = textures[name]
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.region_enabled = true
	sprite.region_rect = Rect2((tile%int(entry.atlas_columns))*w,(tile/int(entry.atlas_columns))*h,w,h)
	sprite.position = Vector2(entry.bounds[0]+w/2.0-96,entry.bounds[1]+h/2.0-128)
	sprite.set_meta("motion_time",float(entry.times[index]))
	sprite.set_meta("motion_octant",octant)
	sprite.rotation = 0
	sprite.scale = Vector2.ONE
