extends Node3D

const PLANET_SCENES = [
	"res://scenes/planets/mars.tscn",
	"res://scenes/planets/venus.tscn",
	"res://scenes/planets/saturn.tscn",
	"res://scenes/planets/mercury.tscn",
	"res://scenes/planets/jupiter.tscn",
	"res://scenes/planets/neptune.tscn",
	"res://scenes/planets/uranus.tscn",
]

@export var spawn_interval: float = 3.0
# Jednostki 3D są znacznie mniejsze niż piksele (np. 1 jednostka = ~1 metr w świecie gry)
@export var speed_min: float = 2.0
@export var speed_max: float = 6.0
@export var preprocess_time: float = 20.0

var spawn_timer: float = 0.0

func _ready() -> void:
	spawn_timer = spawn_interval
	_preprocess(preprocess_time)

func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_random_planet()
		spawn_timer = spawn_interval

func _preprocess(time: float) -> void:
	var elapsed := 0.0
	while elapsed < time:
		elapsed += spawn_interval
		spawn_random_planet()
		var last = get_child(get_child_count() - 1)
		# W 3D ruch do przodu/tyłu odbywa się na osi Z (zgodnie z Twoim skryptem planety)
		last.global_position.z += last.speed * (time - elapsed)

func spawn_random_planet() -> void:
	var scene_path = PLANET_SCENES[randi() % PLANET_SCENES.size()]
	var planet_scene = load(scene_path)
	if planet_scene == null:
		push_error("Nie udało się załadować sceny: " + scene_path)
		return

	var planet = planet_scene.instantiate()

	var world_width = 17.0
	var margin = world_width * 0.1
	var spawn_z = -100.0 

	var random_x = randf_range(-world_width/2 + margin, world_width/2 - margin)
	var random_speed = randf_range(speed_min, speed_max)

	# --- 1. NAJPIERW DODAJEMY DO DRZEWA ---
	add_child(planet)

	# --- 2. TERAZ MOŻEMY BEZPIECZNIE UŻYĆ GLOBAL_POSITION ---
	planet.global_position = Vector3(random_x, -10.0, spawn_z)

	planet.speed = random_speed
