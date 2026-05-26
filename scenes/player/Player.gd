extends CharacterBody3D  # 1. Zmiana na 3D

# --- Loadout (konfiguracja w inspektorze) ---
# --- KADŁUB (SHIP) ---
@export var ship_id: int = 2

# --- BROŃ PRZEDNIA (FRONT WEAPON) ---
@export var front_weapon_index: int = 2
@export var front_power_level: int = 1

# --- BROŃ TYLNA (REAR WEAPON) ---
@export var rear_weapon_index: int = 1
@export var rear_power_level: int = 1

# --- SYSTEMY ENERGII ---
@export var generator_id: int = 1
@export var shield_id: int = 1

# --- POMOCNICY (SIDEKICKS) ---
@export var left_sidekick_id: int = 0
@export var right_sidekick_id: int = 0
@export var sidekick_level: int = 1

# --- ZASOBY (RESOURCES) ---
@export var credits: int = 1000
@export var score: int = 0

# --- Zmienne dynamiczne ---
var armor: int = 0
var max_armor: int = 0

# --- Systemy energii (Power) ---
var power: float = 900.0
var power_max: float = 900.0
var power_add: float = 0.0

var ship_data: ShipData = null

# --- 2. Ograniczenia ruchu w świecie 3D (Zamiast 1080x1920) ---
# Dostosuj te wartości w inspektorze, aby statek nie wylatywał poza pole widzenia kamery
@export var max_bound_x: float = 14.0
@export var max_bound_z: float = 22.0

# --- Systemy (child nodes) ---
@onready var weapon_system: Node = $WeaponSystem
@onready var damage_system: Node = $DamageSystem
@onready var shield_system: Node = $ShieldSystem

# 3. Model jest teraz bezpośrednim dzieckiem Node3D
@onready var ship_model: Node3D = $PlayerModel

# Do sterowania myszką potrzebujemy dostępu do aktywnej kamery
var main_camera: Camera3D

# ============================================================================
# 1. INICJALIZACJA
# ============================================================================

func _ready():
	add_to_group("player")
	# W 3D używamy collision_layer/mask jako bitów (np. 1 dla gracza)
	collision_layer = 1
	collision_mask  = 0
	
	# Łapiemy kamerę z drzewa sceny
	main_camera = get_viewport().get_camera_3d()
	
	load_ship_data()
	apply_ship_stats()
	init_power_regeneration()
	
func load_ship_data():
	var s_id = ship_id
	ship_data = DataManager.get_ship_by_id(s_id)
	if ship_data:
		print("Player: Statek załadowany: ", ship_data.ship_name)
	else:
		push_error("Player: BŁĄD: Nie znaleziono danych dla statku o ID: " + str(s_id))

func apply_ship_stats():
	armor = ship_data.armor if ship_data else 10
	max_armor = armor
	print("Player: Ship → armor=", armor)

func init_power_regeneration():
	var generator_power = DataManager.get_generator_power(generator_id)
	power_add = generator_power
	print("Player: Generator ID=", generator_id, " power=", generator_power, " → power_add=", power_add)

# ============================================================================
# 2. RUCH I INPUT
# ============================================================================

func _physics_process(delta: float):
	power = min(power_max, power + power_add * delta)
	
	var prev_x: float = global_position.x
	
	# --- 4. Ruch za myszką w przestrzeni 3D ---
	var mouse_pos_3d = _get_mouse_world_position()
	if mouse_pos_3d != Vector3.ZERO:
		# Przypisujemy pozycję myszy, ale blokujemy oś Y na 0, żeby statek nie latał w górę i w dół
		global_position.x = mouse_pos_3d.x
		global_position.z = mouse_pos_3d.z
	
	_clamp_to_screen()
	
	weapon_system.set_firing(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	
	# Obliczamy różnicę pozycji X do efektu przechyłu samolotu
	_update_tilt(global_position.x - prev_x, delta)

func _update_tilt(dx: float, delta: float) -> void:
	# W 3D ruch lewo/prawo to X, więc obracamy wokół osi Z (roll), aby samolot kładł się na skrzydło
	var target: float = clampf(-dx * 1.5, -0.8, 0.8)
	ship_model.rotation.z = lerpf(ship_model.rotation.z, target, delta * 10.0) 

func _clamp_to_screen():
	# Blokujemy pozycję w granicach świata 3D
	global_position.x = clamp(global_position.x, -max_bound_x, max_bound_x)
	global_position.z = clamp(global_position.z, -max_bound_z, max_bound_z)

# --- Funkcja pomocnicza: rzutowanie myszy z ekranu 2D w przestrzeń 3D ---
func _get_mouse_world_position() -> Vector3:
	if not main_camera:
		main_camera = get_viewport().get_camera_3d()
		if not main_camera: return Vector3.ZERO
		
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = main_camera.project_ray_origin(mouse_pos)
	var ray_direction = main_camera.project_ray_normal(mouse_pos)
	
	# Tworzymy matematyczną płaszczyznę na wysokości Y = 0 (tam gdzie lata gracz)
	var plane = Plane(Vector3.UP, 0.0)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	
	if intersection != null:
		return intersection
	return Vector3.ZERO

# ============================================================================
# 3. DEBUG
# ============================================================================

func take_damage(amount: int) -> void:
	armor -= amount
	if armor <= 0:
		die()
	else:
		SoundManager.play_sound(3)

func die() -> void:
	queue_free()

func _process(_delta):
	if Input.is_action_just_pressed("ui_home"):
		print("Player: --- DEBUG GRACZA ---")
		print("Player: Statek ID: ", ship_id)
		print("Player: Pozycja 3D: ", global_position)
		print("Player: Pancerz: ", armor, "/", max_armor)
