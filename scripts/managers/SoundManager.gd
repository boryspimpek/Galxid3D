extends Node

const SOUND_DIR = "res://data/extracted_sounds/"

var _weapon_player: AudioStreamPlayer   # kanał broni - restartuje przy każdym strzale
var _impact_player: AudioStreamPlayer   # kanał eksplozji/dużych efektów - niezależny
var _hit_player: AudioStreamPlayer      # kanał trafień (osobny bus do ściszania)
var _cache: Dictionary = {}      # sound_id -> AudioStream or null
var _path_map: Dictionary = {}   # sound_id -> file path

## Minimalny odstęp między dźwiękami trafień (ms) — tłumi spam przy salwach wielopociskowych.
const HIT_SOUND_MIN_INTERVAL_MS := 90
var _last_hit_sound_ms: int = -HIT_SOUND_MIN_INTERVAL_MS

func _ready():
	_weapon_player = AudioStreamPlayer.new()
	_weapon_player.bus = "Weapons"
	add_child(_weapon_player)
	_impact_player = AudioStreamPlayer.new()
	_impact_player.bus = "Explosions"
	add_child(_impact_player)
	_hit_player = AudioStreamPlayer.new()
	_hit_player.bus = "Impacts"
	add_child(_hit_player)
	_scan_sounds()

func _scan_sounds():
	# Pre-defined sound paths for better Android compatibility
	_path_map = {
		1: SOUND_DIR + "001_S_WEAPON_1.wav",
		2: SOUND_DIR + "002_S_WEAPON_2.wav",
		3: SOUND_DIR + "003_S_ENEMY_HIT.wav",
		4: SOUND_DIR + "004_S_EXPLOSION_4.wav",
		5: SOUND_DIR + "005_S_WEAPON_5.wav",
		6: SOUND_DIR + "006_S_WEAPON_6.wav",
		7: SOUND_DIR + "007_S_WEAPON_7.wav",
		8: SOUND_DIR + "008_S_SELECT_EXPLOSION_8.wav",
		9: SOUND_DIR + "009_S_EXPLOSION_9.wav",
		10: SOUND_DIR + "010_S_WEAPON_10.wav",
		11: SOUND_DIR + "011_S_EXPLOSION_11.wav",
		12: SOUND_DIR + "012_S_EXPLOSION_12.wav",
		13: SOUND_DIR + "013_S_WEAPON_13.wav",
		14: SOUND_DIR + "014_S_WEAPON_14.wav",
		15: SOUND_DIR + "015_S_WEAPON_15.wav",
		16: SOUND_DIR + "016_S_SPRING.wav",
		17: SOUND_DIR + "017_S_WARNING.wav",
		18: SOUND_DIR + "018_S_ITEM.wav",
		19: SOUND_DIR + "019_S_HULL_HIT.wav",
		20: SOUND_DIR + "020_S_MACHINE_GUN.wav",
		21: SOUND_DIR + "021_S_SOUL_OF_ZINGLON.wav",
		22: SOUND_DIR + "022_S_EXPLOSION_22.wav",
		23: SOUND_DIR + "023_S_CLINK.wav",
		24: SOUND_DIR + "024_S_CLICK.wav",
		25: SOUND_DIR + "025_S_WEAPON_25.wav",
		26: SOUND_DIR + "026_S_WEAPON_26.wav",
		27: SOUND_DIR + "027_S_SHIELD_HIT.wav",
		28: SOUND_DIR + "028_S_CURSOR.wav",
		29: SOUND_DIR + "029_S_POWERUP.wav",
	}
	print("SoundManager: Załadowano ", _path_map.size(), " ścieżek dźwiękowych")

func play_weapon_sound(sound_id: int) -> void:
	_play_on(_weapon_player, sound_id)

func play_sound(sound_id: int) -> void:
	_play_on(_impact_player, sound_id)

func play_hit_sound(sound_id: int) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_hit_sound_ms < HIT_SOUND_MIN_INTERVAL_MS:
		return
	_last_hit_sound_ms = now
	_play_on(_hit_player, sound_id)

func _play_on(player: AudioStreamPlayer, sound_id: int) -> void:
	if sound_id <= 0:
		return
	if not _cache.has(sound_id):
		_cache[sound_id] = _load_stream(sound_id)
	var stream = _cache[sound_id]
	if stream == null:
		return
	player.stream = stream
	player.play()

func _load_stream(sound_id: int) -> AudioStream:
	var path = _path_map.get(sound_id, "")
	if path == "":
		push_warning("SoundManager: brak pliku dla sound_id=", sound_id)
		return null
	return load(path) as AudioStream
