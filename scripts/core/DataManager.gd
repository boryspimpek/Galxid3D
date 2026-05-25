extends Node

# Singleton - DataManager do centralnego ładowania i cache'owania danych JSON

# Preload resource classes
const WeaponDataClass = preload("res://scripts/resources/WeaponData.gd")

# Cache danych
var ships_cache: Array = []
var enemies_cache: Array = []
var weapons_cache: Array = []
var shields_cache: Array = []
var sidekicks_cache: Array = []
var generators_cache: Array = []

# Flaga ładowania
var _ships_loaded: bool = false
const SHIPS_DIR = "res://data/ships/"
var _enemies_loaded: bool = false
var _weapons_loaded: bool = false
const WEAPONS_DIR = "res://data/weapons/"
var _shields_loaded: bool = false
const SHIELDS_DIR = "res://data/shields/"
var _sidekicks_loaded: bool = false
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
	_scan_weapon_sprites()

# ============================================================================
# PODSTAWOWA FUNKCJA ŁADOWANIA JSON
# ============================================================================

func load_json(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		push_error("DataManager: Plik nie istnieje: " + file_path)
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("DataManager: Błąd JSON w " + file_path + ": " + json.get_error_message())
		return null
	
	return json.get_data()

# ============================================================================
# STATKI (ships.json)
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
# PRZECIWNICY (enemies.json)
# ============================================================================

func get_enemies() -> Array:
	if not _enemies_loaded:
		var data = load_json("res://data/enemies.json")
		if data:
			enemies_cache = data
			_enemies_loaded = true
			print("DataManager: Załadowano ", enemies_cache.size(), " przeciwników")
	return enemies_cache

func get_enemy_by_id(id: int) -> Dictionary:
	for enemy in get_enemies():
		if int(enemy.get("index", -1)) == int(id):
			return enemy
	push_error("DataManager: Nie znaleziono przeciwnika o ID=", id)
	return {}

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
# TARCZE (shields.json)
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
# SIDEKICKS (sidekicks.json)
# ============================================================================

func get_sidekicks() -> Array:
	if not _sidekicks_loaded:
		var data = load_json("res://data/sidekicks.json")
		if data:
			sidekicks_cache = data
			_sidekicks_loaded = true
			print("DataManager: Załadowano ", sidekicks_cache.size(), " sidekicków")
	return sidekicks_cache

func get_sidekick_by_id(id: int) -> Dictionary:
	for sidekick in get_sidekicks():
		if sidekick.get("index", 0) == id:
			return sidekick
	push_error("DataManager: Nie znaleziono sidekicka o ID=", id)
	return {}

# ============================================================================
# GENERATORY (generators.json)
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
	return float(generator.power) * 30.0 if generator else 0.0

# ============================================================================
# SPRITE'Y POCISKÓW (data/weapon_sprites/)
# ============================================================================

var _shot_textures: Dictionary = {}   # sg -> Texture2D
var _shot_sprite_map: Dictionary = {} # "shots_0059.bmp" -> "res://data/weapon_sprites/..."
var _shot_sprites_scanned: bool = false

func _scan_weapon_sprites():
	if _shot_sprites_scanned:
		return
	_shot_sprites_scanned = true
	var dir = DirAccess.open("res://data/weapon_sprites")
	if not dir:
		push_error("DataManager: Nie można otworzyć res://data/weapon_sprites")
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var parts = file_name.split("__")
			if parts.size() > 0:
				var sprite_key = parts[-1]  # np. "shots_0059.bmp"
				_shot_sprite_map[sprite_key] = "res://data/weapon_sprites/" + file_name
		file_name = dir.get_next()
	dir.list_dir_end()
	print("DataManager: Zeskanowano ", _shot_sprite_map.size(), " unikalnych sprite'ów pocisków")

func get_shot_texture_frames(sg: int, anim_count: int) -> Array:
	var frames: Array = []
	for i in range(max(1, anim_count)):
		var tex = get_shot_texture(sg + i)
		if tex:
			frames.append(tex)
	return frames

func get_shot_texture(sg: int) -> Texture2D:
	if _shot_textures.has(sg):
		return _shot_textures[sg]

	_scan_weapon_sprites()

	var effective_sg = sg
	if effective_sg >= 60000:
		return null  # option shapes — nie dotyczy pocisków
	if effective_sg > 1000:
		effective_sg = effective_sg % 1000

	var sprite_key: String
	if effective_sg > 500:
		sprite_key = "shots2_%04d.png" % (effective_sg - 500)
	else:
		sprite_key = "shots_%04d.png" % effective_sg

	var path = _shot_sprite_map.get(sprite_key, "")
	if path == "":
		push_warning("DataManager: Brak sprite'a dla sg=", sg, " (szukano: ", sprite_key, ")")
		_shot_textures[sg] = null
		return null

	var texture = load(path) as Texture2D
	_shot_textures[sg] = texture
	return texture

# ============================================================================
# CZYSZCZENIE CACHE (do debugowania)
# ============================================================================

func clear_cache():
	ships_cache.clear()
	enemies_cache.clear()
	weapons_cache.clear()
	shields_cache.clear()
	sidekicks_cache.clear()
	generators_cache.clear()
	
	_ships_loaded = false
	_enemies_loaded = false
	_weapons_loaded = false
	_shields_loaded = false
	_sidekicks_loaded = false
	_generators_loaded = false
	
	print("DataManager: Cache wyczyszczony")
