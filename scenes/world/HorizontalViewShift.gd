extends Node3D

## Przesuwa kamerę w bok przy krawędziach ekranu — widać więcej mapy, bez ruszania
## świata (wrogowie i pociski zostają w spójnych współrzędnych globalnych).

@export var max_shift_x: float = 3
## Od jakiej części max_bound_x zaczyna się przesuw (0.5 = od połowy drogi do krawędzi).
@export var edge_begin: float = 0.1
@export var smooth: float = 8.0
## Tło przesuwa się słabiej niż kamera (paralaksa, opcjonalnie 0 = wyłączone).
@export var background_parallax: float = 0.35

var _player: Node3D
var _camera: Camera3D
var _noise_bg: Node3D
var _camera_base_x: float = 0.0
var _noise_base_x: float = 0.0
var _shift_x: float = 0.0


func _ready() -> void:
	# Po ruchu gracza (CharacterBody3D); kamera w _physics_process — wymagane przy physics_interpolation.
	process_physics_priority = 10
	call_deferred("_setup")


func _setup() -> void:
	var game := get_parent()
	if game == null:
		return

	_player = get_tree().get_first_node_in_group("player") as Node3D
	_camera = game.get_node_or_null("Camera3D") as Camera3D
	_noise_bg = game.get_node_or_null("NoiseBackground") as Node3D

	if _camera:
		_camera_base_x = _camera.position.x
	if _noise_bg:
		_noise_base_x = _noise_bg.position.x


func _physics_process(delta: float) -> void:
	if _player == null or _camera == null:
		return

	var target_shift := _calc_target_shift()
	_shift_x = lerpf(_shift_x, target_shift, smooth * delta)

	_camera.position.x = _camera_base_x + _shift_x

	if _noise_bg and background_parallax > 0.0:
		_noise_bg.position.x = _noise_base_x + _shift_x * background_parallax


func get_shift_x() -> float:
	return _shift_x


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
