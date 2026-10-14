extends SceneTree
const Save = preload("res://scripts/save_manager.gd")
var checks: int = 0
var failures: int = 0
class FlakyStore extends "res://scripts/save_manager.gd":
	var attempts: int = 0
	func save_state(state: RefCounted) -> bool:
		attempts += 1
		if attempts == 1:
			last_error = "Injected temporary write failure"
			return false
		return super.save_state(state)
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func run() -> void:
	var store := FlakyStore.new()
	store.path = "user://quality-autosave-restart-fixture.json"
	if "--read-fixture" in OS.get_cmdline_user_args():
		var restored = store.load_state()
		check(restored != null and restored.stones == 11 and restored.picked.has("herb_0"),"independent process reads production autosave snapshot")
		print("AUTOSAVE PROCESS RESTART: %d checks, %d failures" % [checks,failures])
		quit(1 if failures else 0)
		return
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save_manager = store
	game.autosave_enabled = true # Explicitly exercise production pipeline in an isolated slot.
	game.start_game()
	game.mode = "test"
	game.state.pickup("herb_0","herb")
	game._process(0.4)
	check(store.attempts == 1 and game.save_pending and game.save_failures == 1,"failed autosave retains dirty state")
	game._process(1.0)
	check(store.attempts == 1,"retry is bounded, not every frame")
	game._process(2.0)
	check(store.attempts == 2 and not game.save_pending and game.save_status == "Đã lưu","retry succeeds without a new event")
	var restored = store.load_state()
	check(restored != null and restored.picked.has("herb_0"),"pipeline persists actual event")
	game.state.use_stone()
	check(game.save_pending,"new inventory event schedules save")
	game._process(0.4)
	check(store.load_state().stones == 11,"consumed inventory survives pipeline save")
	game.queue_free()
	await process_frame
	var replacement = load("res://scenes/Main.tscn").instantiate()
	root.add_child(replacement)
	await process_frame
	replacement.save_manager = store
	replacement.continue_game()
	check(replacement.state.stones == 11 and not replacement.item_nodes.has("herb_0"),"new scene continues production snapshot")
	replacement.queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("AUTOSAVE PIPELINE: %d checks, %d failures; isolated fixture %s" % [checks,failures,store.path])
	quit(1 if failures else 0)
