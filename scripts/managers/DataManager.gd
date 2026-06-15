extends Node

# Cache danych
var ships_cache: Array = []
var weapons_cache: Array = []
var shields_cache: Array = []
var generators_cache: Array = []

const PLAY_AREA_CONFIG_PATH := "res://data/play_area/default.tres"
var play_area_config: PlayAreaConfig

var _loaded: bool = false

func _ready():
	_load_all()

func _load_all():
	if _loaded:
		return
	_loaded = true

	ships_cache = _load_tres_from_dir("res://data/ships", ShipData)
	ships_cache.sort_custom(func(a, b): return a.ship_index < b.ship_index)
	print("DataManager: Załadowano ", ships_cache.size(), " statków")

	weapons_cache = _load_tres_from_dir("res://data/weapons", WeaponData)
	weapons_cache.sort_custom(func(a, b): return a.weapon_index < b.weapon_index)
	print("DataManager: Załadowano ", weapons_cache.size(), " broni")

	shields_cache = _load_tres_from_dir("res://data/shields", ShieldData)
	shields_cache.sort_custom(func(a, b): return a.shield_index < b.shield_index)
	print("DataManager: Załadowano ", shields_cache.size(), " tarcz")

	generators_cache = _load_tres_from_dir("res://data/generators", GeneratorData)
	generators_cache.sort_custom(func(a, b): return a.generator_index < b.generator_index)
	print("DataManager: Załadowano ", generators_cache.size(), " generatorów")

	play_area_config = load(PLAY_AREA_CONFIG_PATH) as PlayAreaConfig
	if play_area_config == null:
		push_error("DataManager: Nie załadowano PlayAreaConfig: ", PLAY_AREA_CONFIG_PATH)


func _load_tres_from_dir(dir_path: String, type) -> Array:
	var cache: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("DataManager: Nie można otworzyć katalogu: ", dir_path)
		return cache

	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var path: String = dir_path.path_join(file_name)
		var res = load(path)
		if res != null and is_instance_of(res, type):
			cache.append(res)

	return cache

func get_ship_by_id(id: int) -> ShipData:
	for ship in ships_cache:
		if ship.ship_index == id:
			return ship
	push_error("DataManager: Nie znaleziono statku o ID=", id)
	return null

func get_weapon_by_id(id: int) -> WeaponData:
	for weapon in weapons_cache:
		if weapon.weapon_index == id:
			return weapon
	push_error("DataManager: Nie znaleziono broni o ID=", id)
	return null

func get_shield_by_id(id: int) -> ShieldData:
	for shield in shields_cache:
		if shield.shield_index == id:
			return shield
	push_error("DataManager: Nie znaleziono tarczy o ID=", id)
	return null

func get_generator_by_id(id: int) -> GeneratorData:
	for generator in generators_cache:
		if generator.generator_index == id:
			return generator
	push_error("DataManager: Nie znaleziono generatora o ID=", id)
	return null

func get_weapon_power_use(weapon_index: int, power_level: int = 1) -> int:
	var weapon = get_weapon_by_id(weapon_index)
	if weapon:
		return weapon.get_power_level_data(power_level).power_use
	return 0

func get_generator_regeneration(generator_id: int) -> float:
	var generator = get_generator_by_id(generator_id)
	return generator.regeneration if generator else 0

func get_generator_power(generator_id: int) -> float:
	var generator = get_generator_by_id(generator_id)
	return generator.power if generator else 0

func get_play_area_config() -> PlayAreaConfig:
	return play_area_config

# ============================================================================
# CZYSZCZENIE CACHE (do debugowania)
# ============================================================================

func clear_cache():
	ships_cache.clear()
	weapons_cache.clear()
	shields_cache.clear()
	generators_cache.clear()
