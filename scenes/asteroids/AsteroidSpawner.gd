extends Node3D

const ASTEROID_SCENES = [
	"res://scenes/asteroids/asteroid.tscn",
	"res://scenes/asteroids/asteroid_2.tscn",
	"res://scenes/asteroids/asteroid_3.tscn",
	"res://scenes/asteroids/asteroid_4.tscn",
	"res://scenes/asteroids/asteroid_5.tscn",
	"res://scenes/asteroids/asteroid_6.tscn",
	"res://scenes/asteroids/asteroid_7.tscn",
]

const LEVEL_COUNT := 3
const ASTEROID_META := "asteroid"

@export_group("Obrót")
@export var randomize_spin: bool = true
@export var despawn_off_screen: bool = true

@export_group("Paralaksa boczna")
@export var enable_edge_parallax: bool = true
## Maks. przesunięcie warstw asteroid przy graczu na krawędzi play area (oś X).
@export var max_parallax_shift: float = 8.0
@export var parallax_smooth: float = 8.0
## Mnożnik przesunięcia gracza per warstwa asteroid (bliższe = większa wartość).

@export_group("Poziom 1")
@export var y_1: float = 5.0
@export var spawn_interval_1: float = 10.0
@export var asteroid_speed_1: float = 10.0
@export var spin_speed_1: float = 1.0
@export_range(0.05, 2.0, 0.01) var scale_1: float = 1.8
@export_range(0.0, 1.5, 0.01) var edge_parallax_1: float = 0.2

@export_group("Poziom 2")
@export var y_2: float = -15.0
@export var spawn_interval_2: float = 5.0
@export var asteroid_speed_2: float = 4.0
@export var spin_speed_2: float = 1.0
@export_range(0.05, 2.0, 0.01) var scale_2: float = 1.8
@export_range(0.0, 1.5, 0.01) var edge_parallax_2: float = 0.2

@export_group("Poziom 3")
@export var y_3: float = -20.0
@export var spawn_interval_3: float = 15.0
@export var asteroid_speed_3: float = 0.5
@export var spin_speed_3: float = 1.0
@export_range(0.05, 2.0, 0.01) var scale_3: float = 0.35
@export_range(0.0, 1.5, 0.01) var edge_parallax_3: float = 0.1

@export var preprocess_time: float = 360.0

var _spawn_timers: Array[float] = []
var _layers: Array[Node3D] = []
var _player: Node3D
var _shift_x: float = 0.0


func _ready() -> void:
	_setup_layers()
	call_deferred("_setup_player")
	_spawn_timers = [
		spawn_interval_1,
		spawn_interval_2,
		spawn_interval_3,
	]
	if preprocess_time > 0.0:
		_start_preprocess()


func _start_preprocess() -> void:
	await get_tree().process_frame
	_preprocess(preprocess_time)


func _setup_layers() -> void:
	_layers.clear()
	for i in LEVEL_COUNT:
		var layer := Node3D.new()
		layer.name = "Layer%d" % (i + 1)
		add_child(layer)
		_layers.append(layer)


func _setup_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D


func _process(delta: float) -> void:
	_update_parallax_shift(delta)
	_update_layer_parallax()
	_tick_spawn_timers(delta)
	_update_asteroids(delta)


func _update_parallax_shift(delta: float) -> void:
	if _player == null:
		return

	var target_shift := _calc_target_shift()
	_shift_x = lerpf(_shift_x, target_shift, parallax_smooth * delta)


func _update_layer_parallax() -> void:
	if not enable_edge_parallax:
		for layer in _layers:
			layer.position.x = 0.0
		return

	for i in LEVEL_COUNT:
		_layers[i].position.x = _shift_x * _get_parallax(i)


func _calc_target_shift() -> float:
	var bound_x: float = float(_player.get("max_bound_x"))
	if bound_x <= 0.0:
		return 0.0

	return (_player.global_position.x / bound_x) * max_parallax_shift


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
				var layer := _layers[i]
				if layer.get_child_count() > 0:
					var last := layer.get_child(layer.get_child_count() - 1)
					last.global_position.z += _get_speed(i) * (time - elapsed - dt)
		elapsed += dt


func _tick_spawn_timers(delta: float) -> void:
	for i in LEVEL_COUNT:
		_spawn_timers[i] -= delta
		if _spawn_timers[i] <= 0.0:
			_spawn_at_level(i)
			_spawn_timers[i] += _get_interval(i)


func _update_asteroids(delta: float) -> void:
	for layer in _layers:
		for child in layer.get_children():
			if not child.get_meta(ASTEROID_META, false):
				continue

			child.global_position.z += child.get_meta("speed") * delta

			if randomize_spin:
				child.rotation += child.get_meta("angular_velocity") * delta
			else:
				child.transform = child.transform.rotated_local(
					Vector3.UP, child.get_meta("spin_speed") * delta
				)


func _setup_asteroid(asteroid: Node3D, level: int) -> void:
	asteroid.set_meta(ASTEROID_META, true)
	asteroid.set_meta("speed", _get_speed(level))
	var spin_speed := _get_spin_speed(level)
	asteroid.set_meta("spin_speed", spin_speed)

	if randomize_spin:
		asteroid.rotation = Vector3(
			randf_range(0.0, TAU),
			randf_range(0.0, TAU),
			randf_range(0.0, TAU),
		)
		asteroid.set_meta("angular_velocity", Vector3(
			randf_range(-1.0, 1.0) * spin_speed,
			randf_range(-1.0, 1.0) * spin_speed,
			randf_range(-1.0, 1.0) * spin_speed,
		))

	var notifier := asteroid.get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if notifier and despawn_off_screen:
		notifier.screen_exited.connect(asteroid.queue_free)


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


func _get_spin_speed(level: int) -> float:
	match level:
		0: return spin_speed_1
		1: return spin_speed_2
		_: return spin_speed_3


func _get_parallax(level: int) -> float:
	match level:
		0: return edge_parallax_1
		1: return edge_parallax_2
		_: return edge_parallax_3


func _visible_x_range_at_y(spawn_y: float) -> Vector2:
	var vp: Viewport = GameViewportHelper.get_render_viewport(get_tree())
	var cam: Camera3D = GameViewportHelper.get_game_camera(get_tree())
	if cam == null:
		push_warning("Brak kamery — używam domyślnego zakresu spawnu X")
		return Vector2(-7.65, 7.65)

	var plane := Plane(Vector3.UP, spawn_y)
	var vp_size: Vector2 = vp.get_visible_rect().size
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

	var level_scale := _get_scale(level)
	asteroid.scale = Vector3.ONE * level_scale
	_layers[level].add_child(asteroid)
	asteroid.position = Vector3(random_x, spawn_y, spawn_z)
	_setup_asteroid(asteroid, level)
