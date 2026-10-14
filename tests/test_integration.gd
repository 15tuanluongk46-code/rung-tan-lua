extends SceneTree
var failures: int = 0
var checks: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(ResourceLoader.exists("res://scripts/main.gd"), "playable orchestration exists")
	if failures > 0:
		quit(1)
		return
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_game()
	await physics_frame
	check(main.actors.size() == 28, "runtime spawn census includes player")
	check(main.world.y_sort_enabled, "world y-sorts feet")
	check(main.player.position.distance_to(Vector2(430,450)) < 10, "player starts at contract location")
	check(main.camera.get_parent() == main.player, "camera follows player")
	# Missing trigger/input mappings must not silently disable normal play.
	for action: String in ["move_left","move_right","move_up","move_down","spear","throw","dodge","interact","heal","pause"]:
		check(InputMap.has_action(action) and InputMap.action_get_events(action).size() > 0,"mapped input " + action)
	main.ui.pause_menu()
	var before: Vector2 = main.actor_by_id("melee_0").position
	for i: int in range(3): await physics_frame
	check(main.actor_by_id("melee_0").position == before,"pause freezes AI")
	main.resume()
	check(main.mode == "playing" and not main.ui.modal.visible,"resume closes modal")
	# A guarded pickup cannot be obtained just by reaching its location.
	main.player.position = Vector2(1850,380)
	main.interact()
	check(main.state.embers.is_empty(),"live guards block ember interaction")
	main.player.position = Vector2(430,450)
	main.mode = "test"
	var victim: Node = main.actor_by_id("melee_0")
	victim.receive_hit(500, "test_kill", main.player)
	check(main.state.killed.has("melee_0"), "real combat marks killed actor")
	main.state.pickup("herb_0", "herb")
	main.state.activate_checkpoint("creek")
	var survivor: Node = main.actor_by_id("melee_1")
	survivor.health.hp = 1
	survivor.position += Vector2(50,20)
	main.spawn_projectile(main.player, Vector2.RIGHT, "stone")
	main.state.hp = 0
	main.respawn()
	# Assert the reset before patrol resumes on subsequent physics frames.
	survivor = main.actor_by_id("melee_1")
	check(survivor.position.distance_to(survivor.home) < 1, "survivor position resets on death")
	await process_frame
	check(main.actor_by_id("melee_0") == null, "killed enemies do not respawn")
	survivor = main.actor_by_id("melee_1")
	check(survivor.health.hp == survivor.health.maximum, "survivor health resets on death")
	check(main.projectiles.get_child_count() == 0, "death clears projectiles")
	check(main.player.position.distance_to(Vector2(530,1190)) < 10, "death returns player to creek checkpoint")
	check(main.state.picked.has("herb_0"), "runtime reset preserves pickup ledger")
	main.mode = "test"
	main.state.accept("main")
	for data: Dictionary in main.content.items():
		if data.kind != "ember": continue
		for id: String in data.guards:
			var enemy: Node = main.actor_by_id(id)
			if enemy != null: enemy.receive_hit(500, "quest_" + id, main.player)
		main.player.position = data.pos
		main.interact()
		main.mode = "test"
	check(main.state.embers.size() == 3, "guarded ember pickup through interaction API")
	main.player.position = Vector2(1810,1190)
	main.interact()
	check(main.state.altar_lit, "altar interaction lights after three embers")
	main.player.position = main.actor_by_id("chief").position
	main.mode = "test"
	main.interact()
	check(main.state.ended and main.mode == "ending", "interaction API completes quest at chief")
	main.start_game()
	await process_frame
	check(main.actors.size() == 28 and main.state.killed.is_empty(), "replay clears prior session")
	main.mode = "test"
	# Production spear route, neutral immunity, hostile dedupe, and bear faction.
	main.player.position = Vector2(1100,760)
	main.player.facing = Vector2.RIGHT
	var foe: Node = main.actor_by_id("melee_0")
	foe.position = Vector2(1130,760)
	main.spear_attack(main.player)
	check(foe.health.hp == 50,"real spear route applies 25 damage")
	main.spear_attack(main.player)
	check(foe.health.hp == 50,"real combat invulnerability blocks rapid spear damage")
	var rabbit: Node = main.actor_by_id("rabbit_0")
	rabbit.position = Vector2(1130,760)
	check(not rabbit.receive_hit(999,"neutral",main.player) and not rabbit.dead,"wildlife cannot be killed")
	var bear: Node = main.actor_by_id("bear_0")
	bear.position = Vector2(1100,780)
	check(bear.valid_target(foe) and bear.valid_target(main.player),"bear targets both goblins and player")
	# Independent audio bus setup, exact inventory and visual helper contracts.
	for bus: String in ["Master","Music","Ambient","SFX"]:
		check(AudioServer.get_bus_index(bus) >= 0,"independent audio bus " + bus)
	main.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("INTEGRATION TESTS: %d checks, %d failures (API simulation, not a real playtest)" % [checks,failures])
	quit(1 if failures else 0)
