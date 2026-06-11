extends Node

signal combo_changed(combo: int)

## Maks. czas (s) między zabójstwami — po przekroczeniu combo zeruje się.
@export var combo_window_sec: float = 3.0

var combo: int = 0

var _last_kill_at: float = -1.0


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)


func _process(_delta: float) -> void:
	if combo == 0 or _last_kill_at < 0.0:
		return
	if _now() - _last_kill_at > combo_window_sec:
		_reset_combo()


func register_kill() -> void:
	var now := _now()
	if _last_kill_at >= 0.0 and (now - _last_kill_at) <= combo_window_sec:
		combo += 1
	else:
		combo = 1
	_last_kill_at = now
	combo_changed.emit(combo)


func _reset_combo() -> void:
	if combo == 0:
		return
	combo = 0
	_last_kill_at = -1.0
	combo_changed.emit(0)


func _on_scene_changed(_scene: Node) -> void:
	_reset_combo()


func _now() -> float:
	return Time.get_ticks_msec() * 0.001
