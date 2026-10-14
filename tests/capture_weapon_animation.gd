extends SceneTree
## Frame-exact visual fixture, no effects/trails needed to read physical weapons.
var game: Node
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://captures/weapons")
	var error: Error = root.get_texture().get_image().save_png("user://captures/weapons/"+name+".png")
	print("WEAPON CAPTURE ",name," status=",error)
func run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.mode = "test"
	game.player.position = Vector2(430,430)
	game.camera.reset_smoothing()
	game.ui.toast_left = 0
	game.ui.previous_region = "camp"
	game.ui.region_banner_time = 0
	game.ui.hud.hide()
	for actor: Node in game.actors:
		if actor != game.player: actor.hide()
	game.effects.hide()
	var visual = game.player.visual
	visual.rig.use_trail = false
	for i: int in range(8):
		var direction := Vector2.from_angle(i*PI/4)
		for phase: Array in [["pull",0.04],["extend",0.085],["return",0.2]]:
			visual.start_action("thrust",direction,func() -> void: pass)
			visual.tick_action(phase[1])
			visual.pose(direction,false,"attack",1+phase[1])
			await capture("spear-"+str(i)+"-"+phase[0])
	visual.start_action("heavy",Vector2.RIGHT,func() -> void: pass)
	visual.tick_action(0.135)
	visual.pose(Vector2.RIGHT,false,"attack",2)
	await capture("charged-extend")
	var coal: Node = load("res://scripts/enemy_actor.gd").new()
	coal.setup(game,{"id":"capture_coal","kind":"coal","pos":Vector2(490,430)},100)
	game.world.add_child(coal)
	for entry: Array in [["archer","bow"],["shaman","cast"],["coal","slam"]]:
		var actor: Node = game.actor_by_id(entry[0]+"_0")
		if entry[0] == "coal": actor = coal
		actor.show()
		actor.position = game.player.position+Vector2(60,0)
		actor.visual.start_action(entry[1],Vector2.LEFT,func() -> void: pass)
		actor.visual.tick_action(0.04)
		actor.visual.pose(Vector2.LEFT,false,"attack",3)
		await capture(entry[0]+"-pull")
		actor.visual.tick_action(0.065)
		actor.visual.pose(Vector2.LEFT,false,"attack",3.1)
		await capture(entry[0]+"-release")
		actor.hide()
	visual.start_action("throw",Vector2.RIGHT,func() -> void: pass)
	visual.tick_action(0.03)
	visual.pose(Vector2.RIGHT,false,"throw",4)
	await capture("stone-windup")
	visual.tick_action(0.035)
	visual.pose(Vector2.RIGHT,false,"throw",4.1)
	await capture("stone-release")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	quit()
