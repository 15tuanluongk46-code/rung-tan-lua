extends SceneTree
const State = preload("res://scripts/run_state.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func chapter_two(state: RefCounted) -> void:
	state.accept("main")
	for region: String in ["forest","creek","ruins"]: state.pickup("ember_"+region,"ember",region)
	state.light_altar(); state.finish_main(); state.continue_chapter()
func run() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(2))
	var state := State.new()
	state.accept("bridge"); state.planks = 3
	check(not state.reward("bridge"),"chapter I cannot construct southern quest")
	state.activate_checkpoint("ash")
	check(state.checkpoint == "camp","checkpoint authority enforces chapter")
	state = State.new()
	var bad: Dictionary = state.snapshot()
	bad.picked.ember_forest = true
	check(not State.valid_snapshot(bad),"missing ember credit rejected")
	chapter_two(state)
	state.stage = 1
	for id: String in ["lamp_0","lamp_1","lamp_2"]: state.complete_event(id)
	bad = state.snapshot(); bad.stage = 1
	check(not State.valid_snapshot(bad),"completed lamps cannot have lagging stage")
	check(not state.complete_event("bridge"),"construction cannot bypass reward transaction")
	bad = state.snapshot(); bad.embers = null
	check(State.migrate_v1(bad).is_empty(),"malformed legacy migration fails safely")
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game(); game.mode = "test"
	game.settings.reduced_motion = true
	chapter_two(game.state)
	game.build_session(); game.state.stage = 5
	var boss = game.actor_by_id("guardian")
	boss.sweep_id = "prior_unhit_sweep"; boss.sweep_direction = Vector2.RIGHT
	boss.attack_kind = 2; boss.aim_locked = Vector2.UP
	game.player.position = boss.position+Vector2.RIGHT*50
	game.player.health.invulnerable = 0
	boss.execute_attack(); boss.visual.tick_action(.3)
	check(game.player.health.hp == 100,"trail does not replay previous boss sweep")
	boss.visual.cancel_action()
	game.player.position = Vector2(430,430)
	var wall := StaticBody2D.new()
	wall.position = game.player.position+Vector2(12,0); wall.collision_layer = 1
	var shape := CollisionShape2D.new(); var rect := RectangleShape2D.new()
	rect.size = Vector2(4,80); shape.shape = rect; wall.add_child(shape); game.world.add_child(wall)
	await physics_frame; await physics_frame
	var before: int = game.projectiles.get_child_count()
	game.player.visual.start_action("throw",Vector2.RIGHT,func() -> void: game.spawn_projectile(game.player,Vector2.RIGHT,"stone"))
	game.player.visual.tick_action(.06)
	check(game.projectiles.get_child_count() == before,"source-to-muzzle cover blocks release")
	game.player.visual.cancel_action()
	var stalker = game.actor_by_id("stalker_0")
	stalker.position = game.player.position+Vector2(22,0)
	stalker.ai_state = "rush"; stalker.rush_left = .2; stalker.aim_locked = Vector2.LEFT
	game.mode = "playing"; game.player.health.invulnerable = 0
	stalker._physics_process(.016)
	check(game.player.health.hp == 100,"rush blocked by thin wall cannot damage player")
	game.mode = "test"; wall.queue_free(); await physics_frame; await physics_frame
	game.settings.reduced_motion = false; game.mode = "playing"
	var age: float = game.player.age
	game.player.visual.start_action("thrust",Vector2.RIGHT,func() -> void: game.trigger_hitstop(.05))
	check(not game.player.advance(.1) and game.player.age == age,"contact hitstop stops remaining actor update")
	game.mode = "test"; game.combat_freeze_left = 0; game.player.visual.cancel_action()
	# First circle entry, not nearest projected center, determines projectile hit.
	for actor: Node in game.actors:
		if actor != game.player: actor.position = Vector2(2250,2250)
	var a = game.actor_by_id("melee_0"); var b = game.actor_by_id("melee_1")
	game.player.position = Vector2(430,430)
	a.position = Vector2(460,439); b.position = Vector2(462,430)
	a.health.reset(); b.health.reset()
	var projectile = load("res://scripts/projectile.gd").new()
	projectile.game = game; projectile.source = game.player; projectile.kind = "stone"
	projectile.direction = Vector2.RIGHT; projectile.attack_id = "first_entry"; projectile.position = game.player.position
	game.projectiles.add_child(projectile);game.mode = "playing"
	projectile._physics_process(.2)
	check(a.health.hp == a.health.maximum and b.health.hp == b.health.maximum-20,"first circle intersection intercepts projectile")
	game.mode = "test";game.combat_freeze_left = 0
	var bear = game.actor_by_id("bear_0");bear.health.reset()
	stalker.position = Vector2(450,430);bear.position = Vector2(470,430)
	game.player.position = Vector2(430,470);stalker.ai_state = "rush";stalker.rush_left = .2;stalker.aim_locked = Vector2.RIGHT
	game.mode = "playing";stalker._physics_process(.016)
	check(bear.health.hp == bear.health.maximum-18,"stalker rush hits valid bear target")
	game.mode = "test";game.combat_freeze_left = 0
	a.position = game.player.position;a.health.reset();game.player.facing = Vector2.RIGHT
	game.spear_attack(game.player)
	check(a.health.hp == a.health.maximum-25,"overlapping spear target is hittable")
	game.combat_freeze_left = 0
	game.ui.show_map()
	game.player.visual.start_action("throw",Vector2.RIGHT,func() -> void: failures += 1)
	for actor: Node in game.actors:
		if actor.faction in ["goblin","bear"]: actor.position = Vector2(2300,2300)
	check(game.travel_checkpoint("camp") and not game.player.visual.rig.active,"teleport cancels pending release")
	game.mode = "test"
	# Production E uses the exact displayed target, even if another is now nearer.
	game.player.position = Vector2(430,430)
	game.ui.cached_interaction = {"type":"checkpoint","id":"camp","name":"rest"}
	game.player.position = game.content.checkpoints.camp
	check(game.ui.selected_interaction().get("id") == "camp","displayed target is selected")
	game.player_died()
	check(game.mode == "dying","death gets a visual-only phase")
	game._process(.45)
	check(game.mode == "dead","death modal follows visual phase")
	game.queue_free(); await process_frame; await create_timer(.35).timeout
	print("FULL AUDIT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
