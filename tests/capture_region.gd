extends Node
## Screenshot readback is deliberately AFTER the measured interval.
var game: Node
var region: String
var frames: int = 0
var started: int = 0
var previous_tick: int = 0
var samples: Array[float] = []
var finished: bool = false

func begin(owner_game: Node, selected: String) -> void:
	game = owner_game
	region = selected
	game.start_game()
	game.player.position = game.content.centers[region]
	game.camera.reset_smoothing()

func _process(_delta: float) -> void:
	if game == null or finished: return
	frames += 1
	var now: int = Time.get_ticks_usec()
	if frames == 60:
		started = now
		previous_tick = now
	if frames > 60:
		samples.append((now - previous_tick)/1000.0)
		previous_tick = now
	if frames < 240: return
	finished = true
	var seconds: float = (now-started)/1000000.0
	samples.sort()
	print("PERFORMANCE region=%s frames=%d seconds=%.3f fps=%.2f median_ms=%.2f p95_ms=%.2f renderer=%s mode=%s" % [region,samples.size(),seconds,samples.size()/seconds,samples[samples.size()/2],samples[int(samples.size()*0.95)],DisplayServer.get_name(),game.mode])
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("user://captures")
		var path: String = "user://captures/" + region + ".png"
		var error: Error = get_viewport().get_texture().get_image().save_png(path)
		print("CAPTURE ",ProjectSettings.globalize_path(path)," status=",error)
	else:
		print("CAPTURE skipped: headless, not a GPU measurement")
	# Let the audio server finish releasing decoder voices before quitting.
	game.queue_free()
	get_tree().create_timer(0.2).timeout.connect(get_tree().quit)
