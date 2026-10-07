extends SceneTree
func _initialize() -> void:
	var file: FileAccess = FileAccess.open("res://build/linux/GODOT-LICENSES.txt",FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(Engine.get_license_text() + "\n\nTHIRD PARTY NOTICES\n\n")
	for name: String in Engine.get_license_info():
		file.store_string(name + "\n" + str(Engine.get_license_info()[name]) + "\n\n")
	file.close()
	quit()
