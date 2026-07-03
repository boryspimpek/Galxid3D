extends Area3D

# --- ZMIENNE WEWNĘTRZNE (LOGIKA) ---
var velocity: Vector3 = Vector3.ZERO  
var damage: int = 1                  
var homing: bool = false
var turn_speed: float = 3.0
var homing_duration: float = -1.0
var _homing_timer: float = -1.0
var _homing_timer_initialized: bool = false


# --- METODY WBUDOWANE (LIFECYCLE) ---

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier3D.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	if homing:
		if homing_duration > 0.0:
			if not _homing_timer_initialized:
				_homing_timer = homing_duration
				_homing_timer_initialized = true
			_homing_timer -= delta
			if _homing_timer <= 0.0:
				homing = false
		if homing:
			_steer_towards_player(delta)
	position += velocity * delta


func _steer_towards_player(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var speed := velocity.length()
	if speed < 0.0001:
		return
	var to_player := (player.global_position - global_position).normalized()
	velocity = (velocity / speed).slerp(to_player, clampf(turn_speed * delta, 0.0, 1.0)).normalized() * speed

# --- OBSŁUGA SYGNAŁÓW (SIGNALS) ---

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()
