extends Node3D

## Przesuwa mapę w bok, gdy gracz zbliża się do lewej/prawej krawędzi — widać więcej planszy z boku.

@export var max_shift_x: float = 2.5
## Od jakiej części max_bound_x zaczyna się przesuw (0.5 = od połowy drogi do krawędzi).
@export var edge_begin: float = 0.5
@export var smooth: float = 8.0
## Tło przesuwa się słabiej niż LevelScroll (paralaksa).
@export var background_parallax: float = 0.35
@export var shift_asteroids: bool = true

var _player: Node3D
var _level_scroll: Node3D
var _noise_bg: Node3D
var _asteroid_spawner: Node3D
var _base_positions: Dictionary = {}
var _shift_x: float = 0.0


func _ready() -> void:
	process_priority = 10
	call_deferred("_setup")


func _setup() -> void:
	var game := get_parent()
	if game == null:
		return

	_player = get_tree().get_first_node_in_group("player") as Node3D
	_level_scroll = game.get_node_or_null("LevelScroll") as Node3D
	_noise_bg = game.get_node_or_null("NoiseBackground") as Node3D
	_asteroid_spawner = game.get_node_or_null("AsteroidSpawner") as Node3D

	for node in _get_shift_nodes():
		_base_positions[node] = node.position


func _get_shift_nodes() -> Array[Node3D]:
	var nodes: Array[Node3D] = []
	if _level_scroll:
		nodes.append(_level_scroll)
	if _noise_bg:
		nodes.append(_noise_bg)
	if shift_asteroids and _asteroid_spawner:
		nodes.append(_asteroid_spawner)
	return nodes


func _process(delta: float) -> void:
	if _player == null or _base_positions.is_empty():
		return

	var target_shift := _calc_target_shift()
	_shift_x = lerpf(_shift_x, target_shift, smooth * delta)

	if _level_scroll and _base_positions.has(_level_scroll):
		var base: Vector3 = _base_positions[_level_scroll]
		_level_scroll.position.x = base.x - _shift_x

	if _noise_bg and _base_positions.has(_noise_bg):
		var base_bg: Vector3 = _base_positions[_noise_bg]
		_noise_bg.position.x = base_bg.x - _shift_x * background_parallax

	if shift_asteroids and _asteroid_spawner and _base_positions.has(_asteroid_spawner):
		var base_ast: Vector3 = _base_positions[_asteroid_spawner]
		_asteroid_spawner.position.x = base_ast.x - _shift_x


func _calc_target_shift() -> float:
	var bound_x: float = float(_player.get("max_bound_x"))
	if bound_x <= 0.0:
		return 0.0

	var px: float = _player.global_position.x
	var norm: float = absf(px) / bound_x
	if norm <= edge_begin:
		return 0.0

	var t: float = (norm - edge_begin) / maxf(0.001, 1.0 - edge_begin)
	return signf(px) * t * max_shift_x
