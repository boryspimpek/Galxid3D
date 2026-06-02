extends CharacterBody3D

# --- Loadout ---
@export var ship_id: int = 2
@export var front_weapon_index: int = 2
@export var front_power_level: int = 1
@export var rear_weapon_index: int = 1
@export var rear_power_level: int = 1
@export var generator_id: int = 1
@export var shield_id: int = 1
@export var left_sidekick_id: int = 0
@export var right_sidekick_id: int = 0
@export var sidekick_level: int = 1
@export var credits: int = 1000
@export var score: int = 0

var armor: int = 0
var max_armor: int = 0
var power: float = 900.0
var power_max: float = 900.0
var power_add: float = 0.0
var ship_data: ShipData = null

@export var max_bound_x: float = 11.7
@export var max_bound_z: float = 15.25

@onready var weapon_system: Node = $WeaponSystem
@onready var damage_system: Node = $DamageSystem
@onready var shield_system: Node = $ShieldSystem
@onready var ship_model: Node3D = $PlayerModel

var main_camera: Camera3D

# ── NOWE zmienne dotykowe ──────────────────────────────────────────
var touch_target := Vector3.ZERO   # ostatnia pozycja palca w świecie 3D
var is_firing    := false           # czy palec jest przyciśnięty

# ============================================================================
# 1. INICJALIZACJA
# ============================================================================

func _ready():
	add_to_group("player")
	collision_layer = 1
	collision_mask  = 0
	main_camera = get_viewport().get_camera_3d()
	await get_tree().process_frame
	load_ship_data()
	apply_ship_stats()
	init_power_regeneration()

func load_ship_data():
	var s_id = ship_id
	ship_data = DataManager.get_ship_by_id(s_id)
	if ship_data:
		print("Player: Statek załadowany: ", ship_data.ship_name, " Armor: ", ship_data.armor)
	else:
		push_error("Player: BŁĄD: Nie znaleziono danych dla statku o ID: " + str(s_id))

func apply_ship_stats():
	armor = ship_data.armor if ship_data else 10
	max_armor = armor

func init_power_regeneration():
	var generator_power = DataManager.get_generator_power(generator_id)
	power_add = generator_power

# ============================================================================
# 2. INPUT — mysz I dotyk w jednym miejscu
# ============================================================================

func _unhandled_input(event: InputEvent) -> void:
	# ── Dotyk (tablet / telefon) ──
	if event is InputEventScreenTouch:
		is_firing = event.pressed
		if event.pressed:
			var pos = _screen_to_world(event.position)
			if pos != Vector3.ZERO:
				touch_target = pos

	elif event is InputEventScreenDrag:
		var pos = _screen_to_world(event.position)
		if pos != Vector3.ZERO:
			touch_target = pos

	# ── Mysz (PC / One-Click Deploy w przeglądarce) ──
	elif event is InputEventMouseButton:
		is_firing = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	elif event is InputEventMouseMotion:
		var pos = _screen_to_world(get_viewport().get_mouse_position())
		if pos != Vector3.ZERO:
			touch_target = pos

# Pomocnik: rzut ekran → płaszczyzna Y=0
func _screen_to_world(screen_pos: Vector2) -> Vector3:
	if not main_camera:
		main_camera = get_viewport().get_camera_3d()
		if not main_camera: return Vector3.ZERO
	var ray_origin    = main_camera.project_ray_origin(screen_pos)
	var ray_direction = main_camera.project_ray_normal(screen_pos)
	var plane         = Plane(Vector3.UP, 0.0)
	var hit           = plane.intersects_ray(ray_origin, ray_direction)
	return hit if hit != null else Vector3.ZERO

# ============================================================================
# 3. FIZYKA
# ============================================================================

func _physics_process(delta: float):
	power = min(power_max, power + power_add * delta)

	var prev_x: float = global_position.x

	if touch_target != Vector3.ZERO:
		global_position.x = touch_target.x
		global_position.z = touch_target.z

	_clamp_to_screen()
	weapon_system.set_firing(is_firing)
	_update_tilt(global_position.x - prev_x, delta)

func _update_tilt(dx: float, delta: float) -> void:
	var target: float = clampf(-dx * 1.5, -0.8, 0.8)
	ship_model.rotation.z = lerpf(ship_model.rotation.z, target, delta * 10.0)

func _clamp_to_screen():
	global_position.x = clamp(global_position.x, -max_bound_x, max_bound_x)
	global_position.z = clamp(global_position.z, -max_bound_z, max_bound_z)

# ============================================================================
# 4. OBRAŻENIA / ŚMIERĆ / DEBUG
# ============================================================================

func take_damage(amount: int) -> void:
	armor -= amount
	if armor <= 0:
		die()
	else:
		# 019_S_HULL_HIT.wav
		SoundManager.play_hit_sound(4)

func die() -> void:
	queue_free()

func _process(_delta):
	if Input.is_action_just_pressed("ui_home"):
		print("Player: --- DEBUG GRACZA ---")
		print("Player: Statek ID: ", ship_id)
		print("Player: Pozycja 3D: ", global_position)
		print("Player: Pancerz: ", armor, "/", max_armor)
