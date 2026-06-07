class_name WeaponData
extends Resource

const POWER_LEVEL_COUNT := 10

@export_group("Combat")
@export var weapon_index: int = 1
@export var weapon_name: String = "Pulse Cannon"
@export var power_level_1: WeaponPowerLevelData
@export var power_level_2: WeaponPowerLevelData
@export var power_level_3: WeaponPowerLevelData
@export var power_level_4: WeaponPowerLevelData
@export var power_level_5: WeaponPowerLevelData
@export var power_level_6: WeaponPowerLevelData
@export var power_level_7: WeaponPowerLevelData
@export var power_level_8: WeaponPowerLevelData
@export var power_level_9: WeaponPowerLevelData
@export var power_level_10: WeaponPowerLevelData

@export_group("Audio")
@export var sound: int = 1


func _init() -> void:
	_ensure_power_levels()


func _ensure_power_levels() -> void:
	if power_level_1 == null:
		power_level_1 = WeaponPowerLevelData.new()
	if power_level_2 == null:
		power_level_2 = WeaponPowerLevelData.new()
	if power_level_3 == null:
		power_level_3 = WeaponPowerLevelData.new()
	if power_level_4 == null:
		power_level_4 = WeaponPowerLevelData.new()
	if power_level_5 == null:
		power_level_5 = WeaponPowerLevelData.new()
	if power_level_6 == null:
		power_level_6 = WeaponPowerLevelData.new()
	if power_level_7 == null:
		power_level_7 = WeaponPowerLevelData.new()
	if power_level_8 == null:
		power_level_8 = WeaponPowerLevelData.new()
	if power_level_9 == null:
		power_level_9 = WeaponPowerLevelData.new()
	if power_level_10 == null:
		power_level_10 = WeaponPowerLevelData.new()


func get_power_level_data(level: int) -> WeaponPowerLevelData:
	_ensure_power_levels()
	match clampi(level, 1, POWER_LEVEL_COUNT):
		1: return power_level_1
		2: return power_level_2
		3: return power_level_3
		4: return power_level_4
		5: return power_level_5
		6: return power_level_6
		7: return power_level_7
		8: return power_level_8
		9: return power_level_9
		_: return power_level_10
