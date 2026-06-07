@tool
extends Node3D

@export_group("Błyskawica")
@export var bolt_width: float = 3.0:
	set(value):
		bolt_width = maxf(value, 0.01)
		_update_bolt_transform()

@export_group("Aktywacja")
@export var activate_on_scroll_line: bool = true
## Górna krawędź kadru — jak u wrogów (np. -17.0 z PlayAreaFrame).
@export var scroll_activation_z: float = -17.0

@onready var _start: Marker3D = $Start
@onready var _end: Marker3D = $End
@onready var _bolt: MeshInstance3D = $Bolt

var _quad_mesh: QuadMesh
var _active: bool = false
var _was_active: bool = false


func _ready() -> void:
	_quad_mesh = _bolt.mesh as QuadMesh
	_active = not activate_on_scroll_line
	_update_bolt_transform()


func _process(_delta: float) -> void:
	if activate_on_scroll_line:
		_active = global_position.z >= scroll_activation_z
	else:
		_active = true

	if _active and not _was_active:
		_on_activated()
	_was_active = _active

	if _bolt:
		_bolt.visible = _active
	_update_bolt_transform()


func _on_activated() -> void:
	if not Engine.is_editor_hint():
		LevelScroll3D.detach_to_active_scene(self)


func _update_bolt_transform() -> void:
	if _start == null or _end == null or _bolt == null or _quad_mesh == null:
		return

	var start_pos := _start.global_position
	var end_pos := _end.global_position
	var delta := end_pos - start_pos
	var length := delta.length()
	if length < 0.001:
		_bolt.visible = false
		return

	var up := delta / length
	var midpoint := (start_pos + end_pos) * 0.5
	var to_camera := _camera_direction(midpoint)
	var right := up.cross(to_camera)
	if right.length_squared() < 0.0001:
		right = up.cross(Vector3.UP if absf(up.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT)
	right = right.normalized()
	var facing := right.cross(up).normalized()

	_quad_mesh.size = Vector2(bolt_width, length)
	_bolt.global_transform = Transform3D(Basis(right, up, -facing), midpoint)


func _camera_direction(from: Vector3) -> Vector3:
	var viewport := get_viewport()
	if viewport == null:
		return Vector3.FORWARD

	var camera := viewport.get_camera_3d()
	if camera == null:
		return Vector3.FORWARD

	return (camera.global_position - from).normalized()
