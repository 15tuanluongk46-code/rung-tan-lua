extends SceneTree
var failures: int = 0
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ",description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var content = load("res://scripts/world_content.gd").new()
	for actor: Dictionary in content.actors():
		if actor.kind in ["chief","hunter","healer","smith","gatherer"]:
			check(content.region_at(actor.pos) == "camp", "NPC in camp: " + actor.kind)
	var herbs: int = 0
	for item: Dictionary in content.items():
		if item.kind == "herb": herbs += 1
		if item.kind == "bag": check(content.region_at(item.pos) == "creek", "Bag at creek")
	check(herbs == 5, "Exactly five herbs")
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_game()
	main.mode = "test"
	check(main.art.listener == main.player, "Explicit art listener")
	main.state.hp = 5
	main.player.health.hp = 5
	main.player.receive_hit(1000,"overkill",null)
	check(main.state.damage_taken == 5,"Damage statistics exclude overkill")
	main.respawn()
	main.ui.pause_menu()
	main.ui.confirm_exit(true)
	main.ui.escape()
	check(main.mode == "paused", "Escape from exit confirmation returns to pause")
	main.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("DELIVERY REGRESSIONS failures=",failures)
	quit(1 if failures else 0)
