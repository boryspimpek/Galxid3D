extends Area3D

# --- Parametry pocisku (ustawiane przez WeaponSystem) ---
@export var velocity: Vector3 = Vector3.ZERO
@export var acceleration: Vector3 = Vector3.ZERO  # Przyspieszenie po wystrzeleniu
@export var damage: int = 3
@export var lifetime: float = 0.0  # Czas życia w sekundach (0 = brak limitu)
# --- Wewnętrzne ---
var lifetime_timer: float = 0.0

func _ready():
	# Warstwa 4 = pocisk gracza; maska 2 = wykrywa wrogów (warstwa 2)
	collision_layer = 4
	collision_mask  = 2
	$VisibleOnScreenNotifier3D.screen_exited.connect(queue_free)

func _physics_process(delta: float):
	velocity += acceleration * delta

	position += velocity * delta

	if lifetime > 0.0:
		lifetime_timer += delta
		if lifetime_timer >= lifetime:
			queue_free()
			return

func _on_area_entered(area: Area3D):
	if area.is_in_group("enemies"):
		area.take_damage(damage)
		queue_free()

func _on_body_entered(_body: Node3D):
	queue_free()
