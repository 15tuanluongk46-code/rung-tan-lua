extends Node2D
const Geometry = preload("res://scripts/combat_geometry.gd")
const WeaponRig = preload("res://scripts/weapon_rig.gd")
var rig: WeaponRig
var reduced_motion: bool = false
var reduced_flash: bool = false
## Four-facing original pixel sprites; grounded animation and legible action poses.
var sprite: Sprite2D
var kind: String = "player"
var shadow: Sprite2D
var flash: float = 0.0
var last_action: String = ""
var action_started: float = 0.0
var trail: Line2D
var cue_direction: Vector2 = Vector2.DOWN
var cue_action: String = "idle"
var cue_phase: float = 0.0
var body_texture: Texture2D
var attack_texture: Texture2D
var cloak: Sprite2D
var cloak_idle: Texture2D
var cloak_attack: Texture2D
var player_reference: Texture2D
var player_motion: RefCounted

func setup(actor_kind: String) -> void:
	kind = actor_kind
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow = Sprite2D.new()
	var image: Image = Image.create(32, 12, false, Image.FORMAT_RGBA8)
	for y: int in range(12):
		for x: int in range(32):
			var distance: float = Vector2((float(x)-16.0)/16.0,(float(y)-6.0)/6.0).length()
			if distance < 0.85: image.set_pixel(x,y,Color(0.03,0.09,0.09,0.30 if distance < 0.5 else 0.16))
	shadow.texture = ImageTexture.create_from_image(image)
	shadow.position.y = -1
	shadow.scale = Vector2(1.2,1.0) if kind == "bear" else Vector2(0.7,0.65)
	add_child(shadow)
	sprite = Sprite2D.new()
	var body_path: String = "res://assets/layers/%s_body.png" % kind
	sprite.texture = load(body_path) if ResourceLoader.exists(body_path) else load("res://assets/sprites/%s.png" % kind)
	body_texture = sprite.texture
	var attack_path: String = "res://assets/layers/%s_poses.png" % kind
	if ResourceLoader.exists(attack_path): attack_texture = load(attack_path)
	sprite.hframes = 6
	sprite.vframes = 4
	sprite.position = Vector2(0,-21)
	var outline := ShaderMaterial.new()
	outline.shader = preload("res://assets/shaders/actor_readability.gdshader")
	outline.set_shader_parameter("rim_strength",0.28 if kind == "player" else 0.10)
	sprite.material = outline
	add_child(sprite)
	if kind == "player":
		player_reference = load("res://assets/sprites/player.png")
		player_motion = preload("res://scripts/player_motion.gd").new()
		cloak = Sprite2D.new()
		cloak_idle = load("res://assets/layers/player_cloak.png")
		cloak_attack = load("res://assets/layers/player_cloak_poses.png")
		cloak.z_index = 3
		add_child(cloak)
	trail = Line2D.new()
	trail.width = 2.0
	trail.default_color = Color("f6d7a1")
	trail.visible = false
	add_child(trail)
	if kind in ["player","melee","archer","shaman","hunter","smith","guardian","coal"]:
		rig = WeaponRig.new()
		rig.position = Vector2(0,-13)
		add_child(rig)
		rig.setup(kind)

func start_action(name: String, direction: Vector2, callback: Callable) -> void:
	if rig != null: rig.start(name,direction,callback)
	else: callback.call()

func tick_action(delta: float) -> void:
	if rig != null: rig.tick(delta)

func cancel_action() -> void:
	if rig != null: rig.cancel()

func pose(facing: Vector2, moving: bool, action: String, elapsed: float) -> void:
	if sprite == null: return
	if kind == "player":
		pose_player(facing,moving,action,elapsed)
		return
	if rig != null and rig.active:
		facing = rig.attack_direction
		action = "attack"
	if action != last_action:
		action_started = elapsed
		last_action = action
	var phase: float = elapsed - action_started
	cue_direction = facing
	cue_action = action
	cue_phase = phase
	queue_redraw()
	var row: int = 0
	if absf(facing.x) > absf(facing.y): row = 1 if facing.x < 0 else 2
	elif facing.y < 0: row = 3
	var frame: int = 0
	if moving: frame = 1 + int(elapsed * (12.0 if action == "flee" else 8.0)) % 3
	elif int(elapsed * 1.2) % 4 == 3: frame = 2
	sprite.rotation = 0
	sprite.scale = Vector2.ONE
	sprite.position = Vector2(0,-21)
	sprite.modulate = Color(1.0, 0.86, 0.72) if flash > 0.0 and (reduced_flash or int(elapsed*28.0) % 2 == 0) else Color.WHITE
	trail.visible = false
	trail.modulate = Color.WHITE
	shadow.modulate.a = 1
	shadow.scale = Vector2(1.2,1.0) if kind == "bear" else Vector2(0.7,0.65)
	if action == "windup":
		frame = 4
		sprite.position -= facing * 3
		sprite.modulate = Color(1.0,0.83 if reduced_flash else 0.78 + 0.15*sin(phase*25),0.66)
	elif action == "charge":
		frame = 4
		sprite.position -= facing*3
		sprite.modulate = Color(1.0,0.9,0.55) if phase >= 0.55 else Color(0.85,0.95,1.0)
	elif action in ["attack","throw","work"]:
		frame = 4 if int(phase * 9) % 3 != 2 else 0
		var thrust: float = sin(minf(phase * 9,PI))
		sprite.position += facing * thrust * 3
		if rig == null and action == "attack" and phase < 0.3:
			trail.visible = true
			trail.clear_points()
			var angle: float = facing.angle()
			for i: int in range(9):
				var a: float = angle - 0.65 + float(i)/8.0*1.3
				trail.add_point(Vector2(cos(a),sin(a))*25.0 + Vector2(0,-10))
			trail.modulate.a = maxf(0,1-phase/0.3)
		if rig == null and action == "throw" and phase < 0.28:
			trail.visible = true
			trail.clear_points()
			trail.add_point(Vector2(-8, -8))
			trail.add_point(facing * 20.0 + Vector2(0,-8))
			trail.modulate = Color(0.95,0.78,0.45,maxf(0,1-phase/0.28))
	elif action == "dodge":
		frame = 2
		sprite.rotation = facing.x * 0.35
		sprite.position.y -= sin(minf(phase*12,PI))*5
		shadow.modulate.a = 0.5
		sprite.scale = Vector2(1.0,0.88)
	elif action == "hurt":
		frame = 5
		if not reduced_motion: sprite.position.x += sin(phase*70)*2
		sprite.scale = Vector2(0.95,1.03)
	elif action == "dead":
		frame = 5
		sprite.rotation = PI*0.5
		sprite.position = Vector2(0,-7)
		sprite.modulate = Color(0.57,0.57,0.5,0.76)
		shadow.scale.x = 1.0
	if kind == "bird" and action == "flee": sprite.position.y -= 12 + sin(elapsed*5)*3
	if rig != null:
		if not rig.active: rig.position = Vector2(0,-13)+sprite.position-Vector2(0,-21)
		else:
			sprite.position = Vector2(0,-21)+rig.attack_direction*rig.body_push
			rig.position = Vector2(0,-13)+rig.attack_direction*rig.body_push
		rig.update_pose(facing,action,phase)
	if rig != null and rig.active and attack_texture != null:
		sprite.texture = attack_texture
		sprite.hframes = 3
		sprite.vframes = 8
		sprite.frame = rig.pose_octant*3+rig.pose_stage
	else:
		sprite.texture = player_reference if kind == "player" and not action in ["charge","windup"] else body_texture
		sprite.hframes = 6
		sprite.vframes = 4
		sprite.frame = row * 6 + frame
	if cloak != null:
		var reference_rest: bool = sprite.texture == player_reference
		cloak.visible = not reference_rest
		# The approved sheet already contains compact hands and the carried spear.
		# Keep the animation clock alive but do not draw duplicate idle limbs/weapon.
		rig.weapon.visible = rig.weapon.visible and not reference_rest
		rig.arms_visible = rig.arms_visible and not reference_rest
		rig.queue_redraw()
		rig.rear_arms.queue_redraw()
		rig.front_arms.queue_redraw()
		cloak.texture = cloak_attack if rig.active else cloak_idle
		cloak.hframes = sprite.hframes
		cloak.vframes = sprite.vframes
		cloak.frame = sprite.frame
		cloak.position = sprite.position
		cloak.rotation = sprite.rotation
		cloak.scale = sprite.scale
		cloak.modulate = sprite.modulate

func pose_player(facing: Vector2, moving: bool, action: String, elapsed: float) -> void:
	if rig.active:
		facing = rig.attack_direction
		action = "attack"
	if action != last_action:
		action_started = elapsed
		last_action = action
	var phase: float = maxf(0,elapsed-action_started)
	cue_direction = facing
	cue_action = action
	cue_phase = phase
	rig.update_pose(facing,action,phase)
	var octant: int = posmod(roundi(facing.angle()/(PI/4)),8)
	if rig.active:
		player_motion.apply(sprite,rig.action_name,octant,rig.animator.current_animation_position)
	elif action in ["charge","windup","dodge","hurt","dead"]:
		var motion: String = "charge" if action == "windup" else action
		var clock: float = minf(phase,float(player_motion.timelines[motion].duration)-0.0001)
		if motion == "charge": clock = clampf(phase,0.01,0.12)
		player_motion.apply(sprite,motion,octant,clock)
	else:
		var rows: Array[int] = [2,0,0,0,1,3,3,3]
		var row: int = rows[octant]
		var frame: int = 1+int(elapsed*8)%3 if moving else 0
		sprite.texture = player_reference
		sprite.region_enabled = false
		sprite.hframes = 6
		sprite.vframes = 4
		sprite.frame = row*6+frame
		sprite.position = Vector2(0,-21)
		sprite.rotation = 0
		sprite.scale = Vector2.ONE
	sprite.modulate = Color(1,0.86,0.72) if flash>0 and (reduced_flash or int(elapsed*28)%2 == 0) else Color.WHITE
	# Player rendered from complete poses only: clock rig has no visible limbs.
	rig.weapon.hide()
	rig.arms_visible = false
	cloak.hide()
	trail.hide()
	rig.queue_redraw()
	rig.rear_arms.queue_redraw()
	rig.front_arms.queue_redraw()
	shadow.modulate.a = 0.5 if action == "dodge" else 1
	queue_redraw()

func _draw() -> void:
	if cue_action == "charge":
		draw_arc(Vector2(0,-12),15,-PI/2,-PI/2+TAU*minf(cue_phase/0.55,1.0),24,Color("ffe19b"),2)
	if kind == "player" and cue_action != "dead":
		draw_arc(Vector2(0,1),10,0.15,PI-0.15,16,Color(0.95,0.78,0.45,0.5),1)
		var aim: Vector2 = WeaponRig.Spec.direction(cue_direction)
		draw_line(aim*12,aim*16,Color(0.95,0.82,0.5,0.65),1)
	if cue_action != "windup": return
	var color := Color(1,0.48,0.28,0.8 if reduced_flash else 0.65+sin(cue_phase*20)*0.15)
	if kind == "shaman": color = Color(0.77,0.62,1,0.8)
	elif kind == "archer": color = Color(1,0.79,0.43,0.8)
	var angle: float = cue_direction.angle()
	if kind in ["archer","shaman"]:
		for i: int in range(3):
			var point: Vector2 = cue_direction*(18+i*9)
			draw_line(point,point+cue_direction*4,color,1)
	elif kind not in ["guardian","stalker"]:
		var radius: float = Geometry.BEAR_RADIUS if kind == "bear" else Geometry.MELEE_RADIUS
		var half_angle: float = acos(Geometry.MELEE_DOT)
		draw_colored_polygon(Geometry.sector(cue_direction,radius,Geometry.MELEE_DOT),Color(color,0.1))
		draw_arc(Vector2.ZERO,radius,angle-half_angle,angle+half_angle,32,color,2)
