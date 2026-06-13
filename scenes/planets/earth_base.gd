extends Node3D

@export var spin_speed: float = 0.5
@export var speed: float = 0.0


func _process(delta: float) -> void:
	rotate_object_local(Vector3.UP, spin_speed * delta)
	global_position.z += speed * delta
