extends SceneTree

# Regression targets: duplicate pickups/rewards, bypassed prerequisites, lost
# death progress, repeated damage per swing and missing/extra spawn actors.
var failures: int = 0
var checks: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	for path: String in ["run_state", "combat_health", "world_content"]:
		check(ResourceLoader.exists("res://scripts/%s.gd" % path), "required gameplay module " + path)
	if failures > 0:
		finish()
		return
	var state: RefCounted = load("res://scripts/run_state.gd").new()
	check(not state.light_altar(), "altar rejects missing quest/embers")
	check(not state.finish_main(), "chief rejects premature completion")
	state.accept("main")
	check(state.pickup("herb_a", "herb"), "first herb pickup succeeds")
	check(not state.pickup("herb_a", "herb"), "duplicate pickup is rejected")
	check(state.herbs == 1, "duplicate pickup cannot increase inventory")
	state.accept("herbs")
	check(not state.reward("herbs"), "herbalist requires five herbs")
	for i: int in range(4):
		state.pickup("herb_" + str(i), "herb")
	state.potions = 0
	check(state.reward("herbs"), "five herbs reward succeeds")
	check(state.potions == 2 and state.herbs == 0, "herbs consumed for two potions")
	check(not state.reward("herbs") and state.potions == 2, "herb reward once only")
	state.accept("bag")
	check(not state.reward("bag"), "hunter requires bag")
	state.pickup("hunter_bag", "bag")
	state.stones = 0
	check(state.reward("bag"), "bag reward accepted")
	check(state.stones == 8 and state.potions == 3, "hunter gives eight stones and potion")
	check(not state.reward("bag"), "hunter reward once only")
	for ember: String in ["forest", "creek", "ruins"]:
		check(state.pickup("ember_" + ember, "ember", ember), "unique ember " + ember)
	check(not state.pickup("forged_duplicate", "ember", "forest"), "ember identity cannot be duplicated")
	check(state.embers.size() == 3, "three distinct embers")
	check(state.light_altar(), "all prerequisites light altar")
	check(not state.light_altar(), "altar activation idempotent")
	check(state.finish_main() and state.ended, "end-to-end quest can return to chief")
	check(not state.finish_main(), "ending once only")
	state.kill_actor("melee_0")
	state.activate_checkpoint("creek")
	state.hp = 0
	state.respawn()
	check(state.hp == 100 and state.deaths == 1, "death restores HP and counts death")
	check(state.checkpoint == "creek", "checkpoint survives death")
	check(state.killed.has("melee_0") and state.picked.has("herb_a"), "death preserves kills and pickups")
	check(state.altar_lit and state.claimed.has("bag"), "death preserves progression")
	state.potions = 6
	check(not state.pickup("full_potion", "potion"), "full inventory leaves pickup available")
	check(not state.picked.has("full_potion"), "failed pickup does not consume object")
	state.hp = 70
	check(state.heal() and state.hp == 100 and state.potions == 5, "healing capped at 100")
	check(not state.heal() and state.potions == 5, "full HP does not waste potion")
	var health: RefCounted = load("res://scripts/combat_health.gd").new(100)
	check(health.hit(25, "swing1"), "first spear attack deals damage")
	check(health.hp == 75, "spear deals exactly 25")
	check(not health.hit(25, "swing2"), "invulnerability blocks damage")
	health.tick(1.0)
	check(not health.hit(25, "swing1"), "attack deduplication persists after invulnerability")
	check(health.hit(25, "swing2") and health.hp == 50, "new attack after invulnerability damages")
	health.guard(0.25)
	check(not health.hit(25, "swing3"), "dodge grants protection")
	health.reset()
	check(health.hp == 100 and health.hit(25, "swing1"), "survivor reset clears damage/attack IDs")
	var content: RefCounted = load("res://scripts/world_content.gd").new()
	var census: Dictionary = {}
	var ids: Dictionary = {}
	for actor: Dictionary in content.actors():
		census[actor.kind] = int(census.get(actor.kind, 0)) + 1
		check(not ids.has(actor.id), "unique actor ID " + actor.id)
		ids[actor.id] = true
	check(ids.size() == 28 and census.size() == 13, "28 actors / 13 kinds")
	check(census == {"player":1,"chief":1,"hunter":1,"healer":1,"smith":1,"gatherer":1,"melee":6,"archer":4,"shaman":2,"bear":2,"deer":3,"rabbit":3,"bird":2}, "exact actor census")
	check(content.centers.size() == 4, "four connected region definitions")
	finish()

func finish() -> void:
	print("GAMEPLAY TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
