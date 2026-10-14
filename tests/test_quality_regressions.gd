extends SceneTree
const State = preload("res://scripts/run_state.gd")
const Geometry = preload("res://scripts/combat_geometry.gd")
var failures: int = 0
var checks: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func run() -> void:
	var half_angle: float = acos(Geometry.MELEE_DOT)
	check(Geometry.contains(Vector2.from_angle(half_angle-0.01)*39,Vector2.RIGHT,Geometry.MELEE_RADIUS,Geometry.MELEE_DOT),"telegraph inner edge matches damage")
	check(not Geometry.contains(Vector2.from_angle(half_angle+0.01)*39,Vector2.RIGHT,Geometry.MELEE_RADIUS,Geometry.MELEE_DOT),"outside telegraph cannot hit")
	var state := State.new()
	var invalid: Dictionary = state.snapshot()
	invalid.killed.player = true
	check(not State.valid_snapshot(invalid),"save rejects killed player")
	invalid = state.snapshot()
	invalid.ended = true
	check(not State.valid_snapshot(invalid),"save rejects false ending")
	invalid = state.snapshot()
	invalid.memories.unknown_lore = true
	check(not State.valid_snapshot(invalid),"save rejects unknown memory")
	state.accept("main")
	for region: String in ["forest","creek","ruins"]: state.pickup("ember_"+region,"ember",region)
	state.light_altar(); state.finish_main(); state.continue_chapter()
	state.accept("bridge")
	state.planks = 3
	state.potions = 6
	check(state.reward("bridge") and state.planks == 0 and not state.rewards_received.has("bridge"),"full pouch retains bridge reward pending after construction")
	state.accept("bell")
	state.bell_parts = 3
	state.stones = 29
	check(state.reward("bell") and state.bell_parts == 0 and not state.rewards_received.has("bell"),"full stone pouch retains bell reward pending")
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.state.accept("main")
	for id: String in ["forest","creek","ruins"]: game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar()
	game.state.finish_main()
	game.continue_chapter()
	game.mode = "test"
	game.settings.reduced_motion = true
	game.player.position = Vector2(150,1820)
	game.mode = "playing"
	Input.action_press("move_right")
	game.player._physics_process(0.016)
	Input.action_release("move_right")
	check(is_equal_approx(game.player.velocity.length(),81.0),"mud modifies actual movement velocity before slide")
	game.settings.reduced_motion = false
	game.mode = "test"
	check(game.world_events.movement_factor(Vector2(150,1820)) == 0.75,"mud speed modifier exists in physics path")
	check(game.world_events.movement_factor(Vector2(480,1760)) == 1.0,"road retains full speed")
	check(game.point_blocked(Vector2(1670,2200)) and game.point_blocked(Vector2(2250,2200)),"tower side walls prevent endpoint bypass")
	game.trigger_hitstop(0.05)
	game.mode = "playing"
	var age_before: float = game.player.age
	check(not game.player.advance(0.016) and game.player.age == age_before,"hit-stop freezes actor update")
	game._process(0.06)
	check(game.player.advance(0.016),"hit-stop releases through unscaled UI clock")
	game.mode = "test"
	game.state.events.bridge = true
	game.world_events.refresh_state()
	game.state.events.erase("bridge")
	game.world_events.refresh_state()
	var bridge: Sprite2D = game.world_events.nodes.bridge.get_child(0)
	check(bridge.texture.resource_path.ends_with("broken_bridge.png") and bridge.position.x == 0,"bridge visual resets in both directions")
	var projectile = load("res://scripts/projectile.gd").new()
	projectile.game = game
	projectile.kind = "stone"
	projectile.direction = Vector2.UP
	game.projectiles.add_child(projectile)
	check(projectile.get_child(0).points[0].is_equal_approx(Vector2.DOWN*14),"projectile trail follows direction")
	var visual = game.player.visual
	visual.pose(Vector2.RIGHT,false,"throw",1.0)
	visual.pose(Vector2.RIGHT,false,"attack",1.1)
	check(is_equal_approx(visual.trail.modulate.r,1.0),"attack trail does not inherit throw tint")
	game.ui.notify("Notification retained while paused")
	game.ui.pause_menu()
	game.ui._process(5.0)
	check(game.ui.toast_left > 0,"hidden HUD does not expire notification")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("QUALITY REGRESSIONS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
