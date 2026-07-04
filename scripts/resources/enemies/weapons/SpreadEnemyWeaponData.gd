extends EnemyWeaponData
class_name SpreadEnemyWeaponData

# ============================================================================
# SPREAD WEAPON DATA - salwa pocisków wachlarzem w jednym kierunku (płaszczyzna XZ).
# bullet_count pocisków rozłożonych w kącie spread_angle_deg wokół base_angle_deg.
# rotate_per_salvo obraca wzorzec między salwami. aim kieruje środek wachlarza
# na gracza (mieszanie z base_angle_deg).
# ============================================================================

const KEY_ANGLE := &"spread_angle"

## Liczba pocisków w salwie.
@export_range(1, 36, 1) var bullet_count: int = 3
## Prędkość pocisków. 0 = długość projectile_velocity z bazy.
@export var spread_speed: float = 8.0
## Środkowy kierunek salwy (stopnie, w płaszczyźnie XZ).
@export var base_angle_deg: float = 0.0
## Całkowity kąt rozwarcia wachlarza (stopnie). 0 = wszystkie w tym samym kierunku.
@export var spread_angle_deg: float = 30.0
## Obrót środkowego kierunku po każdej salwie (stopnie).
@export var rotate_per_salvo_deg: float = 0.0
## true = spawn ze środka wroga; false = ze średniej pozycji muzzli.
@export var spawn_from_center: bool = true


func on_begin_firing(state: Dictionary) -> void:
	state[KEY_ANGLE] = deg_to_rad(base_angle_deg)


func fire(enemy: Node3D, muzzles: Array[Marker3D], state: Dictionary) -> void:
	var origin := _get_spawn_origin(enemy, muzzles)
	var base_angle: float = float(state.get(KEY_ANGLE, deg_to_rad(base_angle_deg)))

	var speed := spread_speed if spread_speed > 0.001 else projectile_velocity.length()
	if speed < 0.001:
		speed = 8.0

	var base_dir := Vector3(cos(base_angle), 0.0, sin(base_angle))
	var aimed_dir := _compute_aimed_direction(enemy, base_dir, origin)
	var aimed_angle := atan2(aimed_dir.z, aimed_dir.x)

	var half_spread := deg_to_rad(spread_angle_deg) * 0.5
	for i in bullet_count:
		var t := 0.0 if bullet_count <= 1 else float(i) / float(bullet_count - 1)
		var angle := aimed_angle + lerpf(-half_spread, half_spread, t)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		spawn_projectile_at(enemy, origin, dir * speed)

	if rotate_per_salvo_deg != 0.0:
		state[KEY_ANGLE] = base_angle + deg_to_rad(rotate_per_salvo_deg)


func _compute_aimed_direction(enemy: Node3D, base_dir: Vector3, origin: Vector3) -> Vector3:
	if aim <= 0:
		return base_dir

	var bullet_speed := base_dir.length()
	if bullet_speed < 0.001:
		return base_dir

	var player := enemy.get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return base_dir

	var to_player := player.global_position - origin
	if to_player.length_squared() < 0.0001:
		return base_dir

	var aim_weight := clampf(float(aim) / float(AIM_MAX), 0.0, 1.0)
	return base_dir.lerp(to_player.normalized(), aim_weight).normalized()


func _get_spawn_origin(enemy: Node3D, muzzles: Array[Marker3D]) -> Vector3:
	if spawn_from_center or muzzles.is_empty():
		return enemy.global_position
	var sum := Vector3.ZERO
	for muzzle in muzzles:
		sum += muzzle.global_position
	return sum / float(muzzles.size())
