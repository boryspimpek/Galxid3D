extends Node3D

const ASTEROID_SCENES = [
	"res://scenes/asteroids/asteroid.tscn",
]

@export var spawn_interval: float = 3.0
@export var speed_min: float = 2.0
@export var speed_max: float = 6.0
@export var y_max: float = -10.0
@export var y_min: float = -50.0
@export var preprocess_time: float = 20.0

var spawn_timer: float = 0.0

func _ready() -> void:
	spawn_timer = spawn_interval
	_preprocess(preprocess_time)

func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_random_asteroid()
		spawn_timer = spawn_interval

func _preprocess(time: float) -> void:
	var elapsed := 0.0
	while elapsed < time:
		elapsed += spawn_interval
		spawn_random_asteroid()
		var last = get_child(get_child_count() - 1)
		# W 3D ruch do przodu/tyłu odbywa się na osi Z (zgodnie z Twoim skryptem planety)
		last.global_position.z += last.speed * (time - elapsed)

func spawn_random_asteroid() -> void:
	var scene_path = ASTEROID_SCENES[randi() % ASTEROID_SCENES.size()]
	var asteroid_scene = load(scene_path)
	if asteroid_scene == null:
		push_error("Nie udało się załadować sceny: " + scene_path)
		return

	var asteroid = asteroid_scene.instantiate()

	var world_width = 17.0
	var margin = world_width * 0.1
	var spawn_z = -100.0 

	var random_x = randf_range(-world_width/2 + margin, world_width/2 - margin)
	var random_y = randf_range(y_max, y_min)
	var random_speed = randf_range(speed_min, speed_max)

	# --- 1. NAJPIERW DODAJEMY DO DRZEWA ---
	add_child(asteroid)

	# --- 2. TERAZ MOŻEMY BEZPIECZNIE UŻYĆ GLOBAL_POSITION ---
	asteroid.global_position = Vector3(random_x, random_y, spawn_z)

	asteroid.speed = random_speed
