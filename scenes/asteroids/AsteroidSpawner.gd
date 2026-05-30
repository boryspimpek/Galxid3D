extends Node3D

const ASTEROID_SCENES = [
	"res://scenes/asteroids/asteroid.tscn",
	"res://scenes/asteroids/asteroid_2.tscn",
	"res://scenes/asteroids/asteroid_3.tscn",
]

const LEVEL_COUNT := 3

@export_group("Poziom 1")
@export var y_1: float = -10.0
@export var spawn_interval_1: float = 3.0
@export var asteroid_speed_1: float = 2.0
@export_range(0.05, 2.0, 0.01) var scale_1: float = 1.0

@export_group("Poziom 2")
@export var y_2: float = -30.0
@export var spawn_interval_2: float = 3.0
@export var asteroid_speed_2: float = 2.0
@export_range(0.05, 2.0, 0.01) var scale_2: float = 0.65

@export_group("Poziom 3")
@export var y_3: float = -50.0
@export var spawn_interval_3: float = 3.0
@export var asteroid_speed_3: float = 2.0
@export_range(0.05, 2.0, 0.01) var scale_3: float = 0.35

@export var preprocess_time: float = 20.0

var _spawn_timers: Array[float] = []


func _ready() -> void:
	_spawn_timers = [
		spawn_interval_1,
		spawn_interval_2,
		spawn_interval_3,
	]
	_preprocess(preprocess_time)


func _process(delta: float) -> void:
	_tick_spawn_timers(delta)


func _preprocess(time: float) -> void:
	var elapsed := 0.0
	const STEP := 0.05
	while elapsed < time:
		var dt := minf(STEP, time - elapsed)
		for i in LEVEL_COUNT:
			_spawn_timers[i] -= dt
			if _spawn_timers[i] <= 0.0:
				_spawn_at_level(i)
				_spawn_timers[i] += _get_interval(i)
				var last := get_child(get_child_count() - 1)
				last.global_position.z += _get_speed(i) * (time - elapsed - dt)
		elapsed += dt


func _tick_spawn_timers(delta: float) -> void:
	for i in LEVEL_COUNT:
		_spawn_timers[i] -= delta
		if _spawn_timers[i] <= 0.0:
			_spawn_at_level(i)
			_spawn_timers[i] += _get_interval(i)


func _get_y(level: int) -> float:
	match level:
		0: return y_1
		1: return y_2
		_: return y_3


func _get_interval(level: int) -> float:
	match level:
		0: return spawn_interval_1
		1: return spawn_interval_2
		_: return spawn_interval_3


func _get_speed(level: int) -> float:
	match level:
		0: return asteroid_speed_1
		1: return asteroid_speed_2
		_: return asteroid_speed_3


func _get_scale(level: int) -> float:
	match level:
		0: return scale_1
		1: return scale_2
		_: return scale_3


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


func _spawn_at_level(level: int) -> void:
	var scene_path = ASTEROID_SCENES[randi() % ASTEROID_SCENES.size()]
	var asteroid_scene = load(scene_path)
	if asteroid_scene == null:
		push_error("Nie udało się załadować sceny: " + scene_path)
		return

	var asteroid = asteroid_scene.instantiate()
	var spawn_y := _get_y(level)
	var spawn_z := -100.0
	var x_range := _visible_x_range_at_y(spawn_y)
	var margin := (x_range.y - x_range.x) * 0.01
	var random_x := randf_range(x_range.x + margin, x_range.y - margin)

	add_child(asteroid)
	var level_scale := _get_scale(level)
	asteroid.scale = Vector3.ONE * level_scale
	asteroid.global_position = Vector3(random_x, spawn_y, spawn_z)
	asteroid.speed = _get_speed(level)
