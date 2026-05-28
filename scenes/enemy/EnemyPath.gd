extends PathFollow3D

@export var speed:Vector3 = Vector3.ZERO

func _process(delta: float):
	global_position += speed * delta
