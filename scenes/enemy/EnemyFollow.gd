extends PathFollow3D
class_name EnemyPath

const SCROLL_COMPENSATOR_NAME := "ScrollCompensator"

const DEFAULT_SPEED := 5.0
const DEFAULT_BANK_ENABLED := false
const DEFAULT_BANK_MAX_DEGREES := 45.0
const DEFAULT_BANK_STRENGTH := 2.0
const DEFAULT_BANK_LOOKAHEAD := 1.0
const DEFAULT_BANK_SMOOTH := 10.0

var _path_active: bool = false
## Ustawienia fali (EnemyPath3D) — cache przed odpinaniem od LevelScroll.
var _wave_settings: EnemyPath3D


func _ready() -> void:
	_wave_settings = get_parent() as EnemyPath3D
	_cleanup_legacy_scroll_compensator()
	_path_active = false
	set_physics_process(false)
	_setup_path_start()


func _setup_path_start() -> void:
	if _wave_settings != null and _wave_settings.uses_scene_activation():
		if _wave_settings.is_wave_activated():
			_start_path()
		else:
			_wave_settings.wave_activated.connect(_start_path, CONNECT_ONE_SHOT)
		return

	var enemy := _find_enemy()
	if enemy == null:
		_start_path()
		return

	if enemy.is_combat_active():
		_start_path()
	else:
		enemy.combat_activated.connect(_start_path, CONNECT_ONE_SHOT)


func _cleanup_legacy_scroll_compensator() -> void:
	var compensator := get_node_or_null(SCROLL_COMPENSATOR_NAME) as Node3D
	if compensator == null:
		return
	for child in compensator.get_children():
		if child.is_in_group("enemies"):
			child.reparent(self, true)
	compensator.queue_free()


func _find_enemy() -> Node:
	for child in get_children():
		if child.is_in_group("enemies"):
			return child
	return null


func _start_path() -> void:
	if _path_active:
		return
	_path_active = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	_detach_path_from_level_scroll()
	set_physics_process(true)
	reset_physics_interpolation()


func _detach_path_from_level_scroll() -> void:
	var path3d := get_parent() as Path3D
	if path3d == null or not LevelScroll3D.is_under_level_scroll(self):
		return
	var root := get_tree().current_scene
	if root == null:
		return

	var active_path := Path3D.new()
	active_path.name = "%s__%d" % [path3d.name, get_instance_id()]
	active_path.curve = path3d.curve
	root.add_child(active_path)
	active_path.global_transform = path3d.global_transform
	reparent(active_path, true)


func _physics_process(delta: float) -> void:
	if not _path_active:
		return

	var baked_len: float = get_baked_length_safe()
	var t: float = clampf(progress / baked_len, 0.0, 1.0)
	var speed_mul: float = 1.0
	var curve := _get_speed_curve()
	if curve:
		speed_mul = maxf(0.0, curve.sample_baked(t))

	progress += (_get_speed() * speed_mul) * delta
	progress = clamp(progress, 0.0, baked_len)

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
