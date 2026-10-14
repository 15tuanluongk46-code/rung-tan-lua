extends CanvasLayer
## Dark parchment, warm brass typography, focused keyboard navigation.
var game: Node
var root: Control
var hud: Control
var modal: Control
var hp_bar: ProgressBar
var inventory: Label
var objective: Label
var region: Label
var prompt: Label
var toast: Label
var toast_left: float = 0.0
var theme_ui: Theme
var return_action: Callable
var exit_confirmation_open: bool = false
var supplies: Label
var ember_icons: Array[TextureRect] = []
var region_banner: Label
var region_banner_time: float = 0.0
var previous_region: String = ""
var ember_flash_index: int = -1
var ember_flash_left: float = 0.0
var ceremony_left: float = 0.0
var transition_alpha: float = 0.0
var transition_target: float = 0.0
var backdrop: Texture2D = preload("res://assets/ui/mystic-forest.png")
const MapUI = preload("res://scripts/map_ui.gd")
const Quests = preload("res://scripts/quest_registry.gd")
var save_label: Label
var interaction_clock: float = 0.0
var cached_interaction: Dictionary = {}
var skill_status: Label
var refresh_elapsed: float = 0.0
var occupied_actors: Array[Rect2] = []

func setup(owner_game: Node) -> void:
	game = owner_game
	layer = 10
	theme_ui = Theme.new()
	theme_ui.default_font_size = 12
	if ResourceLoader.exists("res://assets/fonts/DejaVuSans.ttf"):
		theme_ui.default_font = load("res://assets/fonts/DejaVuSans.ttf")
	theme_ui.set_color("font_color", "Label", Color("ebd8b2"))
	theme_ui.set_color("font_color", "Button", Color("f5dfb2"))
	theme_ui.set_color("font_hover_color", "Button", Color("fff3cf"))
	theme_ui.set_stylebox("normal", "Button", style(Color("173735"),Color("6a795f"),8))
	theme_ui.set_stylebox("hover", "Button", style(Color("34564a"),Color("e3b36b"),8))
	theme_ui.set_stylebox("pressed", "Button", style(Color("665236"),Color("ffd59a"),8))
	theme_ui.set_stylebox("focus", "Button", style(Color(0,0,0,0),Color("ffd18a"),2))
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_ui
	theme_ui.default_font_size = 14 if game.settings.large_text else 12
	add_child(root)
	build_hud()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	save_label = label("",10)
	save_label.position = Vector2(442,340)
	save_label.size = Vector2(188,18)
	save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	save_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(save_label)

func style(fill: Color, border: Color, padding: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.shadow_color = Color(0.01,0.035,0.04,0.35)
	box.shadow_size = 3
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box

func label(text: String, size: int = 12) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.set_meta("base_font_size",size)
	node.add_theme_font_size_override("font_size",size+2 if game.settings.large_text and size <= 14 else size)
	return node

func box_at(parent: Control, rect: Rect2) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel",style(Color(0.035,0.085,0.09,0.95),Color("89734d"),12))
	parent.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	panel.add_child(box)
	return box

func build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var box: VBoxContainer = box_at(hud,Rect2(10,10,196,76))
	box.add_theme_constant_override("separation",4)
	region = label("TRẠI TRO",11)
	region.add_theme_color_override("font_color",Color("e7be7b"))
	box.add_child(region)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(168,7)
	hp_bar.show_percentage = false
	hp_bar.add_theme_stylebox_override("background",style(Color("31282a"),Color("55403a"),0))
	hp_bar.add_theme_stylebox_override("fill",style(Color("bc653f"),Color("dfa36a"),0))
	box.add_child(hp_bar)
	inventory = label("",10)
	box.add_child(inventory)
	var supply_row := HBoxContainer.new()
	supply_row.add_theme_constant_override("separation",6)
	box.add_child(supply_row)
	icon(supply_row,"potion",Vector2(14,14))
	supplies = label("",10)
	supply_row.add_child(supplies)
	icon(supply_row,"stone",Vector2(14,14))
	var quest_box: VBoxContainer = box_at(hud,Rect2(434,10,196,58))
	quest_box.add_theme_constant_override("separation",3)
	var ember_row := HBoxContainer.new()
	ember_row.add_theme_constant_override("separation",8)
	quest_box.add_child(ember_row)
	for i: int in range(3): ember_icons.append(icon(ember_row,"ember",Vector2(16,16)))
	ember_row.add_child(label("TÀN LỬA",10))
	objective = label("",10)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_box.add_child(objective)
	var keys := label("WASD Đi · Space Né · Q Thuốc · M Map · Esc Nhật ký",9)
	keys.position = Vector2(12,339)
	keys.add_theme_color_override("font_color",Color("c1ccb4"))
	keys.add_theme_color_override("font_shadow_color",Color("09171e"))
	keys.add_theme_constant_override("shadow_offset_y",1)
	hud.add_child(keys)
	prompt = label("")
	prompt.position = Vector2(160,264)
	prompt.size = Vector2(200,25)
	prompt.clip_text = true
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_stylebox_override("normal",style(Color(0.025,0.07,0.08,0.88),Color("94744b"),4))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color",Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(prompt)
	toast = label("")
	toast.position = Vector2(216,12)
	toast.size = Vector2(208,68)
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_stylebox_override("normal",style(Color(0.02,0.07,0.07,0.92),Color("89734d"),4))
	toast.add_theme_color_override("font_shadow_color",Color.BLACK)
	toast.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(toast)
	var vignette: ColorRect = ColorRect.new()
	vignette.name = "DamageVignette"
	var vignette_material := ShaderMaterial.new()
	vignette_material.shader = preload("res://assets/shaders/damage_vignette.gdshader")
	vignette.material = vignette_material
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(vignette)
	hud.move_child(vignette,0)
	region_banner = label("",17)
	region_banner.position = Vector2(210,92)
	region_banner.size = Vector2(220,24)
	region_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_banner.add_theme_color_override("font_color",Color("f6daa2"))
	region_banner.add_theme_color_override("font_shadow_color",Color("0b2125"))
	region_banner.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(region_banner)
	skill_status = label("",10)
	skill_status.position = Vector2(150,310)
	skill_status.size = Vector2(340,16)
	skill_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_status.add_theme_color_override("font_shadow_color",Color.BLACK)
	skill_status.add_theme_constant_override("shadow_offset_y",1)
	hud.add_child(skill_status)
	set_nonblocking(hud)

func icon(parent: Node, kind: String, dimensions: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load("res://assets/props/%s.png" % kind)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = dimensions
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(node)
	return node

func set_nonblocking(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children(): set_nonblocking(child)

func _process(delta: float) -> void:
	if game == null: return
	if game.settings.reduced_motion:
		modal.modulate.a = 1.0
		hud.modulate.a = 1.0
	else:
		modal.modulate.a = move_toward(modal.modulate.a,1.0,delta*6)
		hud.modulate.a = move_toward(hud.modulate.a,1.0,delta*6)
	if save_label != null:
		save_label.text = game.save_status if game.autosave_enabled else ""
		save_label.modulate = Color("ffb488") if game.save_failures > 0 else Color("b3c9b4")
	hud.visible = game.mode in ["playing", "test"]
	if not hud.visible: return
	toast_left -= delta
	toast.visible = toast_left > 0
	hud.visible = game.mode in ["playing", "test"]
	var vignette_node: ColorRect = hud.get_node_or_null("DamageVignette") as ColorRect
	if vignette_node != null:
		var danger: float = 1.0 - float(game.state.hp) / 100.0 if game.state != null else 0.0
		vignette_node.material.set_shader_parameter("amount",clampf((danger-0.5)*0.4,0.0,0.2))
	if game.state == null or game.player == null: return
	refresh_elapsed += delta
	if refresh_elapsed < 1.0/30.0 and interaction_clock > 0: return
	delta = refresh_elapsed
	refresh_elapsed = 0
	occupied_actors.clear()
	var canvas: Transform2D = game.world.get_global_transform_with_canvas()
	for actor: Node2D in game.actors:
		if is_instance_valid(actor) and actor.visible:
			occupied_actors.append(Rect2(canvas*actor.position+Vector2(-22,-76),Vector2(44,88)))
	hp_bar.value = game.state.hp
	inventory.text = "SINH LỰC  %d / 100" % game.state.hp
	supplies.text = "%d/6 [Q]      %d/30" % [game.state.potions,game.state.stones]
	skill_status.text = ""
	if game.player.abilities.charging: skill_status.text = "TÍCH LỰC · " + ("THẢ ĐỂ ĐÂM" if game.player.abilities.charge >= 0.55 else "ĐANG CHUẨN BỊ")
	elif game.player.abilities.counter_left > 0: skill_status.text = "NÉ CHUẨN · PHẢN CÔNG!"
	var current_region: String = game.content.region_at(game.player.position)
	region.text = game.content.names[current_region].to_upper()
	if previous_region != current_region:
		previous_region = current_region
		region_banner.text = region.text
		region_banner_time = 2.6
	region_banner_time = maxf(0,region_banner_time-delta)
	region_banner.modulate.a = minf(1,region_banner_time)
	region_banner.visible = region_banner_time > 0 and not game.in_combat() and not overlaps_actor(Rect2(region_banner.position,region_banner.size))
	if toast.visible:
		var best_toast: Vector2 = Vector2(216,12)
		var toast_score: float = INF
		for placement: Vector2 in [Vector2(216,12),Vector2(12,264),Vector2(420,264),Vector2(216,264)]:
			var score: float = actor_overlap_area(Rect2(placement,toast.size))
			# Keep the warm focal fire clear, including when resting directly beside it.
			for checkpoint: Vector2 in game.content.checkpoints.values():
				var point: Vector2 = game.world.get_global_transform_with_canvas()*checkpoint
				if Rect2(placement,toast.size).intersects(Rect2(point-Vector2(25,44),Vector2(50,58))): score += 6000
			if placement.y > 100: score += 50
			if score < toast_score:
				toast_score = score
				best_toast = placement
		toast.position = best_toast
	for i: int in range(3):
		var lit: bool = game.state.embers.has(["forest","creek","ruins"][i])
		var pulse: float = 1.0 + sin((ember_flash_left)*16.0)*0.12 if not game.settings.reduced_motion and i == ember_flash_index and ember_flash_left > 0.0 else 1.0
		ember_icons[i].scale = Vector2.ONE * pulse
		ember_icons[i].modulate = Color.WHITE if lit else Color(0.45,0.51,0.51,0.5)
	ember_flash_left = maxf(0.0,ember_flash_left-delta)
	ceremony_left = maxf(0.0,ceremony_left-delta)
	objective.text = "Tìm tàn lửa  %d / 3" % game.state.embers.size()
	if not game.state.accepted.has("main"): objective.text = "Gặp già làng An"
	elif game.state.altar_lit: objective.text = "Trở về gặp An"
	elif game.state.embers.size() == 3: objective.text = "Thắp tế đàn ở Phế Tích"
	if game.state.chapter == 2:
		objective.text = "Ch.II · " + ["Gặp Sen","Thắp 3 đèn","Giếng Nguồn","Gặp Tùng","Khôi phục van","Tháp Lửa","Trở về An"][game.state.stage]
	interaction_clock -= delta
	if interaction_clock <= 0:
		interaction_clock = 0.08
		var next: Dictionary = game.closest_interaction()
		# Stable within each displayed frame; refresh when the nearest object changes.
		cached_interaction = next
	var candidate: Dictionary = cached_interaction
	if candidate.get("type") == "item" and not game.item_nodes.has(candidate.id): candidate = {}
	prompt.visible = not candidate.is_empty()
	if not candidate.is_empty():
		prompt.text = "[E] " + candidate.name
		var font: Font = prompt.get_theme_font("font")
		var font_size: int = prompt.get_theme_font_size("font_size")
		var text_width: float = font.get_string_size(prompt.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+16
		prompt.size = Vector2(clampf(text_width,88,238),(font_size+4)*ceilf(text_width/238.0)+8)
		var point: Vector2 = game.player.position
		match candidate.type:
			"event", "bell_rest": point = candidate.pos
			"npc":
				var npc: Node = game.actor_by_id(candidate.id)
				if is_instance_valid(npc): point = npc.position
			"item": point = game.item_nodes[candidate.id].position
			"checkpoint": point = game.content.checkpoints[candidate.id]
			"altar": point = Vector2(1810,1190)
		var screen: Vector2 = game.world.get_global_transform_with_canvas()*point
		var placements: Array[Vector2] = [Vector2(screen.x-prompt.size.x/2,screen.y+22),Vector2(screen.x+30,screen.y-20),Vector2(screen.x-prompt.size.x-30,screen.y-20),Vector2(screen.x-prompt.size.x/2,screen.y-85),Vector2(320-prompt.size.x/2,286)]
		var best: Vector2 = placements[0]
		var best_score: float = INF
		for placement: Vector2 in placements:
			placement = placement.clamp(Vector2(8,126),Vector2(632-prompt.size.x,304-prompt.size.y))
			var rect := Rect2(placement,prompt.size)
			var score: float = actor_overlap_area(rect)+placement.distance_to(placements[0])*0.05
			if game.art != null:
				for prop: Node2D in game.art._props:
					if not prop.visible or prop.get_meta("kind","") not in ["tower","hut","forge","tent"]: continue
					var size: Vector2 = game.art.SIZES[prop.get_meta("kind")]
					var occupied: Rect2 = canvas*Rect2(prop.position-Vector2(size.x/2,size.y),size)
					if rect.intersects(occupied): score += rect.intersection(occupied).get_area()*0.4
			if toast.visible and rect.intersects(Rect2(toast.position,toast.size)): score += 10000
			if score < best_score:
				best_score = score
				best = placement
		prompt.position = best.round()

func actor_overlap_area(rect: Rect2) -> float:
	var area: float = 0
	for occupied: Rect2 in occupied_actors:
		if not rect.intersects(occupied): continue
		var overlap: Rect2 = rect.intersection(occupied)
		area += overlap.get_area()
	return area

func overlaps_actor(rect: Rect2) -> bool:
	return actor_overlap_area(rect)>0

func interaction_valid(candidate: Dictionary) -> bool:
	if candidate.is_empty() or game.player == null: return false
	var point: Vector2
	match candidate.get("type",""):
		"npc":
			var npc: Node = game.actor_by_id(candidate.id)
			if not is_instance_valid(npc): return false
			point = npc.position
		"item":
			if not game.item_nodes.has(candidate.id): return false
			point = game.item_nodes[candidate.id].position
		"checkpoint": point = game.content.checkpoints[candidate.id]
		"altar": point = game.content.ALTAR
		"event", "bell_rest": point = candidate.pos
		_: return false
	return game.player.position.distance_to(point)<48 and game.line_clear(game.player.position,point)

func selected_interaction() -> Dictionary:
	if not cached_interaction.is_empty():
		if interaction_valid(cached_interaction): return cached_interaction
		cached_interaction = {}
		return {}
	cached_interaction = game.closest_interaction()
	return cached_interaction

func notify(text: String) -> void:
	toast.text = text
	toast_left = clampf(2.0+text.length()*0.025,2.5,5.5)

func flash_ember_slot(index: int) -> void:
	ember_flash_index = clampi(index,0,2)
	ember_flash_left = 1.2

func begin_altar_ceremony() -> void:
	ceremony_left = 2.8
	region_banner.text = "TẾ ĐÀN THỨC TỈNH"
	region_banner_time = 2.8

func clear() -> void:
	exit_confirmation_open = false
	for child: Node in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.hide()
	hud.modulate.a = 1.0 if game.settings.reduced_motion else 0.45
	cached_interaction = {}
	interaction_clock = 0.0
	transition_alpha = 0.0
	transition_target = 0.0

func sheet(title: String, subtitle: String = "") -> VBoxContainer:
	clear()
	modal.show()
	modal.modulate.a = 1.0 if game.settings.reduced_motion else 0.35
	transition_alpha = 1.0
	transition_target = 0.0
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02,0.025,0.03,0.83)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	if title in ["RỪNG TÀN LỬA","LỬA ĐÃ TRỞ VỀ"]:
		var scenery := TextureRect.new()
		scenery.texture = backdrop
		scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		scenery.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.add_child(scenery)
		var veil := ColorRect.new()
		veil.color = Color(0.01,0.05,0.07,0.26 if title == "RỪNG TÀN LỬA" else 0.08)
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.add_child(veil)
	var box: VBoxContainer = box_at(modal,Rect2(82,16,476,328))
	if title in ["RỪNG TÀN LỬA","LỬA ĐÃ TRỞ VỀ"]:
		box.get_parent().add_theme_stylebox_override("panel",style(Color(0.025,0.065,0.07,0.82),Color("b99359"),12))
	box.add_child(label(title,23))
	if not subtitle.is_empty():
		var sub: Label = label(subtitle,10)
		sub.add_theme_color_override("font_color",Color("b69b79"))
		box.add_child(sub)
	var separator: HSeparator = HSeparator.new()
	box.add_child(separator)
	return box

func paragraph(parent: Control, text: String) -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 64
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	parent.add_child(scroll)
	var body: Label = label(text)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("line_spacing",4)
	scroll.add_child(body)

func _input(event: InputEvent) -> void:
	if not modal.visible or not event is InputEventKey or not event.pressed: return
	var amount: int = 0
	if event.keycode == KEY_PAGEDOWN: amount = 90
	elif event.keycode == KEY_PAGEUP: amount = -90
	elif root.get_viewport().gui_get_focus_owner() is ScrollContainer:
		if event.keycode == KEY_DOWN: amount = 24
		elif event.keycode == KEY_UP: amount = -24
	if amount == 0: return
	for reader: Node in modal.find_children("*","ScrollContainer",true,false):
		reader.scroll_vertical += amount
		get_viewport().set_input_as_handled()
		break

func button(parent: Control, text: String, callback: Callable, focus: bool = false) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.custom_minimum_size.y = 30
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.pressed.connect(func() -> void:
		game.sfx("click")
		callback.call())
	node.mouse_entered.connect(func() -> void:
		node.modulate = Color(1.08,1.03,0.92,1.0))
	node.mouse_exited.connect(func() -> void:
		node.modulate = Color.WHITE)
	parent.add_child(node)
	if focus: focus_when_ready.call_deferred(node)
	return node

func focus_when_ready(node: Button) -> void:
	if is_instance_valid(node) and node.is_inside_tree(): node.grab_focus()

func main_menu() -> void:
	game.mode = "menu"
	var box: VBoxContainer = sheet("RỪNG TÀN LỬA", "MỘT CHUYẾN ĐI QUA TRO TÀN  /  PHIÊU LƯU SINH TỒN")
	paragraph(box,"Ba đốm lửa còn ngủ dưới tán rừng.\nMang chúng về trước khi ký ức cuối cùng của làng tắt hẳn.")
	var has_save: bool = game.autosave_enabled and game.save_manager.available()
	if has_save: button(box,"Tiếp tục hành trình",game.continue_game,true)
	button(box,"Bắt đầu hành trình",request_new_game,not has_save)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	box.add_child(row)
	button(row,"Cách chơi",func() -> void: help(main_menu))
	button(row,"Cài đặt",func() -> void: settings(main_menu))
	button(row,"Tác giả",credits)
	button(box,"Thoát",func() -> void: confirm_exit(false))

func help(back: Callable) -> void:
	return_action = back
	var box: VBoxContainer = sheet("HÀNH TRANG", "ĐỌC DẤU HIỆU · CHỌN THỜI ĐIỂM · GIỮ NGỌN LỬA")
	paragraph(box,"W A S D — Di chuyển       Chuột — Ngắm\nChuột trái — Đâm giáo (25 sát thương)\nChuột phải — Ném đá; tiếng động thu hút kẻ địch\nSpace — Né, hồi sau 0,8 giây; né xuyên đòn đánh\nE — Nói chuyện / nhặt đồ / thắp lửa\nQ — Uống thuốc (+40 máu)       Esc — Tạm dừng\n\nKhi kẻ địch hiện NÉ NGAY, rời hướng tấn công. Cây và đá chắn đạn. Gấu tấn công cả bạn lẫn yêu tinh. Thú rừng không phải mục tiêu chiến đấu.\n\nTìm ba tàn lửa ở Rừng Sâu, Bờ Suối và Phế Tích; đánh bại lính canh để lấy lửa. Thắp tế đàn, rồi trở lại già làng. Hai việc phụ: thuốc của Mai và túi của Lâm.\n\nLửa trại và bờ suối là điểm hồi sinh. Khi ngã xuống, nhiệm vụ, đồ đã nhặt và địch đã hạ được giữ; kẻ địch sống sót hồi phục. Không lưu hành trình khi đóng trò chơi.")
	button(box,"Trở lại",back,true)
	for child: Node in box.get_children():
		if child is ScrollContainer and child.get_child_count() > 0:
			child.get_child(0).text = child.get_child(0).text.replace("Không lưu hành trình khi đóng trò chơi.","Hành trình tự lưu tại mốc nhiệm vụ và điểm nghỉ. [M] mở bản đồ khám phá; tiếp tục tại điểm nghỉ sau khi thoát.")
			child.get_child(0).text += "\n\nChương II: gặp Sen, thắp 3 đèn, thanh tẩy giếng, gặp Tùng và khôi phục 2 van. Cầu/chuông cần 3 vật liệu; để trống chỗ nhận thưởng. Than nóng báo vòng trước khi gây sát thương; bùn làm chậm.\n\nPageUp / PageDown cuộn văn bản. Tab chọn vùng đọc; ↑ / ↓ cuộn khi vùng đọc được chọn."
			child.get_child(0).text += "\n\nKỹ năng: ember đầu mở Shift + chuột trái tích lực (0,55 giây); thả để đâm mạnh, Space hủy. Giếng Nguồn mở Né chuẩn: 0,12 giây đầu né một đòn thực sắp trúng cho phản công 1,2 giây. Than kéo dài không thưởng né chuẩn. Tùng cho đổi lối Giáo / Đá / Sinh tồn. Công trình hoàn thành dù túi đầy, thưởng giữ chờ."

func settings(back: Callable) -> void:
	return_action = back
	var box: VBoxContainer = sheet("CÀI ĐẶT", "CÀI ĐẶT VÀ HÀNH TRÌNH ĐƯỢC LƯU TRÊN MÁY")
	box.add_theme_constant_override("separation",4)
	var bus_names: Dictionary = {"Master":"Tổng", "Music":"Âm nhạc", "Ambient":"Thiên nhiên", "SFX":"Hiệu ứng"}
	for bus: String in bus_names:
		var row: HBoxContainer = HBoxContainer.new()
		box.add_child(row)
		var name_label: Label = label(bus_names[bus])
		name_label.custom_minimum_size.x = 100
		row.add_child(name_label)
		var slider: HSlider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = game.settings.volumes[bus]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y = 23
		row.add_child(slider)
		slider.value_changed.connect(func(value: float) -> void:
			game.settings.set_bus(game.audio,bus,value))
	var shake_toggle: CheckButton = CheckButton.new()
	shake_toggle.text = "Rung màn hình khi trúng đòn"
	shake_toggle.button_pressed = game.settings.screenshake
	box.add_child(shake_toggle)
	shake_toggle.toggled.connect(func(value: bool) -> void:
		game.settings.screenshake = value
		game.settings.save())
	var full: CheckButton = CheckButton.new()
	full.text = "Toàn màn hình"
	full.button_pressed = game.settings.fullscreen
	box.add_child(full)
	full.toggled.connect(func(value: bool) -> void:
		game.settings.fullscreen = value
		game.settings.apply(game.audio)
		game.settings.save())
	button(box,"Chữ, chuyển động và hiển thị",func() -> void: accessibility_settings(back))
	button(box,"Trở lại",func() -> void:
		if game.settings.dirty_left >= 0: game.settings.save()
		back.call(),true)

func accessibility_settings(back: Callable) -> void:
	return_action = func() -> void: settings(back)
	var box := sheet("HIỂN THỊ & DỄ ĐỌC","GIỮ CẢNH BÁO COMBAT RÕ RÀNG")
	box.add_theme_constant_override("separation",1)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var controls := VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation",3)
	scroll.add_child(controls)
	for entry: Array in [["large_text","Chữ lớn"],["reduced_motion","Giảm chuyển động / hit-stop"],["reduced_flash","Giảm nhấp nháy"],["vsync","VSync"]]:
		var toggle := CheckButton.new()
		toggle.text = entry[1]
		toggle.button_pressed = game.settings.get(entry[0])
		controls.add_child(toggle)
		toggle.toggled.connect(func(value: bool) -> void:
			game.settings.set(entry[0],value)
			game.settings.apply(game.audio)
			game.settings.mark_dirty()
			refresh_text_sizes(root))
	var cap := OptionButton.new()
	cap.add_item("Giới hạn 60 FPS",60)
	cap.add_item("Giới hạn 120 FPS",120)
	cap.selected = 0 if game.settings.frame_cap == 60 else 1
	cap.item_selected.connect(func(index: int) -> void:
		game.settings.frame_cap = cap.get_item_id(index)
		game.settings.apply(game.audio)
		game.settings.mark_dirty())
	controls.add_child(cap)
	var hitstop := OptionButton.new()
	hitstop.add_item("Khựng khi trúng đòn: Tắt",0)
	hitstop.add_item("Khựng khi trúng đòn: Nhẹ",1)
	hitstop.add_item("Khựng khi trúng đòn: Hiện tại",2)
	hitstop.selected = game.settings.hitstop_level
	hitstop.item_selected.connect(func(index: int) -> void:
		game.settings.hitstop_level = hitstop.get_item_id(index)
		game.settings.mark_dirty())
	controls.add_child(hitstop)
	button(box,"Ưu tiên mượt trên màn hình 60 Hz",func() -> void:
		game.settings.frame_cap = 60
		game.settings.vsync = true
		game.settings.apply(game.audio)
		game.settings.mark_dirty()
		accessibility_settings(back)).custom_minimum_size.y = 24
	button(box,"Trở lại",return_action,true)

func refresh_text_sizes(node: Node) -> void:
	theme_ui.default_font_size = 14 if game.settings.large_text else 12
	if node is Label and node.has_meta("base_font_size"):
		var size: int = node.get_meta("base_font_size")
		node.add_theme_font_size_override("font_size",size+2 if game.settings.large_text and size <= 14 else size)
	for child: Node in node.get_children(): refresh_text_sizes(child)

func credits() -> void:
	return_action = main_menu
	var box: VBoxContainer = sheet("BÊN ÁNH LỬA", "RỪNG TÀN LỬA · 2026")
	paragraph(box,"Một hành trình nhỏ về việc giữ lại điều quý giá.\n\nĐược xây dựng bằng Godot Engine.\nPixel art và âm thanh: bộ tài nguyên gốc của dự án; xem LICENSE và tài liệu tài nguyên khi bàn giao.\nChữ Việt: DejaVu Sans — giấy phép trong assets/fonts.\n\nKhông có mua hàng, tài khoản hay kết nối mạng. Chỉ cài đặt được lưu trên máy.\n\nCảm ơn bạn đã mang lửa về.")
	button(box,"Trở lại",main_menu,true)
	for child: Node in box.get_children():
		if child is ScrollContainer and child.get_child_count() > 0:
			child.get_child(0).text = child.get_child(0).text.replace("Chỉ cài đặt được lưu trên máy.","Cài đặt và hành trình được lưu trên máy; không cần tài khoản.")

func pause_menu() -> void:
	game.mode = "paused"
	return_action = game.resume
	var box: VBoxContainer = sheet("NGHỈ BÊN ĐƯỜNG", "THỜI GIAN TẠM DỪNG")
	var state: RefCounted = game.state
	var herbs_status: String = "gặp Mai để nhận việc"
	if state.claimed.has("herbs"): herbs_status = "đã nhận thưởng"
	elif state.accepted.has("herbs"):
		herbs_status = "đủ dược thảo — trở về gặp Mai" if state.herbs >= 5 else "đang thu thập"
	paragraph(box,state.objective() + "\n\nThuốc của Mai: %d/5 cây · %s\nTúi của Lâm: %s\nĐiểm hồi sinh: %s\nThời gian: %s · Đã ngã: %d" % [state.herbs,herbs_status, "đã trả" if state.claimed.has("bag") else ("đang mang" if state.bag else "gần gấu ở Bờ Suối"), game.content.names[state.checkpoint], game.time_text(),state.deaths])
	if state.chapter == 2:
		var quest_text: String = state.objective()+"\n\nCây cầu về nhà: %d/3 gỗ · %s\nTiếng chuông dưới tro: %d/3 mảnh · %s\nKý ức: %d/3\nĐiểm nghỉ: %s\nThời gian: %s · Đã ngã: %d" % [state.planks,"đã sửa" if state.claimed.has("bridge") else ("đang tìm" if state.accepted.has("bridge") else "gặp Sen"),state.bell_parts,"đã ngân" if state.claimed.has("bell") else ("đang tìm" if state.accepted.has("bell") else "gặp Tùng"),state.memories.size(),game.content.names[state.checkpoint],game.time_text(),state.deaths]
		for child: Node in box.get_children():
			if child is ScrollContainer: child.get_child(0).text = quest_text
	button(box,"Tiếp tục",game.resume,true)
	if game.state.chapter == 2 and game.state.stage >= 4: button(box,"Lối chiến đấu / điểm nghỉ",specialization_menu)
	box.add_theme_constant_override("separation",5)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	box.add_child(row)
	button(row,"Cách chơi",func() -> void: help(pause_menu))
	button(row,"Cài đặt",func() -> void: settings(pause_menu))
	button(row,"Bản đồ [M]",show_map)
	button(row,"Rời hành trình",func() -> void: confirm_exit(true))

func dialogue(title: String, text: String, options: Array[Dictionary] = []) -> void:
	if game.player != null: game.player.enter_dialogue()
	game.mode = "dialogue"
	return_action = game.resume
	var box: VBoxContainer = sheet(title,"LỜI KỂ BÊN RỪNG")
	var portrait_kind: String = {"Già làng An":"chief","Thầy thuốc Mai":"healer","Thợ săn Lâm":"hunter","Thợ rèn Bình":"smith","Người hái thuốc Nhi":"gatherer","Người giữ đèn Sen":"sen","Thợ lò Tùng":"tung"}.get(title,"")
	if not portrait_kind.is_empty():
		var heading: Label = box.get_child(0)
		box.remove_child(heading)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		box.add_child(row)
		box.move_child(row,0)
		var portrait := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/sprites/%s.png" % portrait_kind)
		atlas.region = Rect2(8,2,32,32)
		portrait.texture = atlas
		portrait.custom_minimum_size = Vector2(34,34)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(portrait)
		row.add_child(heading)
	paragraph(box,text)
	for option: Dictionary in options: button(box,option.text,option.action)
	button(box,"Khép lời thoại  [Esc]",game.resume,true)

func death() -> void:
	game.mode = "dead"
	var box: VBoxContainer = sheet("TRO CHƯA NGUỘI", "BẠN ĐÃ NGÃ XUỐNG — NHƯNG LỬA VẪN CÒN")
	paragraph(box,"Bạn sẽ tỉnh lại tại %s.\n\nNhiệm vụ, tàn lửa, đồ đã nhặt và kẻ địch đã hạ được giữ nguyên. Kẻ địch còn sống trở về vị trí ban đầu và hồi đầy máu. Đạn đang bay biến mất.\n\nHãy quan sát dấu hiệu ra đòn và dùng né để tìm khoảng trống." % game.content.names[game.state.checkpoint])
	button(box,"Đứng dậy",game.respawn,true)
	button(box,"Rời hành trình",func() -> void: confirm_exit(true))

func ending() -> void:
	game.mode = "ending"
	var box: VBoxContainer = sheet("LỬA ĐÃ TRỞ VỀ", "NGƯỜI ĐI QUA TRO TÀN")
	var summary: Label = label("Thời gian: %s\nKẻ địch đã hạ: %d · Số lần ngã: %d\nNhiệm vụ phụ hoàn thành: %d/%d · Ký ức: %d/3\nTổng sát thương đã nhận: %d" % [game.time_text(),game.state.killed.size(),game.state.deaths,game.state.claimed.size(),2 if game.state.chapter == 1 else 4,game.state.memories.size(),game.state.damage_taken],11)
	box.add_child(summary)
	paragraph(box,"Già làng An đặt tay lên ngọn lửa: “Rừng còn nhớ chúng ta.”\n\nBa tàn lửa đã sáng lại. Trại Tro sẽ không phải đón một đêm tối nữa." if game.state.chapter == 1 else "Nước nguồn đã trong. Người Giữ Than buông lời thề cũ. Trại Tro lại được sưởi ấm.\n\nHai chương hoàn thành · Sáu vùng đất")
	box.add_theme_constant_override("separation",4)
	if game.state.chapter == 1:
		button(box,"Tiếp tục Chương II",game.continue_chapter,true)
	button(box,"Một hành trình mới",request_new_game,game.state.chapter == 2)
	button(box,"Về màn hình chính",main_menu)

func confirm_exit(to_menu: bool) -> void:
	# Repeated OS close requests must not replace the original return context.
	if exit_confirmation_open: return
	var previous: String = game.mode
	game.mode = "paused"
	return_action = func() -> void:
		if previous in ["dead","dying"]: death()
		elif previous == "ending": ending()
		elif game.state != null and previous != "menu": pause_menu()
		else: main_menu()
	var box: VBoxContainer = sheet("RỜI NGỌN LỬA?", "TIẾN ĐỘ ĐƯỢC LƯU · TIẾP TỤC TẠI ĐIỂM NGHỈ")
	exit_confirmation_open = true
	paragraph(box,"Nhiệm vụ, vật phẩm và công trình đã khôi phục được lưu. Khi tiếp tục bạn xuất hiện tại điểm nghỉ đã chọn.\n\nBạn có chắc muốn rời hành trình?")
	button(box,"Ở lại",return_action,true)
	button(box,"Rời hành trình" if to_menu else "Thoát trò chơi",func() -> void:
		if not game.flush_save():
			dialogue("Chưa lưu được",game.save_manager.last_error)
			return_action = func() -> void: confirm_exit(to_menu)
			return
		if to_menu: main_menu()
		else: game.get_tree().quit())

func escape() -> void:
	if game.mode == "map":
		game.resume()
		return
	if game.mode == "playing": pause_menu()
	elif game.mode in ["paused", "dialogue"]:
		if return_action.is_valid(): return_action.call()
		else: game.resume()
	elif game.mode == "menu": main_menu()

func request_new_game() -> void:
	if not game.autosave_enabled or not game.save_manager.available():
		game.start_game()
		return
	game.mode = "paused"
	return_action = main_menu
	var box := sheet("HÀNH TRÌNH MỚI?","MỘT SLOT LƯU TRÊN MÁY")
	paragraph(box,"Hành trình mới sẽ thay thế tiến độ hiện tại. Bản dự phòng được giữ khi ghi thành công. Bạn muốn bắt đầu lại?")
	button(box,"Giữ hành trình hiện tại",main_menu,true)
	button(box,"Bắt đầu lại",game.start_game)

func show_map() -> void:
	game.mode = "map"
	clear()
	modal.show()
	var shade := ColorRect.new()
	shade.color = Color(0.01,0.035,0.04,0.95)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var map := MapUI.new()
	map.game = game
	map.position = Vector2(22,-8)
	modal.add_child(map)
	var box := box_at(modal,Rect2(382,16,242,328))
	box.add_child(label("BẢN ĐỒ RỪNG",18))
	var lore: String = ""
	for id: String in game.state.memories: lore += Quests.MEMORIES.get(id,"")+"\n\n"
	for quest: String in ["bridge","bell"]:
		if game.state.claimed.has(quest) and not game.state.rewards_received.has(quest): lore += "Thưởng chờ nhận: "+Quests.QUESTS[quest].title+"\n"
	paragraph(box,game.state.objective()+"\n\nVùng đã khám phá: %d/6\nKý ức: %d/3\n\n" % [game.state.discovered.size(),game.state.memories.size()] + lore)
	button(box,"Trở lại [M / Esc]",game.resume,true)
	button(box,"Về điểm nghỉ đã biết",checkpoint_menu)

func specialization_menu() -> void:
	game.player.enter_dialogue()
	game.mode = "dialogue"
	return_action = game.resume
	var box := sheet("LỐI CHIẾN ĐẤU","ĐỔI TẠI ĐIỂM NGHỈ HOẶC GẶP TÙNG")
	paragraph(box,"Giáo: phản công sau Né chuẩn thêm 8 sát thương.\nĐá: đá gây khựng quái thường 0,35 giây.\nSinh tồn: thuốc hồi 50 thay vì 40 HP.\n\nTúi đầy không mất thưởng công trình. Hiện chọn: "+{"":"chưa chọn","spear":"Giáo","stone":"Đá","survival":"Sinh tồn"}.get(game.state.specialization,""))
	var row := HBoxContainer.new()
	box.add_child(row)
	for entry: Array in [["spear","Giáo"],["stone","Đá"],["survival","Sinh tồn"]]:
		button(row,entry[1],func() -> void:
			var near_rest: bool = false
			for point: Vector2 in game.content.checkpoints.values():
				if point.distance_to(game.player.position) < 70: near_rest = true
			var tung: Node = game.actor_by_id("tung")
			if tung != null and tung.position.distance_to(game.player.position) < 70: near_rest = true
			if near_rest and not game.in_combat() and game.state.choose_specialization(entry[0]): game.notify("Đã chọn "+entry[1])
			else: game.notify("Đổi lối ở điểm nghỉ hoặc gặp Tùng, ngoài combat.")
			game.resume())
	button(box,"Nhận thưởng chờ",func() -> void:
		var received: bool = game.state.collect_reward("bridge")
		received = game.state.collect_reward("bell") or received
		game.resume()
		game.notify("Đã nhận thưởng chờ." if received else "Chưa có thưởng hoặc túi còn đầy."))
	button(box,"Trở lại",game.resume,true)

func checkpoint_menu() -> void:
	game.mode = "paused"
	return_action = game.resume
	var box := sheet("ĐƯỜNG VỀ","ĐIỂM NGHỈ ĐÃ KÍCH HOẠT · NGOÀI COMBAT")
	paragraph(box,"Trở về điểm nghỉ đã ghé để giảm đi lại. Không hồi máu tự động và không dùng được khi có địch gần.")
	for id: String in game.state.known_checkpoints:
		button(box,game.content.names[id],func() -> void: game.travel_checkpoint(id))
	button(box,"Trở lại",game.resume,true)
