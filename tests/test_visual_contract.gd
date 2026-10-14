extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.mode = "test"
	check(game.actors.size() == 28 and game.item_nodes.size() == 15,"art upgrade preserves actor and pickup census")
	check(game.effects != null and game.atmosphere != null,"cosmetic layers exist")
	check(game.player.visual.sprite.material is ShaderMaterial,"player has readability shader")
	for i: int in range(80): game.effects.burst(Vector2(430,450),"hit")
	check(game.effects.bursts.size() == 48,"effect pool has strict upper bound")
	game.effects._process(2)
	check(game.effects.bursts.is_empty(),"effect pool expires")
	game.state.accept("main")
	for place: String in ["forest","creek","ruins"]: game.state.pickup("ember_"+place,"ember",place)
	game.ui._process(0.1)
	check(game.ui.objective.text == "Thắp tế đàn ở Phế Tích","compact HUD follows objective")
	for icon: TextureRect in game.ui.ember_icons: check(icon.modulate == Color.WHITE,"acquired ember icon lit")
	game.state.light_altar()
	game.ui._process(0.1)
	check(game.ui.objective.text == "Trở về gặp An","lit altar updates compact HUD")
	game.start_game()
	check(game.effects.bursts.is_empty() and game.ember_sprites.size() == 3 and not game.state.altar_lit,"replay clears transient visuals and altar")
	for kind: String in ["chief","healer","hunter","smith","gatherer"]:
		game.talk(kind)
		await process_frame
		await process_frame
		var panel: Control = game.ui.modal.get_child(1)
		check(panel.position.y+panel.size.y <= 360,"portrait dialogue fits native viewport " + kind)
		game.resume()
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("VISUAL CONTRACT: %d checks, %d failures (structural, not aesthetic acceptance)" % [checks,failures])
	quit(1 if failures else 0)
