extends RefCounted
static var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world_routes.json"))
static func bridge_rect(key: String) -> Rect2:
	var rect: Array = data.bridge[key]
	return Rect2(rect[0],rect[1],rect[2],rect[3])
## Single authored source shared by terrain generation and runtime clearance.
static func paths(key: String) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var entries: Array = [data[key]] if key == "creek" else data[key]
	for entry: Array in entries:
		var path := PackedVector2Array()
		for point: Array in entry: path.append(Vector2(point[0],point[1]))
		result.append(path)
	return result
