extends Node

# ============================================================================
# WEAPON SYSTEM - Logika strzelania
# ============================================================================

# Preload resource class
const WeaponDataClass = preload("res://scripts/resources/WeaponData.gd")

# --- Referencje ---
var player: CharacterBody3D
var muzzle: Marker3D

# --- Dane broni (proste) ---
var weapon_data: WeaponDataClass
var current_weapon_index: int = 1

# --- Konfiguracja strzelania ---
var fire_timer: float = 0.0
var is_firing: bool = false
var _ready_to_fire: bool = false

func _ready():
	player = get_parent()
	muzzle = player.get_node("Muzzle")
	await get_tree().process_frame
	load_weapon_config()
	_ready_to_fire = true

func _physics_process(delta: float):
	if not _ready_to_fire:
		return
	fire_timer = max(0.0, fire_timer - delta)
	if is_firing and fire_timer <= 0.0:
		shoot()
		
func load_weapon_config():
	current_weapon_index = player.front_weapon_index
	print("WeaponSystem: próbuję załadować broń ID=", current_weapon_index)
	
	weapon_data = DataManager.get_weapon_by_id(current_weapon_index)
	
	if weapon_data == null:
		push_error("WeaponSystem: Nie znaleziono broni o ID: ", current_weapon_index)
	else:
		print("WeaponSystem: Załadowano broń - weapon_id=", current_weapon_index)

func set_firing(firing: bool):
	is_firing = firing

func shoot():
	# Zabezpieczenie - jeśli brak danych broni, spróbuj załadować ponownie
	if weapon_data == null:
		push_error("WeaponSystem: weapon_data jest null, próbuję załadować ponownie...")
		load_weapon_config()
		if weapon_data == null:
			return  # nadal null - rezygnujemy
	
	var power_level_data = weapon_data.get_power_level_data(player.front_power_level)
	var power_use = power_level_data.power_use
	if player.power < power_use:
		return
	
	player.power -= power_use
	
	create_projectile(power_level_data.damage, power_level_data.velocity)
	SoundManager.play_weapon_sound(weapon_data.sound)
	fire_timer = power_level_data.fire_rate

func create_projectile(damage: int, velocity: Vector3):
	var projectile_scene = GameConstants.player_projectile_scene
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.velocity = velocity
	projectile.damage = damage
