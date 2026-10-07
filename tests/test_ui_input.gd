extends SceneTree
## End-to-end input/render smoke, without invoking gameplay attack/movement methods.
var failures: int = 0
var checks: int = 0
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func frames(count: int) -> void:
	for index: int in range(count): await physics_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://captures")
	check(get_root().get_texture().get_image().save_png("user://captures/"+name+".png") == OK,"save " + name)

func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames(3)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)

func run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	await capture("menu")
	var focus: Control = root.gui_get_focus_owner()
	check(focus is Button and focus.text == "Bắt đầu hành trình","new game button receives keyboard focus")
	await press("ui_accept")
	check(game.mode == "playing","Enter on focused button starts actual game")
	var before: Vector2 = game.player.position
	Input.action_press("move_right")
	await frames(25)
	Input.action_release("move_right")
	check(game.player.position.x > before.x + 20,"continuous WASD input moves through physics world")
	var stones: int = game.state.stones
	await press("throw")
	check(game.state.stones == stones-1,"throw input spends exactly one stone")
	await press("dodge")
	check(game.player.dodge_cooldown > 0,"dodge input runs action")
	await press("pause")
	check(game.mode == "paused","Escape opens pause through event dispatch")
	before = game.player.position
	Input.action_press("move_right")
	await frames(10)
	Input.action_release("move_right")
	check(game.player.position == before,"movement input cannot move while paused")
	await capture("pause")
	game.ui.settings(game.ui.pause_menu)
	await frames(3)
	await capture("settings")
	var box: Node = game.ui.modal.get_child(1).get_child(0)
	var sliders: Array[HSlider] = []
	for child: Node in box.get_children():
		for control: Node in child.get_children():
			if control is HSlider: sliders.append(control)
	check(sliders.size() == 4,"four bus sliders exist")
	var buses: Array[String] = ["Master","Music","Ambient","SFX"]
	var original: Dictionary = game.settings.volumes.duplicate()
	for index: int in range(sliders.size()):
		sliders[index].value = 0.25
		check(is_equal_approx(game.settings.volumes[buses[index]],0.25),"slider bound to " + buses[index])
		check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(buses[index])),0.25),"actual bus " + buses[index])
	game.settings.volumes = original
	game.settings.apply(game.audio)
	game.settings.save()
	await press("pause")
	check(game.mode == "paused","Escape from settings returns pause")
	await press("pause")
	check(game.mode == "playing","Escape resumes game")
	await capture("gameplay-input")
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("UI INPUT TESTS: %d checks, %d failures; actual input/physics smoke, not a complete human playthrough" % [checks,failures])
	quit(1 if failures else 0)
