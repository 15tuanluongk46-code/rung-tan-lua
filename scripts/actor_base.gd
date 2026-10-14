extends CharacterBody2D
const Health = preload("res://scripts/combat_health.gd")
var game: Node
var actor_id: String
var kind: String
var display_name: String
var home: Vector2
var health: RefCounted
var visual: Node2D
var facing: Vector2 = Vector2.DOWN
var action: String = "idle"
var action_time: float = 0.0
var age: float = 0.0
var dead: bool = false
var hurt_time: float = 0.0
var faction: String = "neutral"
var caption: Label
var caption_size: int = -1

func setup(owner_game: Node, data: Dictionary, maximum: int = 100) -> void:
	game = owner_game
	actor_id = data.id
	kind = data.kind
	display_name = data.get("name", "")
	home = data.pos
	position = home
	health = Health.new(maximum)
	collision_layer = 2
	collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 7 if kind != "bear" else 12
	shape.shape = circle
	add_child(shape)
	if ResourceLoader.exists("res://scripts/actor_visual.gd"):
		visual = load("res://scripts/actor_visual.gd").new()
		add_child(visual)
		visual.setup(kind)
	caption = Label.new()
	caption.position = Vector2(-65,-52)
	caption.size = Vector2(130,20)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", Color("f6d89b"))
	caption.add_theme_color_override("font_shadow_color", Color("171315"))
	caption.add_theme_constant_override("shadow_offset_x", 1)
	caption.add_theme_constant_override("shadow_offset_y", 1)
	add_child(caption)

func advance(delta: float) -> bool:
	if game.mode != "playing":
		velocity = Vector2.ZERO
		return false
	if game.combat_freeze_left > 0 and not game.settings.reduced_motion:
		return false
	if visual != null and not dead:
		visual.tick_action(delta)
		if game.mode != "playing" or dead: return false
		if game.combat_freeze_left > 0 and not game.settings.reduced_motion: return false
	age += delta
	health.tick(delta)
	action_time = maxf(0, action_time - delta)
	hurt_time = maxf(0, hurt_time - delta)
	if visual != null:
		var size: int = 12 if game.settings.large_text else 10
		if size != caption_size:
			caption_size = size
			caption.add_theme_font_size_override("font_size",size)
		visual.flash = maxf(0,visual.flash-delta)
		visual.reduced_motion = game.settings.reduced_motion
		visual.reduced_flash = game.settings.reduced_flash
		visual.pose(facing, velocity.length_squared() > 2, "dead" if dead else ("hurt" if hurt_time > 0 else action), age)
	if dead or game.mode != "playing":
		velocity = Vector2.ZERO
		return false
	return true

func receive_hit(amount: int, attack_id: String, source: Node) -> bool:
	var before: int = health.hp
	if dead or faction == "neutral" or not health.hit(amount, attack_id): return false
	hurt_time = 0.18
	if visual != null:
		visual.flash = 0.18
	game.sfx("hit", position)
	if game.effects != null:
		game.effects.burst(position, "impact", (position - source.position).normalized() if is_instance_valid(source) else Vector2.UP)
	game.trigger_hitstop(0.045 if kind != "bear" else 0.065)
	if kind == "player":
		game.state.hp = health.hp
		game.state.damage_taken += before - health.hp
		game.state.changed.emit()
		game.shake = clampf(2.5 + float(before - health.hp) * 0.055, 2.5, 7.0)
		if game.effects != null: game.effects.burst(position, "hurt", facing)
	if health.hp <= 0:
		dead = true
		velocity = Vector2.ZERO
		collision_layer = 0
		if visual != null: visual.cancel_action()
		if visual != null: visual.pose(facing,false,"dead",age)
		if game.effects != null: game.effects.burst(position, "death", facing)
		if kind == "player": game.player_died()
		else: game.state.kill_actor(actor_id)
	else:
		on_damaged(source)
	return true

func on_damaged(_source: Node) -> void:
	pass

func move_actor(delta: float) -> void:
	if hurt_time > 0: velocity *= maxf(0, 1.0 - delta * 8)
	move_and_slide()
	position = position.clamp(Vector2(24,24), game.content.SIZE-Vector2(24,24))
	if velocity.length_squared() > 1: facing = velocity.normalized()
