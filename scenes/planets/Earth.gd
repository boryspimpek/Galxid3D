extends Node3D

@export var speed: float = 50.0

func _process(delta: float) -> void:
	position.z += speed * delta
