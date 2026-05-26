extends Node

# Singleton - DataManager do centralnego ładowania i cache'owania danych JSON

# Preload resource classes
const WeaponDataClass = preload("res://scripts/resources/WeaponData.gd")

# Cache danych
var ships_cache: Array = []
var weapons_cache: Array = []
var shields_cache: Array = []
var generators_cache: Array = []

# Flaga ładowania
var _ships_loaded: bool = false
const SHIPS_DIR = "res://data/ships/"
var _weapons_loaded: bool = false
const WEAPONS_DIR = "res://data/weapons/"
var _shields_loaded: bool = false
const SHIELDS_DIR = "res://data/shields/"
var _generators_loaded: bool = false
const GENERATORS_DIR = "res://data/generators/"

# ============================================================================
# PRELOAD — wszystko ładowane przy starcie, żeby uniknąć czkawek w grze
# ============================================================================

func _ready():
	get_ships()
	get_weapons()
	get_shields()
	get_generators()

# ============================================================================
# STATKI (ships/*.tres)
# ============================================================================

func get_ships() -> Array:
	if not _ships_loaded:
		var dir = DirAccess.open(SHIPS_DIR)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var res = load(SHIPS_DIR + file_name) as ShipData
					if res:
						ships_cache.append(res)
				file_name = dir.get_next()
			dir.list_dir_end()
			ships_cache.sort_custom(func(a, b): return a.ship_index < b.ship_index)
		_ships_loaded = true
		print("DataManager: Załadowano ", ships_cache.size(), " statków")
	return ships_cache

func get_ship_by_id(id: int) -> ShipData:
	for ship in get_ships():
		if ship.ship_index == id:
			return ship
	push_error("DataManager: Nie znaleziono statku o ID=", id)
	return null

# ============================================================================
# BRONIE (weapons/*.tres - uproszczona wersja 3D)
# ============================================================================

func get_weapons() -> Array:
	if not _weapons_loaded:
		var dir = DirAccess.open(WEAPONS_DIR)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var res = load(WEAPONS_DIR + file_name) as WeaponDataClass
					if res:
						weapons_cache.append(res)
				file_name = dir.get_next()
			dir.list_dir_end()
			weapons_cache.sort_custom(func(a, b): return a.weapon_index < b.weapon_index)
		_weapons_loaded = true
		print("DataManager: Załadowano ", weapons_cache.size(), " broni")
	return weapons_cache

func get_weapon_by_id(id: int) -> WeaponDataClass:
	for weapon in get_weapons():
		if weapon.weapon_index == id:
			return weapon
	push_error("DataManager: Nie znaleziono broni o ID=", id)
	return null

func get_weapon_power_use(weapon_index: int) -> int:
	var weapon = get_weapon_by_id(weapon_index)
	if weapon:
		return weapon.power_use
	return 0

# ============================================================================
# TARCZE (shields/*.tres)
# ============================================================================

func get_shields() -> Array:
	if not _shields_loaded:
		var dir = DirAccess.open(SHIELDS_DIR)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var res = load(SHIELDS_DIR + file_name) as ShieldData
					if res:
						shields_cache.append(res)
				file_name = dir.get_next()
			dir.list_dir_end()
			shields_cache.sort_custom(func(a, b): return a.shield_index < b.shield_index)
		_shields_loaded = true
		print("DataManager: Załadowano ", shields_cache.size(), " tarcz")
	return shields_cache

func get_shield_by_id(id: int) -> ShieldData:
	for shield in get_shields():
		if shield.shield_index == id:
			return shield
	push_error("DataManager: Nie znaleziono tarczy o ID=", id)
	return null

# ============================================================================
# GENERATORY (generators/*.tres)
# ============================================================================

func get_generators() -> Array:
	if not _generators_loaded:
		var dir = DirAccess.open(GENERATORS_DIR)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var res = load(GENERATORS_DIR + file_name) as GeneratorData
					if res:
						generators_cache.append(res)
				file_name = dir.get_next()
			dir.list_dir_end()
			generators_cache.sort_custom(func(a, b): return a.generator_index < b.generator_index)
		_generators_loaded = true
		print("DataManager: Załadowano ", generators_cache.size(), " generatorów")
	return generators_cache

func get_generator_by_id(id: int) -> GeneratorData:
	for generator in get_generators():
		if generator.generator_index == id:
			return generator
	push_error("DataManager: Nie znaleziono generatora o ID=", id)
	return null

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
	
	_ships_loaded = false
	_weapons_loaded = false
	_shields_loaded = false
	_generators_loaded = false
	
	print("DataManager: Cache wyczyszczony")
