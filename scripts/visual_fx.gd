extends Node2D
## Bounded cosmetic effects. Never mutate combat/state or create physics bodies.
const MAX_BURSTS: int = 48
var bursts: Array[Dictionary] = []

func _ready() -> void:
	z_index = 12
	var material_fx := CanvasItemMaterial.new()
	material_fx.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = material_fx

func burst(point: Vector2, kind: String, direction: Vector2 = Vector2.UP) -> void:
	if bursts.size() >= MAX_BURSTS: bursts.pop_front()
	var duration: float = 1.2 if kind in ["ember","altar","altar_pulse"] else (0.62 if kind in ["death","ember_pickup"] else 0.42)
	bursts.append({"point":point,"kind":kind,"direction":direction.normalized(),"age":0.0,"duration":duration})

func _process(delta: float) -> void:
	var owner_game: Node = get_parent().get_parent()
	if owner_game.get("mode") not in ["playing","test"]: return
	var had_bursts: bool = not bursts.is_empty()
	for i: int in range(bursts.size()-1,-1,-1):
		bursts[i].age += delta
		if bursts[i].age >= bursts[i].duration: bursts.remove_at(i)
	if had_bursts: queue_redraw()

func _draw() -> void:
	var settings: RefCounted = get_parent().get_parent().settings
	for effect: Dictionary in bursts:
		var t: float = effect.age/effect.duration
		var color := Color("ffd18a")
		if effect.kind == "hit": color = Color("fff0c2")
		elif effect.kind == "heal": color = Color("91e5b6")
		elif effect.kind == "dodge": color = Color("b5e1d8")
		elif effect.kind in ["hurt", "death"]: color = Color("ff9a70")
		elif effect.kind in ["magic", "projectile_impact"]: color = Color("c6a3ff")
		elif effect.kind == "wall_impact": color = Color("d2d7bc")
		elif effect.kind == "ember_pickup": color = Color("ffe39b")
		elif effect.kind in ["swing", "stone"]: color = Color("f7d48d")
		elif effect.kind == "altar_pulse": color = Color("ffc77d")
		color.a = (1-t)*0.9
		var origin: Vector2 = effect.point + Vector2(0,-12)
		var count: int = 16 if effect.kind in ["altar","altar_pulse","ember","ember_pickup"] else (10 if effect.kind in ["death","projectile_impact"] else 7)
		if settings.reduced_motion: count = 3
		for i: int in range(count):
			var angle: float = TAU*i/count + 0.31
			var radius: float = t*(52 if effect.kind in ["altar","altar_pulse"] else (38 if effect.kind in ["death","ember_pickup"] else 25))
			if settings.reduced_motion: radius = 6
			var point: Vector2 = origin + Vector2.from_angle(angle)*radius + Vector2(0,-t*12)
			var size: Vector2 = Vector2(2,2) if effect.kind not in ["death","swing"] else Vector2(3,2)
			draw_rect(Rect2(point.round(),size),color)
		if effect.kind in ["altar","altar_pulse","ember","ember_pickup","heal","impact","projectile_impact","wall_impact"]:
			draw_arc(origin,8+t*(42 if effect.kind in ["altar","altar_pulse"] else 32),0,TAU,32,Color(color, color.a*0.65),1)
		if effect.kind == "swing":
			var angle: float = effect.direction.angle()
			draw_arc(effect.point + Vector2(0,-10),24+t*9,angle-0.75,angle+0.75,14,Color(color,color.a),2)
		if effect.kind in ["hurt","death"] and not settings.reduced_flash:
			var flash_alpha: float = 0.36*(1.0-t)
			draw_circle(effect.point + Vector2(0,-14),14+t*10,Color(1.0,0.27,0.18,flash_alpha))
		if effect.kind == "dodge":
			var back: Vector2 = -effect.direction*18
			draw_line(origin,origin+back*(1.0-t),Color(color,color.a*0.8),2)
