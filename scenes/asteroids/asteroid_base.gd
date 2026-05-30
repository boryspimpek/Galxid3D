@tool
extends MeshInstance3D


@export var spin_speed: float = 2.0
@export var speed: float = 2.0


func _ready() -> void:
	set_process(not Engine.is_editor_hint())

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	transform = transform.rotated_local(Vector3.UP, spin_speed * delta)
	global_position.z += speed * delta
