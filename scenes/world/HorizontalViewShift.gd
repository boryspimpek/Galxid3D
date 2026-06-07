extends Node3D

## Paralaksa tła przy ruchu gracza w bok — kamera stoi nieruchomo, warstwy tła
## przesuwają się z różną prędkością (bliższe mocniej, dalsze słabiej).

@export var max_parallax_shift: float = 8.0
@export var smooth: float = 8.0

@export_group("Warstwy")
@export var noise_parallax: float = 0.25
@export var earth_parallax: float = 0.18

var _player: Node3D
var _noise_bg: Node3D
var _earth: Node3D
var _noise_base_x: float = 0.0
var _earth_base_x: float = 0.0
var _shift_x: float = 0.0


func _ready() -> void:
	process_physics_priority = 10
	call_deferred("_setup")


func _setup() -> void:
	var background := get_parent()
	if background == null:
		return

	_player = get_tree().get_first_node_in_group("player") as Node3D
	_noise_bg = background.get_node_or_null("MeshInstance3D") as Node3D
	_earth = background.get_node_or_null("earth") as Node3D

	if _noise_bg:
		_noise_base_x = _noise_bg.position.x
	if _earth:
		_earth_base_x = _earth.position.x


func _physics_process(delta: float) -> void:
	if _player == null:
		return

	var target_shift := _calc_target_shift()
	_shift_x = lerpf(_shift_x, target_shift, smooth * delta)

	if _noise_bg and noise_parallax > 0.0:
		_noise_bg.position.x = _noise_base_x + _shift_x * noise_parallax

	if _earth and earth_parallax > 0.0:
		_earth.position.x = _earth_base_x + _shift_x * earth_parallax


func get_shift_x() -> float:
	return _shift_x


func _calc_target_shift() -> float:
	var bound_x: float = float(_player.get("max_bound_x"))
	if bound_x <= 0.0:
		return 0.0

	return (_player.global_position.x / bound_x) * max_parallax_shift
