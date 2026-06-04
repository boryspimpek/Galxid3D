extends CharacterBody3D

## Sonda: ten sam pipeline co gracz — dotyk przesuwa statek (porównanie na tablecie).

@export var max_bound_x: float = 11.7
@export var max_bound_z: float = 15.25

var _camera: Camera3D
var touch_target := Vector3.ZERO
var _touch_grab_offset := Vector3.ZERO


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	collision_layer = 1
	collision_mask = 0
	add_to_group("player")
	_camera = get_viewport().get_camera_3d()
	reset_physics_interpolation()
	set_physics_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			_begin_touch(e.position)
		else:
			touch_target = Vector3.ZERO
	elif event is InputEventScreenDrag:
		_update_touch((event as InputEventScreenDrag).position)


func _begin_touch(screen_pos: Vector2) -> void:
	var hit := _screen_to_world(screen_pos)
	if hit == Vector3.ZERO:
		return
	_touch_grab_offset = Vector3(hit.x - global_position.x, 0.0, hit.z - global_position.z)
	touch_target = global_position


func _update_touch(screen_pos: Vector2) -> void:
	var hit := _screen_to_world(screen_pos)
	if hit == Vector3.ZERO:
		return
	touch_target = Vector3(
		hit.x - _touch_grab_offset.x,
		0.0,
		hit.z - _touch_grab_offset.z
	)


func _screen_to_world(screen_pos: Vector2) -> Vector3:
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return Vector3.ZERO
	var ray_origin := _camera.project_ray_origin(screen_pos)
	var ray_dir := _camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, 0.0)
	var hit = plane.intersects_ray(ray_origin, ray_dir)
	return hit if hit != null else Vector3.ZERO


func _physics_process(_delta: float) -> void:
	if touch_target == Vector3.ZERO:
		return
	global_position.x = touch_target.x
	global_position.z = touch_target.z
	global_position.x = clampf(global_position.x, -max_bound_x, max_bound_x)
	global_position.z = clampf(global_position.z, -max_bound_z, max_bound_z)
