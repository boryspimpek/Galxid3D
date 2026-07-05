extends Node3D

@export var speed_z: float = 2
@export var speed_x: float = 0
@export var speed_y: float = 0

@export_group("Activation")
@export var activate_on_scroll_line: bool = false

var _scroll_activation_z: float = -12.0
var _active: bool = false


func _ready() -> void:
	var play_area := DataManager.get_play_area_config()
	if play_area:
		_scroll_activation_z = play_area.scroll_activation_z

	if not activate_on_scroll_line:
		_active = true


func _process(delta: float) -> void:
	if activate_on_scroll_line and not _active:
		if global_position.z >= _scroll_activation_z:
			_active = true
		else:
			return

	position.z += speed_z * delta
	position.x += speed_x * delta
	rotation.y += speed_y * delta
