extends Node

# ============================================================================
# WEAPON SYSTEM - Logika strzelania (uproszczona wersja 3D)
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

func _ready():
	player = get_parent()
	muzzle = player.get_node("Muzzle")
	
	# Załaduj konfigurację broni
	load_weapon_config()

func _physics_process(delta: float):
	fire_timer = max(0.0, fire_timer - delta)
	if is_firing and fire_timer <= 0.0:
		shoot()

func load_weapon_config():
	current_weapon_index = player.front_weapon_index
	
	# Pobierz dane broni z resources (uproszczone)
	weapon_data = DataManager.get_weapon_by_id(current_weapon_index)
	
	if weapon_data == null:
		push_error("WeaponSystem: Nie znaleziono broni o ID: ", current_weapon_index)
	else:
		print("WeaponSystem: Załadowano broń - weapon_id=", current_weapon_index)

func set_firing(firing: bool):
	is_firing = firing

func shoot():
	var power_use = DataManager.get_weapon_power_use(current_weapon_index)
	if player.power < power_use:
		return
	
	player.power -= power_use
	
	# Proste parametry z weapon_data
	var damage = weapon_data.damage
	var velocity = weapon_data.velocity  # do przodu (-Z)

	# Stwórz projectile
	create_projectile(damage, velocity)
	
	SoundManager.play_weapon_sound(weapon_data.sound)

	fire_timer = weapon_data.fire_rate

func create_projectile(damage: int, velocity: Vector3):
	var projectile_scene = GameConstants.player_projectile_scene
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.velocity = velocity
	projectile.damage = damage
