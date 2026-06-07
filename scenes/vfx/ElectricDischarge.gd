@tool
extends Node3D

@export_group("Cele")
## Gdy ustawione — błyskawica łączy te węzły (np. wrogów) i podąża za nimi.
@export var start_target: Node3D:
	set(value):
		start_target = value
		_update_bolt_transform()
@export var end_target: Node3D:
	set(value):
		end_target = value
		_update_bolt_transform()
@export var start_offset: Vector3 = Vector3.ZERO
@export var end_offset: Vector3 = Vector3.ZERO

@export_group("Błyskawica")
@export var bolt_width: float = 3.0:
	set(value):
		bolt_width = maxf(value, 0.01)
		_update_bolt_transform()

@export_group("Aktywacja")
## Gdy są cele — aktywacja i widoczność zależą od stanu walki obu wrogów.
@export var sync_with_targets: bool = false
@export var activate_on_scroll_line: bool = true
## Górna krawędź kadru — jak u wrogów (np. -17.0 z PlayAreaFrame).
@export var scroll_activation_z: float = -17.0

@onready var _start: Marker3D = get_node_or_null("Start") as Marker3D
@onready var _end: Marker3D = get_node_or_null("End") as Marker3D
@onready var _bolt: MeshInstance3D = $Bolt

var _quad_mesh: QuadMesh
var _active: bool = false
var _was_active: bool = false


func _ready() -> void:
	_quad_mesh = _bolt.mesh as QuadMesh
	_active = _compute_active()
	_update_bolt_transform()


func _physics_process(_delta: float) -> void:
	if not _targets_valid():
		if _bolt:
			_bolt.visible = false
		return

	_active = _compute_active()

	if _active and not _was_active:
		_on_activated()
	_was_active = _active

	if _bolt:
		_bolt.visible = _active
	_update_bolt_transform()


func _compute_active() -> bool:
	if sync_with_targets and start_target and end_target:
		if not _targets_valid():
			return false
		if start_target.has_method("is_combat_active") and end_target.has_method("is_combat_active"):
			return start_target.is_combat_active() and end_target.is_combat_active()
		return true
	if activate_on_scroll_line:
		return global_position.z >= scroll_activation_z
	return true


func _targets_valid() -> bool:
	if start_target == null or end_target == null:
		return _start != null and _end != null
	return is_instance_valid(start_target) and is_instance_valid(end_target)


func _on_activated() -> void:
	if not Engine.is_editor_hint():
		LevelScroll3D.detach_to_active_scene(self)


func _resolve_start_position() -> Vector3:
	if start_target and is_instance_valid(start_target):
		return start_target.to_global(start_offset)
	if _start:
		return _start.global_position
	return global_position


func _resolve_end_position() -> Vector3:
	if end_target and is_instance_valid(end_target):
		return end_target.to_global(end_offset)
	if _end:
		return _end.global_position
	return global_position


func _update_bolt_transform() -> void:
	if _bolt == null or _quad_mesh == null:
		return
	if not _targets_valid():
		return

	var start_pos := _resolve_start_position()
	var end_pos := _resolve_end_position()
	var delta := end_pos - start_pos
	var length := delta.length()
	if length < 0.001:
		_bolt.visible = false
		return

	var along := delta / length
	var midpoint := (start_pos + end_pos) * 0.5
	var to_camera := _camera_direction(midpoint)
	var side := along.cross(to_camera)
	if side.length_squared() < 0.0001:
		side = along.cross(Vector3.UP if absf(along.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT)
	side = side.normalized()
	var facing := side.cross(along).normalized()

	# Shader rysuje błyskawicę wzdłuż UV.x — długość musi iść po lokalnej osi X.
	_quad_mesh.size = Vector2(length, bolt_width)
	_bolt.global_transform = Transform3D(Basis(along, side, -facing), midpoint)


func _camera_direction(from: Vector3) -> Vector3:
	var viewport := get_viewport()
	if viewport == null:
		return Vector3.FORWARD

	var camera := viewport.get_camera_3d()
	if camera == null:
		return Vector3.FORWARD

	return (camera.global_position - from).normalized()
