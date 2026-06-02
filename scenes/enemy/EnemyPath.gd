extends PathFollow3D

const SCROLL_COMPENSATOR_NAME := "ScrollCompensator"

@export var use_parent_settings: bool = true
@export var speed: float = 5.0 # jednostki 3D na sekundę wzdłuż krzywej
## Opcjonalny mnożnik prędkości wzdłuż ścieżki (oś X: 0..1 = progress/baked_length).
## Jeśli puste, poruszanie jest ze stałą prędkością `speed`.
@export var speed_curve: Curve
## Odejmuje przesunięcie LevelScroll od wroga — ścieżkę układasz tak, jak ma wyglądać na ekranie.
@export var compensate_level_scroll: bool = true

## Wymusza "przechył" (roll/bank) na zakrętach nawet dla płaskiej ścieżki (top-down).
@export var bank_enabled: bool = false
## Maksymalny przechył w stopniach.
@export_range(0.0, 89.0, 0.1) var bank_max_degrees: float = 45.0
## Jak mocno bank reaguje na zakręt (większe = mocniej).
@export_range(0.0, 10.0, 0.01) var bank_strength: float = 2.0
## Dystans (w jednostkach progress) użyty do estymacji skrętu.
@export_range(0.001, 100.0, 0.001) var bank_lookahead: float = 1.0
## Szybkość wygładzania przechyłu (większe = szybciej dogania).
@export_range(0.0, 30.0, 0.1) var bank_smooth: float = 10.0

var _path_active: bool = false
var _level_scroll: Node3D
var _scroll_compensator: Node3D
## Suma przesunięć scrolla w osi świata (nie w lokalnej PathFollow — tam obraca się na zakrętach).
var _anti_scroll_world: Vector3 = Vector3.ZERO


func _ready() -> void:
	_level_scroll = _find_level_scroll()
	if _is_scroll_compensation_enabled():
		_ensure_scroll_compensator()

	_path_active = false
	set_physics_process(false)

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
	add_child(_scroll_compensator)
	enemy.reparent(_scroll_compensator, true)


func _start_path() -> void:
	if _path_active:
		return
	_path_active = true
	_anti_scroll_world = Vector3.ZERO
	set_physics_process(true)


func _physics_process(delta: float) -> void:
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


func _get_parent_settings_node() -> Node:
	if not use_parent_settings:
		return null
	var p := get_parent()
	if p == null:
		return null
	var s: Script = p.get_script()
	if s == null:
		return null
	# Linter w edytorze może nie widzieć class_name; opieramy się o plik skryptu.
	if s.resource_path.get_file() != "EnemyPath3D.gd":
		return null
	return p


func _get_speed() -> float:
	var settings: Node = _get_parent_settings_node()
	if settings == null:
		return speed
	var v: Variant = settings.get("speed")
	return float(v) if v != null else speed


func _get_speed_curve() -> Curve:
	var settings: Node = _get_parent_settings_node()
	if settings == null:
		return speed_curve
	var v: Variant = settings.get("speed_curve")
	return v as Curve if v != null else speed_curve


func _is_scroll_compensation_enabled() -> bool:
	var settings: Node = _get_parent_settings_node()
	if settings == null:
		return compensate_level_scroll
	var v: Variant = settings.get("compensate_level_scroll")
	return bool(v) if v != null else compensate_level_scroll


func _is_bank_enabled() -> bool:
	var settings: Node = _get_parent_settings_node()
	if settings == null:
		return bank_enabled
	var v: Variant = settings.get("bank_enabled")
	return bool(v) if v != null else bank_enabled


func _get_bank_max_degrees() -> float:
	var settings: Node = _get_parent_settings_node()
	if settings == null:
		return bank_max_degrees
	var v: Variant = settings.get("bank_max_degrees")
	return float(v) if v != null else bank_max_degrees


func _get_bank_strength() -> float:
	var settings: Node = _get_parent_settings_node()
	if settings == null:
		return bank_strength
	var v: Variant = settings.get("bank_strength")
	return float(v) if v != null else bank_strength


func _get_bank_lookahead() -> float:
	var settings: Node = _get_parent_settings_node()
	if settings == null:
		return bank_lookahead
	var v: Variant = settings.get("bank_lookahead")
	return float(v) if v != null else bank_lookahead


func _get_bank_smooth() -> float:
	var settings: Node = _get_parent_settings_node()
	if settings == null:
		return bank_smooth
	var v: Variant = settings.get("bank_smooth")
	return float(v) if v != null else bank_smooth
