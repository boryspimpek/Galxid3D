extends PathFollow3D
class_name EnemyPath

const SCROLL_COMPENSATOR_NAME := "ScrollCompensator"

const DEFAULT_SPEED := 5.0
const DEFAULT_COMPENSATE_LEVEL_SCROLL := true
const DEFAULT_BANK_ENABLED := false
const DEFAULT_BANK_MAX_DEGREES := 45.0
const DEFAULT_BANK_STRENGTH := 2.0
const DEFAULT_BANK_LOOKAHEAD := 1.0
const DEFAULT_BANK_SMOOTH := 10.0

var _path_active: bool = false
var _level_scroll: Node3D
var _scroll_compensator: Node3D
## Suma przesunięć scrolla w osi świata (nie w lokalnej PathFollow — tam obraca się na zakrętach).
var _anti_scroll_world: Vector3 = Vector3.ZERO


func _ready() -> void:
	# Ruch w _process — zsynchronizowany z klatką renderu (tablet 90/120 Hz).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	_level_scroll = _find_level_scroll()
	if _is_scroll_compensation_enabled():
		_ensure_scroll_compensator()

	_path_active = false
	set_process(false)
	_setup_path_start()


func _setup_path_start() -> void:
	var wave := _get_path_settings()
	if wave != null and wave.uses_scene_activation():
		if wave.is_wave_activated():
			_start_path()
		else:
			wave.wave_activated.connect(_start_path, CONNECT_ONE_SHOT)
		return

	var enemy := _find_enemy()
	if enemy == null:
		_start_path()
		return

	if enemy.is_combat_active():
		_start_path()
	else:
		enemy.combat_activated.connect(_start_path, CONNECT_ONE_SHOT)


func _find_enemy() -> Node:
	if _scroll_compensator:
		for child in _scroll_compensator.get_children():
			if child.is_in_group("enemies"):
				return child
	for child in get_children():
		if child == _scroll_compensator:
			continue
		if child.is_in_group("enemies"):
			return child
	return null


func _ensure_scroll_compensator() -> void:
	_scroll_compensator = get_node_or_null(SCROLL_COMPENSATOR_NAME) as Node3D
	if _scroll_compensator:
		return

	var enemy: Node = null
	for child in get_children():
		if child.is_in_group("enemies"):
			enemy = child
			break
	if enemy == null:
		return

	_scroll_compensator = Node3D.new()
	_scroll_compensator.name = SCROLL_COMPENSATOR_NAME
	_scroll_compensator.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_scroll_compensator)
	enemy.reparent(_scroll_compensator, true)


func _start_path() -> void:
	if _path_active:
		return
	_path_active = true
	_anti_scroll_world = Vector3.ZERO
	set_process(true)
	reset_physics_interpolation()


func _process(delta: float) -> void:
	if not _path_active:
		return

	# PathFollow3D automatycznie ustawia swoją pozycję na podstawie `progress`.
	var baked_len: float = get_baked_length_safe()
	var t: float = clampf(progress / baked_len, 0.0, 1.0)
	var speed_mul: float = 1.0
	var curve := _get_speed_curve()
	if curve:
		speed_mul = maxf(0.0, curve.sample_baked(t))

	progress += (_get_speed() * speed_mul) * delta

	progress = clamp(progress, 0.0, baked_len)

	_apply_scroll_compensation(delta)

	rotation_mode = PathFollow3D.ROTATION_ORIENTED
	_apply_banking(delta)


func get_baked_length_safe() -> float:
	var p := get_parent()
	if p is Path3D and p.curve:
		return max(0.001, p.curve.get_baked_length())
	return 0.001


func _find_level_scroll() -> Node3D:
	var node := get_parent()
	while node:
		var script: Script = node.get_script()
		if script and script.resource_path.get_file() == "LevelScroll3D.gd":
			return node as Node3D
		node = node.get_parent()
	return null


func _apply_scroll_compensation(delta: float) -> void:
	if not _is_scroll_compensation_enabled() or _level_scroll == null:
		return
	var scroll_speed: Variant = _level_scroll.get("scroll_speed")
	if scroll_speed == null or float(scroll_speed) == 0.0:
		return

	var anchor: Node3D = _scroll_compensator if _scroll_compensator else _find_enemy() as Node3D
	if anchor == null:
		return

	var scroll_delta: Vector3 = _level_scroll.global_transform.basis.z * float(scroll_speed) * delta
	_anti_scroll_world -= scroll_delta

	# Najpierw punkt na ścieżce (ze scrollem), potem stały offset w świecie — nie w local parent.
	anchor.position = Vector3.ZERO
	anchor.global_position += _anti_scroll_world


func _apply_banking(delta: float) -> void:
	if not _is_bank_enabled():
		return

	var p := get_parent()
	if not (p is Path3D):
		return
	var curve := (p as Path3D).curve
	if curve == null:
		return

	var baked_len: float = maxf(0.001, curve.get_baked_length())
	var ahead: float = maxf(0.001, _get_bank_lookahead())
	var d0: float = clampf(progress - ahead, 0.0, baked_len)
	var d1: float = clampf(progress + ahead, 0.0, baked_len)

	var pos0: Vector3 = curve.sample_baked(d0)
	var pos: Vector3 = curve.sample_baked(progress)
	var pos1: Vector3 = curve.sample_baked(d1)

	var dir_prev: Vector3 = (pos - pos0)
	var dir_next: Vector3 = (pos1 - pos)
	if dir_prev.length_squared() < 0.000001 or dir_next.length_squared() < 0.000001:
		return
	dir_prev = dir_prev.normalized()
	dir_next = dir_next.normalized()

	# Znak skrętu względem osi świata "UP" (dla top-down zwykle to właśnie chcesz).
	var signed_turn: float = atan2(Vector3.UP.dot(dir_prev.cross(dir_next)), dir_prev.dot(dir_next))

	var target: float = -signed_turn * _get_bank_strength()
	var max_bank: float = deg_to_rad(_get_bank_max_degrees())
	target = clampf(target, -max_bank, max_bank)

	var smooth := _get_bank_smooth()
	var alpha: float = 1.0 - exp(-smooth * delta) if smooth > 0.0 else 1.0

	var anchor := _get_bank_anchor()
	if anchor == null:
		return

	# Roll (bank) wokół lokalnej osi Z wroga.
	var r := anchor.rotation
	r.z = lerp_angle(r.z, target, alpha)
	anchor.rotation = r


func _get_bank_anchor() -> Node3D:
	if _scroll_compensator:
		for child in _scroll_compensator.get_children():
			var n := child as Node3D
			if n and child.is_in_group("enemies"):
				return n
	var e := _find_enemy() as Node3D
	return e


func _get_path_settings() -> EnemyPath3D:
	var p := get_parent()
	return p as EnemyPath3D if p is EnemyPath3D else null


func _get_speed() -> float:
	var settings := _get_path_settings()
	return settings.speed if settings else DEFAULT_SPEED


func _get_speed_curve() -> Curve:
	var settings := _get_path_settings()
	return settings.speed_curve if settings else null


func _is_scroll_compensation_enabled() -> bool:
	var settings := _get_path_settings()
	return settings.compensate_level_scroll if settings else DEFAULT_COMPENSATE_LEVEL_SCROLL


func _is_bank_enabled() -> bool:
	var settings := _get_path_settings()
	return settings.bank_enabled if settings else DEFAULT_BANK_ENABLED


func _get_bank_max_degrees() -> float:
	var settings := _get_path_settings()
	return settings.bank_max_degrees if settings else DEFAULT_BANK_MAX_DEGREES


func _get_bank_strength() -> float:
	var settings := _get_path_settings()
	return settings.bank_strength if settings else DEFAULT_BANK_STRENGTH


func _get_bank_lookahead() -> float:
	var settings := _get_path_settings()
	return settings.bank_lookahead if settings else DEFAULT_BANK_LOOKAHEAD


func _get_bank_smooth() -> float:
	var settings := _get_path_settings()
	return settings.bank_smooth if settings else DEFAULT_BANK_SMOOTH
