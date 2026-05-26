extends Area3D

# --- KLASY I ZASOBY ---
const EnemyWeaponDataClass = preload("res://scripts/resources/EnemyWeaponData.gd")

# --- ZMIENNE EKSPORTOWANE (@EXPORT) ---
@export_group("Statystyki")
@export var armor: int = 1
@export var weapon_index: int = 1

@export_group("Ruch Bazowy")
@export var xmove: int = 0
@export var ymove: int = 0
@export var zmove: int = 0

# --- REFERENCJE WĘZŁÓW (@ONREADY) ---
@onready var ship_model: Node3D = $EnemyModel
@onready var muzzle: Marker3D = $Muzzle

# --- ZMIENNE WEWNĘTRZNE (LOGIKA) ---
var enemy_weapon_data: EnemyWeaponDataClass
var enemy_velocity: Vector3

var fire_timer: float = 0.0
var is_firing: bool = false


# --- METODY WBUDOWANE (LIFECYCLE) ---

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5
	
	enemy_velocity = Vector3(float(xmove), float(ymove), float(zmove))
	load_weapon_config()


func _process(delta: float) -> void:
	# Obsługa strzelania
	fire_timer = max(0.0, fire_timer - delta)
	if is_firing and fire_timer <= 0.0:
		shoot()

	# Aktualizacja pozycji i wyliczenie delty ruchu dla pochylenia
	var prev_x: float = global_position.x
	position += enemy_velocity * delta
	
	var dx: float = global_position.x - prev_x
	_update_tilt(dx, delta)


# --- METODY PRYWATNE / POMOCNICZE ---

func _update_tilt(dx: float, delta: float) -> void:
	var target: float = clampf(-dx * 1.5, -0.8, 0.8)
	ship_model.rotation.z = lerpf(ship_model.rotation.z, target, delta * 10.0)


func load_weapon_config() -> void:
	var weapon_path: String = "res://data/enemy_weapons/weapon_%d.tres" % weapon_index
	enemy_weapon_data = load(weapon_path) as EnemyWeaponDataClass


# --- METODY PUBLICZNE (API) ---

func set_firing(firing: bool) -> void:
	is_firing = firing


func shoot() -> void:
	var damage = enemy_weapon_data.damage
	var velocity = enemy_weapon_data.velocity

	create_projectile(damage, velocity)
	SoundManager.play_weapon_sound(enemy_weapon_data.sound)

	fire_timer = enemy_weapon_data.fire_rate


func create_projectile(damage: int, velocity: Vector3) -> void:
	var projectile_scene = GameConstants.enemy_projectile_scene
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.velocity = velocity
	projectile.damage = damage