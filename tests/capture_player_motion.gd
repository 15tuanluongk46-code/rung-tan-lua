extends SceneTree
var game: Node
var sequence: int = 0
func _initialize() -> void: call_deferred("run")
func snapshot() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://captures/player-motion/frames/frame-%04d.png" % sequence)
	sequence += 1
func run() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(2))
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
	DirAccess.make_dir_recursive_absolute("user://captures/player-motion/frames")
	var visual = game.player.visual
	for octant: int in range(8):
		var direction := Vector2.from_angle(octant*PI/4)
		for i: int in range(6):
			visual.pose(direction,i>2,"run" if i>2 else "idle",i/60.0)
			await snapshot()
		visual.start_action("thrust",direction,func() -> void: pass)
		for i: int in range(22):
			visual.tick_action(1.0/60)
			visual.pose(direction,false,"idle",i/60.0)
			await snapshot()
	for action: String in ["heavy","throw","charge","dodge","hurt","dead"]:
		for octant: int in [0,2,4,6]:
			var direction := Vector2.from_angle(octant*PI/4)
			visual.cancel_action()
			visual.last_action = "idle"
			if action in ["heavy","throw"]: visual.start_action(action,direction,func() -> void: pass)
			for i: int in range(28):
				if action in ["heavy","throw"]: visual.tick_action(1.0/60)
				visual.pose(direction,false,"idle" if action in ["heavy","throw"] else action,i/60.0)
				await snapshot()
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("PLAYER MOTION CAPTURE: ",sequence," consecutive 60fps frames, 8 spear directions + actions")
	quit()
