extends "res://scripts/actor_base.gd"
const Geometry = preload("res://scripts/combat_geometry.gd")
## Stable target until invalid/outside leash. Windups lock attack direction.
var target: Node2D
var ai_state: String = "patrol"
var timer: float = 0.0
var patrol_point: Vector2
var investigation: Vector2
var aim_locked: Vector2 = Vector2.DOWN
var attack_serial: int = 0
var scan_clock: float = 0.0
var coal_hazards: Array[Dictionary] = []
var rush_left: float = 0.0

func _ready() -> void:
	faction = "bear" if kind == "bear" else "goblin"
	patrol_point = home

func _physics_process(delta: float) -> void:
	if not advance(delta):
		caption.text = ""
		return
	# New southern encounters sleep outside player view; global history is retained.
	if kind in ["stalker","coal"] and position.distance_to(game.player.position) > 420:
		velocity = Vector2.ZERO
		caption.text = ""
		return
	timer -= delta
	var had_hazards: bool = not coal_hazards.is_empty()
	for i: int in range(coal_hazards.size()-1,-1,-1):
		coal_hazards[i].age += delta
		if coal_hazards[i].age > 2.2: coal_hazards.remove_at(i)
		elif coal_hazards[i].age > 0.6 and game.player.position.distance_to(coal_hazards[i].point) < 21:
			game.player.receive_hit(10,actor_id+"_trail_"+str(coal_hazards[i].serial),self)
	if had_hazards or kind == "stalker": queue_redraw()
	if ai_state == "rush":
		rush_left -= delta
		velocity = aim_locked*190
		action = "attack"
		var blocked: bool = game.point_blocked(position+aim_locked*14,8)
		if blocked: rush_left = 0
		else:
			move_actor(delta)
			for other: Node in game.actors:
				if valid_target(other) and position.distance_to(other.position) < 23 and game.line_clear(position,other.position):
					other.receive_hit(18,actor_id+":rush:"+str(attack_serial),self)
		if rush_left <= 0:
			ai_state = "recover"
			timer = 0.85
		return
	if kind == "stalker":
		visual.sprite.modulate.a = 1.0 if game.world_events.is_lit(position) or ai_state in ["windup","recover"] else 0.55
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
		caption.modulate = Color(1,0.8 if game.settings.reduced_flash else 0.55 + sin(age * 30) * 0.3,0.28)
		if timer <= 0:
			if kind == "stalker":
				attack_serial += 1
				ai_state = "rush"
				rush_left = 0.38
				return
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
	var speed: float = 48 if kind == "bear" else (66 if kind == "stalker" else (42 if kind == "coal" else 54))
	if target != null:
		ai_state = "chase"
		destination = target.position
		var distance: float = position.distance_to(destination)
		var ranged: bool = kind in ["archer", "shaman"]
		var reach: float = 155 if ranged else 32
		if kind == "stalker": reach = 94
		if ranged and distance < 75:
			velocity = steer(position+(position-target.position).normalized()*90)*speed
			action = "run"
			move_actor(delta)
			return
		if kind == "stalker" and distance > reach:
			destination = target.position + (position-target.position).normalized().rotated(0.45)*65
		if distance < reach and game.line_clear(position, destination):
			ai_state = "windup"
			timer = 0.85 if kind in ["shaman","coal"] else (0.65 if kind == "bear" else 0.52)
			if kind == "stalker": timer = 0.7 if game.world_events.is_lit(position) else 0.6
			aim_locked = (destination - position).normalized()
			if kind == "melee": aim_locked = visual.rig.Spec.direction(aim_locked)
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
	var animation: String = {"archer":"bow","shaman":"cast","coal":"slam"}.get(kind,"thrust")
	visual.start_action(animation,aim_locked,resolve_attack)

func resolve_attack() -> void:
	attack_serial += 1
	game.noise(position, 190)
	game.sfx({"archer":"bow","shaman":"magic","bear":"bear"}.get(kind,"attack"), position)
	if kind in ["archer", "shaman"]:
		game.spawn_projectile(self, aim_locked, "magic" if kind == "shaman" else "arrow")
	else:
		if kind == "coal":
			if coal_hazards.size() >= 2: coal_hazards.pop_front()
			coal_hazards.append({"point":position+aim_locked*30,"age":0.0,"serial":attack_serial})
		for other: Node in game.actors:
			if not valid_target(other): continue
			var offset: Vector2 = other.position - position
			if Geometry.contains(offset,aim_locked,Geometry.BEAR_RADIUS if kind == "bear" else Geometry.MELEE_RADIUS,Geometry.MELEE_DOT) and game.line_clear(position, other.position):
				other.receive_hit(28 if kind == "bear" else (22 if kind == "coal" else 16), actor_id + ":" + str(attack_serial), self)

func interrupt(duration: float) -> void:
	if dead: return
	visual.cancel_action()
	ai_state = "recover"
	timer = duration
	rush_left = 0
	velocity = Vector2.ZERO

func receive_hit(amount: int, attack_id: String, source: Node) -> bool:
	var hit: bool = super.receive_hit(amount,attack_id,source)
	if dead:
		coal_hazards.clear()
		queue_redraw()
	return hit

func _draw() -> void:
	if dead: return
	for hazard: Dictionary in coal_hazards:
		draw_arc(hazard.point-position,21,0,TAU,24,Color("eaae65"),1)
		if hazard.age > 0.6: draw_circle(hazard.point-position,20,Color(1,0.3,0.1,0.2))
	if kind == "stalker" and ai_state == "windup":
		draw_line(Vector2.ZERO,aim_locked*95,Color(0.6,0.9,0.8,0.65),4)
		draw_arc(aim_locked*95,23,0,TAU,20,Color(0.6,0.9,0.8,0.55),1)
	elif kind == "stalker" and ai_state in ["chase","patrol"]:
		for i: int in range(3): draw_line(Vector2(-4,-i*7),Vector2(-1,-i*7+2),Color(0.5,0.8,0.7,0.4),1)
