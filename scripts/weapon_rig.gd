extends Node2D
const Spec = preload("res://scripts/attack_spec.gd")
signal sweep_step(from_angle: float, to_angle: float)
## Manual AnimationPlayer clock: transforms and one-shot contact share physics time.
var actor_kind: String
var weapon: Sprite2D
var animator: AnimationPlayer
var extension: float = 0.0
var lift: float = 0.0
var body_push: float = 0.0
var draw_back: float = 0.0
var glow: float = 0.0
var sweep_angle: float = 0.0
var attack_direction: Vector2 = Vector2.DOWN
var committed: bool = false
var contact_due: bool = false
var commit: Callable
var active: bool = false
var style: String = "spear"
var holding_stone: bool = false
var tip_position: Vector2
var use_trail: bool = true
var action_name: String = ""
var carry_delta: float = 0.0
var generation: int = 0
var skin_color: Color
var sleeve_color: Color
var rear_arms: Node2D
var front_arms: Node2D
var arms_visible: bool = true
var arm_points: Array[Vector2] = []
var pose_octant: int = 2
var pose_stage: int = 0

func setup(kind: String) -> void:
	actor_kind = kind
	skin_color = Color("d4a276") if kind in ["player","hunter","smith"] else Color("91a45f")
	if kind in ["guardian","coal"]: skin_color = Color("a9aa98")
	sleeve_color = Color({"player":"4f9792","hunter":"547054","smith":"765444","melee":"7d8c4b","archer":"627d45","shaman":"665482","guardian":"585769","coal":"5c5354"}.get(kind,"4f9792"))
	style = {"archer":"bow","hunter":"bow","shaman":"staff","coal":"hammer","smith":"hammer","guardian":"guardian"}.get(kind,"spear")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon = Sprite2D.new()
	weapon.name = "Weapon"
	weapon.texture = load("res://assets/layers/%s_directions.png" % style)
	weapon.hframes = 8
	add_child(weapon)
	for front: bool in [false,true]:
		var arms = preload("res://scripts/weapon_arm_layer.gd").new()
		arms.rig = self
		arms.front = front
		arms.z_index = 2 if front else -2
		get_parent().add_child(arms)
		if front: front_arms = arms
		else: rear_arms = arms
	animator = AnimationPlayer.new()
	animator.name = "AnimationPlayer"
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animator.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	add_child(animator)
	var library := AnimationLibrary.new()
	for name: String in ["thrust","heavy","throw","bow","cast","slam","sweep"]:
		var animation := Animation.new()
		var length: float = Spec.duration(name)
		var contact: float = Spec.contact(name)
		animation.length = length
		var amount: float = Spec.extension(name)
		if name == "sweep":
			track(animation,".:extension",[[0.0,-7.0],[Spec.SWEEP_START,34.0],[Spec.SWEEP_END,34.0],[length,0.0]])
			track(animation,".:body_push",[[0.0,0.0],[length,0.0]])
		else:
			track(animation,".:extension",[[0.0,-7.0],[contact*0.55,-10.0],[contact,amount],[contact+0.025,amount],[length,0.0]])
			track(animation,".:body_push",[[0.0,-1.0],[contact,3.0 if name != "heavy" else 5.0],[length,0.0]])
		track(animation,".:lift",[[0.0, -16.0 if name == "slam" else 0.0],[contact,0.0],[length,0.0]])
		track(animation,".:draw_back",[[0.0,6.0 if name == "bow" else 0.0],[contact,0.0],[length,0.0]])
		track(animation,".:glow",[[0.0,1.0 if name == "cast" else 0.0],[contact,0.8 if name == "cast" else 0.0],[length,0.0]])
		if name == "sweep":
			track(animation,".:sweep_angle",[[0.0,-Spec.SWEEP_HALF],[Spec.SWEEP_START,-Spec.SWEEP_HALF],[Spec.SWEEP_END,Spec.SWEEP_HALF],[length,0.0]])
		else: track(animation,".:sweep_angle",[[0.0,0.0],[length,0.0]])
		var method_track: int = animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(method_track,NodePath("."))
		animation.track_insert_key(method_track,contact,{"method":"mark_contact","args":[]})
		library.add_animation(name,animation)
	animator.add_animation_library("",library)
	update_pose(Vector2.DOWN,"idle",0.0)

func track(animation: Animation, path: String, keys: Array) -> void:
	var index: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index,NodePath(path))
	for key: Array in keys: animation.track_insert_key(index,key[0],key[1])

func start(name: String, direction: Vector2, callback: Callable) -> void:
	cancel()
	action_name = name
	attack_direction = Spec.direction(direction) if name in ["thrust","heavy","sweep"] else direction.normalized()
	commit = callback
	committed = false
	active = true
	holding_stone = name == "throw"
	weapon.texture = load("res://assets/layers/%s_directions.png" % ("stone" if holding_stone else style))
	animator.play(name)
	animator.advance(0)
	update_pose(attack_direction,"attack",0)

func mark_contact() -> void:
	if not committed: contact_due = true

func tick(delta: float) -> void:
	if not active: return
	var remaining: float = maxf(0,delta)+carry_delta
	carry_delta = 0
	var identity: int = generation
	# Split on contact and fixed angular sweep steps. Large stalls cannot dispatch
	# contact from the recovery pose. Work bounded to one short action (<=0.38s).
	for iteration: int in range(100):
		if not active or generation != identity or remaining <= 0.000001: break
		var before: float = animator.current_animation_position
		var boundary: float = Spec.contact(action_name)
		var step: float = minf(remaining,Spec.duration(action_name)-before)
		if not committed and before < boundary: step = minf(step,boundary-before)
		if action_name == "sweep":
			step = minf(step,1.0/120.0)
			if before < Spec.SWEEP_START: step = minf(step,Spec.SWEEP_START-before)
			elif before < Spec.SWEEP_END: step = minf(step,Spec.SWEEP_END-before)
		if step <= 0.000001: step = minf(remaining,0.00001)
		animator.advance(step)
		update_pose(attack_direction,"attack",0)
		remaining -= step
		var after: float = minf(before+step,Spec.duration(action_name))
		if not committed and (contact_due or after >= boundary-0.000001):
			contact_due = false
			committed = true
			if commit.is_valid(): commit.call()
		if generation != identity: break
		if action_name == "sweep" and after >= Spec.SWEEP_START and before < Spec.SWEEP_END:
			var first: float = clampf((before-Spec.SWEEP_START)/(Spec.SWEEP_END-Spec.SWEEP_START),0,1)
			var last: float = clampf((after-Spec.SWEEP_START)/(Spec.SWEEP_END-Spec.SWEEP_START),0,1)
			sweep_step.emit(lerpf(-Spec.SWEEP_HALF,Spec.SWEEP_HALF,first),lerpf(-Spec.SWEEP_HALF,Spec.SWEEP_HALF,last))
		var visual: Node = get_parent()
		var actor: Node = visual.get_parent() if visual != null else null
		var game: Node = actor.get("game") if actor != null and "game" in actor else null
		if game != null and (game.mode != "playing" and game.mode != "test" or game.combat_freeze_left > 0 and not game.settings.reduced_motion):
			carry_delta = remaining
			break
		if not animator.is_playing():
			active = false
			holding_stone = false
			weapon.texture = load("res://assets/layers/%s_directions.png" % style)
			break

func cancel() -> void:
	generation += 1
	carry_delta = 0
	if animator != null: animator.stop()
	active = false
	commit = Callable()
	contact_due = false
	extension = 0
	lift = 0
	body_push = 0
	draw_back = 0
	glow = 0
	sweep_angle = 0
	holding_stone = false
	if weapon != null: weapon.texture = load("res://assets/layers/%s_directions.png" % style)

func update_pose(direction: Vector2, action: String, phase: float) -> void:
	if weapon == null: return
	var facing: Vector2 = attack_direction if active else direction.normalized()
	if facing.is_zero_approx(): facing = Vector2.DOWN
	var octant: int = posmod(roundi((facing.angle()+sweep_angle)/(PI/4)),8)
	var visual_direction: Vector2 = Vector2.from_angle(octant*PI/4)
	pose_octant = octant
	pose_stage = 0
	if active:
		var clock: float = animator.current_animation_position
		pose_stage = 0 if clock < Spec.contact(action_name)*0.8 else (1 if clock < Spec.contact(action_name)+0.06 else 2)
	weapon.frame = octant
	# Only the sweeping boss weapon rotates within an octant; its shaft follows
	# the same continuous angular window used by swept damage.
	weapon.rotation = facing.angle()+sweep_angle-octant*PI/4 if active and action_name == "sweep" else 0
	if active and action_name == "sweep": visual_direction = Vector2.from_angle(facing.angle()+sweep_angle)
	var idle_extension: float = -6.0 if action in ["windup","charge"] and not active else 0.0
	if not active and action == "run": idle_extension += sin(phase*10.0)*1.0
	weapon.position = (visual_direction*(extension+idle_extension)+Vector2(0,lift)).round()
	# A small lateral grip exposes the shaft beside the neck on vertical attacks.
	if style in ["spear","guardian"] and absf(visual_direction.x)<0.1:
		var offset := Vector2(8,0)
		weapon.position = (weapon.position+offset-visual_direction*offset.dot(visual_direction)).round()
	if style == "bow":
		weapon.position = (visual_direction*(12 if active or action == "windup" else 7)+Vector2(0,-5)).round()
		if absf(visual_direction.x)<0.1: weapon.position.x += 8
	elif style == "staff":
		if not active and action != "windup":
			weapon.frame = 6
			visual_direction = Vector2.UP
			weapon.position = Vector2(10,1)
		else:
			weapon.position = (visual_direction*8+Vector2(0,-4)).round()
			if absf(visual_direction.x)<0.1: weapon.position.x += 9
	elif style == "hammer":
		if not active:
			weapon.frame = 1 if facing.x >= 0 else 3
			visual_direction = Vector2.from_angle(weapon.frame*PI/4)
			weapon.position = Vector2(9 if facing.x >= 0 else -9,-3)
			if action in ["windup","charge"]: weapon.position.y -= 12
			elif action == "work": weapon.position.y -= roundf(maxf(0,sin(phase*4))*5)
		else:
			var clock: float = animator.current_animation_position
			var swing: float = lerpf(-1.15,0,clampf(clock/Spec.contact("slam"),0,1)) if clock <= Spec.contact("slam") else lerpf(0,0.4,clampf((clock-Spec.contact("slam"))/0.12,0,1))
			weapon.rotation = swing*(1 if facing.x >= 0 else -1)
			visual_direction = Vector2.from_angle(octant*PI/4+weapon.rotation)
			weapon.position = (visual_direction*7+Vector2(8 if facing.x >= 0 else -8,lift-3)).round()
	if holding_stone:
		var throw_phase: float = clampf(animator.current_animation_position/Spec.contact("throw"),0,1)
		weapon.position = (visual_direction*lerpf(-9,16,throw_phase)+Vector2(7 if facing.x >= 0 else -7,-8*(1-throw_phase))).round()
	if not active and action in ["windup","charge"] and style == "hammer": weapon.position.y -= 10
	z_index = -1 if visual_direction.y < -0.1 else 1
	weapon.visible = action != "dead" and not (holding_stone and committed)
	if not active and action in ["windup","charge"] and style in ["spear","guardian"]:
		weapon.position -= visual_direction*3
	if not active:
		glow = 0.5 if action == "windup" and style == "staff" else 0
		draw_back = 12.0 if action == "windup" and style == "bow" else 0
	if not active and action == "dodge": weapon.position -= visual_direction*6
	if active: position = Vector2(0,-13)+attack_direction*body_push
	tip_position = position+weapon.position+visual_direction*(40 if style == "guardian" else (Spec.SPEAR_LENGTH if style == "spear" else 27))
	arms_visible = action != "dead"
	build_arms(visual_direction)
	for arms: Node2D in [rear_arms,front_arms]:
		arms.position = position
		arms.queue_redraw()
	if actor_kind == "player":
		weapon.visible = false
		arms_visible = false
		var visual: Node = get_parent()
		if active and visual.get("player_motion") != null:
			visual.player_motion.apply(visual.sprite,action_name,octant,animator.current_animation_position)
	queue_redraw()

func build_arms(facing: Vector2) -> void:
	arm_points.clear()
	if actor_kind == "player": return
	var side: Vector2 = facing.orthogonal()
	var grip: Vector2 = weapon.position
	for i: int in [-1,1]:
		# Shoulder anchors sit at the top of the torso, not at the belt.
		var shoulder := Vector2(i*7,-8)
		if actor_kind == "player": shoulder = Vector2(-9 if i == -1 else 7,-7)
		var hand: Vector2 = grip+facing*(-8 if i == -1 else 3)
		var elbow: Vector2 = (shoulder+hand)*0.5+Vector2(i*3,2)
		if holding_stone:
			var throwing: bool = i == (1 if attack_direction.x >= 0 else -1)
			hand = grip if throwing else Vector2(i*9,0)-facing*2
			elbow = shoulder-facing*4+Vector2(i*3,1) if throwing and not committed else (shoulder+hand)*0.5+Vector2(i*3,2)
		elif style == "bow":
			hand = grip+facing*12 if i == 1 else grip-facing*(draw_back*2 if active else draw_back)
			elbow = shoulder-facing*5+side*7 if i == -1 else (shoulder+hand)*0.5+Vector2(0,1)
		elif style == "staff":
			hand = grip if i == 1 else Vector2(-9,-4)+(facing*7 if active else Vector2.ZERO)
			elbow = (shoulder+hand)*0.5+Vector2(i*4,3)
		elif style == "hammer":
			hand = grip+facing*(-6 if i == -1 else 2) if active else (grip if i == 1 else Vector2(-9,2))
			elbow = (shoulder+hand)*0.5+Vector2(i*4,0)
		elif actor_kind == "player":
			# Keep the bent elbow at the ribs during pullback, not across the face.
			elbow.y = maxf(elbow.y,-5)
			if not active or pose_stage == 0:
				elbow.x = i*9
		arm_points.append_array([shoulder.round(),elbow.round(),hand.round()])

func draw_arms(canvas: Node2D, front: bool) -> void:
	if actor_kind == "player": return
	if arm_points.size() != 6: return
	var near_index: int = 1 if attack_direction.x >= 0 else 0
	if not active: near_index = 1 if pose_octant in [0,1,2,6,7] else 0
	var facing_up: bool = pose_octant in [5,6,7]
	for index: int in range(2):
		var shoulder: Vector2 = arm_points[index*3]
		var elbow: Vector2 = arm_points[index*3+1]
		var hand: Vector2 = arm_points[index*3+2]
		if front == (index == near_index and not facing_up):
			if actor_kind == "player":
				# Match the reference: short dark cuff, narrow forearm, small hand.
				# A long turquoise sleeve would turn the cloak into a crossed stripe.
				var cuff: Vector2 = shoulder.move_toward(elbow,4).round()
				canvas.draw_line(shoulder,cuff,Color("162632"),4)
				canvas.draw_line(shoulder,cuff,sleeve_color.darkened(0.25),2)
				canvas.draw_line(cuff,elbow,Color("162632"),3)
				canvas.draw_line(cuff,elbow,skin_color,1)
			else:
				canvas.draw_line(shoulder,elbow,Color("162632"),5)
				canvas.draw_line(shoulder,elbow,sleeve_color,3)
			canvas.draw_line(elbow,hand,Color("162632"),4)
			canvas.draw_line(elbow,hand,skin_color,2)
		# Both hands sit over the shaft; the far forearm remains body-occluded.
		if front != facing_up:
			canvas.draw_rect(Rect2(hand-Vector2(1,1),Vector2(3,3)) if actor_kind == "player" else Rect2(hand-Vector2(2,2),Vector2(4,4)),Color("162632"))
			canvas.draw_rect(Rect2(hand,Vector2(2,2)) if actor_kind == "player" else Rect2(hand-Vector2(1,1),Vector2(3,2)),skin_color)

func _draw() -> void:
	if weapon == null or not weapon.visible: return
	var octant: int = weapon.frame
	var facing := Vector2.from_angle(octant*PI/4+weapon.rotation)
	var side := facing.orthogonal()
	var grip: Vector2 = weapon.position
	if style == "bow":
		var pull: float = draw_back*2 if active else draw_back
		draw_polyline(PackedVector2Array([grip+facing*4-side*15,grip-facing*pull,grip+facing*4+side*15]),Color("e7ddb1"),1)
		if not committed or not active: draw_line((grip-facing*pull).round(),(grip+facing*20).round(),Color("d6c79f"),1)
	if glow > 0: draw_circle(grip+facing*27,5+glow*3,Color(0.65,0.9,0.8,glow*0.3))
	if active and committed and use_trail and style in ["spear","guardian"] and not holding_stone:
		draw_line((grip+facing*22).round(),(grip+facing*32).round(),Color(1,0.88,0.58,0.25),1)
