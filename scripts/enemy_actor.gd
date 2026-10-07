extends "res://scripts/actor_base.gd"
## Stable target until invalid/outside leash. Windups lock attack direction.
var target: Node2D
var ai_state: String = "patrol"
var timer: float = 0.0
var patrol_point: Vector2
var investigation: Vector2
var aim_locked: Vector2 = Vector2.DOWN
var attack_serial: int = 0
var scan_clock: float = 0.0

func _ready() -> void:
	faction = "bear" if kind == "bear" else "goblin"
	patrol_point = home

func _physics_process(delta: float) -> void:
	if not advance(delta):
		caption.text = ""
		return
	timer -= delta
	scan_clock -= delta
	if not valid_target(target): target = null
	if target == null and scan_clock <= 0 and ai_state != "return":
		scan_clock = 0.3
		target = game.find_target(self, 190 if kind == "bear" else 225)
	if target != null and (position.distance_to(home) > 320 or target.position.distance_to(home) > 370):
		target = null
		ai_state = "return"
	if ai_state == "windup":
		velocity = Vector2.ZERO
		facing = aim_locked
		action = "windup"
		caption.text = "!  NÉ NGAY"
		caption.modulate = Color(1,0.55 + sin(age * 30) * 0.3,0.28)
		if timer <= 0:
			execute_attack()
			ai_state = "recover"
			timer = 0.8 if kind == "bear" else 0.65
		return
	caption.modulate = Color.WHITE
	caption.text = "%d / %d" % [health.hp,health.maximum] if target != null or health.hp < health.maximum else ""
	if ai_state == "recover":
		velocity = Vector2.ZERO
		action = "attack" if timer > 0.45 else "idle"
		if timer <= 0: ai_state = "chase"
		return
	var destination: Vector2 = home
	var speed: float = 48 if kind == "bear" else 54
	if target != null:
		ai_state = "chase"
		destination = target.position
		var distance: float = position.distance_to(destination)
		var ranged: bool = kind in ["archer", "shaman"]
		var reach: float = 155 if ranged else 32
		if distance < reach and game.line_clear(position, destination):
			ai_state = "windup"
			timer = 0.85 if kind == "shaman" else (0.65 if kind == "bear" else 0.52)
			aim_locked = (destination - position).normalized()
			velocity = Vector2.ZERO
			return
		if ranged and distance < 80:
			destination = position + (position - target.position).normalized() * 80
	elif ai_state == "investigate" and timer > 0:
		destination = investigation
	elif ai_state == "return":
		if position.distance_to(home) < 12: ai_state = "patrol"
	else:
		ai_state = "patrol"
		if timer <= 0:
			timer = 3.5
			patrol_point = home + Vector2.from_angle(age * 0.43 + float(actor_id.hash() % 31)) * 38
		destination = patrol_point
		speed = 22
	velocity = steer(destination) * speed if position.distance_to(destination) > 8 else Vector2.ZERO
	action = "run" if velocity.length_squared() > 0 else "idle"
	move_actor(delta)

func steer(destination: Vector2) -> Vector2:
	var direction: Vector2 = (destination - position).normalized()
	if game.point_blocked(position + direction * 25, 9):
		for angle: float in [0.7,-0.7,1.4,-1.4,2.2,-2.2]:
			var alternative: Vector2 = direction.rotated(angle)
			if not game.point_blocked(position + alternative * 30, 9): return alternative
		return Vector2.ZERO
	return direction

func valid_target(candidate: Node) -> bool:
	return is_instance_valid(candidate) and not candidate.dead and candidate.faction != faction and candidate.faction != "neutral"

func investigate(point: Vector2) -> void:
	if target == null and ai_state not in ["windup", "return"]:
		investigation = point
		ai_state = "investigate"
		timer = 3.0

func on_damaged(source: Node) -> void:
	if valid_target(source): target = source

func execute_attack() -> void:
	attack_serial += 1
	game.noise(position, 190)
	game.sfx({"archer":"bow","shaman":"magic","bear":"bear"}.get(kind,"attack"), position)
	if kind in ["archer", "shaman"]:
		game.spawn_projectile(self, aim_locked, "magic" if kind == "shaman" else "arrow")
	else:
		for other: Node in game.actors:
			if not valid_target(other): continue
			var offset: Vector2 = other.position - position
			if offset.length() <= (46 if kind == "bear" else 40) and aim_locked.dot(offset.normalized()) > 0.3 and game.line_clear(position, other.position):
				other.receive_hit(28 if kind == "bear" else 16, actor_id + ":" + str(attack_serial), self)
