extends Node

# Cache danych
var ships_cache: Array = []
var weapons_cache: Array = []
var generators_cache: Array = []
var sidekicks_cache: Array = []

const DataCatalogClass = preload("res://scripts/resources/DataCatalog.gd")
const DATA_CATALOG_PATH := "res://data/data_catalog.tres"
const PLAY_AREA_CONFIG_PATH := "res://data/play_area/default.tres"
var play_area_config: PlayAreaConfig

var _loaded: bool = false

func _ready():
	_load_all()

func _load_all():
	if _loaded:
		return
	_loaded = true

	var catalog := load(DATA_CATALOG_PATH) as DataCatalogClass
	if catalog == null:
		push_error("DataManager: Nie załadowano katalogu danych: ", DATA_CATALOG_PATH)
		return

	ships_cache = catalog.ships.duplicate()
	ships_cache.sort_custom(func(a, b): return a.ship_index < b.ship_index)
	print("DataManager: Załadowano ", ships_cache.size(), " statków")

	weapons_cache = catalog.weapons.duplicate()
	weapons_cache.sort_custom(func(a, b): return a.weapon_index < b.weapon_index)
	print("DataManager: Załadowano ", weapons_cache.size(), " broni")

	generators_cache = catalog.generators.duplicate()
	generators_cache.sort_custom(func(a, b): return a.generator_index < b.generator_index)
	print("DataManager: Załadowano ", generators_cache.size(), " generatorów")

	sidekicks_cache = catalog.sidekicks.duplicate()
	sidekicks_cache.sort_custom(func(a, b): return a.sidekick_index < b.sidekick_index)
	print("DataManager: Załadowano ", sidekicks_cache.size(), " sidekicków")

	play_area_config = load(PLAY_AREA_CONFIG_PATH) as PlayAreaConfig
	if play_area_config == null:
		push_error("DataManager: Nie załadowano PlayAreaConfig: ", PLAY_AREA_CONFIG_PATH)

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

func get_generator_by_id(id: int) -> GeneratorData:
	for generator in generators_cache:
		if generator.generator_index == id:
			return generator
	push_error("DataManager: Nie znaleziono generatora o ID=", id)
	return null

func get_sidekick_by_id(id: int) -> Resource:
	for sk in sidekicks_cache:
		if sk.sidekick_index == id:
			return sk
	push_error("DataManager: Nie znaleziono sidekicka o ID=", id)
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

func get_generator_power_per_kill(generator_id: int) -> float:
	var generator = get_generator_by_id(generator_id)
	return generator.power_per_kill if generator else 0.0

func get_play_area_config() -> PlayAreaConfig:
	return play_area_config

# ============================================================================
# CZYSZCZENIE CACHE (do debugowania)
# ============================================================================

func clear_cache():
	ships_cache.clear()
	weapons_cache.clear()
	generators_cache.clear()
	sidekicks_cache.clear()
