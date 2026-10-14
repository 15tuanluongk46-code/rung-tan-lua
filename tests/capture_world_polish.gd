extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("run")
func run() -> void:
	# Script errors must not strand a visible fixture indefinitely.
	create_timer(35).timeout.connect(func() -> void: quit(2))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.state.accept("main")
	for id: String in ["forest","creek","ruins"]: game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar()
	game.state.finish_main()
	game.continue_chapter()
	game.mode = "test"
	game.ui.set_process(false)
	game.ui.root.hide()
	game.effects.hide()
	for actor: Node in game.actors:
		if actor != game.player: actor.hide()
	DirAccess.make_dir_recursive_absolute("user://captures/world-polish")
	for entry: Array in [["camp-turn",Vector2(760,465)],["camp-clearing",Vector2(430,430)],["creek-bank",Vector2(300,1060)],["bridge-north",Vector2(297,980)],["bridge-south",Vector2(337,1201)],["north-marsh",Vector2(530,1598)],["north-ash",Vector2(1740,1598)],["marsh-junction",Vector2(620,1910)],["south-seam",Vector2(1200,1901)],["ash-junction",Vector2(1850,1930)],["ruins-court",Vector2(1810,1190)],["tower-court",Vector2(1960,2220)],["well",Vector2(900,2120)],["hut",Vector2(460,1710)],["repair-before",Vector2(570,1990)],["repair-after",Vector2(570,1990)]]:
		if entry[0] == "repair-after":
			game.state.events["bridge"] = true
			game.world_events.refresh_state()
		game.player.position = entry[1]
		game.camera.reset_smoothing()
		game.player.visual.cancel_action()
		game.player.visual.pose(Vector2.RIGHT,false,"idle",0)
		for i: int in range(3): await process_frame
		game.art._update_visibility()
		await RenderingServer.frame_post_draw
		var error: Error = root.get_texture().get_image().save_png("user://captures/world-polish/"+entry[0]+".png")
		print("WORLD POLISH CAPTURE ",entry[0]," status=",error)
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	quit()
