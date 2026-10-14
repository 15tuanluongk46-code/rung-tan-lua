extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("run")
func run() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(2))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.mode = "test"
	game.player.position = Vector2(430,430)
	game.camera.reset_smoothing()
	game.ui.set_process(false)
	game.ui.root.hide()
	game.effects.hide()
	for actor: Node in game.actors:
		if actor != game.player: actor.hide()
	DirAccess.make_dir_recursive_absolute("user://captures/player-hands")
	var visual = game.player.visual
	for i: int in range(8):
		var direction := Vector2.from_angle(i*PI/4)
		for action: String in ["idle","run","charge"]:
			visual.cancel_action()
			visual.pose(direction,action == "run",action,0.25)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://captures/player-hands/%d-%s.png" % [i,action])
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("PLAYER REFERENCE: 24 rendered idle/run/charge samples")
	quit()
