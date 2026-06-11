extends CanvasLayer

@export var show_fps: bool = true
@export var panel_width: float = 300.0:
	set(value):
		panel_width = maxf(180.0, value)
		_apply_panel_width()

@onready var _side_panel: PanelContainer = $Root/SidePanel
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _shield_bar: ProgressBar = %ShieldBar
@onready var _energy_bar: ProgressBar = %EnergyBar
@onready var _health_label: Label = %HealthValue
@onready var _shield_label: Label = %ShieldValue
@onready var _energy_label: Label = %EnergyValue
@onready var _score_label: Label = %ScoreValue
@onready var _shield_row: VBoxContainer = %ShieldRow
@onready var _restart_button: Button = %RestartButton
@onready var _restart_confirm: Control = %RestartConfirm
@onready var _game_over: Control = %GameOver
@onready var _fps_label: Label = %FpsLabel

var _player: CharacterBody3D
var _shield_system: Node


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_panel_width()
	_restart_button.pressed.connect(_on_restart_button_pressed)
	%RestartConfirmYes.pressed.connect(_restart_run)
	%RestartConfirmNo.pressed.connect(_hide_restart_confirm)
	%GameOverRestartButton.pressed.connect(_restart_run)
	call_deferred("_bind_player")
	call_deferred("_enable_game_viewport_render_timing")


func _enable_game_viewport_render_timing() -> void:
	var vp := get_tree().get_first_node_in_group("game_viewport") as SubViewport
	if vp:
		RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)


func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _player:
		_shield_system = _player.get_node_or_null("ShieldSystem")


func _apply_panel_width() -> void:
	if not is_node_ready() or _side_panel == null:
		return
	_side_panel.offset_left = -panel_width


func show_game_over() -> void:
	_hide_restart_confirm()
	_restart_button.visible = false
	_game_over.visible = true
	get_tree().paused = true


func _on_restart_button_pressed() -> void:
	_show_restart_confirm()


func _show_restart_confirm() -> void:
	_restart_confirm.visible = true
	get_tree().paused = true


func _hide_restart_confirm() -> void:
	_restart_confirm.visible = false
	if not _game_over.visible:
		get_tree().paused = false


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if _restart_confirm.visible:
		return
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


func _process(delta: float) -> void:
	_update_fps(delta)

	if _player == null:
		_bind_player()
		return

	_score_label.text = str(_player.score)

	var max_hp := maxi(1, _player.max_armor)
	var hp := clampi(_player.armor, 0, max_hp)
	_health_bar.max_value = max_hp
	_health_bar.value = hp
	_health_label.text = "%d / %d" % [hp, max_hp]

	if _shield_system:
		var max_sh := maxf(1.0, float(_shield_system.shield_max))
		var sh := clampf(float(_shield_system.shield), 0.0, max_sh)
		_shield_bar.max_value = max_sh
		_shield_bar.value = sh
		_shield_label.text = "%d / %d" % [int(roundf(sh)), int(roundf(max_sh))]
		_shield_row.visible = float(_shield_system.shield_max) > 0.0

	var max_pwr := maxf(1.0, float(_player.max_power))
	var pwr := clampf(_player.power, 0.0, max_pwr)
	_energy_bar.max_value = max_pwr
	_energy_bar.value = pwr
	_energy_label.text = "%d / %d" % [int(roundf(pwr)), int(roundf(max_pwr))]


func _update_fps(delta: float) -> void:
	if _fps_label == null:
		return
	_fps_label.visible = show_fps
	if not show_fps:
		return
	var fps := Engine.get_frames_per_second()
	var frame_ms := delta * 1000.0
	var render_ms := _get_game_render_ms()
	var logic_ms := maxf(0.0, frame_ms - render_ms)
	_fps_label.text = "FPS: %d | logika: %.1f ms | gfx: %.1f ms" % [fps, logic_ms, render_ms]


func _get_game_render_ms() -> float:
	var vp := get_tree().get_first_node_in_group("game_viewport") as SubViewport
	if vp == null:
		return 0.0
	var rid := vp.get_viewport_rid()
	# CPU (przygotowanie) + GPU (rysowanie) SubViewport gry — w ms.
	return (
		RenderingServer.viewport_get_measured_render_time_cpu(rid)
		+ RenderingServer.viewport_get_measured_render_time_gpu(rid)
	)
