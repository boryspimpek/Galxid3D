extends Area3D

# --- PARAMETRY WYRZUTU ---
@export var drag: float = 12.0
@export var drift_velocity: Vector3 = Vector3(0, 0, 1)

# --- LOGIKA WEWNĘTRZNA ---
var _impulse: Vector3 = Vector3.ZERO
var _collected: bool = false


func _ready() -> void:
	add_to_group("pickups")
	# Wykrywamy gracza (warstwa 1), sami nie kolidujemy z niczym innym.
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)

	var notifier := get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if notifier:
		notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += (_impulse + drift_velocity) * delta
	_impulse = _impulse.move_toward(Vector3.ZERO, drag * delta)
	# Powrót na płaszczyznę gracza (po wyrzuceniu pod eksplozją).
	global_position.y = move_toward(global_position.y, 0, 3 * delta)


## Nadaje pickupowi początkowy impuls "wystrzału" w danym kierunku.
func launch(dir: Vector3, speed: float) -> void:
	_impulse = dir.normalized() * speed


func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if body.is_in_group("player"):
		_collected = true
		if body.has_method("collect_pickup"):
			body.collect_pickup(1)
		queue_free()
