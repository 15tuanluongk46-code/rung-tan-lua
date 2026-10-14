extends SceneTree
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	await physics_frame
	game.mode = "test"
	game.player.position = Vector2(1110,755)
	var foe: Node = game.actor_by_id("melee_0")
	foe.position = Vector2(1180,755)
	# A real wall in the physics world must block the swept projectile.
	var wall: StaticBody2D = StaticBody2D.new()
	wall.position = Vector2(1140,755)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(8,90)
	collision.shape = shape
	wall.add_child(collision)
	game.world.add_child(wall)
	await physics_frame
	check(not game.line_clear(game.player.position,foe.position),"static wall blocks sight")
	game.spawn_projectile(game.player,Vector2.RIGHT,"stone")
	var projectile: Node = game.projectiles.get_child(0)
	game.mode = "playing"
	projectile._physics_process(0.4)
	game.mode = "test"
	check(foe.health.hp == 75,"wall blocks projectile before enemy")
	check(projectile.is_queued_for_deletion(),"blocked projectile is removed")
	wall.queue_free()
	await physics_frame
	await physics_frame
	game.spawn_projectile(game.player,Vector2.RIGHT,"stone")
	projectile = game.projectiles.get_child(0)
	game.mode = "playing"
	projectile._physics_process(0.4)
	game.mode = "test"
	check(foe.health.hp == 55,"unobstructed swept stone damages target")
	check(projectile.is_queued_for_deletion(),"hit consumes projectile")
	await process_frame
	# Target remains stable even if another target briefly becomes closer.
	var bear: Node = game.actor_by_id("bear_0")
	foe.target = game.player
	foe.home = Vector2(1180,755)
	bear.position = Vector2(1170,755)
	game.mode = "playing"
	foe._physics_process(0.016)
	game.mode = "test"
	check(foe.target == game.player,"AI keeps valid target instead of nearest-target flicker")
	foe.target = null
	foe.ai_state = "patrol"
	game.noise(foe.position,100)
	check(foe.ai_state == "investigate","noise starts hostile investigation")
	# Dodge must be unavailable before 0.8 seconds while granting i-frames.
	game._process(0.08) # Release the newly implemented hit-stop from the projectile hit.
	game.player.dodge_cooldown = 0
	Input.action_press("dodge")
	game.mode = "playing"
	game.player._physics_process(0.016)
	game.mode = "test"
	Input.action_release("dodge")
	check(game.player.dodge_cooldown > 0.7 and game.player.health.invulnerable > 0.2,"input dodge grants cooldown and invulnerability")
	# Arrow hit not overwritten by healing synchronization and death modal.
	game.player.health.invulnerable = 0
	game.player.receive_hit(500,"fatal",foe)
	check(game.mode == "dying","lethal hit first plays visual death phase")
	game._process(.41)
	check(game.mode == "dead" and game.state.hp == 0,"real lethal hit opens death UI")
	game.respawn()
	await process_frame
	check(game.mode == "playing" and game.player.health.hp == 100,"real respawn resumes play")
	# Escape from nested settings returns to pause first, then gameplay.
	game.ui.pause_menu()
	game.player.health.guard(0.25)
	game.player.advance(0.2)
	check(is_equal_approx(game.player.health.invulnerable,0.25),"pause preserves invulnerability timers")
	game.ui.settings(game.ui.pause_menu)
	game.ui.escape()
	check(game.mode == "paused","escape from settings returns to pause")
	game.ui.escape()
	check(game.mode == "playing","escape from pause resumes")
	# Inspect final control geometry at native 640x360 to catch overfull menus.
	for screen: String in ["main_menu","pause_menu","death","ending"]:
		game.ui.call(screen)
		await process_frame
		await process_frame
		var panel: Control = game.ui.modal.get_child(1)
		check(panel.position.y + panel.size.y <= 360,"screen fits viewport: " + screen)
	game.ui.settings(game.ui.main_menu)
	await process_frame
	await process_frame
	var settings_panel: Control = game.ui.modal.get_child(1)
	check(settings_panel.position.y + settings_panel.size.y <= 360,"settings fits viewport")
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("RUNTIME TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
