extends Node
const State = preload("res://scripts/run_state.gd")
const Content = preload("res://scripts/world_content.gd")
const Player = preload("res://scripts/player_actor.gd")
const Enemy = preload("res://scripts/enemy_actor.gd")
const Peaceful = preload("res://scripts/peaceful_actor.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Interface = preload("res://scripts/game_ui.gd")
const Settings = preload("res://scripts/game_settings.gd")
var state: RefCounted
var content: RefCounted = Content.new()
var settings: RefCounted = Settings.new()
var world: Node2D
var art: Node2D
var audio: Node
var ui: CanvasLayer
var player: CharacterBody2D
var camera: Camera2D
var actors: Array[Node] = []
var item_nodes: Dictionary = {}
var objects: Node2D
var projectiles: Node2D
var mode: String = "menu"
var region: String = ""
var shake: float = 0.0
var attack_serial: int = 0
var dependencies_missing: Array[String] = []
var capture: Node

func _ready() -> void:
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
	ui = Interface.new()
	add_child(ui)
	ui.setup(self)
	ui.main_menu()
	for argument: String in OS.get_cmdline_user_args():
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
	build_session()
	mode = "playing"
	ui.clear()
	notify("E : gặp già làng An ở phía bắc lửa trại.  Esc : cách chơi.")

func build_session() -> void:
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
	for data: Dictionary in content.actors():
		if state.killed.has(data.id): continue
		var actor: CharacterBody2D
		if data.kind == "player": actor = Player.new()
		elif data.kind in ["melee", "archer", "shaman", "bear"]: actor = Enemy.new()
		else: actor = Peaceful.new()
		var maximum: int = {"melee":75,"archer":50,"shaman":100,"bear":175}.get(data.kind,100)
		actor.setup(self,data,maximum)
		if data.kind == "player":
			player = actor
			player.faction = "player"
			player.position = Content.START if state.deaths == 0 else content.checkpoints[state.checkpoint]
		world.add_child(actor)
		if point_blocked(actor.position,10):
			actor.position = clear_spawn(actor.position)
			actor.home = actor.position
		actors.append(actor)
	if art != null: art.set_listener(player)
	if audio != null: audio.set_listener(player)
	camera = Camera2D.new()
	camera.zoom = Vector2(1.4,1.4)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2400
	camera.limit_bottom = 1600
	player.add_child(camera)
	camera.make_current()
	add_player_light()
	for data: Dictionary in content.items():
		if not state.picked.has(data.id): spawn_item(data)
	for checkpoint: String in content.checkpoints:
		marker(content.checkpoints[checkpoint],"ĐIỂM NGHỈ","checkpoint")
	marker(Vector2(1810,1190),"TẾ ĐÀN", "altar")
	region = ""
	shake = 0

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
	var caption: Label = Label.new()
	caption.text = text
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
	if mode != "playing" or player == null: return
	state.elapsed += delta
	var next_region: String = content.region_at(player.position)
	if region != next_region:
		region = next_region
		if audio != null: audio.set_region(region)
		if art != null and art.has_method("set_region"): art.set_region(region)
	shake = maxf(0,shake - delta * 15)
	camera.offset = Vector2(sin(state.elapsed * 110),cos(state.elapsed * 93)) * shake if settings.screenshake else Vector2.ZERO
	for node: Node in objects.get_children():
		for child: Node in node.get_children():
			if child is Label: child.visible = player.position.distance_to(node.position) < 140

func _unhandled_input(event: InputEvent) -> void:
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
	ui.death()

func notify(text: String) -> void:
	ui.notify(text)

func sfx(key: String, point: Vector2 = Vector2.ZERO) -> void:
	if audio != null: audio.play_sfx(key,point)

func actor_by_id(id: String) -> Node:
	for actor: Node in actors:
		if actor.actor_id == id: return actor
	return null

func point_blocked(point: Vector2, margin: float = 0) -> bool:
	if point.x < 24 or point.x > 2376 or point.y < 24 or point.y > 1576: return true
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

func spear_attack(attacker: Node) -> void:
	attack_serial += 1
	var id: String = "spear_" + str(attack_serial)
	sfx("attack",attacker.position)
	noise(attacker.position,150)
	for actor: Node in actors:
		if actor == attacker or actor.dead or actor.faction == "neutral": continue
		var offset: Vector2 = actor.position - attacker.position
		if offset.length() <= 49 and attacker.facing.dot(offset.normalized()) > 0.35 and line_clear(attacker.position,actor.position):
			actor.receive_hit(25,id,attacker)

func spawn_projectile(source: Node, direction: Vector2, kind: String) -> void:
	attack_serial += 1
	var projectile: Node2D = Projectile.new()
	projectile.game = self
	projectile.source = source
	projectile.kind = kind
	projectile.direction = direction.normalized()
	projectile.attack_id = "projectile_" + str(attack_serial)
	projectile.position = source.position + direction.normalized() * 8
	projectiles.add_child(projectile)

func closest_interaction() -> Dictionary:
	if player == null or state == null: return {}
	var best: Dictionary = {}
	var distance: float = 48
	for actor: Node in actors:
		if actor.kind not in ["chief","hunter","healer","smith","gatherer"]: continue
		var next: float = player.position.distance_to(actor.position)
		if next < distance:
			distance = next
			best = {"type":"npc", "id":actor.kind, "name":actor.display_name}
	for id: String in item_nodes:
		var item: Node2D = item_nodes[id]
		var next: float = player.position.distance_to(item.position)
		if next < distance:
			distance = next
			best = {"type":"item","id":id,"name":item_name(item.get_meta("data").kind)}
	for checkpoint: String in content.checkpoints:
		var next: float = player.position.distance_to(content.checkpoints[checkpoint])
		if next < distance:
			distance = next
			best = {"type":"checkpoint","id":checkpoint,"name":"Nghỉ tại " + content.names[checkpoint]}
	if player.position.distance_to(Vector2(1810,1190)) < distance:
		best = {"type":"altar","id":"altar","name":"Tế đàn cổ"}
	return best

func interaction_prompt() -> String:
	var candidate: Dictionary = closest_interaction()
	return "[E]  " + candidate.name if not candidate.is_empty() else "WASD  ·  Q thuốc  ·  Space né  ·  Esc nhật ký"

func interact() -> void:
	var candidate: Dictionary = closest_interaction()
	if candidate.is_empty(): return
	match candidate.type:
		"npc": talk(candidate.id)
		"checkpoint":
			state.activate_checkpoint(candidate.id)
			state.hp = 100
			player.health.hp = 100
			sfx("heal",player.position)
			notify("Đã nghỉ tại %s. Hồi đầy máu và ghi điểm hồi sinh." % content.names[candidate.id])
		"altar":
			if state.light_altar():
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
				sfx("quest" if data.kind == "ember" else "pickup",player.position)
				notify("Đã nhận: " + item_name(data.kind))
				item_nodes.erase(candidate.id)
				node.queue_free()
			else: notify("Túi đã đầy. Vật phẩm vẫn ở đây; dùng bớt rồi quay lại.")

func item_name(kind: String) -> String:
	return {"ember":"Tàn lửa", "herb":"Dược thảo", "bag":"Túi của Lâm", "potion":"Bình thuốc", "stone":"Túi đá (+4)"}.get(kind,kind)

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
		"chief":
			if state.finish_main():
				sfx("quest")
				ui.ending()
			elif not state.accepted.has("main"):
				ui.dialogue("Già làng An","Ngọn lửa làng sắp tắt. Ba tàn lửa của rừng còn ở phía đông, bên suối phía nam, và trong phế tích đông nam.\n\nLính canh giữ chúng. Mang đủ ba đến tế đàn ở Phế Tích, thắp lại lửa rồi trở về đây. Con có nhận lời không?",[{"text":"Tôi sẽ mang lửa về", "action":func() -> void: accept_quest("main")}])
			else: ui.dialogue("Già làng An",state.objective() + "\n\nĐường mòn nối cả bốn vùng. Điểm nghỉ bên suối sẽ giúp con không phải quay về tận trại nếu ngã xuống.")
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
