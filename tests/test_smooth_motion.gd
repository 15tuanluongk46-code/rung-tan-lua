extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr(text)
func run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_game();game.mode="test"
	check(physics_interpolation,"physics interpolation enabled")
	check(not game.camera.position_smoothing_enabled and game.camera.process_callback == Camera2D.CAMERA2D_PROCESS_PHYSICS,"camera same physics time source")
	game.mode="playing";game.player.dodge_left=.1;game.player.dodge_direction=Vector2.RIGHT
	game.player._physics_process(1.0/60)
	check(is_equal_approx(game.player.velocity.x,300),"dash gameplay velocity unchanged")
	game.mode="test";game.player.dodge_left=0
	for level: int in range(3):
		game.combat_freeze_left = 0;game.settings.hitstop_level=level;game.trigger_hitstop(.05)
		check(is_equal_approx(game.combat_freeze_left,[0.0,.02,.05][level]),"hitstop level "+str(level))
	game.settings.large_text = true;game.ui.refresh_text_sizes(game.ui.root)
	game.ui.accessibility_settings(game.ui.main_menu);await process_frame;await process_frame
	check(game.ui.modal.get_child(1).position.y+game.ui.modal.get_child(1).size.y<=360,"large settings fits")
	game.ui.ending();await process_frame;await process_frame
	check(game.ui.modal.get_child(1).position.y+game.ui.modal.get_child(1).size.y<=360,"ending fits")
	game.queue_free();await process_frame;await create_timer(.35).timeout
	print("SMOOTH MOTION: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
