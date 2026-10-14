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
	game.ui.set_process(false)
	var visual = game.player.visual
	for i: int in range(8):
		var direction := Vector2.from_angle(i*PI/4)
		visual.start_action("thrust",direction,func() -> void: pass)
		visual.tick_action(0.08)
		visual.pose(direction,false,"attack",0.08)
		check(absf((visual.rig.tip_position-Vector2(0,-13)).length()-49)<1,"normal tip/reach preserved "+str(i))
		check(visual.sprite.get_meta("motion_octant") == i,"directional body pose "+str(i))
	visual.cancel_action()
	visual.pose(Vector2.DOWN,false,"idle",1)
	check(visual.sprite.vframes == 4,"idle restores original sheet")
	game.mode = "playing"
	game._process(0.016)
	for node: Node in game.objects.get_children():
		for child: Node in node.get_children():
			if child is Label and not child.get_meta("landmark_caption",false): check(not child.visible,"duplicate rest/item caption stays hidden during gameplay")
	game.mode = "test"
	for large: bool in [false,true]:
		game.settings.large_text = large
		game.ui.refresh_text_sizes(game.ui.root)
		for point: Vector2 in [Vector2(420,365),Vector2(430,450),Vector2(390,430)]:
			game.player.position = point
			game.camera.reset_smoothing()
			await process_frame
			game.ui.interaction_clock = 0
			game.ui.notify("Đã nghỉ tại Trại Tro. Hồi đầy máu và ghi điểm hồi sinh.")
			game.ui._process(0.016)
			if game.ui.prompt.visible:
				check(not game.ui.overlaps_actor(Rect2(game.ui.prompt.position,game.ui.prompt.size)),"prompt avoids actors "+str(point)+" large="+str(large))
				check(not Rect2(game.ui.prompt.position,game.ui.prompt.size).intersects(Rect2(game.ui.toast.position,game.ui.toast.size)),"prompt avoids toast")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("DETAIL POLISH: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
