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
	check(visual.sprite.texture.resource_path.ends_with("player_body.png"),"body uses weapon-free layered sheet")
	check(visual.rig.animator is AnimationPlayer,"real AnimationPlayer owns action timing")
	var calls: Array[int] = [0]
	visual.start_action("thrust",Vector2.RIGHT,func() -> void: calls[0] += 1)
	visual.tick_action(0.04)
	var retracted: float = visual.rig.weapon.position.x
	check(calls[0] == 0,"no early damage before contact")
	visual.tick_action(0.045)
	check(calls[0] == 1 and visual.rig.weapon.position.x > retracted+20,"contact aligns with extended spear")
	visual.tick_action(0.4)
	check(calls[0] == 1 and not visual.rig.active,"one commit and complete recovery")
	for i: int in range(8):
		visual.start_action("heavy",Vector2.from_angle(i*PI/4),func() -> void: pass)
		visual.tick_action(0.135)
		check(visual.rig.weapon.frame == i,"pixel weapon octant "+str(i))
		check(visual.rig.z_index == (-1 if sin(i*PI/4)<-0.1 else 1),"correct front/back weapon layer "+str(i))
	visual.start_action("throw",Vector2.UP,func() -> void: calls[0]+=1)
	visual.cancel_action()
	visual.tick_action(0.2)
	check(calls[0] == 1,"cancelled attack never releases projectile")
	var archer = game.actor_by_id("archer_0")
	var projectiles_before: int = game.projectiles.get_child_count()
	archer.execute_attack()
	check(game.projectiles.get_child_count() == projectiles_before,"bow arrow remains held before release")
	archer.visual.tick_action(0.11)
	check(game.projectiles.get_child_count() == projectiles_before+1,"arrow created at bow release")
	archer.visual.tick_action(0.3)
	check(game.projectiles.get_child_count() == projectiles_before+1,"arrow release deduplicated")
	visual.start_action("thrust",Vector2.RIGHT,func() -> void: calls[0]+=1)
	game.mode = "paused"
	game.player.advance(0.3)
	check(calls[0] == 1,"pause does not advance animation contact")
	game.mode = "playing"
	game.combat_freeze_left = 0.08
	game.player.advance(0.016)
	check(calls[0] == 1,"hit-stop freezes action contact")
	game.mode = "test"
	game.combat_freeze_left = 0
	var stones: int = game.state.stones
	visual.start_action("throw",Vector2.RIGHT,func() -> void: game.state.use_stone())
	visual.tick_action(0.03)
	check(game.state.stones == stones,"held stone is not consumed early")
	visual.cancel_action()
	visual.tick_action(0.2)
	check(game.state.stones == stones,"cancelled throw retains stone")
	visual.start_action("throw",Vector2.RIGHT,func() -> void: game.state.use_stone())
	visual.tick_action(0.065)
	check(game.state.stones == stones-1,"stone consumption aligns with release")
	game.player.visual.cancel_action()
	game.mode = "test"
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("WEAPON ANIMATION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
