class_name WeaponData
extends Resource

const POWER_LEVEL_COUNT := 10
const COMBO_SHOT_COUNT := 5
## Próg combo dla combo_shot_N = N * COMBO_SHOT_KILL_COMBO_STEP (5 → 10 → 15 → 20 → 25).
const COMBO_SHOT_KILL_COMBO_STEP := 5

@export_group("Combat")
@export var weapon_index: int = 100
@export var weapon_name: String = "Name not set"
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
## Opcjonalne strzały combo — ten sam input; wyższy slot wymaga większego kill combo.
@export var combo_shot_1: WeaponComboShotData
@export var combo_shot_2: WeaponComboShotData
@export var combo_shot_3: WeaponComboShotData
@export var combo_shot_4: WeaponComboShotData
@export var combo_shot_5: WeaponComboShotData

@export_group("Visual")
## Efekt przy lufie — przeciągnij scenę muzzle flash z FileSystem.
@export var muzzle_flash_scene: PackedScene
## Dodatkowy obrót efektu (stopnie), gdy asset wymaga korekty osi.
@export var muzzle_flash_rotation_offset: Vector3 = Vector3.ZERO

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


func get_combo_shot(slot: int) -> WeaponComboShotData:
	match clampi(slot, 1, COMBO_SHOT_COUNT):
		1: return combo_shot_1
		2: return combo_shot_2
		3: return combo_shot_3
		4: return combo_shot_4
		_: return combo_shot_5


func get_combo_shot_kill_threshold(slot: int) -> int:
	return clampi(slot, 1, COMBO_SHOT_COUNT) * COMBO_SHOT_KILL_COMBO_STEP


func has_combo_shot() -> bool:
	for slot in range(1, COMBO_SHOT_COUNT + 1):
		var shot := get_combo_shot(slot)
		if shot != null and shot.enabled:
			return true
	return false


func get_best_available_combo_shot(kill_combo: int) -> WeaponComboShotData:
	var best: WeaponComboShotData = null
	var best_slot := 0
	for slot in range(1, COMBO_SHOT_COUNT + 1):
		var shot := get_combo_shot(slot)
		if shot == null or not shot.enabled:
			continue
		if kill_combo < get_combo_shot_kill_threshold(slot):
			continue
		if slot > best_slot:
			best = shot
			best_slot = slot
	return best


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
