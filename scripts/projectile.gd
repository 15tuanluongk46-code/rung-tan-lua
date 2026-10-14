extends Node2D
## Swept ray + segment-target distance prevents tunnelling; obstacles win ties.
var game: Node
var source: Node
var direction: Vector2
var kind: String
var attack_id: String
var lifetime: float = 2.6
var speed: float = 220
var damage: int = 20
var stagger: float = 0.0
var visual_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if kind == "magic":
		speed = 145
		damage = 22
	elif kind == "stone":
		speed = 285
		damage = 20
	var path: String = "res://assets/props/%s.png" % kind
	var trail: Line2D = Line2D.new()
	trail.width = 1.5 if kind != "magic" else 2.0
	trail.default_color = {"stone":Color("e3c28b"),"arrow":Color("f2d08a"),"magic":Color("c6a3ff")}.get(kind, Color.WHITE)
	trail.default_color.a = 0.55
	trail.points = PackedVector2Array([-direction*14,Vector2.ZERO])
	trail.z_index = -1
	trail.position = visual_offset
	add_child(trail)
	if ResourceLoader.exists(path):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = load(path)
		sprite.rotation = direction.angle()
		sprite.position = visual_offset
		add_child(sprite)

func _physics_process(delta: float) -> void:
	if game.mode != "playing": return
	if game.combat_freeze_left > 0 and not game.settings.reduced_motion: return
	lifetime -= delta
	if lifetime <= 0:
		game.noise(position, 140)
		queue_free()
		return
	var end: Vector2 = position + direction * speed * delta
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(position,end,1)
	var obstruction: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	var stop: Vector2 = obstruction.get("position", end)
	var nearest: Node = null
	var nearest_distance: float = position.distance_to(stop) + 0.01
	for actor: Node in game.actors:
		if actor == source or actor.dead or actor.faction == "neutral": continue
		if is_instance_valid(source) and actor.faction == source.faction: continue
		# A target's hit radius must not reach backwards through a wall.
		if not game.line_clear(position,actor.position): continue
		if not obstruction.is_empty() and (actor.position - position).dot(direction) >= (stop - position).dot(direction): continue
		var offset: Vector2 = actor.position-position
		var along: float = offset.dot(direction)
		var perpendicular_sq: float = maxf(0,offset.length_squared()-along*along)
		if perpendicular_sq >= 100: continue
		var half_chord: float = sqrt(100-perpendicular_sq)
		if along+half_chord < 0: continue
		var distance: float = maxf(0,along-half_chord)
		if distance <= position.distance_to(stop) and distance < nearest_distance:
			nearest = actor
			nearest_distance = distance
	if nearest != null:
		if nearest.receive_hit(damage, attack_id, source) and stagger > 0 and nearest.has_method("interrupt"): nearest.interrupt(stagger)
		if game.effects != null: game.effects.burst(nearest.position, "projectile_impact", direction)
		game.noise(nearest.position, 170)
		queue_free()
	elif not obstruction.is_empty():
		if game.effects != null: game.effects.burst(stop, "wall_impact", direction)
		game.noise(stop, 150)
		queue_free()
	position = stop
