extends SceneTree
## Diagnostic audit only: log observed edge cases, never adjust game state to fix them.
var game: Node
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.settings.reduced_motion = true
	game.mode = "test"
	var rig = game.player.visual.rig
	# Eight weapon directions are quantized; compare actual visual axis against aim.
	var exact := Vector2.from_angle(PI/8+0.01)
	game.player.visual.start_action("thrust",exact,func() -> void: pass)
	game.player.visual.tick_action(0.085)
	var shown := Vector2.from_angle(rig.weapon.frame*PI/4)
	print("REVIEW direction_mismatch_degrees=",rad_to_deg(absf(exact.angle_to(shown))))
	game.player.visual.cancel_action()
	game.player.facing = Vector2.RIGHT
	var stones: int = game.state.stones
	game.mode = "playing"
	Input.action_press("spear")
	Input.action_press("throw")
	game.player._physics_process(0.016)
	Input.action_release("spear")
	Input.action_release("throw")
	print("REVIEW simultaneous_attack current_animation=",rig.animator.current_animation," spear_cooldown=",game.player.attack_cooldown," throw_cooldown=",game.player.throw_cooldown)
	game.mode = "test"
	game.player.visual.tick_action(0.07)
	print("REVIEW simultaneous_attack spent_stones=",stones-game.state.stones," projectiles=",game.projectiles.get_child_count())
	game.player.visual.cancel_action()
	game.player.position = Vector2(420,365)
	game.player.visual.start_action("thrust",Vector2.RIGHT,func() -> void: pass)
	game.player.visual.tick_action(0.04)
	var start: Vector2 = game.player.position
	game.mode = "playing"
	Input.action_press("interact")
	Input.action_press("move_right")
	game.player._physics_process(0.016)
	Input.action_release("interact")
	Input.action_release("move_right")
	print("REVIEW interaction_during_attack mode=",game.mode," rig_active=",rig.active," moved_after_modal=",game.player.position.distance_to(start))
	game.resume()
	game.player.visual.cancel_action()
	var calls: Array[int] = [0]
	game.player.visual.start_action("thrust",Vector2.RIGHT,func() -> void: calls[0]+=1)
	game.player.visual.tick_action(0.2)
	print("REVIEW large_step_contact calls=",calls[0]," extension_at_callback_end=",rig.extension," expected_contact_extension=17")
	game.player.visual.cancel_action()
	game.player.visual.start_action("heavy",Vector2.RIGHT,func() -> void: pass)
	game.player.visual.tick_action(0.135)
	print("REVIEW heavy_visual_tip_distance=",(Vector2.RIGHT*rig.extension+Vector2.RIGHT*32+Vector2.RIGHT*rig.body_push).length()," damage_reach=62")
	var boss_rig = load("res://scripts/weapon_rig.gd").new()
	game.world.add_child(boss_rig)
	boss_rig.setup("guardian")
	boss_rig.start("sweep",Vector2.RIGHT,func() -> void: pass)
	boss_rig.tick(0.105)
	print("REVIEW boss_sweep_weapon_axis_deg=",boss_rig.weapon.frame*45," damage_axis_deg=0")
	var hunter = game.actor_by_id("hunter")
	hunter.visual.pose(Vector2.RIGHT,false,"work",1.0)
	print("REVIEW hunter_weapon_shown=",hunter.visual.rig.style," skin_expected_human_actual_rig_default=goblin")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	quit()
