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

func _ready() -> void:
	if kind == "magic":
		speed = 145
		damage = 22
	elif kind == "stone":
		speed = 285
		damage = 20
	var path: String = "res://assets/props/%s.png" % kind
	if ResourceLoader.exists(path):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = load(path)
		sprite.rotation = direction.angle()
		add_child(sprite)

func _physics_process(delta: float) -> void:
	if game.mode != "playing": return
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
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(actor.position, position, stop)
		var distance: float = position.distance_to(closest)
		if closest.distance_to(actor.position) < 10 and distance < nearest_distance:
			nearest = actor
			nearest_distance = distance
	if nearest != null:
		nearest.receive_hit(damage, attack_id, source)
		game.noise(nearest.position, 170)
		queue_free()
	elif not obstruction.is_empty():
		game.noise(stop, 150)
		queue_free()
	position = stop
