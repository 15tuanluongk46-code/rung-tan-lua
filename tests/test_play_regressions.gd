extends SceneTree
## Targeted reproduction of Windows review findings; no production cheats.
var failures: int = 0
var checks: int = 0
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func texts(node: Node) -> String:
	var result: String = node.text + "\n" if node is Label else ""
	for child: Node in node.get_children(): result += texts(child)
	return result

func wall_at(point: Vector2) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.position = point
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4,100)
	collision.shape = shape
	wall.add_child(collision)
	game.world.add_child(wall)
	return wall

func run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.mode = "test"
	for kind: String in ["chief","healer","hunter"]:
		game.talk(kind)
		check(game.mode == "dialogue" and game.ui.modal.visible, "quest dialogue opens with typed options: " + kind)
		game.resume()
	game.player.receive_hit(1000,"regression-death",null)
	game.ui.confirm_exit(true)
	game.ui.confirm_exit(false)
	game.ui.escape()
	check(game.mode == "dead", "repeated exit confirmation preserves death return screen")
	game.respawn()
	game.state.ended = true
	game.ui.ending()
	game.ui.confirm_exit(false)
	game.ui.confirm_exit(false)
	game.ui.escape()
	check(game.mode == "ending", "repeated exit confirmation preserves ending return screen")
	game.start_game()
	game.state.accept("herbs")
	game.ui.pause_menu()
	check("đang thu thập" in texts(game.ui.modal), "accepted herbs quest journal says collecting")
	game.state.herbs = 5
	game.ui.pause_menu()
	check("đủ dược thảo" in texts(game.ui.modal), "complete herbs collection journal says ready")
	game.state.potions = 4
	game.state.reward("herbs")
	game.ui.pause_menu()
	check("đã nhận thưởng" in texts(game.ui.modal), "claimed herbs journal says rewarded")
	game.mode = "test"
	var chief: Node = game.actor_by_id("chief")
	game.player.position = Vector2(1100,755)
	chief.position = Vector2(1140,755)
	var wall := wall_at(Vector2(1120,755))
	await physics_frame
	await physics_frame
	check(game.closest_interaction().is_empty(), "NPC cannot be interacted with through wall")
	wall.queue_free()
	await physics_frame
	await physics_frame
	check(game.closest_interaction().get("id","") == "chief", "unobstructed nearby NPC remains interactable")
	# Ray stops at x=1138; target center at 1145 must not be hit through wall.
	chief.position = chief.home
	var foe: Node = game.actor_by_id("melee_0")
	foe.position = Vector2(1145,755)
	wall = wall_at(Vector2(1140,755))
	await physics_frame
	await physics_frame
	game.spawn_projectile(game.player,Vector2.RIGHT,"stone")
	var shot: Node = game.projectiles.get_child(0)
	game.mode = "playing"
	shot._physics_process(0.4)
	game.mode = "test"
	check(foe.health.hp == 75, "wall shields target whose center is just behind impact")
	check(shot.is_queued_for_deletion(), "wall consumes projectile")
	wall.queue_free()
	await physics_frame
	await physics_frame
	game.spawn_projectile(game.player,Vector2.RIGHT,"stone")
	shot = game.projectiles.get_child(0)
	foe.health.reset()
	game.mode = "playing"
	shot._physics_process(0.4)
	game.mode = "test"
	check(foe.health.hp == 55, "same target without wall takes 20 damage")
	var state: RefCounted = load("res://scripts/run_state.gd").new()
	state.stones = 29
	check(not state.pickup("near-cap","stone") and state.stones == 29 and not state.picked.has("near-cap"), "stone bag waits for room for all four stones")
	state.stones = 26
	check(state.pickup("near-cap","stone") and state.stones == 30, "stone bag gives exactly four when room exists")
	# Check respawn atomically, before normal patrol is allowed to advance.
	game.state.ended = false
	game.state.kill_actor("melee_0")
	game.state.activate_checkpoint("creek")
	game.state.pickup("saved-herb","herb")
	game.respawn()
	check(game.actor_by_id("melee_1").position == game.actor_by_id("melee_1").home, "respawn resets survivor position synchronously")
	check(game.state.picked.has("saved-herb") and game.actor_by_id("melee_0") == null, "respawn keeps pickup and kill ledgers")
	check(game.state.hp == 100 and game.player.health.hp == 100, "respawn health agrees with UI state")
	for checkpoint: String in ["camp","creek"]:
		game.state.activate_checkpoint(checkpoint)
		game.player.health.invulnerable = 0
		var deaths_before: int = game.state.deaths
		game.player.receive_hit(1000,"death-at-" + checkpoint,null)
		game.ui.confirm_exit(true)
		game.ui.confirm_exit(false)
		game.ui.escape()
		check(game.mode == "dead", "death exit cancel returns to stand-up at " + checkpoint)
		game.respawn()
		check(game.player.position == game.content.checkpoints[checkpoint] and game.state.deaths == deaths_before + 1, "respawn coordinates and death count at " + checkpoint)
		check(game.state.picked.has("saved-herb") and game.actor_by_id("melee_0") == null and game.projectiles.get_child_count() == 0, "death preserves progress and clears projectiles at " + checkpoint)
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("PLAY REGRESSIONS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
