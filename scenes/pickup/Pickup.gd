extends Area3D

# --- PARAMETRY WYRZUTU ---
@export var drag: float = 12.0
@export var drift_velocity: Vector3 = Vector3(0, 0, 1)

# --- MAGNES (przyciąganie do gracza) ---
@export var magnet_range: float = 15.0
@export var magnet_speed: float = 22.0
@export var collect_distance: float = 2.0

# --- LOGIKA WEWNĘTRZNA ---
var _impulse: Vector3 = Vector3.ZERO
var _collected: bool = false
var _player: Node3D = null


func _ready() -> void:
	add_to_group("pickups")
	monitoring = true
	body_entered.connect(_on_body_entered)

	var notifier := get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if notifier:
		notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	if _collected:
		return

	var movement := _impulse + drift_velocity
	var player := _get_player()

	if player:
		var offset := player.global_position - global_position
		offset.y = 0.0
		var dist := offset.length()
		if dist <= collect_distance:
			_collect(player)
			return
		if dist <= magnet_range and dist > 0.001:
			var pull_strength := magnet_speed * (1.0 + (magnet_range - dist) / magnet_range)
			movement = offset.normalized() * pull_strength

	global_position += movement * delta
	_impulse = _impulse.move_toward(Vector3.ZERO, drag * delta)
	# Powrót na płaszczyznę gracza (po wyrzuceniu pod eksplozją).
	global_position.y = move_toward(global_position.y, 0, 3 * delta)


## Nadaje pickupowi początkowy impuls "wystrzału" w danym kierunku.
func launch(dir: Vector3, speed: float) -> void:
	_impulse = dir.normalized() * speed


func _get_player() -> Node3D:
	if is_instance_valid(_player):
		return _player
	_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player


func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if body.is_in_group("player"):
		_collect(body)


func _collect(player: Node3D) -> void:
	if _collected:
		return
	_collected = true
	if player.has_method("collect_pickup"):
		player.collect_pickup(1)
	queue_free()
