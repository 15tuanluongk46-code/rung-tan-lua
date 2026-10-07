extends "res://scripts/actor_base.gd"
var attack_cooldown: float = 0.0
var throw_cooldown: float = 0.0
var dodge_cooldown: float = 0.0
var dodge_left: float = 0.0
var dodge_direction: Vector2
var step_clock: float = 0.0

func _physics_process(delta: float) -> void:
	if not advance(delta): return
	attack_cooldown = maxf(0, attack_cooldown - delta)
	throw_cooldown = maxf(0, throw_cooldown - delta)
	dodge_cooldown = maxf(0, dodge_cooldown - delta)
	dodge_left = maxf(0, dodge_left - delta)
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var aim: Vector2 = (get_global_mouse_position() - global_position).normalized()
	if aim.length_squared() > 0: facing = aim
	if Input.is_action_just_pressed("dodge") and dodge_cooldown <= 0:
		dodge_left = 0.22
		dodge_cooldown = 0.8
		dodge_direction = direction if direction.length_squared() > 0 else facing
		health.guard(0.25)
		game.sfx("dodge", position)
	if dodge_left > 0:
		velocity = dodge_direction * 300
		action = "dodge"
	else:
		velocity = direction * (64 if action_time > 0 else 108)
		if action_time <= 0: action = "run" if direction.length_squared() > 0 else "idle"
		if Input.is_action_pressed("spear") and attack_cooldown <= 0:
			attack_cooldown = 0.44
			action_time = 0.24
			action = "attack"
			game.spear_attack(self)
		if Input.is_action_just_pressed("throw") and throw_cooldown <= 0:
			if game.state.use_stone():
				throw_cooldown = 0.55
				action_time = 0.25
				action = "throw"
				game.spawn_projectile(self, facing, "stone")
				game.sfx("stone", position)
			else: game.notify("Không còn đá. Hãy tìm túi tiếp tế.")
	if Input.is_action_just_pressed("heal"):
		if game.state.heal():
			health.hp = game.state.hp
			game.sfx("heal", position)
		else: game.notify("Chỉ dùng thuốc khi bị thương và còn bình thuốc.")
	if Input.is_action_just_pressed("interact"): game.interact()
	step_clock -= delta
	if velocity.length() > 10 and step_clock <= 0:
		step_clock = 0.36
		game.sfx("step", position)
		game.noise(position, 85)
	var aim_saved: Vector2 = facing
	move_actor(delta)
	facing = aim_saved
