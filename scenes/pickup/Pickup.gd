extends Area3D

# --- PARAMETRY WYRZUTU ---
@export var value: int = 1
@export var drag: float = 12.0
## Stały dryf w stronę gracza (oś +Z, spójnie z LevelScroll3D).
@export var drift_velocity: Vector3 = Vector3(0, 0, 1)

# --- LOGIKA WEWNĘTRZNA ---
var _impulse: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("pickups")
	# Zbieranie przez gracza dodamy później — na razie kolizje nieaktywne.
	collision_layer = 0
	collision_mask = 0

	var notifier := get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if notifier:
		notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += (_impulse + drift_velocity) * delta
	_impulse = _impulse.move_toward(Vector3.ZERO, drag * delta)


## Nadaje pickupowi początkowy impuls "wystrzału" w danym kierunku.
func launch(dir: Vector3, speed: float) -> void:
	_impulse = dir.normalized() * speed
