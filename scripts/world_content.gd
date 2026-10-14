extends RefCounted
const SIZE: Vector2 = Vector2(2400, 2400)
const ALTAR: Vector2 = Vector2(1810,1190)
const NPC_KINDS: Array[String] = ["chief","hunter","healer","smith","gatherer","sen","tung"]
const HOSTILE_KINDS: Array[String] = ["melee","archer","shaman","bear","stalker","coal","guardian"]
const REGION_BOUNDS: Dictionary = {"camp":Rect2(0,0,1200,800),"forest":Rect2(1200,0,1200,800),"creek":Rect2(0,800,1200,800),"ruins":Rect2(1200,800,1200,800),"marsh":Rect2(0,1600,1200,800),"ash":Rect2(1200,1600,1200,800)}
var expansion_roads: Array[PackedVector2Array] = preload("res://scripts/world_routes.gd").paths("expansion_roads")
const START: Vector2 = Vector2(430, 450)
var centers: Dictionary = {"camp":Vector2(420,380), "forest":Vector2(1720,380), "creek":Vector2(520,1190), "ruins":ALTAR,"marsh":Vector2(480,1760),"ash":Vector2(1660,1750)}
var names: Dictionary = {"camp":"Trại Tro", "forest":"Rừng Sâu", "creek":"Bờ Suối", "ruins":"Phế Tích","marsh":"Đầm Sương","ash":"Đồi Than"}
var checkpoints: Dictionary = {"camp":Vector2(440,480), "creek":Vector2(530,1190),"marsh":Vector2(460,1810),"ash":Vector2(1630,1790)}

func region_at(point: Vector2) -> String:
	if point.y >= 1600: return "marsh" if point.x < 1200 else "ash"
	if point.y < 800: return "camp" if point.x < 1200 else "forest"
	return "creek" if point.x < 1200 else "ruins"

func actors(chapter: int = 1) -> Array[Dictionary]:
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
	if chapter >= 2: result.append_array(expansion_actors())
	return result

func expansion_actors() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{"id":"sen","kind":"sen","name":"Người giữ đèn Sen","pos":Vector2(480,1740)},
		{"id":"tung","kind":"tung","name":"Thợ lò Tùng","pos":Vector2(1650,1730)},
		{"id":"guardian","kind":"guardian","name":"Người Giữ Than","pos":Vector2(1960,2140)}]
	for kind: String in ["stalker","coal"]:
		var points: Array = [Vector2(690,1920),Vector2(940,2040),Vector2(330,2090),Vector2(790,2230)] if kind == "stalker" else [Vector2(1510,1920),Vector2(1770,1980),Vector2(2080,1920),Vector2(2180,2180)]
		for i: int in range(points.size()): result.append({"id":kind+"_"+str(i),"kind":kind,"pos":points[i],"name":""})
	result.append({"id":"deer_marsh","kind":"deer","pos":Vector2(280,1800),"name":""})
	result.append({"id":"bird_ash","kind":"bird","pos":Vector2(1450,1740),"name":""})
	return result

func items(chapter: int = 1) -> Array[Dictionary]:
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
	if chapter >= 2: result.append_array(expansion_items())
	return result

func expansion_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i: int in range(3):
		result.append({"id":"plank_"+str(i),"kind":"plank","pos":[Vector2(320,1860),Vector2(650,2150),Vector2(780,1850)][i]})
		result.append({"id":"bell_part_"+str(i),"kind":"bell_part","pos":[Vector2(1440,2040),Vector2(2140,1880),Vector2(2220,2020)][i]})
	for i: int in range(6): result.append({"id":"south_supply_"+str(i),"kind":"potion" if i%2 == 0 else "stone","pos":[Vector2(480,1840),Vector2(880,2130),Vector2(1300,1880),Vector2(1680,1830),Vector2(1810,2050),Vector2(2050,2320)][i]})
	return result

func optional_items() -> Array[Dictionary]:
	return [{"id":"light_cache","kind":"potion","pos":Vector2(1030,2150)}]

func world_events() -> Array[Dictionary]:
	return [
		{"id":"lamp_0","name":"Đèn Bến Lau","kind":"lantern","pos":Vector2(580,1830)},
		{"id":"lamp_1","name":"Đèn Lối Cầu","kind":"lantern","pos":Vector2(680,1970)},
		{"id":"lamp_2","name":"Đèn Giếng Nguồn","kind":"lantern","pos":Vector2(850,2090)},
		{"id":"well","name":"Thanh tẩy Giếng Nguồn","kind":"well","pos":Vector2(900,2120),"guards":["stalker_1"]},
		{"id":"valve_0","name":"Van Lò Tây","kind":"valve","pos":Vector2(1750,1930),"guards":["coal_1"]},
		{"id":"valve_1","name":"Van Lò Đông","kind":"valve","pos":Vector2(2080,1980),"guards":["coal_2"]},
		{"id":"bridge","name":"Sửa Cây Cầu Về Nhà","kind":"broken_bridge","pos":Vector2(570,1990)},
		{"id":"bell","name":"Khôi phục Chuông Lò","kind":"bell","pos":Vector2(1590,1750)},
		{"id":"memory_marsh","name":"Đọc ký ức Miếu Chìm","kind":"memory","pos":Vector2(330,2200)},
		{"id":"memory_ash","name":"Đọc bia Lò Cũ","kind":"memory","pos":Vector2(1500,2160)},
		{"id":"memory_tower","name":"Đọc ký ức Tháp Lửa","kind":"memory","pos":Vector2(2130,2300)}]
