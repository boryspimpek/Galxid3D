extends Node3D
class_name LevelScroll3D

const SCRIPT_FILE := "LevelScroll3D.gd"

## Podciąga fale / slide w stronę gracza (oś Z), aż wejdą w kadr i się aktywują.
## Po aktywacji wrogowie odpinają się (EnemyPathFollow) — scroll ich już nie rusza.

@export var scroll_speed: float = 6.0
@export var start_offset_z: float = 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if start_offset_z != 0.0:
		position.z = start_offset_z
		_cull_enemies_behind_screen()
	reset_physics_interpolation()


## Po starcie z offsetem wrogowie, którzy wylądowali za dolną krawędzią kadru,
## nigdy nie wejdą na ekran (scroll idzie w +Z) — usuwamy ich, żeby nie strzelali.
func _cull_enemies_behind_screen() -> void:
	var play_area := DataManager.get_play_area_config()
	var cull_z: float = play_area.frame_half_z if play_area else 15.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and is_ancestor_of(enemy) and enemy.global_position.z > cull_z:
			enemy.queue_free()


func _process(delta: float) -> void:
	position.z += scroll_speed * delta


static func _find_level_scroll(node: Node) -> Node:
	var n: Node = node
	while n:
		var script: Script = n.get_script()
		if script and script.resource_path.get_file() == SCRIPT_FILE:
			return n
		n = n.get_parent()
	return null


static func is_under_level_scroll(node: Node) -> bool:
	return _find_level_scroll(node) != null


static func detach_to_active_scene(node: Node) -> void:
	if node == null:
		return
	var scroll := _find_level_scroll(node)
	if scroll == null:
		return
	# Przepinamy do rodzica LevelScroll (np. GameWorld), aby węzeł został w tym
	# samym World3D / SubViewport i nadal był renderowany przez kamerę gry,
	# a jednocześnie przestał być przesuwany przez scroll.
	var target := scroll.get_parent()
	if target == null or node.get_parent() == target:
		return
	node.reparent(target, true)
