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
	theme_ui.set_stylebox("normal", "Button", style(Color("342a28"),Color("766048"),8))
	theme_ui.set_stylebox("hover", "Button", style(Color("574032"),Color("d7a15c"),8))
	theme_ui.set_stylebox("pressed", "Button", style(Color("765038"),Color("ffd59a"),8))
	theme_ui.set_stylebox("focus", "Button", style(Color(0,0,0,0),Color("ffd18a"),2))
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_ui
	add_child(root)
	build_hud()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)

func style(fill: Color, border: Color, padding: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box

func label(text: String, size: int = 12) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",size)
	return node

func box_at(parent: Control, rect: Rect2) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel",style(Color(0.085,0.07,0.075,0.94),Color("69533c"),12))
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
	var box: VBoxContainer = box_at(hud,Rect2(12,12,236,78))
	region = label("TRẠI TRO",13)
	box.add_child(region)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(210,9)
	hp_bar.show_percentage = false
	hp_bar.add_theme_stylebox_override("background",style(Color("31282a"),Color("55403a"),0))
	hp_bar.add_theme_stylebox_override("fill",style(Color("bc653f"),Color("dfa36a"),0))
	box.add_child(hp_bar)
	inventory = label("")
	box.add_child(inventory)
	var bottom: VBoxContainer = box_at(hud,Rect2(12,300,616,48))
	objective = label("")
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(objective)
	prompt = label("")
	prompt.position = Vector2(180,264)
	prompt.size = Vector2(420,25)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color",Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(prompt)
	toast = label("")
	toast.position = Vector2(260,14)
	toast.size = Vector2(362,75)
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toast.add_theme_color_override("font_shadow_color",Color.BLACK)
	toast.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(toast)
	set_nonblocking(hud)

func set_nonblocking(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children(): set_nonblocking(child)

func _process(delta: float) -> void:
	if game == null: return
	toast_left -= delta
	toast.visible = toast_left > 0
	hud.visible = game.mode in ["playing", "test"]
	if game.state == null or game.player == null: return
	hp_bar.value = game.state.hp
	inventory.text = "Máu %d  ·  Thuốc %d/6  ·  Đá %d/30" % [game.state.hp,game.state.potions,game.state.stones]
	region.text = game.content.names[game.content.region_at(game.player.position)].to_upper()
	objective.text = game.state.objective()
	prompt.text = game.interaction_prompt()

func notify(text: String) -> void:
	toast.text = text
	toast_left = 4.5

func clear() -> void:
	for child: Node in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.hide()

func sheet(title: String, subtitle: String = "") -> VBoxContainer:
	clear()
	modal.show()
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02,0.025,0.03,0.83)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var box: VBoxContainer = box_at(modal,Rect2(82,16,476,328))
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
	parent.add_child(scroll)
	var body: Label = label(text)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("line_spacing",4)
	scroll.add_child(body)

func button(parent: Control, text: String, callback: Callable, focus: bool = false) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.custom_minimum_size.y = 30
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.pressed.connect(func() -> void:
		game.sfx("click")
		callback.call())
	parent.add_child(node)
	if focus: focus_when_ready.call_deferred(node)
	return node

func focus_when_ready(node: Button) -> void:
	if is_instance_valid(node) and node.is_inside_tree(): node.grab_focus()

func main_menu() -> void:
	game.mode = "menu"
	var box: VBoxContainer = sheet("RỪNG TÀN LỬA", "MỘT CHUYẾN ĐI QUA TRO TÀN  /  PHIÊU LƯU SINH TỒN")
	paragraph(box,"Ba đốm lửa còn ngủ dưới tán rừng.\nMang chúng về trước khi ký ức cuối cùng của làng tắt hẳn.")
	button(box,"Bắt đầu hành trình",game.start_game,true)
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

func settings(back: Callable) -> void:
	return_action = back
	var box: VBoxContainer = sheet("CÀI ĐẶT", "CÀI ĐẶT ĐƯỢC LƯU · HÀNH TRÌNH KHÔNG ĐƯỢC LƯU")
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
			game.settings.volumes[bus] = value
			game.settings.apply(game.audio)
			game.settings.save())
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
	button(box,"Trở lại",back,true)

func credits() -> void:
	return_action = main_menu
	var box: VBoxContainer = sheet("BÊN ÁNH LỬA", "RỪNG TÀN LỬA · 2026")
	paragraph(box,"Một hành trình nhỏ về việc giữ lại điều quý giá.\n\nĐược xây dựng bằng Godot Engine.\nPixel art và âm thanh: bộ tài nguyên gốc của dự án; xem LICENSE và tài liệu tài nguyên khi bàn giao.\nChữ Việt: DejaVu Sans — giấy phép trong assets/fonts.\n\nKhông có mua hàng, tài khoản hay kết nối mạng. Chỉ cài đặt được lưu trên máy.\n\nCảm ơn bạn đã mang lửa về.")
	button(box,"Trở lại",main_menu,true)

func pause_menu() -> void:
	game.mode = "paused"
	return_action = game.resume
	var box: VBoxContainer = sheet("NGHỈ BÊN ĐƯỜNG", "THỜI GIAN TẠM DỪNG")
	var state: RefCounted = game.state
	paragraph(box,state.objective() + "\n\nThuốc của Mai: %d/5 cây · %s\nTúi của Lâm: %s\nĐiểm hồi sinh: %s\nThời gian: %s · Đã ngã: %d" % [state.herbs,"đã nhận thưởng" if state.claimed.has("herbs") else "gặp Mai để nhận việc", "đã trả" if state.claimed.has("bag") else ("đang mang" if state.bag else "gần gấu ở Bờ Suối"), game.content.names[state.checkpoint], game.time_text(),state.deaths])
	button(box,"Tiếp tục",game.resume,true)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	box.add_child(row)
	button(row,"Cách chơi",func() -> void: help(pause_menu))
	button(row,"Cài đặt",func() -> void: settings(pause_menu))
	button(row,"Rời hành trình",func() -> void: confirm_exit(true))

func dialogue(title: String, text: String, options: Array[Dictionary] = []) -> void:
	game.mode = "dialogue"
	return_action = game.resume
	var box: VBoxContainer = sheet(title,"LỜI KỂ BÊN RỪNG")
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
	paragraph(box,"Già làng An đặt tay lên ngọn lửa: “Rừng còn nhớ chúng ta.”\n\nBa tàn lửa đã sáng lại. Những người ở Trại Tro sẽ không phải đón một đêm tối nữa.\n\nThời gian hành trình: %s\nKẻ địch đã hạ: %d · Số lần ngã: %d\nNhiệm vụ phụ hoàn thành: %d/2\nTổng sát thương đã nhận: %d" % [game.time_text(),game.state.killed.size(),game.state.deaths,game.state.claimed.size(),game.state.damage_taken])
	button(box,"Một hành trình mới",game.start_game,true)
	button(box,"Về màn hình chính",main_menu)

func confirm_exit(to_menu: bool) -> void:
	var previous: String = game.mode
	game.mode = "paused"
	return_action = func() -> void:
		if previous == "dead": death()
		elif previous == "ending": ending()
		elif game.state != null and previous != "menu": pause_menu()
		else: main_menu()
	var box: VBoxContainer = sheet("RỜI NGỌN LỬA?", "HÀNH TRÌNH KHÔNG ĐƯỢC LƯU KHI THOÁT")
	paragraph(box,"Mọi tiến độ trong lần chơi này sẽ mất khi rời hành trình. Chỉ âm lượng và cài đặt hình ảnh được lưu.\n\nBạn có chắc muốn tiếp tục?")
	button(box,"Ở lại",return_action,true)
	button(box,"Rời hành trình" if to_menu else "Thoát trò chơi",func() -> void:
		if to_menu: main_menu()
		else: game.get_tree().quit())

func escape() -> void:
	if game.mode == "playing": pause_menu()
	elif game.mode in ["paused", "dialogue"]:
		if return_action.is_valid(): return_action.call()
		else: game.resume()
	elif game.mode == "menu": main_menu()
