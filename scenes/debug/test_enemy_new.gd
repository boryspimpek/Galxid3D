extends CharacterBody3D

## Nowy wróg testowy — wyłącznie pipeline gracza (bez PathFollow / scroll / Area3D).
## Użyj w SmoothEnemyTest.tscn obok sond albo samodzielnie.

@export var patrol_radius: float = 7.0
@export var auto_patrol: bool = true
@export var forward_speed: float = 8.0
@export var patrol_span: float = 32.0

enum PatrolStyle { PING_PONG_Z, HARD_LOOP_Z, FIGURE_EIGHT }
@export var patrol_style: PatrolStyle = PatrolStyle.PING_PONG_Z

var _origin: Vector3
var _t: float = 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	_origin = global_position
	reset_physics_interpolation()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not auto_patrol:
		return
	_t += delta
	global_position = _origin + _patrol_offset(_t)


func _patrol_offset(t: float) -> Vector3:
	match patrol_style:
		PatrolStyle.HARD_LOOP_Z:
			return PatrolPaths.toward_camera_hard_loop(t, forward_speed, patrol_span)
		PatrolStyle.FIGURE_EIGHT:
			return PatrolPaths.figure_eight(t, patrol_radius)
		_:
			return PatrolPaths.toward_camera(t, forward_speed, patrol_span)
