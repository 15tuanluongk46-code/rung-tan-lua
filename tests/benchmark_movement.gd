extends SceneTree
## Real-time input benchmark. Samples buffered in RAM, written once after runs.
var game: Node
var samples: Array[float] = []
var cpu: Array[float] = []
var physics: Array[float] = []
var raw_steps: Array[float] = []
var last_position: Vector2
var last_usec: int
var results: Array = []
func _initialize() -> void: call_deferred("run")
func percentile(values: Array[float], q: float) -> float:
	var copy: Array[float] = values.duplicate(); copy.sort()
	return copy[mini(copy.size()-1,int(copy.size()*q))] if not copy.is_empty() else 0
func run() -> void:
	create_timer(80).timeout.connect(func() -> void: quit(2))
	game = load("res://scenes/Main.tscn").instantiate(); root.add_child(game)
	await process_frame
	game.start_game()
	for actor: Node in game.actors:
		if actor != game.player: actor.set_physics_process(false)
	game.settings.screenshake = false
	var label: String = "baseline"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--label="): label = arg.trim_prefix("--label=")
	var cases: Array = [["120-off",120,false,false,true],["60-off",60,false,false,true],["120-interp",120,false,true,true],["120-interp-direct",120,false,true,false],["60-vsync-interp",60,true,true,false],["120-no-fx",120,false,false,true]]
	for config: Array in cases:
		Engine.max_fps = config[1]
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if config[2] else DisplayServer.VSYNC_DISABLED)
		physics_interpolation = config[3]
		game.camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS if config[3] else Camera2D.CAMERA2D_PROCESS_IDLE
		game.camera.position_smoothing_enabled = config[4]
		game.effects.visible = config[0] != "120-no-fx"
		game.atmosphere.visible = config[0] != "120-no-fx"
		game.art._atmosphere.visible = config[0] != "120-no-fx"
		for light: PointLight2D in game.art._lights: light.shadow_enabled = config[0] != "120-no-fx" and light.position in [Vector2(440,464),Vector2(530,1174)]
		game.player.position = Vector2(440,460)
		game.player.reset_physics_interpolation(); game.camera.reset_smoothing()
		game.mode = "playing"
		game.player.set_test_aim(Vector2(800,460))
		await create_timer(.35).timeout
		samples.clear(); cpu.clear(); physics.clear(); raw_steps.clear()
		last_usec = Time.get_ticks_usec(); last_position = game.player.position
		var start: int = last_usec
		var last_dodge: int = -1
		while Time.get_ticks_usec()-start < 4000000:
			var t: float = (Time.get_ticks_usec()-start)/1000000.0
			var right: bool = t<2
			Input.action_press("move_right" if right else "move_left")
			Input.action_release("move_left" if right else "move_right")
			var dodge_index: int = int(t)
			if dodge_index != last_dodge:
				Input.action_press("dodge");last_dodge = dodge_index
			else: Input.action_release("dodge")
			await process_frame
			var now: int = Time.get_ticks_usec()
			samples.append((now-last_usec)/1000.0); last_usec = now
			cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
			physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
			raw_steps.append(game.player.position.distance_to(last_position));last_position=game.player.position
		Input.action_release("move_left"); Input.action_release("move_right");Input.action_release("dodge")
		var zeros: int = 0;var slow: int = 0
		for d: float in raw_steps:
			if d<.001:zeros+=1
		for ms: float in samples:
			if ms>33.33:slow+=1
		var row: Dictionary = {"case":config[0],"frames":samples.size(),"p50_ms":percentile(samples,.5),"p95_ms":percentile(samples,.95),"p99_ms":percentile(samples,.99),"over33":slow,"cpu_p95_ms":percentile(cpu,.95),"physics_p95_ms":percentile(physics,.95),"raw_physics_zero_percent":100.0*zeros/maxi(1,raw_steps.size()),"refresh_hz":DisplayServer.screen_get_refresh_rate(),"physics_hz":Engine.physics_ticks_per_second}
		results.append(row);print("MOVEMENT ",JSON.stringify(row))
	var store = load("res://scripts/save_manager.gd").new()
	store.path = "user://movement-save-fixture.json"
	var save_ms: Array[float] = []
	for i: int in range(12):
		var started: int = Time.get_ticks_usec()
		if not store.save_state(game.state):printerr(store.last_error);quit(1);return
		save_ms.append((Time.get_ticks_usec()-started)/1000.0)
	print("SAVE LATENCY p50_ms=",percentile(save_ms,.5)," p95_ms=",percentile(save_ms,.95))
	results.append({"case":"save-latency","p50_ms":percentile(save_ms,.5),"p95_ms":percentile(save_ms,.95)})
	var file := FileAccess.open("user://movement-"+label+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"));file.close()
	game.queue_free();await process_frame;await create_timer(.35).timeout;quit()
