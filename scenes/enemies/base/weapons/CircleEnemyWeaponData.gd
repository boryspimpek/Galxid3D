extends EnemyWeaponData
class_name CircleEnemyWeaponData

# ============================================================================
# CIRCLE WEAPON DATA - salwa pocisków równomiernie dookoła wroga (płaszczyzna XZ).
# Każde wywołanie fire() wypuszcza pełny pierścień. rotate_per_salvo obraca
# wzorzec między salwami (efekt „wirowego” pierścienia). aim jest ignorowane.
# ============================================================================

const KEY_ANGLE := &"circle_angle"

## Liczba pocisków w pierścieniu (np. 8 = co 45°).
@export_range(3, 36, 1) var bullet_count: int = 8
## Prędkość pocisków. 0 = długość projectile_velocity z bazy.
@export var circle_speed: float = 8.0
## Kąt startowy pierwszego pocisku (stopnie, w płaszczyznie XZ).
@export var start_angle_deg: float = 0.0
## Obrót całego pierścienia po każdej salwie (stopnie). 0 = stała orientacja.
@export var rotate_per_salvo_deg: float = 22.5
## true = spawn ze środka wroga; false = ze średniej pozycji muzzli.
@export var spawn_from_center: bool = true


func on_begin_firing(state: Dictionary) -> void:
	state[KEY_ANGLE] = deg_to_rad(start_angle_deg)


func fire(enemy: Node3D, muzzles: Array[Marker3D], state: Dictionary) -> void:
	var origin := _get_spawn_origin(enemy, muzzles)
	var base_angle: float = float(state.get(KEY_ANGLE, deg_to_rad(start_angle_deg)))
	var speed := circle_speed if circle_speed > 0.001 else projectile_velocity.length()
	if speed < 0.001:
		speed = 8.0

	for i in bullet_count:
		var angle := base_angle + TAU * float(i) / float(bullet_count)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		spawn_projectile_at(enemy, origin, dir * speed)

	if rotate_per_salvo_deg != 0.0:
		state[KEY_ANGLE] = base_angle + deg_to_rad(rotate_per_salvo_deg)


func _get_spawn_origin(enemy: Node3D, muzzles: Array[Marker3D]) -> Vector3:
	if spawn_from_center or muzzles.is_empty():
		return enemy.global_position
	var sum := Vector3.ZERO
	for muzzle in muzzles:
		sum += muzzle.global_position
	return sum / float(muzzles.size())
