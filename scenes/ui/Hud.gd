extends CanvasLayer

@export var min_combo_to_show: int = 2
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
@onready var _combo_label: Label = %ComboLabel

var _player: CharacterBody3D
var _shield_system: Node
var _player_bound: bool = false


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_panel_width()
	_restart_button.pressed.connect(_on_restart_button_pressed)
	%RestartConfirmYes.pressed.connect(_restart_run)
	%RestartConfirmNo.pressed.connect(_hide_restart_confirm)
	%GameOverRestartButton.pressed.connect(_restart_run)
	HitComboManager.combo_changed.connect(_on_combo_changed)
	_update_combo_label(HitComboManager.combo)
	call_deferred("_bind_player")


func _process(_delta: float) -> void:
	if not _player_bound:
		_bind_player()


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
	_player.power_changed.connect(_on_power_changed)
	if _shield_system:
		_shield_system.shield_changed.connect(_on_shield_changed)

	_refresh_all_stats()
	_player_bound = true
	set_process(false)


func _refresh_all_stats() -> void:
	if _player == null:
		return
	_on_score_changed(_player.score)
	_on_armor_changed(_player.armor, _player.max_armor)
	_on_power_changed(_player.power, _player.max_power)
	if _shield_system:
		_on_shield_changed(_shield_system.shield, _shield_system.shield_max)


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


func _on_score_changed(score: int) -> void:
	_score_label.text = str(score)


func _on_armor_changed(current: int, maximum: int) -> void:
	var max_hp := maxi(1, maximum)
	var hp := clampi(current, 0, max_hp)
	_health_bar.max_value = max_hp
	_health_bar.value = hp
	_health_label.text = "%d / %d" % [hp, max_hp]


func _on_shield_changed(current: float, maximum: float) -> void:
	var max_sh := maxf(1.0, maximum)
	var sh := clampf(current, 0.0, max_sh)
	_shield_bar.max_value = max_sh
	_shield_bar.value = sh
	_shield_label.text = "%d / %d" % [int(roundf(sh)), int(roundf(max_sh))]
	_shield_row.visible = maximum > 0.0


func _on_power_changed(current: float, maximum: float) -> void:
	var max_pwr := maxf(1.0, maximum)
	var pwr := clampf(current, 0.0, max_pwr)
	_energy_bar.max_value = max_pwr
	_energy_bar.value = pwr
	_energy_label.text = "%d / %d" % [int(roundf(pwr)), int(roundf(max_pwr))]


func _on_combo_changed(combo: int) -> void:
	_update_combo_label(combo)


func _update_combo_label(combo: int) -> void:
	if _combo_label == null:
		return
	if combo < min_combo_to_show:
		_combo_label.visible = false
		return
	_combo_label.visible = true
	_combo_label.text = "COMBO x%d" % combo
