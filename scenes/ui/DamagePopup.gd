extends Node3D
class_name DamagePopup

const SCENE: PackedScene = preload("res://scenes/ui/DamagePopup.tscn")

@export var duration: float = 0.75
@export var float_velocity: Vector3 = Vector3(0.0, 1.8, -2.5)
@export var pop_scale: float = 1.35

@onready var _label: Label3D = $Label3D

var _elapsed: float = 0.0


static func spawn(tree: SceneTree, world_position: Vector3, amount: int) -> void:
	var popup: DamagePopup = SCENE.instantiate()
	var parent := _get_spawn_parent(tree)
	if parent == null:
		return
	parent.add_child(popup)
	popup.setup(world_position, amount)


static func _get_spawn_parent(tree: SceneTree) -> Node:
	var game_viewport := GameViewportHelper.get_game_viewport(tree)
	if game_viewport:
		var game_world := game_viewport.get_node_or_null("GameWorld")
		if game_world:
			return game_world
	return tree.current_scene


func setup(world_position: Vector3, amount: int) -> void:
	global_position = world_position
	_label.text = str(amount)
	_label.modulate = Color(1.0, 0.92, 0.45, 1.0)
	_label.scale = Vector3.ONE * pop_scale
	_elapsed = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / duration, 0.0, 1.0)

	global_position += float_velocity * delta

	var pop_t := minf(_elapsed / 0.1, 1.0)
	_label.scale = Vector3.ONE * lerpf(pop_scale, 1.0, pop_t)

	var fade := 1.0 - t * t
	_label.modulate.a = fade

	if t >= 1.0:
		queue_free()
