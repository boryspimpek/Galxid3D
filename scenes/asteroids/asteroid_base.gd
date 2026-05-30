@tool
extends MeshInstance3D

@export_group("Obrót")
@export var randomize_spin: bool = true
@export var spin_speed_min: float = 0.3
@export var spin_speed_max: float = 2.5
## Gdy randomize_spin = false — stary obrót tylko wokół osi Y.
@export var spin_speed: float = 2.0

@export var speed: float = 2.0
@export var despawn_off_screen: bool = true

var _angular_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	set_process(not Engine.is_editor_hint())
	if Engine.is_editor_hint():
		return

	var notifier := get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if notifier and despawn_off_screen:
		notifier.screen_exited.connect(_on_screen_exited)

	if randomize_spin:
		randomize_spin_motion()


func randomize_spin_motion() -> void:
	rotation = Vector3(
		randf_range(0.0, TAU),
		randf_range(0.0, TAU),
		randf_range(0.0, TAU),
	)
	_angular_velocity = Vector3(
		randf_range(-1.0, 1.0) * randf_range(spin_speed_min, spin_speed_max),
		randf_range(-1.0, 1.0) * randf_range(spin_speed_min, spin_speed_max),
		randf_range(-1.0, 1.0) * randf_range(spin_speed_min, spin_speed_max),
	)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if randomize_spin:
		rotation += _angular_velocity * delta
	else:
		transform = transform.rotated_local(Vector3.UP, spin_speed * delta)

	global_position.z += speed * delta


func _on_screen_exited() -> void:
	queue_free()
