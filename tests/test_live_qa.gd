extends SceneTree
## Observation-only QA fixture. No gameplay source changes, isolated saves.
var game: Node
func _initialize() -> void: call_deferred("run")
func run() -> void:
	create_timer(25).timeout.connect(func() -> void: quit(2))
	game = load("res://scenes/Main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.start_game();game.mode = "test"
	var v = game.player.visual
	v.cancel_action();v.last_action = "idle"
	v.pose(Vector2.RIGHT,false,"run",1.0)
	v.pose(Vector2.RIGHT,false,"dodge",1.0)
	v.pose(Vector2.RIGHT,false,"dodge",1.18)
	var first: float = v.sprite.get_meta("motion_time")
	v.pose(Vector2.RIGHT,false,"run",1.22)
	v.pose(Vector2.RIGHT,false,"dodge",1.8)
	var second: float = v.sprite.get_meta("motion_time")
	print("LIVE QA repeat_dodge first_start_then_late=",first," second_start=",second," restarted=",second<.01)
	v.pose(Vector2.RIGHT,false,"hurt",2.0)
	v.pose(Vector2.RIGHT,false,"hurt",2.18)
	game.player.visual.flash = .18
	v.pose(Vector2.RIGHT,false,"hurt",2.5)
	print("LIVE QA repeat_hurt start_frame_time=",v.sprite.get_meta("motion_time")," (action label remains hurt between hits)")
	game.settings.large_text = true;game.ui.refresh_text_sizes(game.ui.root)
	game.ui.interaction_clock = 0;game.ui._process(.016)
	print("LIVE QA empty_prompt_size=",game.ui.prompt.size)
	game.state.accept("main")
	for id: String in ["forest","creek","ruins"]:game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar();game.state.finish_main();game.continue_chapter();game.mode = "test"
	v = game.player.visual
	for id: String in game.content.names:game.state.discovered[id] = true
	game.ui.show_map();await process_frame;await process_frame
	game.ui.specialization_menu();await process_frame;await process_frame
	print("LIVE QA specialization panel_bottom=",game.ui.modal.get_child(1).position.y+game.ui.modal.get_child(1).size.y)
	# Two hurts through production damage path, with an actual idle interval.
	game.ui.clear();game.mode = "test"
	game.player.health.invulnerable = 0
	game.player.receive_hit(1,"qa-hurt-1",null)
	game.combat_freeze_left = 0;game.mode = "playing"
	game.player.advance(.2)
	print("LIVE QA production hurt expired last_action=",v.last_action)
	game.player.health.invulnerable = 0
	game.player.receive_hit(1,"qa-hurt-2",null)
	game.combat_freeze_left = 0
	game.player.advance(.016)
	print("LIVE QA production second hurt time=",v.sprite.get_meta("motion_time")," expected_restart_zero")
	game.mode = "test"
	game.ui.set_process(false);game.ui.root.hide()
	game.player.position = Vector2(430,430);game.camera.reset_smoothing()
	v.cancel_action();v.pose(Vector2.RIGHT,false,"idle",0)
	var entry: Dictionary = v.player_motion.timelines.thrust
	for name: String in ["idle","thrust-contact","heavy-contact","throw-release"]:
		v.cancel_action()
		if name != "idle":
			var action: String = "heavy" if name.begins_with("heavy") else ("throw" if name.begins_with("throw") else "thrust")
			v.start_action(action,Vector2.RIGHT,func() -> void: pass)
			v.tick_action(v.rig.Spec.contact(action))
			v.pose(Vector2.RIGHT,false,"attack",1)
		else:v.pose(Vector2.RIGHT,false,"idle",0)
		await process_frame;await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("user://captures/live-qa")
		root.get_texture().get_image().save_png("user://captures/live-qa/"+name+".png")
		print("LIVE QA pose=",name," texture=",v.sprite.texture.resource_path," region=",v.sprite.region_rect," pivot=",v.sprite.position)
	game.queue_free();await process_frame;await create_timer(.35).timeout;quit()
