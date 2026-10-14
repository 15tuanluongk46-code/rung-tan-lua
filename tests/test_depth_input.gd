extends "res://tests/test_user_journey.gd"
## Controlled fixture; abilities are executed through real input dispatch.
func screenshot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for i: int in range(25): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://captures/depth")
	check(root.get_texture().get_image().save_png("user://captures/depth/"+name+".png") == OK,"capture "+name)

func run():
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await step()
	game.start_game()
	game.settings.path = "user://depth-settings-fixture.cfg"
	game.settings.reduced_motion = true
	game.state.pickup("ember_forest","ember","forest")
	var enemy = game.actor_by_id("melee_0")
	game.player.position = Vector2(1060,375)
	enemy.position = game.player.position+Vector2(42,0)
	game.camera.reset_smoothing()
	game.mode = "test"
	await physics_frame
	await process_frame
	game.mode = "playing"
	aim(enemy.position)
	set_action("charge_modifier",true)
	set_action("spear",true)
	for i: int in range(38): await step()
	check(game.player.abilities.charging and game.player.abilities.charge >= 0.55,"Shift spear charges through InputMap")
	game.mode = "test"
	game.ui._process(0.016)
	await screenshot("charge-ready")
	game.mode = "playing"
	set_action("spear",false)
	set_action("charge_modifier",false)
	for i: int in range(10): await step() # Contact now occurs at the real extended-tip frame.
	check(enemy.health.hp <= 30,"released charge deals heavy damage through actual input")
	check(not game.player.abilities.charging,"charge ends on release")
	game.state.accept("main")
	for id: String in ["creek","ruins"]: game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar()
	game.state.finish_main()
	game.continue_chapter()
	game.player.position = game.content.checkpoints.ash
	game.camera.reset_smoothing()
	game.state.stage = 1
	for id: String in ["lamp_0","lamp_1","lamp_2"]: game.state.complete_event(id)
	game.state.complete_event("well")
	game.state.stage = 4
	game.ui.specialization_menu()
	await step()
	await click_button("Giáo")
	check(game.state.specialization == "spear","UI choice assigns spear specialization")
	game.ui.specialization_menu()
	await screenshot("specialization")
	game.ui.checkpoint_menu()
	await screenshot("checkpoint-menu")
	game.resume()
	game.player.position = Vector2(820,2070)
	game.camera.reset_smoothing()
	game.world_events.refresh_state()
	for i: int in range(10): await step()
	game.mode = "test"
	await screenshot("marsh-light")
	game.state.stage = 5
	game.world_events.refresh_state()
	game.player.position = Vector2(1960,2190)
	game.camera.reset_smoothing()
	var boss = game.actor_by_id("guardian")
	boss.phase = 2
	boss.ai_state = "windup"
	boss.attack_kind = 0
	boss.aim_locked = Vector2.DOWN
	boss.queue_redraw()
	await screenshot("boss-phase-two")
	game.ui.pause_menu()
	await step()
	await step()
	var panel: Control = game.ui.modal.get_child(1)
	check(panel.position.y+panel.size.y <= 360,"chapter two pause depth layout fits")
	await finish()
