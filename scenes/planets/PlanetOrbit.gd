extends Node3D

const ASTEROID_MESHES_SCENE := preload("res://scenes/asteroids/asteroids.tscn")
const ASTEROID_MATERIAL := preload("res://scenes/asteroids/asteroid_material.tres")

@export var asteroid_meshes_scene: PackedScene = ASTEROID_MESHES_SCENE
@export var asteroid_material: Material = ASTEROID_MATERIAL
@export var asteroid_count: int = 10
@export var orbit_radius_min: float = 62.0
@export var orbit_radius_max: float = 62.0
@export var belt_thickness: float = 15.0
@export var orbit_speed: float = 0.12
@export_range(0.05, 10.0, 0.01) var asteroid_scale: float = 0.12
@export var randomize_start_angles: bool = true
@export var spin_asteroids: bool = true
@export var asteroid_spin_speed: float = 0.4

var _orbiters: Array[Dictionary] = []
var _meshes: Array[Mesh] = []
var _multimeshes: Dictionary = {}
var _fixed_basis: Basis


func _ready() -> void:
	_load_meshes()
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
		if spin_asteroids:
			orbiter["spin"] += asteroid_spin_speed * delta

		var multimesh: MultiMesh = _multimeshes[orbiter["mesh_idx"]]
		multimesh.set_instance_transform(
			orbiter["local_idx"],
			_make_transform(orbiter["angle"], orbiter["radius"], orbiter["height"], orbiter["spin"])
		)


func _load_meshes() -> void:
	_meshes.clear()
	var root := asteroid_meshes_scene.instantiate()
	_collect_meshes(root)
	root.queue_free()

	if _meshes.is_empty():
		push_error("PlanetOrbit: Nie znaleziono meshy w scenie: " + asteroid_meshes_scene.resource_path)


func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		_meshes.append(node.mesh)
	for child in node.get_children():
		_collect_meshes(child)


func _spawn_orbiters() -> void:
	_orbiters.clear()
	_multimeshes.clear()
	for child in get_children():
		child.queue_free()

	if _meshes.is_empty():
		return

	var mesh_indices: Array[int] = []
	mesh_indices.resize(asteroid_count)
	var counts := PackedInt32Array()
	counts.resize(_meshes.size())

	for i in asteroid_count:
		var mesh_idx := randi() % _meshes.size()
		mesh_indices[i] = mesh_idx
		counts[mesh_idx] += 1

	for mesh_idx in _meshes.size():
		if counts[mesh_idx] == 0:
			continue

		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = _meshes[mesh_idx]
		multimesh.instance_count = counts[mesh_idx]

		var mm_instance := MultiMeshInstance3D.new()
		mm_instance.name = "Asteroids_%02d" % (mesh_idx + 1)
		mm_instance.layers = 4
		mm_instance.material_override = asteroid_material
		mm_instance.multimesh = multimesh
		add_child(mm_instance)

		_multimeshes[mesh_idx] = multimesh

	var local_counters := PackedInt32Array()
	local_counters.resize(_meshes.size())

	for i in asteroid_count:
		var mesh_idx: int = mesh_indices[i]
		var local_idx: int = local_counters[mesh_idx]
		local_counters[mesh_idx] += 1

		var angle := TAU * float(i) / float(asteroid_count)
		if randomize_start_angles:
			angle += randf_range(-0.15, 0.15)

		var radius_min := minf(orbit_radius_min, orbit_radius_max)
		var radius_max := maxf(orbit_radius_min, orbit_radius_max)
		var radius := randf_range(radius_min, radius_max)
		var height := randf_range(-belt_thickness * 0.5, belt_thickness * 0.5)
		var spin := randf_range(0.0, TAU) if spin_asteroids else 0.0

		_orbiters.append({
			"mesh_idx": mesh_idx,
			"local_idx": local_idx,
			"angle": angle,
			"radius": radius,
			"height": height,
			"spin": spin,
		})

		_multimeshes[mesh_idx].set_instance_transform(
			local_idx,
			_make_transform(angle, radius, height, spin)
		)


func _make_transform(angle: float, radius: float, height: float, spin: float) -> Transform3D:
	var pos := Vector3(
		cos(angle) * radius,
		height,
		sin(angle) * radius
	)
	var orbiter_basis := Basis.from_euler(Vector3(0.0, spin, 0.0)).scaled(Vector3.ONE * asteroid_scale)
	return Transform3D(orbiter_basis, pos)
