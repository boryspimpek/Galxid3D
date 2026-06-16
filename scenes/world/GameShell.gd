extends Control

## Pełnoekranowa gra w SubViewport; HUD jako CanvasLayer na wierzchu.

@onready var _viewport_container: SubViewportContainer = $GameViewportContainer
@onready var _game_viewport: SubViewport = $GameViewportContainer/GameViewport


func _ready() -> void:
	add_to_group("game_shell")
	_game_viewport.add_to_group("game_viewport")
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if not is_node_ready():
		return

	_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)


func get_game_viewport() -> SubViewport:
	return _game_viewport


func is_point_in_game_area(root_pos: Vector2) -> bool:
	return _viewport_container.get_global_rect().has_point(root_pos)


func root_to_game_viewport_pos(root_pos: Vector2) -> Vector2:
	var rect := _viewport_container.get_global_rect()
	if not rect.has_point(root_pos):
		return Vector2(-1.0, -1.0)

	var local := root_pos - rect.position
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2(-1.0, -1.0)

	return local * (Vector2(_game_viewport.size) / rect.size)
