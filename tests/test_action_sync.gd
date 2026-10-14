extends SceneTree
const Spec = preload("res://scripts/attack_spec.gd")
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
	game.settings.reduced_motion = true
	game.mode = "test"
	var player = game.player
	var rig = player.visual.rig
	for step: float in [1.0/120,1.0/60,1.0/30,0.1,0.2,0.5]:
		var hits: Array[float] = []
		player.visual.start_action("thrust",Vector2.RIGHT,func() -> void: hits.append(rig.extension))
		for i: int in range(ceil(0.3/step)): player.visual.tick_action(step)
		check(hits.size() == 1 and is_equal_approx(hits[0],14.0),"exact contact pose across delta "+str(step))
	for i: int in range(8):
		var direction := Spec.direction(Vector2.from_angle(i*PI/4+0.38))
		player.visual.start_action("heavy",direction,func() -> void: pass)
		player.visual.tick_action(0.13)
		var tip: Vector2 = rig.tip_position-Vector2(0,-13)
		check(absf(tip.length()-62) < 1,"heavy tip agrees with reach octant "+str(i))
		check(absf(direction.angle_to(Vector2.from_angle(rig.weapon.frame*PI/4))) < 0.001,"damage/visual aim same octant "+str(i))
	player.visual.cancel_action()
	game.mode = "playing"
	player.attack_cooldown = 0
	player.throw_cooldown = 0
	Input.action_press("spear")
	Input.action_press("throw")
	player._physics_process(0.016)
	Input.action_release("spear")
	Input.action_release("throw")
	check(rig.action_name == "throw" and player.attack_cooldown == 0,"throw priority does not charge rejected spear cooldown")
	var stones: int = game.state.stones
	player.buffered_actions.dodge = 0.15
	player.dodge_cooldown = 0
	player._physics_process(0.05)
	check(not rig.active and game.state.stones == stones,"dodge cancels before throw contact in same tick")
	player.dodge_left = 0
	player.visual.start_action("thrust",Vector2.RIGHT,func() -> void: game.state.stones-=1)
	player.position = Vector2(420,365)
	var before: Vector2 = player.position
	player.buffered_actions.interact = 0.15
	Input.action_press("move_right")
	Input.action_press("spear")
	player._physics_process(0.016)
	check(game.mode == "dialogue" and not rig.active and player.position == before,"NPC modal cancels pending attack and stops movement")
	game.resume()
	player.attack_cooldown = 0
	player._physics_process(0.016)
	check(not rig.active,"held spear cannot auto-attack after dialogue")
	Input.action_release("spear")
	Input.action_release("move_right")
	player._physics_process(0.016)
	check(not player.require_weapon_release,"weapon release rearms input")
	await process_frame # Clear just-pressed flags from prior injected input fixture.
	player.position = Vector2(430,430)
	player.visual.start_action("thrust",Vector2.RIGHT,func() -> void: pass)
	player.buffered_actions.throw = 0.12
	player.throw_cooldown = 0
	var cooldown_before: float = player.throw_cooldown
	player._physics_process(0.02)
	check(rig.action_name == "thrust" and player.throw_cooldown == cooldown_before,"busy action does not consume queued throw or cooldown")
	player._physics_process(0.14)
	check(not player.buffered_actions.has("throw"),"queued weapon input expires without firing")
	player.visual.cancel_action()
	var calls: Array[int] = [0]
	game.settings.reduced_motion = false
	player.visual.start_action("thrust",Vector2.RIGHT,func() -> void:
		calls[0]+=1
		game.trigger_hitstop(0.05))
	player.visual.tick_action(0.5)
	check(calls[0] == 1 and rig.active and absf(rig.extension-14)<0.01,"contact hit-stop keeps contact pose and remainder pending")
	game._process(0.06)
	player.visual.tick_action(0.016)
	check(calls[0] == 1 and not rig.active,"large-step remainder resumes once after hit-stop")
	game.settings.reduced_motion = true
	check(game.actor_by_id("hunter").visual.rig.skin_color == Color("d4a276"),"hunter human hand palette")
	check(game.actor_by_id("smith").visual.rig.skin_color == Color("d4a276"),"smith human hand palette")
	game.state.accept("main")
	for id: String in ["forest","creek","ruins"]: game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar()
	game.state.finish_main()
	game.continue_chapter()
	game.mode = "test"
	game.state.stage = 5
	var boss = game.actor_by_id("guardian")
	game.player.position = boss.position+Vector2.from_angle(0.4)*65
	game.player.health.invulnerable = 0
	boss.attack_kind = 0
	boss.aim_locked = Vector2.RIGHT
	boss.execute_attack()
	boss.visual.tick_action(0.13)
	check(game.player.health.hp == 100,"sweep not yet crossed later target angle")
	check(absf((boss.visual.rig.tip_position-Vector2(0,-13)).length()-74)<1,"boss sweep tip agrees with damaging radius")
	boss.visual.tick_action(0.075)
	check(game.player.health.hp == 76,"sweep crossing target applies one hit")
	game.player.health.invulnerable = 0
	boss.visual.tick_action(0.2)
	check(game.player.health.hp == 76,"same sweep never hits twice")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("ACTION SYNC: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
