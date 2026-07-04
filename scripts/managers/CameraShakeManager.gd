extends Node

# ============================================================================
# CAMERA SHAKE MANAGER - globalny autoload do trzęsienia kamerą.
# Użycie: CameraShakeManager.shake(amount, duration)
# amount: 0.0 - 1.0 (siła)
# duration: czas tłumienia w sekundach
# ============================================================================

@export var max_h_offset: float = 10
@export var max_v_offset: float = 10
@export var shake_frequency: float = 20.0

var _trauma: float = 0.0
var _decay: float = 0.0
var _camera: Camera3D = null


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		_reset_camera()
		return

	_camera = GameViewportHelper.get_game_camera(get_tree())
	if _camera == null:
		return

	_trauma = maxf(_trauma - _decay * delta, 0.0)
	var shake := _trauma * _trauma  # kwadratowe tłumienie daje bardziej naturalny efekt

	var time := Time.get_ticks_msec() * 0.001
	_camera.h_offset = sin(time * shake_frequency) * max_h_offset * shake
	_camera.v_offset = cos(time * shake_frequency) * max_v_offset * shake


func shake(amount: float, duration: float = 0.3) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
	_decay = 1.0 / duration if duration > 0.0 else 0.0


func _reset_camera() -> void:
	if _camera:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0
	_camera = null
