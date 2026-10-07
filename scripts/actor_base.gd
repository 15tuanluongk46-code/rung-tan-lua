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
	age += delta
	health.tick(delta)
	action_time = maxf(0, action_time - delta)
	hurt_time = maxf(0, hurt_time - delta)
	if visual != null:
		visual.pose(facing, velocity.length_squared() > 2, "dead" if dead else ("hurt" if hurt_time > 0 else action), age)
	if dead or game.mode != "playing":
		velocity = Vector2.ZERO
		return false
	return true

func receive_hit(amount: int, attack_id: String, source: Node) -> bool:
	var before: int = health.hp
	if dead or faction == "neutral" or not health.hit(amount, attack_id): return false
	hurt_time = 0.18
	game.sfx("hit", position)
	if kind == "player":
		game.state.hp = health.hp
		game.state.damage_taken += before - health.hp
		game.shake = 3.0
	if health.hp <= 0:
		dead = true
		velocity = Vector2.ZERO
		collision_layer = 0
		if visual != null: visual.pose(facing,false,"dead",age)
		if kind == "player": game.player_died()
		else: game.state.kill_actor(actor_id)
	else:
		on_damaged(source)
	return true

func on_damaged(_source: Node) -> void:
	pass

func move_actor(delta: float) -> void:
	move_and_slide()
	position = position.clamp(Vector2(24,24), Vector2(2376,1576))
	if velocity.length_squared() > 1: facing = velocity.normalized()
	if hurt_time > 0: velocity *= maxf(0, 1.0 - delta * 8)
