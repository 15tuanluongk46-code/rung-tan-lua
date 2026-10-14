extends Node
const State = preload("res://scripts/run_state.gd")
const Content = preload("res://scripts/world_content.gd")
const Player = preload("res://scripts/player_actor.gd")
const Enemy = preload("res://scripts/enemy_actor.gd")
const Peaceful = preload("res://scripts/peaceful_actor.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Interface = preload("res://scripts/game_ui.gd")
const Settings = preload("res://scripts/game_settings.gd")
const VisualFX = preload("res://scripts/visual_fx.gd")
const MysticEnvironment = preload("res://scripts/mystic_environment.gd")
const EmberMarker = preload("res://scripts/ember_marker.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const WorldEvents = preload("res://scripts/world_events.gd")
const Boss = preload("res://scripts/boss_actor.gd")
const Encounters = preload("res://scripts/encounter_director.gd")
const AttackSpec = preload("res://scripts/attack_spec.gd")
var state: RefCounted
var content: RefCounted = Content.new()
var settings: RefCounted = Settings.new()
var world: Node2D
var art: Node2D
var audio: Node
var ui: Interface
var player: CharacterBody2D
var camera: Camera2D
var actors: Array[Node] = []
var item_nodes: Dictionary = {}
var objects: Node2D
var projectiles: Node2D
var mode: String = "menu"
var region: String = ""
var shake: float = 0.0
var combat_freeze_left: float = 0.0
var altar_ceremony: float = 0.0
var altar_pulse_clock: float = 0.0
var attack_serial: int = 0
var dependencies_missing: Array[String] = []
var capture: Node
var effects: VisualFX
var atmosphere: MysticEnvironment
var altar_sprite: Sprite2D
var ember_sprites: Array[Sprite2D] = []
var save_manager: RefCounted = SaveManager.new()
var autosave_enabled: bool = true
var save_pending: bool = false
var save_clock: float = 0.0
var world_events: WorldEvents
var save_failures: int = 0
var save_status: String = ""
var save_dirty_age: float = 0.0
var death_clock: float = 0.0

func _ready() -> void:
	# Tests and captures use isolated state, never the player's journey slot.
	for argument: String in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if argument.contains("tests/") or argument.begins_with("--capture-") or argument == "--no-save": autosave_enabled = false
	get_tree().auto_accept_quit = false
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	if ResourceLoader.exists("res://scripts/world_art.gd"):
		art = load("res://scripts/world_art.gd").new()
		world.add_child(art)
		art.build(world)
	else: missing("scripts/world_art.gd")
	if ResourceLoader.exists("res://scripts/audio_director.gd"):
		audio = load("res://scripts/audio_director.gd").new()
		add_child(audio)
	else: missing("scripts/audio_director.gd")
	if not ResourceLoader.exists("res://scripts/actor_visual.gd"): missing("scripts/actor_visual.gd")
	settings.apply(audio)
	objects = Node2D.new()
	objects.y_sort_enabled = true
	world.add_child(objects)
	projectiles = Node2D.new()
	world.add_child(projectiles)
	atmosphere = MysticEnvironment.new()
	atmosphere.game = self
	world.add_child(atmosphere)
	effects = VisualFX.new()
	world.add_child(effects)
	world_events = WorldEvents.new()
	world_events.game = self
	world.add_child(world_events)
	var encounters := Encounters.new()
	encounters.game = self
	world.add_child(encounters)
	ui = Interface.new()
	add_child(ui)
	ui.setup(self)
	ui.main_menu()
	for argument: String in OS.get_cmdline_user_args():
		if OS.has_feature("release"): break
		if argument.begins_with("--capture-region="):
			var selected: String = argument.trim_prefix("--capture-region=")
			if not content.centers.has(selected):
				printerr("Unknown capture region: " + selected)
				get_tree().quit(2)
				return
			capture = load("res://tests/capture_region.gd").new()
			add_child(capture)
			capture.begin(self,selected)

func missing(path: String) -> void:
	dependencies_missing.append(path)
	push_warning("Gameplay dependency absent (no placeholder substituted): " + path)

func start_game() -> void:
	state = State.new()
	state.changed.connect(schedule_save)
	ui.previous_region = ""
	build_session()
	mode = "playing"
	ui.clear()
	notify("E : gặp già làng An ở phía bắc lửa trại.  Esc : cách chơi.")
	schedule_save()

func schedule_save() -> void:
	if not autosave_enabled: return
	save_pending = true
	if save_failures == 0: save_clock = 0.35
	save_status = "Chưa lưu" if save_failures > 0 else "Đang lưu…"

func flush_save() -> bool:
	if not autosave_enabled or state == null: return true
	if not save_manager.save_state(state):
		save_failures += 1
		save_status = "Lưu lỗi · đang thử lại"
		if save_failures == 1: notify(save_manager.last_error)
		return false
	save_pending = false
	save_dirty_age = 0
	save_failures = 0
	save_status = "Đã lưu"
	return true

func continue_game() -> void:
	var restored: RefCounted = save_manager.load_state()
	if restored == null:
		ui.dialogue("Hành trình chưa đọc được",save_manager.last_error)
		ui.return_action = ui.main_menu
		return
	state = restored
	state.changed.connect(schedule_save)
	ui.previous_region = ""
	build_session()
	player.position = content.checkpoints[state.checkpoint]
	player.reset_physics_interpolation()
	player.health.hp = state.hp
	if state.ended: ui.ending()
	elif state.hp <= 0: ui.death()
	else:
		mode = "playing"
		ui.clear()
		notify("Đã phục hồi từ bản dự phòng." if save_manager.recovered else "Đã tiếp tục tại điểm nghỉ. [M] Bản đồ · [Esc] Nhật ký.")

func continue_chapter() -> void:
	if not state.continue_chapter(): return
	build_session()
	resume()
	notify("Chương II · Đường Lửa Thức Giấc. Đi về phía nam Bờ Suối gặp Sen.")

func build_session() -> void:
	player = null
	ui.toast_left = 0
	ember_sprites.clear()
	altar_sprite = null
	combat_freeze_left = 0.0
	altar_ceremony = 0.0
	altar_pulse_clock = 0.0
	if effects != null: effects.bursts.clear()
	for actor: Node in actors:
		if is_instance_valid(actor):
			world.remove_child(actor)
			actor.queue_free()
	actors.clear()
	for projectile: Node in projectiles.get_children():
		projectiles.remove_child(projectile)
		projectile.queue_free()
	for object: Node in objects.get_children():
		objects.remove_child(object)
		object.queue_free()
	item_nodes.clear()
	for data: Dictionary in content.actors(state.chapter):
		if data.kind != "player" and state.killed.has(data.id): continue
		var actor: CharacterBody2D
		if data.kind == "player": actor = Player.new()
		elif data.kind == "guardian": actor = Boss.new()
		elif data.kind in Content.HOSTILE_KINDS: actor = Enemy.new()
		else: actor = Peaceful.new()
		var maximum: int = {"melee":75,"archer":50,"shaman":100,"bear":175,"stalker":75,"coal":100,"guardian":400}.get(data.kind,100)
		actor.setup(self,data,maximum)
		if data.kind == "player":
			player = actor
			player.faction = "player"
			player.position = Content.START if state.deaths == 0 else content.checkpoints[state.checkpoint]
			player.health.hp = state.hp
		world.add_child(actor)
		if point_blocked(actor.position,10):
			actor.position = clear_spawn(actor.position)
			actor.home = actor.position
		actors.append(actor)
		actor.reset_physics_interpolation()
	assert(player != null,"Session must construct exactly one player")
	if art != null: art.set_listener(player)
	if audio != null: audio.set_listener(player)
	camera = Camera2D.new()
	camera.zoom = Vector2(1.4,1.4)
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position_smoothing_enabled = false
	camera.position_smoothing_speed = 7
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(Content.SIZE.x)
	camera.limit_bottom = int(Content.SIZE.y)
	player.add_child(camera)
	camera.make_current()
	add_player_light()
	for data: Dictionary in content.items(state.chapter):
		if not state.picked.has(data.id): spawn_item(data)
	for checkpoint: String in content.checkpoints:
		if state.chapter == 1 and checkpoint in ["marsh","ash"]: continue
		marker(content.checkpoints[checkpoint],"ĐIỂM NGHỈ","checkpoint")
	marker(Content.ALTAR,"TẾ ĐÀN", "altar")
	region = ""
	shake = 0
	world_events.refresh_state()

func add_player_light() -> void:
	var light: PointLight2D = PointLight2D.new()
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0,Color(1,1,1,0.55))
	gradient.set_color(1,Color(1,1,1,0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	light.texture = texture
	light.color = Color("ffc17c")
	light.energy = 0.5
	light.texture_scale = 1.5
	player.add_child(light)

func spawn_item(data: Dictionary) -> void:
	var node: Node2D = marker(clear_spawn(data.pos),item_name(data.kind),data.kind)
	node.set_meta("data",data)
	item_nodes[data.id] = node

func marker(point: Vector2, text: String, kind: String) -> Node2D:
	var node: Node2D = Node2D.new()
	node.position = point
	objects.add_child(node)
	var path: String = "res://assets/props/%s.png" % kind
	if ResourceLoader.exists(path):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = load(path)
		sprite.offset.y = -8
		node.add_child(sprite)
		if kind == "ember": ember_sprites.append(sprite)
		if kind == "altar": altar_sprite = sprite
	if kind in ["ember","altar"]:
		var aura := EmberMarker.new()
		aura.game = self
		aura.kind = kind
		node.add_child(aura)
	var caption: Label = Label.new()
	caption.text = text
	# Nearby interaction prompt owns item/rest labels; avoid duplicate floating text.
	caption.visible = kind in ["altar","ember"]
	caption.set_meta("landmark_caption",kind in ["altar","ember"])
	caption.position = Vector2(-65,-32)
	caption.size.x = 130
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",10)
	caption.add_theme_color_override("font_color",Color("eec284"))
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_y",1)
	node.add_child(caption)
	return node

func _process(delta: float) -> void:
	settings.tick(delta)
	if save_pending:
		save_dirty_age += delta
		save_clock -= delta
		if save_clock <= 0 or (save_failures == 0 and save_dirty_age >= 2.0):
			if not flush_save(): save_clock = minf(30.0,pow(2.0,min(save_failures,5)))
	if mode == "dying" and player != null:
		death_clock += delta
		player.visual.pose(player.facing,false,"dead",player.age+death_clock)
		if death_clock >= 0.4: ui.death()
		return
	combat_freeze_left = maxf(0.0, combat_freeze_left - delta)
	if altar_ceremony > 0.0:
		altar_ceremony = maxf(0.0, altar_ceremony - delta)
		altar_pulse_clock -= delta
		if altar_pulse_clock <= 0.0 and effects != null:
			altar_pulse_clock = 0.22
			effects.burst(Vector2(1810,1190), "altar_pulse")
	if mode != "playing" or player == null: return
	state.elapsed += delta
	var visited: String = content.region_at(player.position)
	if not state.discovered.has(visited):
		state.discovered[visited] = true
		state.changed.emit()
	if state.chapter == 2:
		for data: Dictionary in content.world_events():
			if player.position.distance_to(data.pos) < 115 and not state.landmarks.has(data.id):
				state.landmarks[data.id] = true
				state.changed.emit()
	for sprite: Sprite2D in ember_sprites:
		if is_instance_valid(sprite):
			sprite.offset.y = -12+sin(state.elapsed*2.8)*2
			sprite.self_modulate = Color(1.15,1.03+sin(state.elapsed*3)*0.08,0.85)
	if is_instance_valid(altar_sprite):
		altar_sprite.self_modulate = Color(1.4,1.12,0.7) if state.altar_lit else Color(0.74,0.88,0.94)
	# The village visibly warms as embers return; quests remain authoritative.
	for checkpoint_node: Node2D in objects.get_children():
		if checkpoint_node.position.distance_to(content.checkpoints.camp) < 1 and checkpoint_node.get_child_count() > 0:
			var camp_fire: Node = checkpoint_node.get_child(0)
			if camp_fire is Sprite2D: camp_fire.self_modulate = Color(1.0+state.embers.size()*0.09,1.0,0.9)
	var next_region: String = content.region_at(player.position)
	if region != next_region:
		region = next_region
		if audio != null: audio.set_region(region)
		if art != null and art.has_method("set_region"): art.set_region(region)
	shake = maxf(0,shake - delta * 15)
	camera.offset = Vector2(sin(state.elapsed * 110),cos(state.elapsed * 93)) * shake if settings.screenshake and not settings.reduced_motion else Vector2.ZERO
	for node: Node in objects.get_children():
		for child: Node in node.get_children():
			if child is Label: child.visible = child.get_meta("landmark_caption",false) and player.position.distance_to(node.position) < 140

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map") and mode in ["playing","map"]:
		if mode == "map": resume()
		else: ui.show_map()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause"):
		ui.escape()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and ui != null:
		if mode == "playing": mode = "paused"
		ui.confirm_exit(false)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "playing": ui.pause_menu()

func resume() -> void:
	if state == null or state.hp <= 0 or state.ended: return
	ui.clear()
	mode = "playing"

func respawn() -> void:
	state.respawn()
	build_session()
	resume()
	notify("Bạn đã tỉnh lại. Tiến độ nhiệm vụ được giữ nguyên.")

func player_died() -> void:
	sfx("death",player.position)
	mode = "dying"
	death_clock = 0
	player.visual.pose(player.facing,false,"dead",player.age)

func notify(text: String) -> void:
	ui.notify(text)

func sfx(key: String, point: Vector2 = Vector2.ZERO) -> void:
	if audio != null: audio.play_sfx(key,point)
	if effects != null and point != Vector2.ZERO and key in ["hit","heal","dodge","stone","quest","pickup"]:
		effects.burst(point,key)

func trigger_hitstop(duration: float = 0.05) -> void:
	combat_freeze_left = maxf(combat_freeze_left,duration*[0.0,0.4,1.0][settings.hitstop_level])

func actor_by_id(id: String) -> Node:
	for actor: Node in actors:
		if actor.actor_id == id: return actor
	return null

func point_blocked(point: Vector2, margin: float = 0) -> bool:
	if point.x < 24 or point.x > Content.SIZE.x-24 or point.y < 24 or point.y > Content.SIZE.y-24: return true
	if world_events != null:
		for rect: Rect2 in world_events.gate_rects():
			if rect.grow(margin).has_point(point): return true
	return art.is_blocked(point,margin) if art != null else false

func clear_spawn(point: Vector2) -> Vector2:
	if not point_blocked(point,10): return point
	for radius: int in [24,48,72,96]:
		for step: int in range(16):
			var candidate: Vector2 = point + Vector2.from_angle(step * TAU / 16.0) * radius
			if not point_blocked(candidate,10): return candidate
	push_warning("No safe spawn near " + str(point))
	return point

func line_clear(from: Vector2, to: Vector2) -> bool:
	if not world.is_inside_tree(): return true
	return world.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from,to,1)).is_empty()

func find_target(seeker: Node, radius: float) -> Node2D:
	var best: Node2D = null
	var nearest: float = radius
	for actor: Node in actors:
		if actor.dead or actor.faction in ["neutral",seeker.faction]: continue
		if seeker.faction == "goblin" and actor.faction not in ["player","bear"]: continue
		var distance: float = seeker.position.distance_to(actor.position)
		if distance < nearest and line_clear(seeker.position,actor.position):
			best = actor
			nearest = distance
	return best

func noise(point: Vector2, radius: float) -> void:
	for actor: Node in actors:
		if not actor.dead and actor.has_method("investigate") and actor.position.distance_to(point) < radius:
			actor.investigate(point)

func spear_attack(attacker: Node, charged: bool = false) -> void:
	attacker.facing = AttackSpec.direction(attacker.facing)
	attack_serial += 1
	var id: String = "spear_" + str(attack_serial)
	sfx("attack",attacker.position)
	# Spear motion comes from the actual weapon; impact bursts occur only on contact.
	noise(attacker.position,150)
	var counter: int = attacker.abilities.consume_counter() if attacker == player else 0
	var damage: int = (45 if charged else 25)+counter
	if counter > 0 and state.specialization == "spear": damage += 8
	for actor: Node in actors:
		if actor == attacker or actor.dead or actor.faction == "neutral": continue
		var offset: Vector2 = actor.position - attacker.position
		if offset.length() <= (AttackSpec.HEAVY_REACH if charged else AttackSpec.NORMAL_REACH) and (offset.is_zero_approx() or attacker.facing.dot(offset.normalized()) > 0.35) and line_clear(attacker.position,actor.position):
			if actor.receive_hit(damage,id,attacker) and charged and actor.has_method("interrupt"): actor.interrupt(0.45)

func spawn_projectile(source: Node, direction: Vector2, kind: String) -> void:
	attack_serial += 1
	var projectile: Node2D = Projectile.new()
	projectile.game = self
	projectile.source = source
	projectile.kind = kind
	if kind == "stone" and source == player and state.specialization == "stone": projectile.stagger = 0.35
	projectile.direction = direction.normalized()
	projectile.attack_id = "projectile_" + str(attack_serial)
	projectile.position = source.position + direction.normalized() * 8
	if source.visual != null and source.visual.rig != null and source.visual.rig.active:
		var rig = source.visual.rig
		var reach: float = 4 if kind == "stone" else (13 if kind == "arrow" else 27)
		# Pixel projectile renders at the hand/muzzle; its gameplay ground plane
		# remains the existing actor-feet plane used by collision and targeting.
		projectile.position = source.position+direction.normalized()*(rig.extension+reach)
		projectile.visual_offset = Vector2(0,-13+rig.lift)
		if source == player and kind == "stone":
			projectile.direction = AttackSpec.direction(direction)
			projectile.position = source.position+projectile.direction*float(AttackSpec.data.stone_release.distance)
			projectile.visual_offset = Vector2(0,float(AttackSpec.data.stone_release.height))
	var obstruction: Dictionary = world.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(source.position,projectile.position,1))
	if not obstruction.is_empty():
		if effects != null: effects.burst(obstruction.position,"wall_impact",direction)
		noise(obstruction.position,150)
		projectile.free()
		return
	projectiles.add_child(projectile)

func closest_interaction() -> Dictionary:
	if player == null or state == null: return {}
	var best: Dictionary = {}
	var distance: float = 48
	for actor: Node in actors:
		if actor.kind not in Content.NPC_KINDS: continue
		var next: float = player.position.distance_to(actor.position)
		if next < distance and line_clear(player.position,actor.position):
			distance = next
			best = {"type":"npc", "id":actor.kind, "name":actor.display_name}
	for id: String in item_nodes:
		var item: Node2D = item_nodes[id]
		var next: float = player.position.distance_to(item.position)
		if next < distance and line_clear(player.position,item.position):
			distance = next
			best = {"type":"item","id":id,"name":item_name(item.get_meta("data").kind)}
	for checkpoint: String in content.checkpoints:
		if state.chapter == 1 and checkpoint in ["marsh","ash"]: continue
		var next: float = player.position.distance_to(content.checkpoints[checkpoint])
		if next < distance and line_clear(player.position,content.checkpoints[checkpoint]):
			distance = next
			best = {"type":"checkpoint","id":checkpoint,"name":"Nghỉ tại " + content.names[checkpoint]}
	if player.position.distance_to(Vector2(1810,1190)) < distance and line_clear(player.position,Vector2(1810,1190)):
		best = {"type":"altar","id":"altar","name":"Tế đàn cổ"}
	if state.chapter == 2:
		for data: Dictionary in content.world_events():
			var next: float = player.position.distance_to(data.pos)
			if next < distance and line_clear(player.position,data.pos):
				distance = next
				best = {"type":"bell_rest" if data.id == "bell" and state.events.has("bell") else "event","id":data.id,"name":"Nghỉ tại Chuông Lò" if data.id == "bell" and state.events.has("bell") else data.name,"pos":data.pos}
	return best

func interaction_prompt() -> String:
	var candidate: Dictionary = closest_interaction()
	return "[E]  " + candidate.name if not candidate.is_empty() else "WASD  ·  Q thuốc  ·  Space né  ·  Esc nhật ký"

func interact(use_displayed_target: bool = false) -> void:
	var candidate: Dictionary = ui.selected_interaction() if use_displayed_target else closest_interaction()
	if candidate.is_empty(): return
	match candidate.type:
		"event": world_events.interact(candidate.id)
		"bell_rest":
			state.collect_reward("bell")
			state.activate_checkpoint("ash")
			state.hp = 100
			player.health.hp = 100
			state.changed.emit()
			sfx("heal",player.position)
			notify("Chuông Lò · Hồi đầy sinh lực, điểm hồi sinh Đồi Than.")
		"npc": talk(candidate.id)
		"checkpoint":
			state.activate_checkpoint(candidate.id)
			state.hp = 100
			player.health.hp = 100
			state.changed.emit()
			sfx("heal",player.position)
			notify("Đã nghỉ tại %s. Hồi đầy máu và ghi điểm hồi sinh." % content.names[candidate.id])
		"altar":
			if state.light_altar():
				effects.burst(Vector2(1810,1190),"altar")
				altar_ceremony = 2.8
				altar_pulse_clock = 0.0
				ui.begin_altar_ceremony()
				sfx("quest",player.position)
				notify("Tế đàn đã sáng! Trở về gặp già làng An.")
			else: notify("Tế đàn cần lời nhờ của An và đủ ba tàn lửa." if not state.altar_lit else "Lửa đã sáng. Già làng An đang chờ.")
		"item":
			var node: Node2D = item_nodes[candidate.id]
			var data: Dictionary = node.get_meta("data")
			for guard: String in data.get("guards",[]):
				if not state.killed.has(guard):
					notify("Tàn lửa bị phong ấn. Hạ lính canh quanh đây trước.")
					return
			if state.pickup(candidate.id,data.kind,data.get("detail","")):
				effects.burst(node.position,"ember_pickup" if data.kind == "ember" else "heal")
				sfx("quest" if data.kind == "ember" else "pickup",player.position)
				if data.kind == "ember": ui.flash_ember_slot(["forest","creek","ruins"].find(data.detail))
				notify("Đã nhận: " + item_name(data.kind))
				if data.kind == "ember" and state.embers.size() == 1: notify("Mở Đâm tích lực: giữ Shift + chuột trái, thả để đâm mạnh. Space hủy.")
				item_nodes.erase(candidate.id)
				node.queue_free()
			else: notify("Cần trống đủ 4 chỗ đá. Túi đá vẫn ở đây." if data.kind == "stone" else "Túi đã đầy. Vật phẩm vẫn ở đây; dùng bớt rồi quay lại.")

func item_name(kind: String) -> String:
	return {"ember":"Tàn lửa", "herb":"Dược thảo", "bag":"Túi của Lâm", "potion":"Bình thuốc", "stone":"Túi đá (+4)","plank":"Gỗ sửa cầu","bell_part":"Mảnh chuông"}.get(kind,kind)

func accept_quest(quest: String) -> void:
	state.accept(quest)
	sfx("quest")
	resume()
	notify("Đã ghi việc mới vào nhật ký [Esc].")

func claim_quest(quest: String) -> void:
	if state.reward(quest):
		sfx("quest")
		resume()
		notify("Đã nhận thưởng: 2 bình thuốc." if quest == "herbs" else "Đã nhận thưởng: 8 đá và 1 bình thuốc.")
	else:
		resume()
		notify("Chưa đủ vật phẩm hoặc túi đầy. Dành chỗ cho toàn bộ phần thưởng rồi trở lại.")

func talk(kind: String) -> void:
	match kind:
		"sen":
			state.collect_reward("bridge")
			if state.stage == 0:
				state.stage = 1
				state.changed.emit()
			var sen_options: Array[Dictionary] = []
			if not state.accepted.has("bridge"): sen_options.append({"text":"Nhận việc: Cây cầu về nhà","action":func() -> void: accept_quest("bridge")})
			ui.dialogue("Người giữ đèn Sen","Ba đèn chỉ lối tới Giếng Nguồn. Thắp chúng bằng E rồi xua Kẻ Rình Sương khỏi giếng. Cầu gãy là lối tắt; đường vòng qua Miếu Chìm vẫn đi được.",sen_options)
		"tung":
			state.collect_reward("bell")
			if state.stage == 3:
				state.stage = 4
				state.changed.emit()
			var tung_options: Array[Dictionary] = []
			if not state.accepted.has("bell"): tung_options.append({"text":"Nhận việc: Tiếng chuông dưới tro","action":func() -> void: accept_quest("bell")})
			if state.stage >= 4:
				tung_options.append({"text":"Chọn lối chiến đấu / nhận thưởng","action":func() -> void: ui.specialization_menu()})
			ui.dialogue("Thợ lò Tùng","Nước đã trong nhưng tháp còn khóa. Khôi phục hai van lò, rồi đối mặt Người Giữ Than. Quan sát vòng cảnh báo, đừng đứng trong than nóng.",tung_options)
		"chief":
			if state.finish_main():
				sfx("quest")
				ui.ending()
			elif not state.accepted.has("main"):
				ui.dialogue("Già làng An","Ngọn lửa làng sắp tắt. Ba tàn lửa của rừng còn ở phía đông, bên suối phía nam, và trong phế tích đông nam.\n\nLính canh giữ chúng. Mang đủ ba đến tế đàn ở Phế Tích, thắp lại lửa rồi trở về đây. Con có nhận lời không?",[{"text":"Tôi sẽ mang lửa về", "action":func() -> void: accept_quest("main")}])
			else: ui.dialogue("Già làng An",state.objective() + "\n\n" + ("Ánh lửa đã ấm hơn. Ta thấy rừng đang nhớ lại. " if not state.embers.is_empty() else "") + "Đường mòn nối các vùng. Điểm nghỉ bên suối giúp con hồi sinh gần hành trình hơn.")
		"healer":
			var text: String = "Ta cần năm cây dược thảo để chăm sóc dân làng. Chúng mọc dọc đường rừng và bờ suối. Ta đổi cho con hai bình thuốc.\n\nThuốc hồi 40 máu; mang tối đa sáu bình. Hãy để trống hai chỗ khi nhận thưởng."
			if state.claimed.has("herbs"): ui.dialogue("Thầy thuốc Mai","Nhờ dược thảo của con, mọi người đã đỡ sốt. Giữ lấy những bình thuốc cho đoạn đường còn lại.")
			elif not state.accepted.has("herbs"): ui.dialogue("Thầy thuốc Mai",text,[{"text":"Nhận việc: năm cây thuốc", "action":func() -> void: accept_quest("herbs")}])
			else: ui.dialogue("Thầy thuốc Mai","Con đã hái %d/5 cây. Đổi đủ năm cây lấy hai bình thuốc." % state.herbs,[{"text":"Trao dược thảo", "action":func() -> void: claim_quest("herbs")}])
		"hunter":
			if state.claimed.has("bag"): ui.dialogue("Thợ săn Lâm","Túi đã về đúng chủ. Cảm ơn! Tiếng đá va vào thân cây có thể kéo lính canh ra khỏi đường đi của con.")
			elif not state.accepted.has("bag"): ui.dialogue("Thợ săn Lâm","Ta đánh rơi túi ở phía đông Bờ Suối, gần chỗ gấu, bên dưới đường sang Phế Tích. Mang nó về, ta tặng tám viên đá và một bình thuốc.\n\nĐừng đùa với gấu. Nó không phân biệt con với yêu tinh đâu.",[{"text":"Nhận việc: tìm túi của Lâm", "action":func() -> void: accept_quest("bag")}])
			else: ui.dialogue("Thợ săn Lâm","Con tìm thấy túi chưa? Nhớ dành chỗ cho tám viên đá và một bình thuốc.",[{"text":"Trả túi cho Lâm", "action":func() -> void: claim_quest("bag")}])
		"smith": ui.dialogue("Thợ rèn Bình","Giáo này gây 25 sát thương mỗi đòn. Nhìn theo chuột để chọn hướng đâm; đừng đứng yên đổi đòn.\n\nCung thủ và pháp sư cần một nhịp để ngắm. Nấp sau cây, đợi đạn chạm đá rồi tiến lên. Space cho con một khoảng bất tử ngắn; né lại sau 0,8 giây.")
		"gatherer": ui.dialogue("Người hái thuốc Nhi","Theo đường phía nam trại đến Bờ Suối. Điểm nghỉ bên đó có thể hồi máu và giữ chỗ hồi sinh. Bấm E khi đứng bên lửa.\n\nPháp sư giữ tàn lửa ở cuối bờ suối phía đông nam. Từ Bờ Suối đi về phía đông là Phế Tích. Đừng bắn hươu và thỏ — chúng chỉ đang tìm một chỗ bình yên.")

func time_text() -> String:
	var seconds: int = int(state.elapsed) if state != null else 0
	return "%02d:%02d" % [seconds / 60,seconds % 60]

func in_combat() -> bool:
	for actor: Node in actors:
		if actor.dead or actor.faction not in ["goblin","bear"]: continue
		var distance: float = actor.position.distance_to(player.position)
		if distance > 260 or not line_clear(player.position,actor.position): continue
		if actor.kind == "guardian":
			if actor.music_owned: return true
		elif actor.target == player or distance < 85: return true
	return false

func travel_checkpoint(id: String) -> bool:
	if mode not in ["paused","map","dialogue"] or not state.known_checkpoints.has(id) or not content.checkpoints.has(id) or in_combat():
		notify("Chỉ trở về điểm nghỉ đã kích hoạt khi ngoài combat.")
		return false
	state.activate_checkpoint(id)
	player.enter_dialogue()
	player.dodge_left = 0
	player.abilities.dodge_age = 99
	for projectile: Node in projectiles.get_children():
		projectiles.remove_child(projectile)
		projectile.queue_free()
	player.position = content.checkpoints[id]
	player.reset_physics_interpolation()
	camera.reset_smoothing()
	resume()
	return true
