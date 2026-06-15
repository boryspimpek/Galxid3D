extends Area3D

# --- Parametry pocisku (ustawiane przez WeaponSystem) ---
@export var velocity: Vector3 = Vector3.ZERO
@export var damage: int = 3

func _ready():
	for child in get_children():
		if child is VisibleOnScreenNotifier3D:
			child.screen_exited.connect(queue_free)

func _physics_process(delta: float):
	position += velocity * delta

func _on_area_entered(area: Area3D):
	if area.is_in_group("enemies"):
		area.take_damage(damage, global_position)
		queue_free()

func _on_body_entered(_body: Node3D):
	queue_free()
