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

@export var asteroid_count: int = 10
@export var orbit_radius_min: float = 62.0
@export var orbit_radius_max: float = 62.0
@export var orbit_speed: float = 0.12
@export_range(0.05, 1.0, 0.01) var asteroid_scale: float = 0.12
@export var randomize_start_angles: bool = true
@export var spin_asteroids: bool = true
@export var asteroid_spin_speed: float = 0.4

var _orbiters: Array[Dictionary] = []
var _fixed_basis: Basis


func _ready() -> void:
	_spawn_orbiters()
	call_deferred("_capture_world_orientation")


func _capture_world_orientation() -> void:
	_fixed_basis = global_basis


func _process(delta: float) -> void:
	var planet := get_parent() as Node3D
	if planet:
		global_position = planet.global_position
		global_basis = _fixed_basis

	for orbiter in _orbiters:
		orbiter["angle"] += orbit_speed * delta
		var angle: float = orbiter["angle"]
		var radius: float = orbiter["radius"]
		var node: Node3D = orbiter["node"]
		node.position = Vector3(
			cos(angle) * radius,
			0.0,
			sin(angle) * radius
		)
		if spin_asteroids:
			node.rotate_object_local(Vector3.UP, asteroid_spin_speed * delta)


func _spawn_orbiters() -> void:
	_orbiters.clear()
	for child in get_children():
		child.queue_free()

	for i in asteroid_count:
		var scene_path: String = ASTEROID_SCENES[randi() % ASTEROID_SCENES.size()]
		var scene: PackedScene = load(scene_path)
		if scene == null:
			push_error("PlanetOrbit: Nie udało się załadować sceny: " + scene_path)
			continue

		var asteroid: Node3D = scene.instantiate()
		add_child(asteroid)
		asteroid.scale = Vector3.ONE * asteroid_scale

		var angle := TAU * float(i) / float(asteroid_count)
		if randomize_start_angles:
			angle += randf_range(-0.15, 0.15)

		var radius_min := minf(orbit_radius_min, orbit_radius_max)
		var radius_max := maxf(orbit_radius_min, orbit_radius_max)
		var radius := randf_range(radius_min, radius_max)

		asteroid.position = Vector3(
			cos(angle) * radius,
			0.0,
			sin(angle) * radius
		)
		_orbiters.append({"node": asteroid, "angle": angle, "radius": radius})
