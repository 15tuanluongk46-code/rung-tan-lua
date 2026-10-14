extends RefCounted
## One validated versioned snapshot. Temporary file is checked before rotation.
const State = preload("res://scripts/run_state.gd")
const VERSION: int = 2
var path: String = "user://journey.json"
var last_error: String = ""
var recovered: bool = false

func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {}
	var file := FileAccess.open(file_path,FileAccess.READ)
	if file == null: return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary: return {}
	var envelope: Dictionary = parser.data
	if not (envelope.get("version") is int or envelope.get("version") is float): return {}
	if float(envelope.version) != floorf(float(envelope.version)): return {}
	if int(envelope.get("version",0)) not in [1,VERSION] or not envelope.get("state") is Dictionary: return {}
	var data: Dictionary = envelope.state
	if int(envelope.version) == 1: data = State.migrate_v1(data)
	if data.is_empty(): return {}
	if not State.valid_snapshot(data): return {}
	return data

func available() -> bool:
	return not _read(path).is_empty() or not _read(path+".bak").is_empty()

func load_state() -> RefCounted:
	last_error = ""
	recovered = false
	var data: Dictionary = _read(path)
	if data.is_empty():
		data = _read(path+".bak")
		recovered = not data.is_empty()
	if data.is_empty():
		last_error = "Không đọc được hành trình. File lưu thiếu, hỏng hoặc khác phiên bản."
		return null
	var state := State.new()
	state.restore(data)
	return state

func save_state(state: RefCounted) -> bool:
	last_error = ""
	var data: Dictionary = state.snapshot()
	if not State.valid_snapshot(data):
		last_error = "Dữ liệu hành trình chưa hợp lệ; giữ nguyên bản lưu trước."
		return false
	var temp: String = path+".tmp"
	var file := FileAccess.open(temp,FileAccess.WRITE)
	if file == null:
		last_error = "Không thể mở file lưu: " + str(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify({"version":VERSION,"state":data}))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK or _read(temp).is_empty():
		last_error = "Không ghi được hành trình; giữ nguyên bản lưu trước."
		return false
	# Do not rotate a corrupt primary over a usable backup.
	if not _read(path).is_empty():
		var backup_error: Error = DirAccess.copy_absolute(path,path+".bak")
		if backup_error != OK:
			last_error = "Không tạo được bản dự phòng: " + str(backup_error)
			return false
	var rename_error: Error = DirAccess.rename_absolute(temp,path)
	if rename_error != OK:
		last_error = "Không thay thế được file lưu: " + str(rename_error)
		return false
	return true
