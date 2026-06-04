extends PathFollow3D
class_name TestEnemyPath

## PathFollow tylko po krzywej — bez LevelScroll i bez kompensacji.
## _physics_process + interpolacja (jak żółty CharacterBody w teście).

const DEFAULT_SPEED := 8.0
const DEFAULT_BANK_ENABLED := true
const DEFAULT_BANK_MAX_DEGREES := 45.0
const DEFAULT_BANK_STRENGTH := 2.0
const DEFAULT_BANK_LOOKAHEAD := 1.0
const DEFAULT_BANK_SMOOTH := 10.0

@export var auto_start: bool = true
@export var loop_path: bool = true

var _wave_settings: EnemyPath3D
var _active: bool = false


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	loop = loop_path
	_wave_settings = get_parent() as EnemyPath3D

	for child in get_children():
		if child.is_in_group("enemies"):
			_activate_enemy(child)

	if auto_start:
		_start_path()


func _activate_enemy(enemy: Node) -> void:
	if enemy.has_method("activate_combat"):
		enemy.activate_combat()
	elif enemy.has_method("_activate"):
		enemy.set("activate_on_scroll_line", false)
		enemy._activate()


func _start_path() -> void:
	if _active:
		return
	_active = true
	set_physics_process(true)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if not _active:
		return

	var baked_len: float = get_baked_length_safe()
	var t: float = clampf(progress / baked_len, 0.0, 1.0)
	var speed_mul: float = 1.0
	var curve := _get_speed_curve()
	if curve:
		speed_mul = maxf(0.0, curve.sample_baked(t))

	progress += (_get_speed() * speed_mul) * delta
	if loop:
		progress = wrapf(progress, 0.0, baked_len)
	else:
		progress = clampf(progress, 0.0, baked_len)

	rotation_mode = PathFollow3D.ROTATION_ORIENTED
	_apply_banking(delta)


func get_baked_length_safe() -> float:
	var p := get_parent()
	if p is Path3D and p.curve:
		return max(0.001, p.curve.get_baked_length())
	return 0.001


func _apply_banking(delta: float) -> void:
	if not _is_bank_enabled():
		return

	var p := get_parent()
	if not (p is Path3D):
		return
	var path_curve := (p as Path3D).curve
	if path_curve == null:
		return

	var baked_len: float = maxf(0.001, path_curve.get_baked_length())
	var ahead: float = maxf(0.001, _get_bank_lookahead())
	var d0: float = clampf(progress - ahead, 0.0, baked_len)
	var d1: float = clampf(progress + ahead, 0.0, baked_len)

	var pos0: Vector3 = path_curve.sample_baked(d0)
	var pos: Vector3 = path_curve.sample_baked(progress)
	var pos1: Vector3 = path_curve.sample_baked(d1)

	var dir_prev: Vector3 = (pos - pos0)
	var dir_next: Vector3 = (pos1 - pos)
	if dir_prev.length_squared() < 0.000001 or dir_next.length_squared() < 0.000001:
		return
	dir_prev = dir_prev.normalized()
	dir_next = dir_next.normalized()

	var signed_turn: float = atan2(
		Vector3.UP.dot(dir_prev.cross(dir_next)),
		dir_prev.dot(dir_next)
	)

	var target: float = -signed_turn * _get_bank_strength()
	var max_bank: float = deg_to_rad(_get_bank_max_degrees())
	target = clampf(target, -max_bank, max_bank)

	var smooth := _get_bank_smooth()
	var alpha: float = 1.0 - exp(-smooth * delta) if smooth > 0.0 else 1.0

	var anchor := _find_enemy() as Node3D
	if anchor == null:
		return

	var r := anchor.rotation
	r.z = lerp_angle(r.z, target, alpha)
	anchor.rotation = r


func _find_enemy() -> Node:
	for child in get_children():
		if child.is_in_group("enemies"):
			return child
	return null


func _get_speed() -> float:
	return _wave_settings.speed if _wave_settings else DEFAULT_SPEED


func _get_speed_curve() -> Curve:
	return _wave_settings.speed_curve if _wave_settings else null


func _is_bank_enabled() -> bool:
	return _wave_settings.bank_enabled if _wave_settings else DEFAULT_BANK_ENABLED


func _get_bank_max_degrees() -> float:
	return _wave_settings.bank_max_degrees if _wave_settings else DEFAULT_BANK_MAX_DEGREES


func _get_bank_strength() -> float:
	return _wave_settings.bank_strength if _wave_settings else DEFAULT_BANK_STRENGTH


func _get_bank_lookahead() -> float:
	return _wave_settings.bank_lookahead if _wave_settings else DEFAULT_BANK_LOOKAHEAD


func _get_bank_smooth() -> float:
	return _wave_settings.bank_smooth if _wave_settings else DEFAULT_BANK_SMOOTH
