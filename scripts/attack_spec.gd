extends RefCounted
## Shared authored pose/contact geometry; distances measured on gameplay ground plane.
const SPEAR_LENGTH: float = 32.0
const NORMAL_REACH: float = 49.0
const HEAVY_REACH: float = 62.0
const SWEEP_START: float = 0.10
const SWEEP_END: float = 0.22
const SWEEP_HALF: float = 1.318116071652818
static var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/action_spec.json"))
static func direction(aim: Vector2) -> Vector2:
	if aim.is_zero_approx(): return Vector2.DOWN
	return Vector2.from_angle(roundi(aim.angle()/(PI/4))*PI/4)
static func contact(name: String) -> float:
	return float(data.actions.get(name,{}).get("contact",0.10))
static func duration(name: String) -> float:
	return float(data.actions.get(name,{}).get("duration",0.32))
static func extension(name: String) -> float:
	return NORMAL_REACH-SPEAR_LENGTH-3.0 if name == "thrust" else (HEAVY_REACH-SPEAR_LENGTH-5.0 if name == "heavy" else (16.0 if name == "throw" else 8.0))
