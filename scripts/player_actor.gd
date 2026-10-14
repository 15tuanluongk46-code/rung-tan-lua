extends "res://scripts/actor_base.gd"
const Abilities = preload("res://scripts/player_abilities.gd")
const Spec = preload("res://scripts/attack_spec.gd")
var abilities: RefCounted = Abilities.new()
var buffered_actions: Dictionary = {}
var attack_cooldown: float = 0.0
var throw_cooldown: float = 0.0
var dodge_cooldown: float = 0.0
var dodge_left: float = 0.0
var dodge_direction: Vector2
var step_clock: float = 0.0
var require_weapon_release: bool = false
var test_aim_enabled: bool = false
var test_aim_position: Vector2 = Vector2.ZERO

func set_test_aim(point: Vector2) -> void:
	# Test-only virtual pointer; never warp the user's desktop cursor.
	if OS.has_feature("release"): return
	for argument: String in OS.get_cmdline_args():
		if argument.contains("res://tests/"):
			test_aim_enabled = true
			test_aim_position = point
			return

func _physics_process(delta: float) -> void:
	if game.mode == "playing":
		for key: String in buffered_actions.keys():
			buffered_actions[key] -= delta
			if buffered_actions[key] <= 0: buffered_actions.erase(key)
		for key: String in ["dodge","throw","heal","interact"]:
			if Input.is_action_just_pressed(key): buffered_actions[key] = 0.15
	else: buffered_actions.clear()
	# Cancellation is processed before advancing to an animation contact boundary.
	if game.mode == "playing" and not dead:
		if buffered_actions.has("interact"):
			consume_action("interact")
			game.interact(true)
			if game.mode != "playing":
				velocity = Vector2.ZERO
				return
		if buffered_actions.has("dodge") and dodge_cooldown <= 0 and (game.combat_freeze_left <= 0 or game.settings.reduced_motion):
			consume_action("dodge")
			visual.cancel_action()
			dodge_left = 0.22
			dodge_cooldown = 0.8
			dodge_direction = Input.get_vector("move_left","move_right","move_up","move_down")
			if dodge_direction.is_zero_approx(): dodge_direction = facing
			health.guard(0.25)
			abilities.begin_dodge()
			game.sfx("dodge",position)
	if not advance(delta): return
	abilities.tick(delta)
	attack_cooldown = maxf(0, attack_cooldown - delta)
	throw_cooldown = maxf(0, throw_cooldown - delta)
	dodge_cooldown = maxf(0, dodge_cooldown - delta)
	dodge_left = maxf(0, dodge_left - delta)
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var aim_position: Vector2 = test_aim_position if test_aim_enabled else get_global_mouse_position()
	var aim: Vector2 = (aim_position - global_position).normalized()
	if aim.length_squared() > 0: facing = aim
	if require_weapon_release and not Input.is_action_pressed("spear") and not Input.is_action_pressed("throw"): require_weapon_release = false
	if dodge_left > 0:
		velocity = dodge_direction * 300
		action = "dodge"
	else:
		velocity = direction * (64 if action_time > 0 else 108) * game.world_events.movement_factor(position)
		if action_time <= 0: action = "run" if direction.length_squared() > 0 else "idle"
		var charge_input: bool = Input.is_action_pressed("charge_modifier") and Input.is_action_pressed("spear") and game.state.skills.has("charge")
		var weapon_busy: bool = visual.rig.active
		var can_start: bool = not weapon_busy and not require_weapon_release
		if charge_input and can_start and not buffered_actions.has("throw") and attack_cooldown <= 0 and not abilities.charging: abilities.begin_charge()
		if abilities.charging:
			velocity *= 0.45
			action = "charge"
			if hurt_time > 0: abilities.cancel_charge()
			elif not charge_input:
				var charged: bool = abilities.release_charge()
				attack_cooldown = 0.8 if charged else 0.44
				action_time = 0.38 if charged else 0.24
				action = "attack"
				var locked_direction: Vector2 = Spec.direction(facing)
				visual.start_action("heavy" if charged else "thrust",locked_direction,func() -> void:
					facing = locked_direction
					game.spear_attack(self,charged))
		elif can_start and buffered_actions.has("throw") and throw_cooldown <= 0:
			consume_action("throw")
			if game.state.stones > 0:
				throw_cooldown = 0.55
				action_time = 0.32
				action = "throw"
				var throw_direction: Vector2 = facing
				visual.start_action("throw",throw_direction,func() -> void:
					if game.state.use_stone():
						game.spawn_projectile(self, throw_direction, "stone")
						game.sfx("stone", position))
			else: game.notify("Không còn đá. Hãy tìm túi tiếp tế.")
		elif can_start and not charge_input and Input.is_action_pressed("spear") and attack_cooldown <= 0:
			attack_cooldown = 0.44
			action_time = 0.24
			action = "attack"
			var locked_direction: Vector2 = Spec.direction(facing)
			visual.start_action("thrust",locked_direction,func() -> void:
				facing = locked_direction
				game.spear_attack(self))
	if consume_action("heal"):
		if game.state.heal():
			health.hp = game.state.hp
			game.sfx("heal", position)
		else: game.notify("Chỉ dùng thuốc khi bị thương và còn bình thuốc.")
	step_clock -= delta
	if velocity.length() > 10 and step_clock <= 0:
		step_clock = 0.36
		game.sfx("step", position)
		game.noise(position, 85)
	var aim_saved: Vector2 = facing
	move_actor(delta)
	facing = aim_saved

func enter_dialogue() -> void:
	visual.cancel_action()
	abilities.cancel_charge()
	buffered_actions.clear()
	action_time = 0
	action = "idle"
	velocity = Vector2.ZERO
	require_weapon_release = true

func receive_hit(amount: int, attack_id: String, source: Node) -> bool:
	if dead: return false
	if health.invulnerable > 0:
		if not health.hits.has(attack_id): abilities.confirm_perfect(game,attack_id,source)
		return false
	var hit: bool = super.receive_hit(amount,attack_id,source)
	if hit:
		abilities.cancel_charge()
		visual.cancel_action()
	return hit

func consume_action(key: String) -> bool:
	if not buffered_actions.has(key): return false
	buffered_actions.erase(key)
	return true
