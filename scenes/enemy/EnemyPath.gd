extends PathFollow3D

@export var speed: float = 5.0 # jednostki 3D na sekundę wzdłuż krzywej
# @export var loop_path: bool = true
@export var face_movement: bool = true
@export var wait_for_screen: bool = true

var _path_active: bool = false


func _ready() -> void:
	if not wait_for_screen:
		_start_path()
		return

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
	for child in get_children():
		if child.is_in_group("enemies"):
			return child
	return null


func _start_path() -> void:
	if _path_active:
		return
	_path_active = true
	set_process(true)


func _process(delta: float) -> void:
	if not _path_active:
		return

	# PathFollow3D automatycznie ustawia swoją pozycję na podstawie `progress`.
	progress += speed * delta

	progress = clamp(progress, 0.0, get_baked_length_safe())

	if face_movement:
		# obrót zgodnie z tangentem ścieżki (w Godot 4 wystarczy włączyć też `rotation_mode` w Inspectorze)
		rotation_mode = PathFollow3D.ROTATION_ORIENTED


func get_baked_length_safe() -> float:
	var p := get_parent()
	if p is Path3D and p.curve:
		return max(0.001, p.curve.get_baked_length())
	return 0.001
