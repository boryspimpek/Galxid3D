extends Node3D

@export var speed_z: float = 2
@export var speed_x: float = 0
@export var speed_y: float = 0

func _process(delta: float) -> void:
	position.z += speed_z * delta
	position.x += speed_x * delta
	rotation.y += speed_y * delta
	
