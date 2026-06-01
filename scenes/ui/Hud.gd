extends CanvasLayer

@onready var _health_bar: ProgressBar = %HealthBar
@onready var _shield_bar: ProgressBar = %ShieldBar
@onready var _energy_bar: ProgressBar = %EnergyBar
@onready var _health_label: Label = %HealthValue
@onready var _shield_label: Label = %ShieldValue
@onready var _energy_label: Label = %EnergyValue
@onready var _shield_row: HBoxContainer = %ShieldRow

var _player: CharacterBody3D
var _shield_system: Node


func _ready() -> void:
	call_deferred("_bind_player")


func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _player:
		_shield_system = _player.get_node_or_null("ShieldSystem")


func _process(_delta: float) -> void:
	if _player == null:
		_bind_player()
		return

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

	var max_pwr := maxf(1.0, _player.power_max)
	var pwr := clampf(_player.power, 0.0, max_pwr)
	_energy_bar.max_value = max_pwr
	_energy_bar.value = pwr
	_energy_label.text = "%d / %d" % [int(roundf(pwr)), int(roundf(max_pwr))]
