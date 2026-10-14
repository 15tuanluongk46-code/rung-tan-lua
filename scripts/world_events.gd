extends Node2D
## Chapter gates, shortcuts, hazard clocks and landmarks share authoritative state.
const Content = preload("res://scripts/world_content.gd")
const Quests = preload("res://scripts/quest_registry.gd")
var game: Node
var nodes: Dictionary = {}
var gates: Array[StaticBody2D] = []
var clock: float = 0.0
var refresh: float = 0.0
var hazard_cooldown: float = 0.0
var view: Rect2
var bridge_gate: Rect2 = preload("res://scripts/world_routes.gd").bridge_rect("gate")
var bridge_data: Dictionary = preload("res://scripts/world_routes.gd").data.bridge
const HAZARDS: Array[Vector2] = [Vector2(1840,2040),Vector2(2120,2090),Vector2(1440,1940)]
const MUD: Array[Rect2] = [Rect2(120,1800,170,95),Rect2(730,1930,180,90)]
const WALLS: Array[Rect2] = [Rect2(1660,2082,20,318),Rect2(2240,2082,20,318)]

func _ready() -> void:
	y_sort_enabled = true
	for data: Dictionary in game.content.world_events():
		var marker := Node2D.new()
		marker.position = data.pos
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/props/"+data.kind+".png")
		sprite.position.y = -sprite.texture.get_height()/2.0
		marker.add_child(sprite)
		if data.id == "bridge": marker.z_index = -2
		add_child(marker)
		nodes[data.id] = marker
	for rect: Rect2 in [Rect2(0,1570,2400,30),Rect2(1660,2060,600,22),bridge_gate]:
		var body := StaticBody2D.new()
		body.position = rect.get_center()
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
		gates.append(body)
	for rect: Rect2 in WALLS:
		var body := StaticBody2D.new()
		body.position = rect.get_center()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
	refresh_state()

func gate_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	result.append_array(WALLS)
	if game.state == null or game.state.chapter == 1: result.append(Rect2(0,1570,2400,30))
	if game.state == null or game.state.stage < 5: result.append(Rect2(1660,2060,600,22))
	if game.state == null or not game.state.events.has("bridge"): result.append(bridge_gate)
	return result

func refresh_state() -> void:
	var state: RefCounted = game.state
	var opened: Array[bool] = [state != null and state.chapter == 2,state != null and state.stage >= 5,state != null and state.events.has("bridge")]
	for i: int in range(gates.size()):
		gates[i].collision_layer = 0 if opened[i] else 1
		gates[i].get_child(0).set_deferred("disabled",opened[i])
	for id: String in nodes:
		var node: Node2D = nodes[id]
		if state == null or state.chapter == 1:
			node.hide()
			continue
		node.show()
		node.get_child(0).modulate = Color(1.15,1.08,0.8) if state.events.has(id) else Color(0.82,0.92,0.95)
		if id == "bridge":
			var repaired: bool = state.events.has(id)
			node.get_child(0).texture = load("res://assets/props/bridge.png" if repaired else "res://assets/props/broken_bridge.png")
			var center := Vector2(bridge_data.deck_center[0],bridge_data.deck_center[1])
			node.get_child(0).position = center-node.position if repaired else Vector2(0,-32)
	queue_redraw()

func movement_factor(point: Vector2) -> float:
	if game.state != null and game.state.chapter == 2:
		for patch: Rect2 in MUD:
			if patch.has_point(point): return 0.75
	return 1.0

func is_lit(point: Vector2) -> bool:
	if game.state == null: return false
	for data: Dictionary in game.content.world_events():
		if data.kind == "lantern" and game.state.events.has(data.id) and data.pos.distance_to(point) < 170: return true
	return false

func _process(delta: float) -> void:
	if game.mode not in ["playing","test"]: return
	clock += delta
	hazard_cooldown = maxf(0,hazard_cooldown-delta)
	refresh -= delta
	if refresh <= 0:
		refresh = 0.1
		view = get_viewport().get_canvas_transform().affine_inverse()*get_viewport().get_visible_rect()
		for node: Node2D in nodes.values(): node.visible = game.state != null and game.state.chapter == 2 and view.grow(80).has_point(node.position)
		queue_redraw()
	if game.mode == "playing" and game.state.chapter == 2 and not game.state.events.has("boss") and fposmod(clock,4.0) > 3.0 and hazard_cooldown <= 0:
		for point: Vector2 in HAZARDS:
			if point.distance_to(game.player.position) < 22:
				hazard_cooldown = 1.0
				game.player.receive_hit(12,"coal_ground_"+str(int(clock)),null)
				break

func _draw() -> void:
	for patch: Rect2 in MUD:
		if patch.intersects(view):
			draw_rect(patch,Color(0.2,0.25,0.2,0.3))
			for i: int in range(12):
				var p: Vector2 = patch.position+Vector2((i*31)%int(patch.size.x),(i*17)%int(patch.size.y))
				draw_line(p,p+Vector2(8,0),Color(0.37,0.45,0.32,0.4),1)
	for rect: Rect2 in gate_rects():
		if not rect.intersects(view): continue
		draw_rect(rect,Color("3a302d"))
		for x: int in range(int(rect.position.x),int(rect.end.x),22):
			draw_line(Vector2(x,rect.position.y),Vector2(x+9,rect.end.y),Color("b77548"),3)
	if game.state == null or game.state.chapter != 2: return
	var phase: float = fposmod(clock,4.0)
	for data: Dictionary in game.content.world_events():
		if data.kind == "lantern" and game.state.events.has(data.id) and view.grow(80).has_point(data.pos):
			draw_circle(data.pos+Vector2(0,-20),36,Color(0.95,0.85,0.5,0.08))
	for point: Vector2 in HAZARDS:
		if not view.grow(32).has_point(point): continue
		var hot: bool = phase > 3 and not game.state.events.has("boss")
		draw_arc(point,22,0,TAU,24,Color(1.0,0.45,0.2,0.8 if hot else 0.25),2)
		if hot: draw_circle(point,19,Color(1.0,0.3,0.08,0.22))
		elif phase > 2.1: draw_arc(point,22,0,TAU*(phase-2.1)/0.9,24,Color("ffd18a"),2)

func interact(id: String) -> void:
	if game.state.chapter != 2: return
	if Quests.MEMORIES.has(id):
		game.state.memories[id] = true
		game.state.changed.emit()
		game.ui.dialogue("Ký ức của rừng",Quests.MEMORIES[id])
		return
	if id in ["bridge","bell"]:
		if game.state.claimed.has(id):
			game.notify("Đã nhận phần thưởng chờ." if game.state.collect_reward(id) else "Công trình đã hoàn thành. Phần thưởng được giữ nếu túi đầy.")
			return
		if game.state.reward(id):
			refresh_state()
			game.sfx("quest",nodes[id].position)
			game.notify(("Cầu đã sửa — đường tắt mở." if id == "bridge" else "Chuông đã ngân — điểm nghỉ mở.")+ (" Phần thưởng đang chờ; quay lại khi túi trống." if not game.state.rewards_received.has(id) else " Đã nhận thưởng."))
		else: game.notify("Nhận việc và tìm đủ 3 vật liệu. Túi đầy không chặn công trình; thưởng được giữ chờ nhận.")
		return
	for data: Dictionary in game.content.world_events():
		if data.id != id: continue
		for guard_id: String in data.get("guards",[]):
			if not game.state.killed.has(guard_id):
				game.notify("Kẻ canh giữ còn ở gần. Hạ chúng trước khi khôi phục nguồn.")
				return
	if game.state.complete_event(id):
		refresh_state()
		game.effects.burst(nodes[id].position,"altar" if id == "well" else "heal")
		game.sfx("quest",nodes[id].position)
		var title: String = id
		for data: Dictionary in game.content.world_events():
			if data.id == id: title = data.name
		game.notify("Đã khôi phục: " + title + ". " + game.state.objective())
		if id == "well": game.notify("Nguồn nước đã trong · Mở Né chuẩn. Né sát lúc đòn trúng để phản công!")
	else: game.notify("Đã hoàn thành hoặc chưa đúng bước. " + game.state.objective())
