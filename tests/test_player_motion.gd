extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.mode = "test"
	var visual = game.player.visual
	for action: String in ["thrust","heavy","throw"]:
		for i: int in range(8):
			var calls: Array[int] = [0]
			visual.start_action(action,Vector2.from_angle(i*PI/4),func() -> void:
				calls[0]+=1
				check(visual.sprite.texture.resource_path.ends_with("player_motion/"+action+".png"),"contact rendered from composite "+action)
				var entry: Dictionary = visual.player_motion.timelines[action]
				var time: float = visual.sprite.get_meta("motion_time")
				check(absf(time-visual.rig.Spec.contact(action))<0.00001,"exact sprite contact time "+action))
			visual.tick_action(0.5)
			check(calls[0] == 1,"one contact after large delta")
			visual.pose(Vector2.from_angle(i*PI/4),false,"idle",1)
			check(not visual.rig.arms_visible and not visual.rig.weapon.visible,"no procedural Player parts")
			check(visual.sprite.texture == visual.player_reference,"rest recovers approved sprite")
	visual.start_action("throw",Vector2.RIGHT,func() -> void: failures+=1)
	visual.cancel_action()
	visual.tick_action(0.5)
	check(not visual.rig.active,"cancel suppresses projectile")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("PLAYER MOTION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
