extends RefCounted
const SIZE: Vector2 = Vector2(2400, 1600)
const START: Vector2 = Vector2(430, 450)
var centers: Dictionary = {"camp":Vector2(420,380), "forest":Vector2(1720,380), "creek":Vector2(520,1190), "ruins":Vector2(1810,1190)}
var names: Dictionary = {"camp":"Trại Tro", "forest":"Rừng Sâu", "creek":"Bờ Suối", "ruins":"Phế Tích"}
var checkpoints: Dictionary = {"camp":Vector2(440,480), "creek":Vector2(530,1190)}

func region_at(point: Vector2) -> String:
	if point.y < 800: return "camp" if point.x < 1200 else "forest"
	return "creek" if point.x < 1200 else "ruins"

func actors() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{"id":"player", "kind":"player", "pos":START, "name":"Lữ khách"},
		{"id":"chief", "kind":"chief", "pos":Vector2(420,340), "name":"Già làng An"},
		{"id":"hunter", "kind":"hunter", "pos":Vector2(570,400), "name":"Thợ săn Lâm"},
		{"id":"healer", "kind":"healer", "pos":Vector2(320,450), "name":"Thầy thuốc Mai"},
		{"id":"smith", "kind":"smith", "pos":Vector2(310,300), "name":"Thợ rèn Bình"},
		{"id":"gatherer", "kind":"gatherer", "pos":Vector2(600,490), "name":"Người hái thuốc Nhi"}]
	var groups: Dictionary = {
		"melee":[Vector2(1370,360),Vector2(1660,430),Vector2(1850,340),Vector2(740,1080),Vector2(1660,1190),Vector2(1920,1240)],
		"archer":[Vector2(1520,300),Vector2(1950,440),Vector2(820,1220),Vector2(1950,1110)],
		"shaman":[Vector2(820,1370),Vector2(1820,1340)],
		"bear":[Vector2(1500,600),Vector2(1000,1130)],
		"deer":[Vector2(1070,380),Vector2(1550,210),Vector2(430,1000)],
		"rabbit":[Vector2(700,500),Vector2(1420,470),Vector2(660,1330)],
		"bird":[Vector2(580,290),Vector2(1690,1040)]}
	for kind: String in groups:
		for i: int in range(groups[kind].size()):
			result.append({"id":kind + "_" + str(i), "kind":kind, "pos":groups[kind][i], "name":""})
	return result

func items() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{"id":"ember_forest", "kind":"ember", "detail":"forest", "pos":Vector2(1850,380), "guards":["melee_2","archer_1"]},
		{"id":"ember_creek", "kind":"ember", "detail":"creek", "pos":Vector2(830,1390), "guards":["shaman_0"]},
		{"id":"ember_ruins", "kind":"ember", "detail":"ruins", "pos":Vector2(1850,1270), "guards":["melee_5","shaman_1"]},
		{"id":"hunter_bag", "kind":"bag", "pos":Vector2(970,1240)}]
	var herbs: Array[Vector2] = [Vector2(720,510),Vector2(1000,420),Vector2(680,1000),Vector2(430,1080),Vector2(610,1280)]
	for i: int in range(herbs.size()):
		result.append({"id":"herb_" + str(i), "kind":"herb", "pos":herbs[i]})
	var supplies: Array[Vector2] = [Vector2(520,490),Vector2(1120,390),Vector2(1720,540),Vector2(530,1230),Vector2(1500,1180),Vector2(2020,1270)]
	for i: int in range(supplies.size()):
		result.append({"id":"supplies_" + str(i), "kind":"potion" if i % 2 == 0 else "stone", "pos":supplies[i]})
	return result
