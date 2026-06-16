extends CanvasLayer

const HEALTH_BAR_PATH := "res://assets/health bar/health_%02d.png"
const SHIELD_BAR_PATH := "res://assets/shield bar/shield_%02d.png"

@export var min_combo_to_show: int = 2
@export_group("Combo display")
@export var combo_pop_scale: float = 1.42
@export var combo_pop_duration: float = 0.2
@export var combo_hide_duration: float = 0.24
@export_group("Status bars")
@export var health_bar_scale: float = 0.5
@export var shield_bar_scale: float = 0.5
@export var status_bar_margin: Vector2 = Vector2(24.0, 20.0)
@export var status_bar_spacing: float = 8.0

@onready var _health_bar: TextureRect = %HealthBar
@onready var _shield_bar: TextureRect = %ShieldBar
@onready var _score_label: Label = %ScoreValue
@onready var _game_over: Control = %GameOver
@onready var _combo_label: Label = %ComboLabel

var _health_textures: Array[Texture2D] = []
var _shield_textures: Array[Texture2D] = []
var _player: CharacterBody3D
var _shield_system: Node
var _player_bound: bool = false
var _combo_tween: Tween
var _combo_base_modulate: Color = Color.WHITE


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_status_bar_textures()
	_apply_status_bars_layout()
	%GameOverRestartButton.pressed.connect(_restart_run)
	HitComboManager.combo_changed.connect(_on_combo_changed)
	_combo_base_modulate = _combo_label.modulate
	_combo_label.visible = false
	_combo_label.scale = Vector2.ONE
	_update_combo_label(HitComboManager.combo)
	call_deferred("_bind_player")


func _process(_delta: float) -> void:
	if not _player_bound:
		_bind_player()


func _load_status_bar_textures() -> void:
	_health_textures.clear()
	_shield_textures.clear()
	for index in range(11):
		_health_textures.append(load(HEALTH_BAR_PATH % index) as Texture2D)
		_shield_textures.append(load(SHIELD_BAR_PATH % index) as Texture2D)
	if _health_textures.size() > 0:
		_health_bar.texture = _health_textures[0]
	if _shield_textures.size() > 0:
		_shield_bar.texture = _shield_textures[0]


func _apply_status_bars_layout() -> void:
	if not is_node_ready() or _health_textures.is_empty() or _shield_textures.is_empty():
		return

	var health_size := _health_textures[0].get_size() * health_bar_scale
	var shield_size := _shield_textures[0].get_size() * shield_bar_scale

	_health_bar.custom_minimum_size = health_size
	_health_bar.offset_left = -health_size.x - status_bar_margin.x
	_health_bar.offset_top = status_bar_margin.y
	_health_bar.offset_right = -status_bar_margin.x
	_health_bar.offset_bottom = status_bar_margin.y + health_size.y

	_shield_bar.custom_minimum_size = shield_size
	_shield_bar.offset_left = -shield_size.x - status_bar_margin.x
	_shield_bar.offset_top = status_bar_margin.y + health_size.y + status_bar_spacing
	_shield_bar.offset_right = -status_bar_margin.x
	_shield_bar.offset_bottom = status_bar_margin.y + health_size.y + status_bar_spacing + shield_size.y


func _bind_player() -> void:
	if _player_bound:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player == null:
		return

	_player = player
	_shield_system = _player.get_node_or_null("ShieldSystem")
	_player.score_changed.connect(_on_score_changed)
	_player.armor_changed.connect(_on_armor_changed)
	if _shield_system:
		_shield_system.shield_changed.connect(_on_shield_changed)

	_on_score_changed(_player.score)
	_on_armor_changed(_player.armor, _player.max_armor)
	if _shield_system:
		call_deferred("_refresh_shield_bar")
	_player_bound = true
	set_process(false)


func _refresh_shield_bar() -> void:
	if _shield_system:
		_on_shield_changed(_shield_system.shield, _shield_system.shield_max)


func show_game_over() -> void:
	_game_over.visible = true
	get_tree().paused = true


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if not _game_over.visible:
		return

	if event is InputEventMouseButton and event.pressed:
		_restart_run()
	elif event is InputEventScreenTouch and event.pressed:
		_restart_run()
	elif event is InputEventKey and event.pressed:
		_restart_run()
	elif event is InputEventJoypadButton and event.pressed:
		_restart_run()


func _on_score_changed(score: int) -> void:
	_score_label.text = str(score)


func _on_armor_changed(current: int, _maximum: int) -> void:
	var index := clampi(current, 0, 10)
	if index < _health_textures.size():
		_health_bar.texture = _health_textures[index]


func _on_shield_changed(current: float, maximum: float) -> void:
	var has_shield := maximum > 0.0
	_shield_bar.visible = has_shield
	if not has_shield:
		return

	var index := clampi(int(round(current)), 0, 10)
	if index < _shield_textures.size():
		_shield_bar.texture = _shield_textures[index]


func _on_combo_changed(combo: int) -> void:
	_update_combo_label(combo)


func _update_combo_label(combo: int) -> void:
	if _combo_label == null:
		return
	if combo < min_combo_to_show:
		_hide_combo_animated()
		return

	var first_show := not _combo_label.visible
	_combo_label.text = "COMBO x%d" % combo
	_combo_label.visible = true
	call_deferred("_play_combo_feedback", combo, first_show)


func _play_combo_feedback(combo: int, first_show: bool) -> void:
	if _combo_label == null or not _combo_label.visible:
		return

	_kill_combo_tween()
	_combo_label.reset_size()
	_combo_label.pivot_offset = _combo_label.size * 0.5

	var peak_scale := combo_pop_scale + minf(0.18, float(combo - min_combo_to_show) * 0.025)
	var start_scale := 0.55 if first_show else 0.88
	_combo_label.scale = Vector2.ONE * start_scale
	_combo_label.rotation_degrees = randf_range(-5.0, 5.0) if not first_show else 0.0
	_combo_label.modulate = _combo_base_modulate

	var flash_color := _combo_flash_color(combo)
	var pop_in := combo_pop_duration * 0.55
	var settle := combo_pop_duration * 0.45

	_combo_tween = create_tween()
	_combo_tween.set_parallel(true)
	(
		_combo_tween.tween_property(_combo_label, "scale", Vector2.ONE * peak_scale, pop_in)
		.set_trans(Tween.TRANS_BACK)
		.set_ease(Tween.EASE_OUT)
	)
	(
		_combo_tween.tween_property(_combo_label, "modulate", flash_color, pop_in * 0.65)
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_OUT)
	)
	if not first_show:
		(
			_combo_tween.tween_property(_combo_label, "rotation_degrees", 0.0, pop_in)
			.set_trans(Tween.TRANS_QUAD)
			.set_ease(Tween.EASE_OUT)
		)

	_combo_tween.chain().set_parallel(true)
	(
		_combo_tween.tween_property(_combo_label, "scale", Vector2.ONE, settle)
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_OUT)
	)
	(
		_combo_tween.tween_property(_combo_label, "modulate", _combo_base_modulate, settle)
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_OUT)
	)


func _hide_combo_animated() -> void:
	if _combo_label == null or not _combo_label.visible:
		return

	_kill_combo_tween()
	_combo_label.pivot_offset = _combo_label.size * 0.5

	_combo_tween = create_tween()
	_combo_tween.set_parallel(true)
	(
		_combo_tween.tween_property(_combo_label, "scale", Vector2(0.55, 0.55), combo_hide_duration)
		.set_trans(Tween.TRANS_BACK)
		.set_ease(Tween.EASE_IN)
	)
	(
		_combo_tween.tween_property(_combo_label, "modulate:a", 0.0, combo_hide_duration)
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN)
	)
	_combo_tween.tween_property(_combo_label, "rotation_degrees", randf_range(-8.0, 8.0), combo_hide_duration)
	_combo_tween.chain().tween_callback(_reset_combo_label)


func _reset_combo_label() -> void:
	if _combo_label == null:
		return
	_combo_label.visible = false
	_combo_label.scale = Vector2.ONE
	_combo_label.rotation_degrees = 0.0
	_combo_label.modulate = _combo_base_modulate


func _kill_combo_tween() -> void:
	if _combo_tween != null and _combo_tween.is_valid():
		_combo_tween.kill()
	_combo_tween = null


func _combo_flash_color(combo: int) -> Color:
	if combo >= 10:
		return _combo_base_modulate * Color(1.45, 0.55, 0.35, 1.0)
	if combo >= 5:
		return _combo_base_modulate * Color(1.35, 1.15, 0.5, 1.0)
	return _combo_base_modulate * Color(1.25, 1.05, 0.75, 1.0)
