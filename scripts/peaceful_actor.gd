extends "res://scripts/actor_base.gd"
var wander_clock: float = 0.0
var destination: Vector2
var panic: float = 0.0
var wildlife: bool = false

func _ready() -> void:
	wildlife = kind in ["deer", "rabbit", "bird"]
	destination = home

func _physics_process(delta: float) -> void:
	if not advance(delta): return
	if not wildlife:
		caption.text = display_name if position.distance_to(game.player.position) < 90 else ""
		facing = (game.player.position - position).normalized() if position.distance_to(game.player.position) < 65 else Vector2.DOWN
		action = "work" if sin(age * 0.7) > 0 else "idle"
		return
	panic = maxf(0, panic - delta)
	wander_clock -= delta
	var threat: Node2D = game.player
	if position.distance_to(threat.position) < 85:
		panic = 1.5
		destination = position + (position - threat.position).normalized() * 150
	if wander_clock <= 0 and panic <= 0:
		wander_clock = 3.0 + float(actor_id.hash() % 4)
		destination = home + Vector2.from_angle(age * 0.3 + float(actor_id.hash() % 31)) * 65
	var direction: Vector2 = (destination - position).normalized()
	velocity = direction * (125 if panic > 0 else 20) if position.distance_to(destination) > 8 else Vector2.ZERO
	if game.point_blocked(position + direction * 20, 8):
		velocity = direction.rotated(PI / 2) * 30
	action = "flee" if panic > 0 else ("run" if velocity.length() > 1 else "idle")
	move_actor(delta)

func investigate(point: Vector2) -> void:
	if wildlife:
		panic = 2.0
		destination = position + (position - point).normalized() * 180
