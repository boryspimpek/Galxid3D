extends PathFollow3D

const SCROLL_COMPENSATOR_NAME := "ScrollCompensator"

@export var speed: float = 5.0 # jednostki 3D na sekundę wzdłuż krzywej
## Odejmuje przesunięcie LevelScroll od wroga — ścieżkę układasz tak, jak ma wyglądać na ekranie.
@export var compensate_level_scroll: bool = true
# @export var loop_path: bool = true
# @export var face_movement: bool = true
# @export var wait_for_screen: bool = true

var _path_active: bool = false
var _level_scroll: Node3D
var _scroll_compensator: Node3D
## Suma przesunięć scrolla w osi świata (nie w lokalnej PathFollow — tam obraca się na zakrętach).
var _anti_scroll_world: Vector3 = Vector3.ZERO


func _ready() -> void:
	# if not wait_for_screen:
	# 	_start_path()
	# 	return

	_level_scroll = _find_level_scroll()
	if compensate_level_scroll:
		_ensure_scroll_compensator()

	_path_active = false
	set_process(false)

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
	set_process(true)


func _process(delta: float) -> void:
	if not _path_active:
		return

	# PathFollow3D automatycznie ustawia swoją pozycję na podstawie `progress`.
	progress += speed * delta

	progress = clamp(progress, 0.0, get_baked_length_safe())

	_apply_scroll_compensation(delta)

	# if face_movement:
	# 	# obrót zgodnie z tangentem ścieżki (w Godot 4 wystarczy włączyć też `rotation_mode` w Inspectorze)
	rotation_mode = PathFollow3D.ROTATION_ORIENTED


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
	if not compensate_level_scroll or _level_scroll == null:
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
