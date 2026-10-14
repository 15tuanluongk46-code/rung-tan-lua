extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://captures/detail-polish")
	var result: Error = root.get_texture().get_image().save_png("user://captures/detail-polish/"+name+".png")
	print("DETAIL CAPTURE ",name," status=",result)
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
	var visual = game.player.visual
	visual.rig.use_trail = false
	for i: int in range(8):
		var direction := Vector2.from_angle(i*PI/4)
		for sample: Array in [["pull",0.04],["contact",0.08],["return",0.2]]:
			visual.start_action("thrust",direction,func() -> void: pass)
			visual.tick_action(sample[1])
			visual.pose(direction,false,"attack",sample[1])
			await capture("spear-%d-%s" % [i,sample[0]])
	for i: int in range(8):
		for sample: Array in [["pull",0.02],["release",0.06],["return",0.15]]:
			var direction := Vector2.from_angle(i*PI/4)
			visual.start_action("throw",direction,func() -> void: pass)
			visual.tick_action(sample[1])
			visual.pose(direction,false,"throw",sample[1])
			await capture("stone-%d-%s" % [i,sample[0]])
	visual.cancel_action()
	visual.pose(Vector2.RIGHT,false,"idle",0)
	var coal: Node = load("res://scripts/enemy_actor.gd").new()
	coal.setup(game,{"id":"capture_coal","kind":"coal","pos":Vector2(490,430)},100)
	game.world.add_child(coal)
	coal.hide()
	for entry: Array in [["archer","bow"],["shaman","cast"],["coal","slam"],["hunter","bow"],["smith","slam"]]:
		var actor: Node = coal if entry[0] == "coal" else game.actor_by_id(entry[0]+"_0" if entry[0] in ["archer","shaman"] else entry[0])
		actor.show()
		actor.position = game.player.position+Vector2(60,0)
		for i: int in [0,2,4,6]:
			var direction := Vector2.from_angle(i*PI/4)
			actor.visual.cancel_action()
			actor.visual.pose(direction,false,"idle",0)
			await capture("%s-%d-idle" % [entry[0],i])
			for sample: Array in [["pull",0.03],["contact",0.1],["return",0.22]]:
				actor.visual.start_action(entry[1],direction,func() -> void: pass)
				actor.visual.tick_action(sample[1])
				actor.visual.pose(direction,false,"attack",sample[1])
				await capture("%s-%d-%s" % [entry[0],i,sample[0]])
		actor.hide()
		actor.visual.cancel_action()
		actor.position = actor.home
	coal.queue_free()
	await process_frame
	game.ui.root.show()
	for actor: Node in game.actors: actor.show()
	for entry: Array in [["camp",Vector2(430,430)],["npc",Vector2(420,365)],["item",Vector2(390,430)]]:
		game.player.position = entry[1]
		game.camera.reset_smoothing()
		game.ui.previous_region = ""
		game.ui.notify("Đã nghỉ tại Trại Tro. Hồi đầy máu và ghi điểm hồi sinh.")
		game.ui.interaction_clock = 0
		game.ui._process(0.016)
		await capture("hud-"+entry[0])
	game.settings.large_text = true
	game.ui.refresh_text_sizes(game.ui.root)
	game.ui._process(0.016)
	await capture("hud-large")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	quit()
