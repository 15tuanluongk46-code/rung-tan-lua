extends SceneTree
var game: Node
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for i: int in range(25): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://captures/quality")
	check(root.get_texture().get_image().save_png("user://captures/quality/"+name+".png") == OK,"capture "+name)
func run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.settings.path = "user://quality-settings-fixture.cfg"
	game.settings.large_text = true
	game.settings.reduced_flash = true
	game.settings.reduced_motion = true
	game.ui.refresh_text_sizes(game.ui.root)
	game.ui.settings(game.ui.main_menu)
	await process_frame
	await process_frame
	var panel: Control = game.ui.modal.get_child(1)
	check(panel.position.y+panel.size.y <= 360,"large-text settings fits")
	await capture("settings-large")
	game.ui.accessibility_settings(game.ui.main_menu)
	await process_frame
	await process_frame
	panel = game.ui.modal.get_child(1)
	check(panel.position.y+panel.size.y <= 360,"accessibility settings fits")
	await capture("accessibility")
	game.ui.help(game.ui.main_menu)
	await process_frame
	await process_frame
	var readers: Array[Node] = game.ui.modal.find_children("*","ScrollContainer",true,false)
	var reader: ScrollContainer = readers[0]
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_PAGEDOWN
	game.ui._input(event)
	check(reader.scroll_vertical > 0,"PageDown scrolls help")
	await capture("help-large")
	game.start_game()
	game.state.accept("main")
	for id: String in ["forest","creek","ruins"]: game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar()
	game.state.finish_main()
	game.continue_chapter()
	game.state.memories.memory_marsh = true
	game.ui.show_map()
	readers = game.ui.modal.find_children("*","ScrollContainer",true,false)
	check("Miếu Chìm" in readers[0].get_child(0).text and "memory_marsh" not in readers[0].get_child(0).text,"lore is localized and readable again")
	await capture("map-lore")
	game.state.stage = 5
	game.world_events.refresh_state()
	game.player.position = Vector2(1960,2190)
	game.resume()
	game.camera.reset_smoothing()
	var boss = game.actor_by_id("guardian")
	boss._physics_process(0.016)
	check(game.audio.region == "boss","boss owns combat music")
	game.player.position = Vector2(1630,1790)
	boss._physics_process(0.016)
	check(game.audio.region == "ash" and not boss.music_owned,"disengage restores same-region music")
	game.mode = "test"
	game.player.position = Vector2(1960,2190)
	game.camera.reset_smoothing()
	game.ui.toast_left = 0
	game.ui.region_banner_time = 0
	game.ui.previous_region = "ash"
	game.ui._process(0.1)
	boss.ai_state = "windup"
	boss.attack_kind = 0
	boss.aim_locked = Vector2.DOWN
	boss.queue_redraw()
	await capture("boss-sector")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("ACCESSIBILITY: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
