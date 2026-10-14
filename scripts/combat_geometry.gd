extends RefCounted
## One authority for damaging sectors and their telegraphs.
const MELEE_RADIUS: float = 40.0
const BEAR_RADIUS: float = 46.0
const MELEE_DOT: float = 0.3
const BOSS_RADIUS: float = 74.0
const BOSS_DOT: float = 0.25
static func contains(offset: Vector2, direction: Vector2, radius: float, threshold: float) -> bool:
	return offset.length() <= radius and (offset.is_zero_approx() or direction.dot(offset.normalized()) > threshold)
static func sector(direction: Vector2, radius: float, threshold: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var half_angle: float = acos(threshold)
	for i: int in range(33): points.append(Vector2.from_angle(direction.angle()-half_angle+half_angle*2*i/32)*radius)
	return points
