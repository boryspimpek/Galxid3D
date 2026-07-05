extends Node3D

@export var speed_z: float = 2
@export var speed_x: float = 0
@export var speed_y: float = 0

@export_group("Activation")
@export var activate_on_scroll_line: bool = false

@export_group("Cleanup")
@export var despawn_off_screen: bool = true
@export var despawn_margin: float = 30.0

var _scroll_activation_z: float = -12.0
var _active: bool = false
var _despawn_z: float = 12.0
var _despawn_with_notifier: bool = false


func _ready() -> void:
	var play_area := DataManager.get_play_area_config()
	if play_area:
		_scroll_activation_z = play_area.scroll_activation_z
		_despawn_z = play_area.frame_half_z + despawn_margin

	if not activate_on_scroll_line:
		_active = true

	if despawn_off_screen:
		_despawn_with_notifier = _setup_despawn_notifier()

func _process(delta: float) -> void:
	if activate_on_scroll_line and not _active:
		if global_position.z >= _scroll_activation_z:
			_active = true
		else:
			return

	position.z += speed_z * delta
	position.x += speed_x * delta
	rotation.y += speed_y * delta

	if despawn_off_screen and not _despawn_with_notifier and global_position.z > _despawn_z:
		queue_free()


func _setup_despawn_notifier() -> bool:
	var notifier := get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if notifier == null:
		return false

	notifier.visible = true
	notifier.screen_exited.connect(_on_screen_exited)
	return true


func _on_screen_exited() -> void:
	if despawn_off_screen:
		queue_free()
