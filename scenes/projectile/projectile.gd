extends Area3D

# --- Parametry pocisku (ustawiane przez WeaponSystem) ---
var _velocity: Vector3 = Vector3.ZERO

@export var velocity: Vector3 = Vector3.ZERO:
	get:
		return _velocity
	set(value):
		_velocity = value
		_align_to_velocity()

@export var damage: int = 3

func _ready():
	for child in get_children():
		if child is VisibleOnScreenNotifier3D:
			child.screen_exited.connect(queue_free)

func _physics_process(delta: float):
	position += _velocity * delta


func _align_to_velocity() -> void:
	if _velocity.length_squared() < 0.0001 or not is_inside_tree():
		return
	var direction := _velocity.normalized()
	var up := Vector3.UP
	if absf(direction.dot(up)) > 0.999:
		up = Vector3.RIGHT
	look_at(global_position + direction, up)

func _on_area_entered(area: Area3D):
	if area.is_in_group("enemies"):
		area.take_damage(damage, global_position)
		queue_free()

func _on_body_entered(_body: Node3D):
	queue_free()
