extends "res://scripts/actor_base.gd"
const Geometry = preload("res://scripts/combat_geometry.gd")
const Spec = preload("res://scripts/attack_spec.gd")
var sweep_id: String = ""
var sweep_direction: Vector2 = Vector2.RIGHT
var sweep_enabled: bool = false
var music_owned: bool = false
## Two phases, three distinct locked telegraphs. No unavoidable instant damage.
var ai_state: String = "idle"
var timer: float = 1.0
var phase: int = 1
var attack_serial: int = 0
var attack_kind: int = 0
var aim_locked: Vector2 = Vector2.DOWN
var target_point: Vector2
var hazards: Array[Dictionary] = []
var combo_left: int = 0

func _ready() -> void:
	faction = "goblin"
	target_point = home
	visual.rig.sweep_step.connect(resolve_sweep)

func _physics_process(delta: float) -> void:
	if not advance(delta): return
	for i: int in range(hazards.size()-1,-1,-1):
		hazards[i].age += delta
		if hazards[i].age >= 2.8: hazards.remove_at(i)
		elif hazards[i].age > 0.7 and game.player.position.distance_to(hazards[i].point) < 23:
			game.player.receive_hit(18,actor_id+"_trail_"+str(hazards[i].serial),self)
	queue_redraw()
	if game.state.stage < 5 or game.player.position.distance_to(home) > 290:
		visual.cancel_action()
		release_music()
		hazards.clear()
		queue_redraw()
		caption.text = "Người Giữ Than" if game.player.position.distance_to(home) < 220 else ""
		ai_state = "idle"
		velocity = Vector2.ZERO
		return
	if health.hp <= health.maximum/2 and phase == 1:
		phase = 2
		game.effects.burst(position,"altar")
		game.notify("Người Giữ Than · Pha II — né khỏi vòng than!")
	game.audio.set_region("boss")
	music_owned = true
	timer -= delta
	caption.text = "NGƯỜI GIỮ THAN · %d/%d · PHA %d" % [health.hp,health.maximum,phase]
	if ai_state == "windup":
		velocity = Vector2.ZERO
		action = "windup"
		facing = aim_locked
		if timer <= 0:
			execute_attack()
			if phase == 2 and combo_left > 0:
				combo_left -= 1
				attack_kind = 1 if attack_kind == 0 else 0
				aim_locked = (game.player.position-position).normalized()
				target_point = game.player.position
				timer = 0.9
			else:
				ai_state = "recover"
				timer = 1.15 if phase == 1 else 1.35
	elif ai_state == "recover":
		velocity = Vector2.ZERO
		action = "attack"
		if timer <= 0: ai_state = "chase"
	else:
		var offset: Vector2 = game.player.position-position
		facing = offset.normalized()
		if offset.length() < 82:
			attack_kind = attack_serial%3 if phase == 1 else [0,2,1,0][attack_serial%4]
			combo_left = 1 if phase == 2 and attack_kind == 0 else 0
			aim_locked = facing
			target_point = game.player.position
			ai_state = "windup"
			timer = 0.95 if phase == 1 else 0.75
			action = "windup"
			game.sfx("bear",position)
		else:
			velocity = facing*42
			action = "run"
			move_actor(delta)
	position = position.clamp(Vector2(1700,2100),Vector2(2220,2310))

func execute_attack() -> void:
	var locked_kind: int = attack_kind
	sweep_enabled = locked_kind == 0
	sweep_id = ""
	var locked_direction: Vector2 = aim_locked
	if locked_kind == 0: locked_direction = Spec.direction(aim_locked)
	var locked_point: Vector2 = target_point
	visual.start_action("slam" if locked_kind == 1 else "sweep",locked_direction,func() -> void: resolve_attack(locked_kind,locked_direction,locked_point))

func resolve_attack(locked_kind: int, locked_direction: Vector2, locked_point: Vector2) -> void:
	attack_serial += 1
	game.sfx("attack",position)
	if locked_kind == 0:
		sweep_id = actor_id+":sweep:"+str(attack_serial)
		sweep_direction = locked_direction
	elif locked_kind == 1:
		game.effects.burst(locked_point,"altar_pulse")
		if locked_point.distance_to(game.player.position) < 52: game.player.receive_hit(28,actor_id+str(attack_serial),self)
	else:
		for i: int in range(4): hazards.append({"point":position+locked_direction*(30+i*28),"age":0.0,"serial":attack_serial})

func resolve_sweep(first: float, last: float) -> void:
	if dead or not sweep_enabled or sweep_id.is_empty() or game.state.stage < 5: return
	var offset: Vector2 = game.player.position-position
	var relative: float = wrapf(offset.angle()-sweep_direction.angle(),-PI,PI)
	if offset.length() <= Geometry.BOSS_RADIUS and relative >= first-0.0001 and relative <= last+0.0001 and game.line_clear(position,game.player.position):
		game.player.receive_hit(24,sweep_id,self)

func receive_hit(amount: int, attack_id: String, source: Node) -> bool:
	if game.state.stage < 5: return false
	var hit: bool = super.receive_hit(amount,attack_id,source)
	if hit and dead:
		sweep_id = ""
		hazards.clear()
		visual.cancel_action()
		ai_state = "idle"
		queue_redraw()
		game.state.complete_event("boss")
		game.world_events.refresh_state()
		game.notify("Tháp Lửa đã yên. Trở về An để khép lại hành trình.")
		release_music()
	return hit

func release_music() -> void:
	if music_owned and game.audio != null:
		game.audio.set_region(game.content.region_at(game.player.position))
	music_owned = false

func interrupt(duration: float) -> void:
	# Charged attacks reward recovery timing, never delete a boss telegraph.
	if ai_state == "recover" and not dead: timer = minf(1.7,timer+duration*0.4)

func _draw() -> void:
	if dead: return
	for hazard: Dictionary in hazards:
		draw_arc(hazard.point-position,23,0,TAU,20,Color(1,0.55,0.22,0.7),2)
		if hazard.age > 0.7: draw_circle(hazard.point-position,21,Color(1,0.24,0.08,0.25))
	if ai_state != "windup": return
	var color := Color(1,0.72,0.3,0.8)
	if attack_kind == 0:
		var half_angle: float = acos(Geometry.BOSS_DOT)
		var shown_direction: Vector2 = Spec.direction(aim_locked)
		draw_colored_polygon(Geometry.sector(shown_direction,Geometry.BOSS_RADIUS,Geometry.BOSS_DOT),Color(color,0.045))
		draw_arc(Vector2.ZERO,Geometry.BOSS_RADIUS,shown_direction.angle()-half_angle,shown_direction.angle()+half_angle,32,color,2)
	elif attack_kind == 1:
		draw_arc(target_point-position,52,0,TAU,32,color,2)
		draw_circle(target_point-position,52,Color(1,0.4,0.2,0.045))
	else: draw_line(aim_locked*30,aim_locked*115,color,4)
