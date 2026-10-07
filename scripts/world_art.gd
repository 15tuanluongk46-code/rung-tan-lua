extends Node2D
## Authored sprite environment. Every standing prop is a direct world child;
## its sort origin is its feet, not a container origin or texture center.
const Content = preload("res://scripts/world_content.gd")
const SEED: int = 641270
var ROADS: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(420,340),Vector2(430,470),Vector2(760,465),Vector2(1060,375),Vector2(1380,380),Vector2(1740,390),Vector2(1980,450)]),
	PackedVector2Array([Vector2(445,470),Vector2(410,720),Vector2(550,960),Vector2(530,1190),Vector2(760,1200),Vector2(1010,1160),Vector2(1420,1190),Vector2(1830,1190)]),
	PackedVector2Array([Vector2(1770,400),Vector2(1840,720),Vector2(1730,940),Vector2(1830,1190)]),
	PackedVector2Array([Vector2(830,1160),Vector2(830,1390)])]
var CREEK: PackedVector2Array = PackedVector2Array([Vector2(255,800),Vector2(300,920),Vector2(300,1060),Vector2(345,1200),Vector2(325,1370),Vector2(390,1600)])
const SIZES: Dictionary = {"tree0":Vector2(112,136),"tree1":Vector2(112,136),"tree2":Vector2(112,136),"pine":Vector2(80,132),"bush":Vector2(48,32),"rock":Vector2(48,40),"tent":Vector2(112,94),"table":Vector2(64,48),"forge":Vector2(64,60),"sign":Vector2(48,56),"bridge":Vector2(128,78),"column":Vector2(48,94),"wall":Vector2(96,58)}
const TINTS: Dictionary = {"camp":Color(0.96,0.90,0.79),"forest":Color(0.79,0.88,0.85),"creek":Color(0.82,0.91,0.89),"ruins":Color(0.78,0.84,0.90)}
var obstacles: Array[Rect2] = []
var listener: Node2D
var _world: Node2D
var _content: RefCounted = Content.new()
var _textures: Dictionary = {}
var _protected: Array[Vector2] = []
var _connections: Array[PackedVector2Array] = []
var _roots: Array[Vector2] = []
var _props: Array[Node2D] = []
var _trees: Array[Dictionary] = []
var _near_trees: Array[Dictionary] = []
var _lights: Array[PointLight2D] = []
var _mood: CanvasModulate
var _target_tint: Color = TINTS.camp
var _shadow: GradientTexture2D
var _glow: GradientTexture2D
var _atmosphere: Atmosphere
var _cull_timer: float = 0.0
var _clock: float = 0.0
var _built: bool = false

class Atmosphere extends Node2D:
	var motes: Array[Dictionary] = []
	var view: Rect2 = Rect2()
	var clock: float = 0.0
	func _draw() -> void:
		for mote: Dictionary in motes:
			var anchor: Vector2 = mote.point
			if not view.grow(32).has_point(anchor): continue
			var phase: float = clock * float(mote.speed) + float(mote.phase)
			var point: Vector2 = anchor + Vector2(sin(phase)*14,cos(phase*0.71)*7)
			var color: Color = mote.color
			if mote.kind == "spark":
				point = anchor + Vector2(sin(phase*3)*7, -fposmod(phase*12,36))
				color.a *= 1.0-fposmod(phase*12,36)/36.0
			elif mote.kind == "leaf":
				point = anchor + Vector2(sin(phase)*19,fposmod(phase*9,45)-22)
				color.a *= sin(fposmod(phase*9,45)/45*PI)
			else:
				color.a *= 0.35 + 0.65 * (sin(phase*1.8)*0.5+0.5)
			draw_line(point.round(),point.round()+Vector2(2,1 if mote.kind == "leaf" else 0),color,1)

func build(world: Node2D) -> void:
	if _built: return
	_built = true
	_world = world
	position = Vector2.ZERO
	world.y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_shadow = _radial_texture(64,Color(0.07,0.10,0.09,0.44))
	_glow = _radial_texture(192,Color.WHITE)
	var missing: Array[String] = []
	for kind: String in SIZES:
		var path: String = "res://assets/props/%s.png" % kind
		if ResourceLoader.exists(path): _textures[kind] = load(path)
		else: missing.append(kind)
	var quadrants: Dictionary = {"camp":Vector2.ZERO,"forest":Vector2(1200,0),"creek":Vector2(0,800),"ruins":Vector2(1200,800)}
	for key: String in quadrants:
		var terrain: Sprite2D = Sprite2D.new()
		terrain.name = "Terrain_" + key
		terrain.position = quadrants[key]
		terrain.centered = false
		terrain.z_index = -20
		terrain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		terrain.set_meta("category","terrain")
		var path: String = "res://assets/terrain/%s.png" % key
		if ResourceLoader.exists(path): terrain.texture = load(path)
		else: missing.append("terrain/" + key)
		world.add_child(terrain)
	if not missing.is_empty(): push_warning("World art assets not generated/imported (no placeholder substituted): " + ", ".join(missing))
	_prepare_clearance()
	_build_landmarks()
	_scatter()
	_mood = CanvasModulate.new()
	_mood.name = "WorldMood"
	_mood.color = _target_tint
	add_child(_mood)
	# Only two shadow-casting warm lights; cool ruins lights are cheap unshadowed accents.
	_add_light(Vector2(440,464),Color("ffbe77"),1.0,1.2,true)
	_add_light(Vector2(530,1174),Color("ffc17b"),0.85,1.0,true)
	_add_light(Vector2(245,271),Color("ffa960"),0.55,0.65,false)
	_add_light(Vector2(1730,1100),Color("91d2ca"),0.50,0.85,false)
	_add_light(Vector2(1970,1340),Color("8bbdcf"),0.48,0.9,false)
	_build_atmosphere()
	_update_visibility()

func _radial_texture(size: int, center: Color) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0,center)
	gradient.set_color(1,Color(center.r,center.g,center.b,0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	return texture

func _prepare_clearance() -> void:
	for data: Dictionary in _content.actors() + _content.items():
		_protected.append(data.pos)
	for point: Vector2 in _content.centers.values() + _content.checkpoints.values():
		_protected.append(point)
	for point: Vector2 in _protected:
		var closest: Vector2 = ROADS[0][0]
		var distance: float = INF
		for road: PackedVector2Array in ROADS:
			for index: int in range(road.size()-1):
				var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(point,road[index],road[index+1])
				if candidate.distance_squared_to(point) < distance:
					closest = candidate
					distance = candidate.distance_squared_to(point)
		_connections.append(PackedVector2Array([point,closest]))

func _distance_to_path(point: Vector2, path: PackedVector2Array) -> float:
	var distance: float = INF
	for index: int in range(path.size()-1):
		distance = minf(distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,path[index],path[index+1])))
	return distance

func _clear_placement(point: Vector2, radius: float, scatter: bool, separate_roots: bool = true) -> bool:
	for road: PackedVector2Array in ROADS:
		if _distance_to_path(point,road) < 42 + radius: return false
	for path: PackedVector2Array in _connections:
		if _distance_to_path(point,path) < 28 + radius: return false
	for spawn: Vector2 in _protected:
		if point.distance_to(spawn) < 38 + radius: return false
	if _distance_to_path(point,CREEK) < 64 + radius: return false
	if scatter:
		# Camp sightlines and stone altar court are authored, not random thickets.
		if Rect2(225,210,470,370).has_point(point): return false
		if Rect2(1620,1035,440,380).has_point(point): return false
	if separate_roots:
		for other: Vector2 in _roots:
			if point.distance_to(other) < radius + 26: return false
	return true

func _build_landmarks() -> void:
	# Five villagers share the camp; the creek shelter is an unstaffed rest stop.
	for entry: Dictionary in [
		{"kind":"tent","point":Vector2(415,252),"size":Vector2(72,20)},
		{"kind":"tent","point":Vector2(220,418),"size":Vector2(70,20)},
		{"kind":"tent","point":Vector2(656,338),"size":Vector2(70,20)},
		{"kind":"tent","point":Vector2(664,1090),"size":Vector2(70,20),"scale":0.8},
		{"kind":"forge","point":Vector2(245,290),"size":Vector2(40,18)},
		{"kind":"table","point":Vector2(285,375),"size":Vector2(48,16)},
		{"kind":"table","point":Vector2(620,1050),"size":Vector2(48,16)},
		{"kind":"sign","point":Vector2(702,390),"size":Vector2(10,10)},
		{"kind":"sign","point":Vector2(635,1220),"size":Vector2(10,10)}]:
		_place_authored(entry.kind,entry.point,entry.size,float(entry.get("scale",1.0)))
	for point: Vector2 in [Vector2(1635,1090),Vector2(1730,1080),Vector2(1900,1050),Vector2(2030,1090),Vector2(1630,1355),Vector2(1730,1405),Vector2(1985,1415),Vector2(2040,1230)]:
		_place_authored("column",point,Vector2(26,16))
	for point: Vector2 in [Vector2(1650,1020),Vector2(1780,1020),Vector2(1980,1000),Vector2(2130,1140),Vector2(2130,1360),Vector2(1830,1445),Vector2(1980,1470),Vector2(1600,1460)]:
		_place_authored("wall",point,Vector2(82,18))
	# Two rock-arch dens assembled from the real shaded rock sprite. Dark radial
	# ground shade suggests the recess; entrances stay open and have no fake wall.
	for origin: Vector2 in [Vector2(1500,720),Vector2(1080,1010)]:
		var den: Node2D = Node2D.new()
		den.name = "BearDen"
		den.position = origin
		den.z_index = -3
		_world.add_child(den)
		var recess: Sprite2D = Sprite2D.new()
		recess.texture = _shadow
		recess.scale = Vector2(1.5,0.8)
		recess.modulate = Color(0.45,0.5,0.5,1)
		den.add_child(recess)
		for offset: Vector2 in [Vector2(-59,12),Vector2(59,12),Vector2(-48,-27),Vector2(45,-30),Vector2(-15,-40),Vector2(18,-42)]:
			var rock_point: Vector2 = origin+offset
			if _clear_placement(rock_point,22,false,false):
				_prop("rock",rock_point,Vector2(28,17),"landmark",1.25)
	# Bridge deck is ground-level, deliberately below foot-sorted actors.
	for point: Vector2 in [Vector2(337,1201),Vector2(297,980)]:
		var bridge: Node2D = _prop("bridge",point,Vector2.ZERO,"bridge",1.0)
		bridge.z_index = -2
		var deck: Sprite2D = bridge.get_node("Art") as Sprite2D
		deck.position.y += 39

func _place_authored(kind: String, point: Vector2, solid: Vector2, factor: float = 1.0) -> void:
	var radius: float = solid.length() * 0.5 * factor
	if _clear_placement(point,radius,false):
		_prop(kind,point,solid,"landmark",factor)
		return
	# Content connectors are authoritative. Move furniture to the nearest safe
	# shoulder rather than silently dropping the building or blocking an NPC.
	for ring: int in [24,48,72,96]:
		for step: int in range(16):
			var candidate: Vector2 = point+Vector2.from_angle(-PI*0.5+TAU*step/16.0)*ring
			if _clear_placement(candidate,radius,false):
				_prop(kind,candidate.round(),solid,"landmark",factor)
				return
	push_warning("No safe authored prop position: %s at %s" % [kind,str(point)])

func _scatter() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED
	for category: String in ["tree","scatter"]:
		var wanted: int = 200 if category == "tree" else 250
		var placed: int = 0
		for attempt: int in range(24000):
			if placed >= wanted: break
			var point: Vector2 = Vector2(rng.randf_range(48,2352),rng.randf_range(140,1555)).round()
			var factor: float = rng.randf_range(0.86,1.13) if category == "tree" else rng.randf_range(0.80,1.18)
			var kind: String
			var solid: Vector2
			if category == "tree":
				kind = "pine" if rng.randf() < (0.45 if point.y > 800 else 0.22) else "tree"+str(rng.randi_range(0,2))
				solid = Vector2(14,10)
			else:
				kind = "rock" if rng.randf() < 0.35 else "bush"
				solid = Vector2(27,14) if kind == "rock" else Vector2.ZERO
			if not _clear_placement(point,33 if category == "tree" else 15,true): continue
			var node: Node2D = _prop(kind,point,solid,category,factor)
			node.get_node("Art").modulate = Color.from_hsv(rng.randf_range(0.0,0.06),rng.randf_range(0.0,0.07),rng.randf_range(0.90,1.0))
			placed += 1
		if placed != wanted: push_warning("World scatter exhausted: %s %d/%d" % [category,placed,wanted])

func _prop(kind: String, point: Vector2, solid: Vector2, category: String, factor: float) -> Node2D:
	var node: Node2D = Node2D.new()
	node.name = kind.capitalize() + "_" + str(_props.size())
	node.position = point
	node.set_meta("category",category)
	node.set_meta("kind",kind)
	_world.add_child(node)
	_props.append(node)
	_roots.append(point)
	var size: Vector2 = SIZES[kind]
	var shadow: Sprite2D = Sprite2D.new()
	shadow.texture = _shadow
	shadow.position = Vector2(2,-3)
	shadow.scale = Vector2(size.x/64.0*factor,0.24*factor)
	shadow.z_index = -1
	node.add_child(shadow)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Art"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = _textures.get(kind) as Texture2D
	sprite.centered = false
	sprite.position = Vector2(-size.x*0.5,-size.y)*factor
	sprite.scale = Vector2.ONE*factor
	node.add_child(sprite)
	if category == "tree":
		# Separate the bottom trunk from the canopy: transparency never erases
		# the solid base, so cover remains readable while the actor is behind.
		var split: float = 109.0 if kind == "pine" else 108.0
		var trunk: Sprite2D = Sprite2D.new()
		trunk.centered = false
		trunk.position = Vector2(-size.x*0.5,-size.y+split)*factor
		trunk.scale = Vector2.ONE*factor
		trunk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if sprite.texture != null:
			var crown: AtlasTexture = AtlasTexture.new()
			crown.atlas = sprite.texture
			crown.region = Rect2(0,0,size.x,split)
			var bark: AtlasTexture = AtlasTexture.new()
			bark.atlas = sprite.texture
			bark.region = Rect2(0,split,size.x,size.y-split)
			sprite.texture = crown
			trunk.texture = bark
		node.add_child(trunk)
		_trees.append({"root":node,"canopy":sprite,"width":size.x*factor,"height":size.y*factor})
	if solid != Vector2.ZERO:
		var dimensions: Vector2 = solid*factor
		var body: StaticBody2D = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position.y = -dimensions.y*0.5
		var collision: CollisionShape2D = CollisionShape2D.new()
		var rectangle: RectangleShape2D = RectangleShape2D.new()
		rectangle.size = dimensions
		collision.shape = rectangle
		body.add_child(collision)
		node.add_child(body)
		obstacles.append(Rect2(point-Vector2(dimensions.x*0.5,dimensions.y),dimensions))
		# Small trunk/base occluders, not enormous canopy polygons.
		var occluder: LightOccluder2D = LightOccluder2D.new()
		var polygon: OccluderPolygon2D = OccluderPolygon2D.new()
		polygon.polygon = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y),Vector2(dimensions.x/2,-dimensions.y),Vector2(dimensions.x/2,0),Vector2(-dimensions.x/2,0)])
		occluder.occluder = polygon
		node.add_child(occluder)
	return node

func is_blocked(point: Vector2, margin: float = 0.0) -> bool:
	for rectangle: Rect2 in obstacles:
		if rectangle.grow(maxf(0.0,margin)).has_point(point): return true
	return false

func set_region(region: String) -> void:
	if TINTS.has(region): _target_tint = TINTS[region]

func set_listener(node: Node2D) -> void:
	listener = node

func _player() -> Node2D:
	if is_instance_valid(listener): return listener
	if not is_instance_valid(_world): return null
	var main: Node = _world.get_parent()
	if main != null:
		for property: Dictionary in main.get_property_list():
			if property.name == "player": return main.get("player") as Node2D
	return null

func _add_light(point: Vector2, color: Color, energy: float, size: float, shadows: bool) -> void:
	var light: PointLight2D = PointLight2D.new()
	light.position = point
	light.texture = _glow
	light.texture_scale = size
	light.color = color
	light.energy = energy
	light.shadow_enabled = shadows
	light.shadow_filter = Light2D.SHADOW_FILTER_NONE
	light.set_meta("base_energy",energy)
	add_child(light)
	_lights.append(light)

func _build_atmosphere() -> void:
	_atmosphere = Atmosphere.new()
	_atmosphere.z_index = 8
	_atmosphere.light_mask = 0
	add_child(_atmosphere)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED+5
	for index: int in range(92):
		var kind: String = "leaf" if index%3 == 0 else "firefly"
		var point: Vector2 = Vector2(rng.randf_range(150,2210),rng.randf_range(200,1480))
		var color: Color = Color(0.70,0.78,0.45,0.62) if kind == "leaf" else Color(0.90,0.91,0.58,0.75)
		if index < 16:
			kind = "spark"
			point = Vector2(440,460) if index < 8 else Vector2(530,1170)
			color = Color(1.0,0.66,0.28,0.8)
		_atmosphere.motes.append({"kind":kind,"point":point,"color":color,"phase":rng.randf()*TAU,"speed":rng.randf_range(0.4,1.0)})

func _update_visibility() -> void:
	var viewport: Viewport = get_viewport()
	var inverse: Transform2D = viewport.get_canvas_transform().affine_inverse()
	var rect: Rect2 = inverse * viewport.get_visible_rect()
	var view: Rect2 = rect.grow(180)
	for node: Node2D in _props:
		node.visible = view.has_point(node.position)
	_near_trees.clear()
	for tree: Dictionary in _trees:
		if tree.root.visible:
			_near_trees.append(tree)
		else:
			tree.canopy.modulate.a = 1.0
	for light: PointLight2D in _lights:
		light.enabled = view.has_point(light.position)
	_atmosphere.view = rect

func _process(delta: float) -> void:
	if not _built: return
	_clock += delta
	_cull_timer -= delta
	if _cull_timer <= 0:
		_cull_timer = 0.10
		_update_visibility()
		_atmosphere.clock = _clock
		_atmosphere.queue_redraw()
	_mood.color = _mood.color.lerp(_target_tint,1.0-exp(-delta*1.2))
	var player: Node2D = _player()
	for tree: Dictionary in _near_trees:
		var opacity: float = 1.0
		if player != null:
			var relative: Vector2 = player.global_position-tree.root.global_position
			if relative.y < 10 and relative.y > -float(tree.height)+10 and absf(relative.x) < float(tree.width)*0.48:
				opacity = 0.27
		var canopy: Sprite2D = tree.canopy
		canopy.modulate.a = move_toward(canopy.modulate.a,opacity,delta*3.5)
	for index: int in range(_lights.size()):
		var light: PointLight2D = _lights[index]
		if light.enabled and index < 3:
			light.energy = float(light.get_meta("base_energy"))*(1.0+0.035*sin(_clock*5.3+index)+0.02*sin(_clock*9.7))
