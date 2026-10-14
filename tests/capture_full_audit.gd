extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i: int in range(25):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://captures/full-audit/"+name+".png")
func run() -> void:
	create_timer(35).timeout.connect(func() -> void: quit(2))
	game = load("res://scenes/Main.tscn").instantiate();root.add_child(game)
	await process_frame
	DirAccess.make_dir_recursive_absolute("user://captures/full-audit")
	game.start_game();game.mode = "test"
	game.player.position = Vector2(430,430);game.camera.reset_smoothing()
	game.ui.toast_left = 0;game.ui._process(.016)
	await capture("hud")
	game.settings.large_text = true;game.ui.refresh_text_sizes(game.ui.root)
	game.ui.settings(game.ui.main_menu);await capture("settings-large")
	game.ui.accessibility_settings(game.ui.main_menu);await capture("accessibility-large")
	game.ui.ending();await capture("ending-summary")
	game.ui.accessibility_settings(game.ui.main_menu)
	await process_frame;await process_frame
	for reader: Node in game.ui.modal.find_children("*","ScrollContainer",true,false):reader.scroll_vertical = 1000
	await capture("smooth-preset")
	game.state.accept("main")
	for id: String in ["forest","creek","ruins"]:game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar();game.state.finish_main();game.continue_chapter()
	game.mode = "test"
	for id: String in ["creek","forest","ruins","marsh","ash"]:game.state.discovered[id] = true
	game.state.landmarks.well = true
	game.state.stage = 2
	game.ui.show_map();await capture("map-large")
	game.ui.clear();game.ui.set_process(false);game.ui.root.hide()
	game.player.position = Vector2(530,1951);game.camera.reset_smoothing()
	game.player.visual.pose(Vector2.RIGHT,false,"idle",0)
	await capture("bridge-before")
	game.state.events.bridge = true;game.world_events.refresh_state()
	await capture("bridge-after")
	game.player.position = Vector2(430,430);game.camera.reset_smoothing()
	game.mode = "playing";game.player.health.invulnerable = 0
	game.player.receive_hit(1000,"capture_death",null)
	game.set_process(false)
	for i: int in range(6):
		game._process(.07)
		await capture("death-"+str(i))
	game.queue_free();await process_frame;await create_timer(.35).timeout;quit()
