@tool
extends MeshInstance3D


@export var spin_speed: float = 2.0
@export var speed: float = 2.0
@export var despawn_off_screen: bool = true


func _ready() -> void:
	set_process(not Engine.is_editor_hint())
	if Engine.is_editor_hint():
		return

	var notifier := get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if notifier and despawn_off_screen:
		notifier.screen_exited.connect(_on_screen_exited)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	transform = transform.rotated_local(Vector3.UP, spin_speed * delta)
	global_position.z += speed * delta


func _on_screen_exited() -> void:
	queue_free()
