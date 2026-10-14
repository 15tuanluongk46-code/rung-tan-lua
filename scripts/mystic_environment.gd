extends Node2D
## Regional accents, culled to visible world rectangle; no extra shadow lights.
var game: Node
var clock: float = 0.0
var refresh: float = 0.0
var view: Rect2
var mushrooms: Array[Vector2] = []
var mist: Array[Vector2] = []
var ripples: Array[Vector2] = []

func _ready() -> void:
	z_index = -1
	var rng := RandomNumberGenerator.new()
	rng.seed = 92173
	for i: int in range(56):
		mushrooms.append(Vector2(rng.randf_range(1250,2300),rng.randf_range(120,700)))
	for i: int in range(14): mist.append(Vector2(rng.randf_range(1300,2200),rng.randf_range(120,1450)))
	for i: int in range(22): mist.append(Vector2(rng.randf_range(120,1080),rng.randf_range(1660,2320)))
	for i: int in range(44):
		var y: float = 820+i*17
		var x: float = 300 if y < 1060 else (345 if y < 1370 else 365)
		ripples.append(Vector2(x+rng.randf_range(-25,25),y))

func _process(delta: float) -> void:
	if not game.settings.reduced_motion: clock += delta
	refresh -= delta
	if refresh > 0: return
	refresh = 0.08
	view = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	queue_redraw()

func _draw() -> void:
	# Camp lantern posts and smoke stay cosmetic; no new route-blocking bodies.
	for point: Vector2 in [Vector2(355,340),Vector2(580,470),Vector2(490,1110)]:
		if not view.grow(60).has_point(point): continue
		draw_line(point,point-Vector2(0,33),Color("5a4935"),3)
		draw_line(point-Vector2(0,33),point+Vector2(10,-33),Color("b59762"),2)
		draw_rect(Rect2(point+Vector2(6,-31),Vector2(8,11)),Color("312f2b"))
		draw_rect(Rect2(point+Vector2(7,-29),Vector2(6,7)),Color("f3b868"))
		draw_circle(point+Vector2(10,-25),17,Color(1,0.63,0.25,0.07))
	for origin: Vector2 in [Vector2(440,447),Vector2(530,1157)]:
		if not view.grow(80).has_point(origin): continue
		for i: int in range(5):
			var phase: float = fposmod(clock*0.12+i*0.2,1.0)
			var point: Vector2 = origin+Vector2(sin(phase*4+i)*7,-phase*62)
			draw_circle(point,3+phase*9,Color(0.70,0.70,0.61,(1-phase)*0.04))
		# Small flame tongues and ember sparks over the two safe fires.
		var flame: Vector2 = origin + Vector2(0,-7)
		draw_colored_polygon(PackedVector2Array([flame+Vector2(-6,3),flame+Vector2(-2,-13-sin(clock*4.0)*2),flame+Vector2(1,-5),flame+Vector2(5,-16-sin(clock*3.0+1.0)*2),flame+Vector2(7,3)]),Color(1.0,0.55,0.22,0.68))
		draw_circle(flame+Vector2(0,0),4,Color(1.0,0.86,0.48,0.82))
	for point: Vector2 in mushrooms:
		if not view.grow(10).has_point(point): continue
		draw_line(point,point-Vector2(0,5),Color("94b6a0"),1)
		draw_arc(point-Vector2(0,5),3,PI,TAU,6,Color("85c5b0"),2)
		draw_circle(point-Vector2(0,5),5,Color(0.38,0.84,0.7,0.07))
	for i: int in range(ripples.size()):
		var point: Vector2 = ripples[i] + Vector2(sin(clock*0.8+i)*5,fmod(clock*4+i,12))
		if view.grow(15).has_point(point):
			draw_line(point,point+Vector2(8+sin(clock+i)*4,0),Color(0.65,0.89,0.84,0.25),1)
	for i: int in range(mist.size()):
		var point: Vector2 = mist[i] + Vector2(sin(clock*0.09+i)*35,0)
		if not view.grow(110).has_point(point): continue
		for j: int in range(3):
			draw_line(point+Vector2(-70,j*3),point+Vector2(75,j*3),Color(0.65,0.79,0.78,0.025),3)
	# Deliberately restrained moon shafts at forest edges, away from main roads.
	for point: Vector2 in [Vector2(1470,200),Vector2(2100,570)]:
		if view.grow(140).has_point(point):
			draw_colored_polygon(PackedVector2Array([point+Vector2(-25,-90),point+Vector2(0,-90),point+Vector2(115,110),point+Vector2(65,110)]),Color(0.76,0.88,0.73,0.045))
	# Altar runes respond to authoritative quest state and reset on replay.
	var altar := Vector2(1810,1190)
	if view.grow(100).has_point(altar):
		var lit: bool = game.state != null and game.state.altar_lit
		var rune: Color = Color("ffc77d") if lit else Color("70a5a0")
		rune.a = 0.85 if lit else 0.32
		for i: int in range(8):
			var p: Vector2 = altar+Vector2.from_angle(i*TAU/8)*42
			draw_polyline(PackedVector2Array([p+Vector2(-3,2),p+Vector2(0,-4),p+Vector2(3,2),p+Vector2(-3,2)]),rune,1)
		if lit: draw_arc(altar,42,0,TAU,48,Color(1,0.73,0.38,0.35+sin(clock*2)*0.1),1)
	# Southern guide-lights, water glints and glowing coal fissures.
	if game.state != null and game.state.chapter == 2:
		for data: Dictionary in game.content.world_events():
			if not view.grow(70).has_point(data.pos): continue
			if data.kind == "lantern" and game.state.events.has(data.id):
				draw_circle(data.pos+Vector2(0,-22),38,Color(0.8,0.95,0.68,0.10))
				for i: int in range(5):
					var p: Vector2 = data.pos + Vector2(sin(clock*0.8+i)*25,-20+cos(clock+i)*10)
					draw_rect(Rect2(p.round(),Vector2(1,1)),Color("d4e7a0"))
		if view.grow(100).has_point(Vector2(900,2120)):
			var clean: bool = game.state.events.has("well")
			draw_arc(Vector2(900,2100),24+sin(clock*2)*2,0,TAU,24,Color(0.5,0.9,0.85,0.5 if clean else 0.16),1)
