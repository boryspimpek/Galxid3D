extends CanvasLayer

const HEALTH_BAR_PATH := "res://assets/health bar/health_%02d.png"
const POWER_BAR_PATH := "res://assets/power bar/power_%02d.png"
const POWER_PER_LEVEL := 50
const POWER_BAR_MAX_INDEX := 10

@export var min_combo_to_show: int = 5
@export_group("Combo display")
@export var combo_pop_scale: float = 1.42
@export var combo_pop_duration: float = 0.2
@export var combo_hide_duration: float = 0.24

@onready var _health_bar: TextureRect = %HealthBar
@onready var _power_bar: TextureRect = %PowerBar
@onready var _score_label: Label = %ScoreValue
@onready var _game_over: Control = %GameOver
@onready var _start_game: Control = %StartGame
@onready var _pause_screen: Control = %PauseScreen
@onready var _final_score_label: Label = %FinalScore
@onready var _combo_label: Label = %ComboLabel

@onready var _options_screen: Control = %OptionsScreen
@onready var _controls_screen: Control = %ControlsScreen

@onready var _play_button: Button = %StartGame/Center/Panel/VBox/PlayButton
@onready var _hangar_button: Button = %StartGame/Center/Panel/VBox/HangarButton
@onready var _options_button: Button = %StartGame/Center/Panel/VBox/OptionsButton
@onready var _controls_button: Button = %StartGame/Center/Panel/VBox/ControlsButton

var _health_textures: Array[Texture2D] = []
var _power_textures: Array[Texture2D] = []
var _player: CharacterBody3D
var _player_bound: bool = false
var _combo_tween: Tween
var _combo_label_settings: LabelSettings
var _combo_base_modulate: Color = Color.WHITE


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_status_bar_textures()
	HitComboManager.combo_changed.connect(_on_combo_changed)
	if _combo_label.label_settings:
		_combo_label_settings = _combo_label.label_settings.duplicate()
	else:
		_combo_label_settings = LabelSettings.new()
	_combo_base_modulate = Color.WHITE
	_combo_label.modulate = _combo_base_modulate
	_combo_label.visible = false
	_combo_label.scale = Vector2.ONE
	_update_combo_label(HitComboManager.combo)
	call_deferred("_bind_player")
	_start_pulse_hints()
	_start_game.visible = true
	get_tree().paused = true
	_play_button.grab_focus()

	_play_button.pressed.connect(_on_play_pressed)
	_hangar_button.pressed.connect(_on_hangar_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_controls_button.pressed.connect(_on_controls_pressed)


func _process(_delta: float) -> void:
	if not _player_bound:
		_bind_player()


func _load_status_bar_textures() -> void:
	_health_textures.clear()
	_power_textures.clear()
	for index in range(11):
		_health_textures.append(load(HEALTH_BAR_PATH % index) as Texture2D)
	for index in range(POWER_BAR_MAX_INDEX + 1):
		_power_textures.append(load(POWER_BAR_PATH % index) as Texture2D)
	if _health_textures.size() > 0:
		_health_bar.texture = _health_textures[0]
	if _power_textures.size() > 0:
		_power_bar.texture = _power_textures[0]


func _bind_player() -> void:
	if _player_bound:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player == null:
		return

	_player = player
	_player.score_changed.connect(_on_score_changed)
	_player.armor_changed.connect(_on_armor_changed)
	_player.power_changed.connect(_on_power_changed)

	_on_score_changed(_player.score)
	_on_armor_changed(_player.armor, _player.max_armor)
	_on_power_changed(_player.power, _player.max_power)
	_player_bound = true
	set_process(false)


func show_game_over() -> void:
	if _player != null and _final_score_label != null:
		_final_score_label.text = str(_player.score)
	_game_over.visible = true
	get_tree().paused = true


func _start_pulse_hints() -> void:
	for hint in get_tree().get_nodes_in_group("pulse_hint"):
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(hint, "modulate:a", 0.35, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(hint, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _start_run() -> void:
	_start_game.visible = false
	get_tree().paused = false


func _toggle_pause() -> void:
	var will_pause := not get_tree().paused
	get_tree().paused = will_pause
	_pause_screen.visible = will_pause


func _on_play_pressed() -> void:
	_start_run()


func _on_hangar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hangar/hangar_scene.tscn")


func _on_options_pressed() -> void:
	_start_game.visible = false
	_options_screen.visible = true


func _on_controls_pressed() -> void:
	_start_game.visible = false
	_controls_screen.visible = true


func _return_to_start_menu() -> void:
	_options_screen.visible = false
	_controls_screen.visible = false
	_start_game.visible = true
	_play_button.grab_focus()


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		print("[HUD DEBUG] Joypad button pressed: index=", event.button_index)
	if event.is_action_pressed("pause"):
		print("[HUD DEBUG] pause action triggered")

	if _options_screen.visible or _controls_screen.visible:
		if event.is_action_pressed("back") or event.is_action_pressed("ui_cancel"):
			_return_to_start_menu()
		return

	if _game_over.visible:
		if event.is_action_pressed("pause"):
			_restart_run()
			return
		if (
			(event is InputEventMouseButton and event.pressed)
			or (event is InputEventScreenTouch and event.pressed)
			or (event is InputEventKey and event.pressed)
			or (event is InputEventJoypadButton and event.pressed)
		):
			_restart_run()
		return

	if _pause_screen.visible:
		if event.is_action_pressed("fire"):
			_restart_run()
			return
		if event.is_action_pressed("pause"):
			_toggle_pause()
		return

	if event.is_action_pressed("pause"):
		_toggle_pause()


func _on_score_changed(score: int) -> void:
	_score_label.text = str(score)


func _on_armor_changed(current: int, _maximum: int) -> void:
	var index := clampi(current, 0, 10)
	if index < _health_textures.size():
		_health_bar.texture = _health_textures[index]


func _on_power_changed(current: float, maximum: float) -> void:
	var max_val := maximum if maximum > 0.0 else float(POWER_PER_LEVEL * POWER_BAR_MAX_INDEX)
	var index := clampi(floori((current / max_val) * POWER_BAR_MAX_INDEX), 0, POWER_BAR_MAX_INDEX)
	if index < _power_textures.size():
		_power_bar.texture = _power_textures[index]


func _on_combo_changed(combo: int) -> void:
	_update_combo_label(combo)


func _update_combo_label(combo: int) -> void:
	if _combo_label == null:
		return
	if combo < min_combo_to_show:
		_hide_combo_animated()
		return

	var first_show := not _combo_label.visible
	_combo_label.text = "HIT x%d" % combo
	_apply_combo_label_color(combo)
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

	var flash_modulate := Color(1.35, 1.35, 1.35, 1.0)
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
		_combo_tween.tween_property(_combo_label, "modulate", flash_modulate, pop_in * 0.65)
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


func _combo_tier_color(combo: int) -> Color:
	if combo >= 25:
		return Color(1.0, 1.0, 1.0, 1.0)
	if combo >= 20:
		return Color(1.0, 0.28, 0.22, 1.0)
	if combo >= 15:
		return Color(0.35, 0.72, 1.0, 1.0)
	if combo >= 10:
		return Color(0.32, 1.0, 0.42, 1.0)
	if combo >= 5:
		return Color(1.0, 0.9, 0.18, 1.0)
	return Color(0.72, 0.38, 1.0, 1.0)


func _apply_combo_label_color(combo: int) -> void:
	if _combo_label_settings == null:
		return
	_combo_label_settings.font_color = _combo_tier_color(combo)
	_combo_label.label_settings = _combo_label_settings
