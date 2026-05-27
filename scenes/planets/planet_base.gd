@tool
extends MeshInstance3D

@export var albedo_texture: Texture2D:
	set(value):
		albedo_texture = value
		_apply_textures()

@export var spin_speed: float = 2.0
@export var speed: float = 2.0

var _runtime_material_initialized := false

func _ready() -> void:
	_ensure_unique_material()
	_apply_textures()
	set_process(not Engine.is_editor_hint())

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	transform = transform.rotated_local(Vector3.UP, spin_speed * delta)
	global_position.z += speed * delta

func _ensure_unique_material() -> void:
	if _runtime_material_initialized:
		return
	_runtime_material_initialized = true

	# IMPORTANT:
	# Do NOT mutate mesh.material here because the Mesh resource can be shared
	# across instances/scenes, which would make texture changes affect all planets.
	# Use per-node material_override instead.
	var source: Material = material_override
	if source == null and mesh != null:
		source = mesh.material

	if source != null:
		material_override = source.duplicate(true)

func _apply_textures() -> void:
	_ensure_unique_material()
	var mat: Material = material_override
	if mat is ShaderMaterial and albedo_texture != null:
		mat.set_shader_parameter("albedo_texture", albedo_texture)

