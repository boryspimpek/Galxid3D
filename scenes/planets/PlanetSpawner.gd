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
@export var speed_min: float = 2.0
@export var speed_max: float = 6.0
@export var y_max: float = -10.0
@export var y_min: float = -20.0
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

func _visible_x_range_at_y(spawn_y: float) -> Vector2:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		push_warning("Brak kamery — używam domyślnego zakresu spawnu X")
		return Vector2(-7.65, 7.65)

	var plane := Plane(Vector3.UP, spawn_y)
	var vp_size := get_viewport().get_visible_rect().size
	var corners := [
		Vector2.ZERO,
		Vector2(vp_size.x, 0.0),
		vp_size,
		Vector2(0.0, vp_size.y),
	]

	var min_x := INF
	var max_x := -INF
	var hits := 0

	for corner in corners:
		var hit = plane.intersects_ray(
			cam.project_ray_origin(corner),
			cam.project_ray_normal(corner)
		)
		if hit != null:
			min_x = minf(min_x, hit.x)
			max_x = maxf(max_x, hit.x)
			hits += 1

	if hits == 0:
		push_warning("Nie udało się wyznaczyć zakresu X — używam domyślnego")
		return Vector2(-7.65, 7.65)

	return Vector2(min_x, max_x)


func spawn_random_planet() -> void:
	var scene_path = PLANET_SCENES[randi() % PLANET_SCENES.size()]
	var planet_scene = load(scene_path)
	if planet_scene == null:
		push_error("Nie udało się załadować sceny: " + scene_path)
		return

	var planet = planet_scene.instantiate()

	var spawn_z = -100.0
	var random_y = randf_range(y_max, y_min)
	var x_range := _visible_x_range_at_y(random_y)
	var margin := (x_range.y - x_range.x) * 0.01
	var random_x = randf_range(x_range.x + margin, x_range.y - margin)
	var random_speed = randf_range(speed_min, speed_max)

	# --- 1. NAJPIERW DODAJEMY DO DRZEWA ---
	add_child(planet)

	# --- 2. TERAZ MOŻEMY BEZPIECZNIE UŻYĆ GLOBAL_POSITION ---
	planet.global_position = Vector3(random_x, random_y, spawn_z)

	planet.speed = random_speed
