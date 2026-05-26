extends Node

# Preload resource classes
const WeaponDataClass = preload("res://scripts/resources/WeaponData.gd")

# Cache danych
var ships_cache: Array = []
var weapons_cache: Array = []
var shields_cache: Array = []
var generators_cache: Array = []

var _loaded: bool = false

func _ready():
	_load_all()

func _load_all():
	if _loaded:
		return
	_loaded = true

	# --- STATKI --- dodawaj kolejne jeśli masz więcej plików
	var ship_files = [
		"res://data/ships/ship_001.tres",
		"res://data/ships/ship_002.tres",
		"res://data/ships/ship_003.tres",
		"res://data/ships/ship_004.tres",
		"res://data/ships/ship_005.tres",
		"res://data/ships/ship_006.tres",
		"res://data/ships/ship_007.tres",
		"res://data/ships/ship_008.tres",
		"res://data/ships/ship_009.tres",
		"res://data/ships/ship_010.tres",
		"res://data/ships/ship_011.tres",
		"res://data/ships/ship_012.tres",
		"res://data/ships/ship_013.tres",
	]
	for path in ship_files:
		if ResourceLoader.exists(path):
			var res = load(path) as ShipData
			if res:
				ships_cache.append(res)
	ships_cache.sort_custom(func(a, b): return a.ship_index < b.ship_index)
	print("DataManager: Załadowano ", ships_cache.size(), " statków")

	# --- BRONIE ---
	var weapon_files = [
		"res://data/weapons/weapon_1.tres",
		"res://data/weapons/weapon_2.tres",
		"res://data/weapons/weapon_3.tres",
	]
	for path in weapon_files:
		if ResourceLoader.exists(path):
			var res = load(path) as WeaponDataClass
			if res:
				weapons_cache.append(res)
	weapons_cache.sort_custom(func(a, b): return a.weapon_index < b.weapon_index)
	print("DataManager: Załadowano ", weapons_cache.size(), " broni")

	# --- TARCZE ---
	var shield_files = [
		"res://data/shields/shield_001.tres",
		"res://data/shields/shield_002.tres",
		"res://data/shields/shield_003.tres",
		"res://data/shields/shield_004.tres",
		"res://data/shields/shield_005.tres",
		"res://data/shields/shield_006.tres",
		"res://data/shields/shield_007.tres",
		"res://data/shields/shield_008.tres",
		"res://data/shields/shield_009.tres",
		"res://data/shields/shield_010.tres",
	]
	for path in shield_files:
		if ResourceLoader.exists(path):
			var res = load(path) as ShieldData
			if res:
				shields_cache.append(res)
	shields_cache.sort_custom(func(a, b): return a.shield_index < b.shield_index)
	print("DataManager: Załadowano ", shields_cache.size(), " tarcz")

	# --- GENERATORY ---
	var generator_files = [
		"res://data/generators/generator_001.tres",
		"res://data/generators/generator_002.tres",
		"res://data/generators/generator_003.tres",
		"res://data/generators/generator_004.tres",
		"res://data/generators/generator_005.tres",
		"res://data/generators/generator_006.tres",
	]
	for path in generator_files:
		if ResourceLoader.exists(path):
			var res = load(path) as GeneratorData
			if res:
				generators_cache.append(res)
	generators_cache.sort_custom(func(a, b): return a.generator_index < b.generator_index)
	print("DataManager: Załadowano ", generators_cache.size(), " generatorów")

func get_ship_by_id(id: int) -> ShipData:
	for ship in ships_cache:
		if ship.ship_index == id:
			return ship
	push_error("DataManager: Nie znaleziono statku o ID=", id)
	return null

func get_weapon_by_id(id: int) -> WeaponDataClass:
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

func get_weapon_power_use(weapon_index: int) -> int:
	var weapon = get_weapon_by_id(weapon_index)
	if weapon:
		return weapon.power_use
	return 0

func get_generator_power(generator_id: int) -> float:
	var generator = get_generator_by_id(generator_id)
	return float(generator.power) if generator else 0.0

# ============================================================================
# CZYSZCZENIE CACHE (do debugowania)
# ============================================================================

func clear_cache():
	ships_cache.clear()
	weapons_cache.clear()
	shields_cache.clear()
	generators_cache.clear()
