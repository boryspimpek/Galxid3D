extends Area3D

## Sonda: Area3D + _process (jak EnemyPath po zmianie na tablet).

@export var patrol_radius: float = 7.0
@export var use_figure_eight: bool = true
@export var forward_speed: float = 8.0

var _origin: Vector3
var _t: float = 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_origin = global_position
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	var offset: Vector3
	if use_figure_eight:
		offset = PatrolPaths.figure_eight(_t, patrol_radius)
	else:
		offset = PatrolPaths.toward_camera(_t, forward_speed)
	global_position = _origin + offset
