extends Area3D

# --- ZMIENNE WEWNĘTRZNE (LOGIKA) ---
var velocity: Vector3 = Vector3.ZERO  
var damage: int = 1                  


# --- METODY WBUDOWANE (LIFECYCLE) ---

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier3D.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += velocity * delta

# --- OBSŁUGA SYGNAŁÓW (SIGNALS) ---

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()
