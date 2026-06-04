extends Node3D
class_name LevelScroll3D

const SCRIPT_FILE := "LevelScroll3D.gd"

## Podciąga fale / slide w stronę gracza (oś Z), aż wejdą w kadr i się aktywują.
## Po aktywacji wrogowie odpinają się (EnemyPath / animation) — scroll ich już nie rusza.

@export var scroll_speed: float = 1.0
@export var start_offset_z: float = 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if start_offset_z != 0.0:
		position.z = start_offset_z
	reset_physics_interpolation()


func _process(delta: float) -> void:
	position.z += scroll_speed * delta


static func is_under_level_scroll(node: Node) -> bool:
	var n: Node = node
	while n:
		var script: Script = n.get_script()
		if script and script.resource_path.get_file() == SCRIPT_FILE:
			return true
		n = n.get_parent()
	return false


static func detach_to_active_scene(node: Node) -> void:
	if node == null or not is_under_level_scroll(node):
		return
	var tree := node.get_tree()
	if tree == null:
		return
	var root := tree.current_scene
	if root == null or node.get_parent() == root:
		return
	node.reparent(root, true)
