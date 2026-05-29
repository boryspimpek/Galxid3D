extends Node3D

const DEFAULT_ENEMY_SCENES: Array[String] = [
	"res://scenes/enemies/starfighter.tscn",
	"res://scenes/enemies/blaze1.tscn",
	"res://scenes/enemies/blaze2.tscn",
	"res://scenes/enemies/blaze3.tscn",
	"res://scenes/enemies/blaze4.tscn",
	"res://scenes/enemies/blaze5.tscn",
	"res://scenes/enemies/falcon.tscn",
	"res://scenes/enemies/heli_crimson.tscn",
	"res://scenes/enemies/heli_gold.tscn",
	"res://scenes/enemies/sky_tank.tscn",
	"res://scenes/enemies/voyager.tscn",
	"res://scenes/enemies/z_drone.tscn",
	"res://scenes/enemies/comet.tscn",
	"res://scenes/enemies/satelite1.tscn",
	"res://scenes/enemies/satelite2.tscn",
	"res://scenes/enemies/rocket.tscn",
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
		spawn_random_enemy()
		spawn_timer = spawn_interval

func _preprocess(time: float) -> void:
	var elapsed := 0.0
	while elapsed < time:
		elapsed += spawn_interval
		spawn_random_enemy()
		var last = get_child(get_child_count() - 1)
		# W 3D ruch do przodu/tyłu odbywa się na osi Z (zgodnie z Twoim skryptem planety)
		last.global_position.z += last.speed * (time - elapsed)

func spawn_random_enemy() -> void:
	var scene_path = DEFAULT_ENEMY_SCENES[randi() % DEFAULT_ENEMY_SCENES.size()]
	var enemy_scene = load(scene_path)
	if enemy_scene == null:
		push_error("Nie udało się załadować sceny: " + scene_path)
		return

	var enemy = enemy_scene.instantiate()

	var world_width = 17.0
	var margin = world_width * 0.1
	var spawn_z = -15.0

	var random_x = randf_range(-world_width/2 + margin, world_width/2 - margin)
	var random_speed = randf_range(speed_min, speed_max)

	# --- 1. NAJPIERW DODAJEMY DO DRZEWA ---
	add_child(enemy)

	# --- 2. TERAZ MOŻEMY BEZPIECZNIE UŻYĆ GLOBAL_POSITION ---
	enemy.global_position = Vector3(random_x, 0.0, spawn_z)

	enemy.speed = random_speed
