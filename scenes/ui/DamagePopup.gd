extends Node3D
class_name DamagePopup

const SCENE: PackedScene = preload("res://scenes/ui/DamagePopup.tscn")
const POP_IN_TIME := 0.14
const SETTLE_TIME := 0.08

@export var duration: float = 0.8
@export var pop_scale: float = 1.55

@export_group("Drift")
@export var drift_x: Vector2 = Vector2(-0.55, 0.55)
@export var drift_y: Vector2 = Vector2(1.4, 2.2)
@export var drift_z: Vector2 = Vector2(-1.2, 0.35)
@export var tilt_y: Vector2 = Vector2(-0.25, 0.25)

@onready var _label: Label3D = $Label3D
@onready var _glow: Label3D = $GlowLabel3D

var _elapsed: float = 0.0
var _start_pos: Vector3 = Vector3.ZERO
var _drift: Vector3 = Vector3.ZERO
var _tilt: float = 0.0
var _label_base_color: Color = Color.WHITE
var _glow_base_color: Color = Color.WHITE


static func spawn(tree: SceneTree, world_position: Vector3, amount: int) -> void:
	var popup: DamagePopup = SCENE.instantiate()
	var parent := _get_spawn_parent(tree)
	if parent == null:
		return
	parent.add_child(popup)
	popup.setup(world_position, amount)


static func _get_spawn_parent(tree: SceneTree) -> Node:
	var game_viewport := GameViewportHelper.get_game_viewport(tree)
	if game_viewport:
		var game_world := game_viewport.get_node_or_null("GameWorld")
		if game_world:
			return game_world
	return tree.current_scene


func setup(world_position: Vector3, amount: int) -> void:
	var text := str(amount)
	_start_pos = world_position
	global_position = world_position

	_label.text = text
	_glow.text = text
	_label_base_color = _label.modulate
	_glow_base_color = _glow.modulate
	_label.modulate = _label_base_color
	_glow.modulate = _glow_base_color

	_drift = Vector3(
		randf_range(drift_x.x, drift_x.y),
		randf_range(drift_y.x, drift_y.y),
		randf_range(drift_z.x, drift_z.y)
	)
	_tilt = randf_range(tilt_y.x, tilt_y.y)
	rotation.y = _tilt

	var tiny_scale := 0.15
	_label.scale = Vector3.ONE * tiny_scale
	_glow.scale = Vector3.ONE * tiny_scale * 1.15
	_elapsed = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / duration, 0.0, 1.0)

	var move_ease := 1.0 - pow(1.0 - t, 2.2)
	global_position = _start_pos + _drift * move_ease

	var scale_val: float
	if _elapsed < POP_IN_TIME:
		var pop_t := _elapsed / POP_IN_TIME
		scale_val = lerpf(0.15, pop_scale, _ease_out_back(pop_t))
	elif _elapsed < POP_IN_TIME + SETTLE_TIME:
		var settle_t := (_elapsed - POP_IN_TIME) / SETTLE_TIME
		scale_val = lerpf(pop_scale, 1.0, _ease_out_cubic(settle_t))
	else:
		var shrink_t := clampf((t - 0.65) / 0.35, 0.0, 1.0)
		scale_val = lerpf(1.0, 0.88, shrink_t)

	_label.scale = Vector3.ONE * scale_val
	_glow.scale = Vector3.ONE * scale_val * 1.12

	var fade_start := 0.45
	var fade_t := clampf((t - fade_start) / (1.0 - fade_start), 0.0, 1.0)
	var alpha := 1.0 - fade_t * fade_t
	_label.modulate = Color(_label_base_color.r, _label_base_color.g, _label_base_color.b, _label_base_color.a * alpha)
	_glow.modulate = Color(_glow_base_color.r, _glow_base_color.g, _glow_base_color.b, _glow_base_color.a * alpha)

	rotation.y = _tilt * (1.0 - move_ease * 0.6)

	if t >= 1.0:
		queue_free()


static func _ease_out_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


static func _ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)
