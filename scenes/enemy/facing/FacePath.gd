extends EnemyFacing
class_name FacePath

# ============================================================================
# FACE PATH - obraca wroga (yaw wokół Y) wzdłuż kierunku ruchu po Path3D.
# Dodaj jako węzeł „Facing” na wrogu będącym dzieckiem PathFollow3D (EnemyPath).
# EnemyFollow wyłącza wtedy ROTATION_ORIENTED na PathFollow — orientacją
# steruje ten komponent (bank nadal z EnemyPath3D / EnemyFollow).
# ============================================================================

## Szybkość wygładzania obrotu (większe = szybciej dogania kierunek ścieżki).
@export var turn_smooth: float = 6.0
## Korekta, jeśli „dziób” modelu nie jest skierowany w +Z (np. 180 dla -Z).
@export var yaw_offset_degrees: float = 0.0
## Dystans wzdłuż ścieżki (progress) do estymacji stycznej.
@export_range(0.001, 100.0, 0.001) var lookahead: float = 1.0

var _path_follow: PathFollow3D


func _ready() -> void:
	super._ready()
	var parent := _enemy.get_parent() if _enemy else null
	if parent is PathFollow3D:
		_path_follow = parent


func process_facing(delta: float) -> void:
	if _enemy == null or _path_follow == null:
		return

	var tangent := _get_path_tangent_world()
	tangent.y = 0.0
	if tangent.length_squared() < 0.0001:
		return

	var target_yaw := atan2(tangent.x, tangent.z) + deg_to_rad(yaw_offset_degrees)
	var parent := _enemy.get_parent() as Node3D
	if parent:
		target_yaw -= parent.global_rotation.y

	var alpha := 1.0 - exp(-turn_smooth * delta) if turn_smooth > 0.0 else 1.0
	var r := _enemy.rotation
	r.y = lerp_angle(r.y, target_yaw, alpha)
	_enemy.rotation = r


func _get_path_tangent_world() -> Vector3:
	var path3d := _path_follow.get_parent() as Path3D
	if path3d == null or path3d.curve == null:
		return Vector3.ZERO

	var baked_len := maxf(0.001, path3d.curve.get_baked_length())
	var ahead := maxf(0.001, lookahead)
	var d0 := clampf(_path_follow.progress - ahead * 0.5, 0.0, baked_len)
	var d1 := clampf(_path_follow.progress + ahead * 0.5, 0.0, baked_len)
	if is_equal_approx(d0, d1):
		d0 = maxf(0.0, _path_follow.progress - ahead)
		d1 = minf(baked_len, _path_follow.progress + ahead)

	var p0 := path3d.to_global(path3d.curve.sample_baked(d0))
	var p1 := path3d.to_global(path3d.curve.sample_baked(d1))
	return p1 - p0
