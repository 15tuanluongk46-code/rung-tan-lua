extends SceneTree
const State = preload("res://scripts/run_state.gd")
const Save = preload("res://scripts/save_manager.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.autosave_enabled = false
	game.start_game()
	game.mode = "test"
	check(game.actors.size() == 28,"chapter one retains 28 initial actors")
	check(game.point_blocked(Vector2(530,1580)),"south gate closed before chapter two")
	game.state.accept("main")
	for region: String in ["forest","creek","ruins"]: game.state.pickup("ember_"+region,"ember",region)
	check(game.state.light_altar() and game.state.finish_main(),"original main quest completes")
	game.continue_chapter()
	game.mode = "test"
	check(game.state.chapter == 2 and game.actors.size() == 41,"chapter two spawns southern cast")
	check(not game.point_blocked(Vector2(530,1580)),"chapter gate opens")
	check(game.camera.limit_bottom == 2400,"camera uses shared expanded bounds")
	game.talk("sen")
	game.resume()
	check(game.state.stage == 1,"Sen advances main quest")
	check(not game.state.complete_event("well"),"cannot skip lamps")
	for id: String in ["lamp_0","lamp_1","lamp_2"]: check(game.state.complete_event(id),"light "+id)
	game.state.kill_actor("stalker_1")
	game.world_events.interact("well")
	check(game.state.stage == 3,"well advances source quest")
	game.talk("tung")
	game.resume()
	check(game.state.stage == 4,"Tung advances valves")
	for id: String in ["valve_0","valve_1"]: check(game.state.complete_event(id),"restore "+id)
	game.world_events.refresh_state()
	await physics_frame
	check(not game.point_blocked(Vector2(1960,2070)),"tower gate opens after both valves")
	for quest: String in ["bridge","bell"]:
		game.state.accept(quest)
		for i: int in range(3): game.state.pickup(("plank_" if quest == "bridge" else "bell_part_")+str(i),"plank" if quest == "bridge" else "bell_part")
		check(game.state.reward(quest),"one-time world reward "+quest)
		check(not game.state.reward(quest),"duplicate reward rejected "+quest)
	game.world_events.refresh_state()
	check(not game.point_blocked(Vector2(525,1990)),"bridge shortcut really opens")
	var boss = game.actor_by_id("guardian")
	check(boss.receive_hit(210,"test_phase",game.player),"boss takes confirmed damage")
	boss.health.invulnerable = 0
	game._process(0.08) # Advance the real hit-stop release clock before phase update.
	game.player.position = boss.position + Vector2(70,0)
	game.mode = "playing"
	boss._physics_process(0.016)
	game.mode = "test"
	check(boss.phase == 2,"boss enters phase two")
	boss.health.invulnerable = 0
	check(boss.receive_hit(300,"test_finish",game.player),"boss defeated")
	check(game.state.events.has("boss") and game.state.stage == 6,"boss victory advances once")
	game.state.activate_checkpoint("ash")
	game.state.discovered.ash = true
	game.state.memories.memory_ash = true
	game.ui.pause_menu()
	await process_frame
	check(game.ui.modal.get_child_count() == 2,"chapter two journal renders without errors")
	game.resume()
	check(State.valid_snapshot(game.state.snapshot()),"progress snapshot valid")
	if not State.valid_snapshot(game.state.snapshot()): print("INVALID SNAPSHOT: ",game.state.snapshot())
	var store := Save.new()
	store.path = "user://expansion-tests-" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_state(game.state),"isolated save writes")
	if not store.last_error.is_empty(): print("SAVE ERROR: ",store.last_error)
	var restored = store.load_state()
	check(restored != null and restored.events.has("boss") and restored.claimed.size() == 2 and restored.checkpoint == "ash","load preserves boss rewards and checkpoint")
	game.save_manager = store
	game.continue_game()
	check(game.player.health.hp == game.state.hp and game.player.position == game.content.checkpoints.ash,"continue rebuilds correct HP at saved checkpoint")
	check(store.save_state(game.state),"second save rotates backup")
	var file := FileAccess.open(store.path,FileAccess.WRITE)
	file.store_string("corrupt test fixture")
	file.close()
	restored = store.load_state()
	check(restored != null and store.recovered,"corrupt primary recovers backup")
	var invalid: Dictionary = game.state.snapshot()
	invalid.chapter = 8
	check(not State.valid_snapshot(invalid),"invalid chapter rejected")
	invalid = game.state.snapshot()
	invalid.stage = 2.5
	check(not State.valid_snapshot(invalid),"fractional stage rejected")
	invalid = game.state.snapshot()
	invalid.events.erase("well")
	check(not State.valid_snapshot(invalid),"inconsistent progression rejected")
	game.state.finish_main()
	game.ui.ending()
	await process_frame
	check(game.mode == "ending" and game.state.ended,"final chapter ending")
	game.respawn()
	check(game.actor_by_id("guardian") == null,"defeated boss does not respawn")
	game.start_game()
	check(game.state.chapter == 1 and game.state.events.is_empty() and game.actors.size() == 28,"new run clears expansion progression")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("EXPANSION: %d checks, %d failures; isolated save fixtures retained at %s" % [checks,failures,store.path])
	quit(1 if failures else 0)
