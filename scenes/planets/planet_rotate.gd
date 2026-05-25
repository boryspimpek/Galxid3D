extends Node3D

@export var spin_speed: float = 2
@export var speed: float = 2.0

func _process(delta: float) -> void:
	transform = transform.rotated_local(Vector3.UP, spin_speed * delta)
	global_position.z += speed * delta

# Sygnał wywoła się automatycznie, gdy planeta całkowicie zniknie z widoku kamery
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free()
