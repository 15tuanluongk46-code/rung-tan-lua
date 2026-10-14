extends RefCounted
var volumes: Dictionary = {"Master":0.8, "Music":0.65, "Ambient":0.7, "SFX":0.85}
var screenshake: bool = true
var fullscreen: bool = false
var large_text: bool = false
var reduced_motion: bool = false
var reduced_flash: bool = false
var vsync: bool = false
var frame_cap: int = 120
var hitstop_level: int = 2
var dirty_left: float = -1.0
var path: String = "user://settings.cfg"

func _init() -> void:
	for argument: String in OS.get_cmdline_args()+OS.get_cmdline_user_args():
		if argument.contains("tests/") or argument.begins_with("--capture-"):
			path = "user://test-settings-%d.cfg" % OS.get_process_id()
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) == OK:
		for bus: String in volumes:
			volumes[bus] = clampf(float(config.get_value("audio", bus, volumes[bus])),0,1)
		screenshake = bool(config.get_value("video", "screenshake", true))
		fullscreen = bool(config.get_value("video", "fullscreen", false))
		large_text = bool(config.get_value("accessibility","large_text",false))
		reduced_motion = bool(config.get_value("accessibility","reduced_motion",false))
		reduced_flash = bool(config.get_value("accessibility","reduced_flash",false))
		vsync = bool(config.get_value("video","vsync",false))
		var cap: int = int(config.get_value("video","frame_cap",120))
		frame_cap = cap if cap in [60,120] else 120
		hitstop_level = clampi(int(config.get_value("video","hitstop_level",2)),0,2)

func apply(audio: Node) -> void:
	for bus: String in volumes:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
		var index: int = AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001,volumes[bus])))
		AudioServer.set_bus_mute(index, volumes[bus] <= 0)
		if audio != null and audio.has_method("set_volume"): audio.set_volume(bus, volumes[bus])
	if DisplayServer.get_name() != "headless":
		var target: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != target: DisplayServer.window_set_mode(target)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = frame_cap

func set_bus(audio: Node, bus: String, value: float) -> void:
	volumes[bus] = clampf(value,0,1)
	if audio != null: audio.set_volume(bus,volumes[bus])
	mark_dirty()

func mark_dirty() -> void:
	dirty_left = 0.5

func tick(delta: float) -> void:
	if dirty_left < 0: return
	dirty_left -= delta
	if dirty_left <= 0: save()

func save() -> void:
	dirty_left = -1.0
	var config: ConfigFile = ConfigFile.new()
	for bus: String in volumes: config.set_value("audio", bus, volumes[bus])
	config.set_value("video", "screenshake", screenshake)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video","vsync",vsync)
	config.set_value("video","frame_cap",frame_cap)
	config.set_value("video","hitstop_level",hitstop_level)
	config.set_value("accessibility","large_text",large_text)
	config.set_value("accessibility","reduced_motion",reduced_motion)
	config.set_value("accessibility","reduced_flash",reduced_flash)
	var error: Error = config.save(path)
	if error != OK: push_warning("Không lưu được cài đặt: " + error_string(error))
