extends SceneTree
## Deterministic graphical fixtures, separate from the input-driven journey.
var game: Node
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://captures/expansion")
	var error: Error = root.get_texture().get_image().save_png("user://captures/expansion/"+name+".png")
	print("EXPANSION CAPTURE ",name," status=",error)
func run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.autosave_enabled = false
	await capture("menu")
	game.start_game()
	game.state.accept("main")
	for id: String in ["forest","creek","ruins"]: game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar()
	game.state.finish_main()
	game.continue_chapter()
	game.player.position = game.content.centers.marsh
	game.camera.reset_smoothing()
	for i: int in range(60): await process_frame
	await capture("marsh")
	game.ui.pause_menu()
	await capture("journal")
	game.resume()
	game.state.discovered.marsh = true
	game.state.discovered.ash = true
	game.ui.show_map()
	await capture("map")
	game.resume()
	game.player.position = game.content.centers.ash
	game.camera.reset_smoothing()
	for i: int in range(60): await process_frame
	await capture("ash")
	game.state.stage = 5
	game.world_events.refresh_state()
	game.player.position = Vector2(1960,2190)
	game.camera.reset_smoothing()
	var boss = game.actor_by_id("guardian")
	game.mode = "test"
	for kind: int in range(3):
		boss.attack_kind = kind
		boss.ai_state = "windup"
		boss.target_point = game.player.position
		boss.aim_locked = Vector2.DOWN
		boss.queue_redraw()
		await capture("boss-cue-"+str(kind))
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	quit()
