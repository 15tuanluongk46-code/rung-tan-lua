extends SceneTree
## Actual sequential animation renders, not repeated pose stills.
var game: Node
func _initialize() -> void: call_deferred("run")
func run() -> void:
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
	DirAccess.make_dir_recursive_absolute("user://captures/action-sync/frames")
	var frame: int = 0
	for octant: int in range(8):
		var direction := Vector2.from_angle(octant*PI/4)
		game.player.visual.start_action("thrust",direction,func() -> void: pass)
		for i: int in range(24):
			game.player.visual.tick_action(1.0/60)
			game.player.visual.pose(direction,false,"idle",i/60.0)
			await process_frame
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			image.save_png("user://captures/action-sync/frames/frame-%04d.png" % frame)
			frame += 1
	for kind: String in ["hunter","smith"]:
		var actor = game.actor_by_id(kind)
		actor.show()
		actor.position = game.player.position+Vector2(55,0)
		actor.visual.pose(Vector2.LEFT,false,"idle",0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://captures/action-sync/"+kind+"-hands.png")
		actor.hide()
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("ACTION SYNC CAPTURE: ",frame," sequential render frames; fixed 1/60 animation clock")
	quit()
