extends RefCounted
var volumes: Dictionary = {"Master":0.8, "Music":0.65, "Ambient":0.7, "SFX":0.85}
var screenshake: bool = true
var fullscreen: bool = false

func _init() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for bus: String in volumes:
			volumes[bus] = clampf(float(config.get_value("audio", bus, volumes[bus])),0,1)
		screenshake = bool(config.get_value("video", "screenshake", true))
		fullscreen = bool(config.get_value("video", "fullscreen", false))

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
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func save() -> void:
	var config: ConfigFile = ConfigFile.new()
	for bus: String in volumes: config.set_value("audio", bus, volumes[bus])
	config.set_value("video", "screenshake", screenshake)
	config.set_value("video", "fullscreen", fullscreen)
	var error: Error = config.save("user://settings.cfg")
	if error != OK: push_warning("Không lưu được cài đặt: " + error_string(error))
