extends Control

## Dzieli ekran: gra w SubViewport (lewa strona), HUD poza obszarem gry (prawa).

@export var hud_panel_width: float = 300.0:
	set(value):
		hud_panel_width = maxf(180.0, value)
		_apply_layout()

@onready var _viewport_container: SubViewportContainer = $GameViewportContainer
@onready var _game_viewport: SubViewport = $GameViewportContainer/GameViewport
@onready var _hud: CanvasLayer = $Hud


func _ready() -> void:
	add_to_group("game_shell")
	_game_viewport.add_to_group("game_viewport")
	get_viewport().size_changed.connect(_apply_layout)
	if _hud:
		_hud.panel_width = hud_panel_width
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if not is_node_ready():
		return

	var window_size := get_viewport().get_visible_rect().size
	var game_width := maxf(1.0, window_size.x - hud_panel_width)

	_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport_container.offset_right = -hud_panel_width
	_game_viewport.size = Vector2i(int(game_width), int(window_size.y))

	if _hud:
		_hud.panel_width = hud_panel_width


func get_game_viewport() -> SubViewport:
	return _game_viewport


func get_hud_panel_width() -> float:
	return hud_panel_width


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
