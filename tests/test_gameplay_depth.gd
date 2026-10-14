extends SceneTree
const State = preload("res://scripts/run_state.gd")
const Save = preload("res://scripts/save_manager.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func run() -> void:
	var state := State.new()
	state.accept("main")
	state.pickup("ember_creek","ember","creek")
	check(state.skills.has("charge"),"any first ember unlocks charge")
	var old: Dictionary = state.snapshot()
	for key: String in ["skills","specialization","rewards_received","known_checkpoints","encountered"]: old.erase(key)
	var migrated: Dictionary = State.migrate_v1(old)
	check(State.valid_snapshot(migrated) and migrated.skills.has("charge"),"v1 migration infers unlocked skills")
	var store := Save.new()
	store.path = "user://depth-save-fixture-"+str(Time.get_ticks_usec())+".json"
	var file := FileAccess.open(store.path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"state":old}))
	file.close()
	check(store.load_state() != null,"actual v1 file loads")
	var old_completed: Dictionary = old.duplicate(true)
	old_completed.claimed = {}
	check(not State.migrate_v1(old_completed).rewards_received.has("bridge"),"migration never grants unearned reward")
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.mode = "test"
	game.state.accept("main")
	for id: String in ["forest","creek","ruins"]: game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar()
	game.state.finish_main()
	game.continue_chapter()
	game.mode = "test"
	game.state.stage = 1
	for id: String in ["lamp_0","lamp_1","lamp_2"]: game.state.complete_event(id)
	game.state.complete_event("well")
	game.state.stage = 4
	game.state.changed.emit()
	check(game.state.skills.has("perfect_dodge"),"well unlocks perfect dodge")
	game.state.accept("bridge")
	game.state.planks = 3
	game.state.potions = 6
	check(game.state.reward("bridge") and game.state.events.has("bridge") and not game.state.rewards_received.has("bridge"),"full inventory never blocks construction")
	game.state.potions = 5
	check(game.state.collect_reward("bridge") and game.state.potions == 6,"pending reward claim delivers full reward")
	check(not game.state.collect_reward("bridge"),"no duplicate reward")
	game.state.accept("bell")
	game.state.bell_parts = 3
	game.state.stones = 30
	check(game.state.reward("bell") and not game.state.rewards_received.has("bell"),"bell pending persisted")
	check(store.save_state(game.state),"v2 state saves")
	var backup := FileAccess.open(store.path+".bak",FileAccess.READ)
	check(backup != null and int(JSON.parse_string(backup.get_as_text()).version) == 1,"first migration save preserves v1 backup")
	if backup != null: backup.close()
	var restored = store.load_state()
	check(restored != null and restored.skills.has("perfect_dodge") and not restored.rewards_received.has("bell"),"v2 skill and pending reward survive load")
	var previous: Dictionary = game.state.snapshot()
	for key: String in ["skills","specialization","rewards_received","known_checkpoints","encountered"]: previous.erase(key)
	var legacy: Dictionary = State.migrate_v1(previous)
	check(legacy.rewards_received.has("bridge") and legacy.rewards_received.has("bell"),"v1 completed construction rewards are never reissued")
	check(game.state.choose_specialization("survival"),"stage four allows specialization")
	game.state.hp = 40
	check(game.state.heal() and game.state.hp == 90,"survival potion heals 50")
	var ability = game.player.abilities
	ability.begin_charge()
	ability.tick(0.3)
	check(not ability.release_charge(),"undercharged release is not heavy attack")
	ability.begin_charge()
	ability.tick(0.6)
	check(ability.release_charge(),"charge reaches threshold")
	ability.begin_charge()
	ability.begin_dodge()
	check(not ability.charging,"dodge cancels charge")
	game.player.dodge_left = 0.2
	var enemy = game.actor_by_id("coal_0")
	check(ability.confirm_perfect(game,"coal_0:confirmed",enemy),"actual incoming attack grants perfect counter")
	check(not ability.confirm_perfect(game,"coal_0:confirmed",enemy),"same attack cannot reward twice")
	check(not ability.confirm_perfect(game,"coal_0_trail_2",enemy),"persistent hazard grants no perfect reward")
	check(ability.consume_counter() == 10 and ability.consume_counter() == 0,"counter consumed once")
	ability.begin_dodge()
	ability.tick(0.2)
	check(not ability.confirm_perfect(game,"late_hit",enemy),"late dodge never grants perfect reward")
	ability.begin_dodge()
	check(not ability.confirm_perfect(game,"ground",null),"empty/ground dodge never grants perfect reward")
	enemy.ai_state = "windup"
	enemy.interrupt(0.45)
	check(enemy.ai_state == "recover","charged interruption creates opening")
	enemy.aim_locked = Vector2.RIGHT
	enemy.execute_attack()
	enemy.visual.tick_action(0.11)
	check(enemy.coal_hazards.size() == 1,"coal attack leaves bounded hazard")
	for i: int in range(4):
		enemy.execute_attack()
		enemy.visual.tick_action(0.11)
	check(enemy.coal_hazards.size() <= 2,"coal hazard pool remains bounded")
	var stalker = game.actor_by_id("stalker_0")
	game.player.position = stalker.position+Vector2(75,0)
	game.mode = "playing"
	game.combat_freeze_left = 0
	stalker.target = game.player
	stalker.ai_state = "chase"
	stalker._physics_process(0.016)
	check(stalker.ai_state == "windup","stalker warns before rush")
	stalker.timer = 0
	stalker._physics_process(0.016)
	check(stalker.ai_state == "rush" and stalker.rush_left > 0,"stalker locks a timed rush")
	game.mode = "test"
	check(game.world_events.is_lit(Vector2(850,2090)),"activated lamp reveals nearby stalker")
	var boss = game.actor_by_id("guardian")
	boss.ai_state = "windup"
	boss.interrupt(0.45)
	check(boss.ai_state == "windup","boss windup cannot be deleted by stagger")
	boss.ai_state = "recover"
	boss.timer = 0.7
	boss.interrupt(0.45)
	check(boss.timer > 0.7,"charged recovery timing extends boss opening")
	game.state.stage = 5
	boss.phase = 2
	boss.ai_state = "windup"
	boss.attack_kind = 0
	boss.combo_left = 1
	boss.timer = 0
	game.player.position = boss.position+Vector2(110,0)
	game.mode = "playing"
	game.combat_freeze_left = 0
	boss._physics_process(0.016)
	check(boss.ai_state == "windup" and boss.attack_kind == 1 and boss.timer >= 0.85,"phase two combo includes another readable warning")
	game.mode = "test"
	game.state.known_checkpoints.marsh = true
	game.player.position = Vector2(450,480)
	game.mode = "paused"
	check(not game.travel_checkpoint("ash"),"cannot fast travel to unknown checkpoint")
	var hp_before: int = game.state.hp
	var stones_before: int = game.state.stones
	check(game.travel_checkpoint("marsh"),"known checkpoint outside combat permits return")
	check(game.state.hp == hp_before and game.state.stones == stones_before,"checkpoint travel grants no health or inventory")
	game.player.position = enemy.position+Vector2(40,0)
	game.mode = "paused"
	check(not game.travel_checkpoint("camp"),"combat blocks checkpoint escape")
	game.start_game()
	check(game.state.skills.is_empty() and game.player.abilities.counter_left == 0,"new run resets permanent and transient progression")
	game.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("GAMEPLAY DEPTH: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
