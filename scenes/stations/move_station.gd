extends Node3D

@export var speed: float = 5

func _process(delta: float) -> void:
	position.z += speed * delta
