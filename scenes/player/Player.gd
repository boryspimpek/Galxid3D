extends CharacterBody3D

# --- Loadout ---
@export var ship_id: int = 1
@export var front_weapon_index: int = 1
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
var regen: float = 0.0
var max_power: float = 0
var power: float = 0
var ship_data: ShipData = null

@export var play_area: PlayAreaConfig
var max_bound_x: float = 40.0
var max_bound_z: float = 20.0
@export var gamepad_move_speed: float = 30.0
@export var gamepad_l2_move_speed: float = 12.0
@export var gamepad_acceleration: float = 70.0
@export var gamepad_deceleration: float = 100.0
@export_range(1.0, 3.0, 0.05) var gamepad_response_exponent: float = 1.4
@export var tilt_velocity_factor: float = 0.025

@export var dodge_depth: float = 1.0
@export var dodge_descend_speed: float = 12.0
@export var dodge_duration: float = 0.4
@export var dodge_ascend_speed: float = 10.0
@export var dodge_cooldown: float = 0.6
@export var dodge_pitch: float = -0.4

enum DodgePhase { GROUNDED, DESCENDING, UNDER, ASCENDING, COOLDOWN }

const PLAYER_COLLISION_LAYER := 1

var is_dodging := false

@onready var weapon_system: Node = $WeaponSystem
@onready var damage_system: Node = $DamageSystem
@onready var shield_system: Node = $ShieldSystem
@onready var ship_model: Node3D = $Blaze

var main_camera: Camera3D

# ── Dotyk: cel w świecie + offset (palec nie musi być nad modelem) ──
var touch_target := Vector3.ZERO
var is_firing := false
var _touch_firing := false
var _touch_grab_offset := Vector3.ZERO  # różnica palec↔statek w momencie dotknięcia
var _gamepad_velocity := Vector2.ZERO
var _dodge_phase: DodgePhase = DodgePhase.GROUNDED
var _dodge_timer: float = 0.0

# ============================================================================
# 1. INICJALIZACJA
# ============================================================================

func _ready():
	add_to_group("player")
	collision_layer = PLAYER_COLLISION_LAYER
	collision_mask  = 0
	main_camera = GameViewportHelper.get_game_camera(get_tree())
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	await get_tree().process_frame
	_apply_play_area_bounds()
	load_ship_data()
	apply_ship_stats()
	init_power_regeneration()
	_log_connected_joypads()

func _resolve_play_area() -> PlayAreaConfig:
	if play_area != null:
		return play_area
	return DataManager.get_play_area_config()


func _apply_play_area_bounds() -> void:
	var area := _resolve_play_area()
	if area == null:
		return
	max_bound_x = area.player_half_x
	max_bound_z = area.player_half_z


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
	var regeneration = DataManager.get_generator_regeneration(generator_id)
	regen = regeneration
	max_power = DataManager.get_generator_power(generator_id)
	power = max_power

func _log_connected_joypads() -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		print("Player: Brak podłączonych padów (joypadów).")
		return
	# print("Player: Wykryto %d pad(ów):" % pads.size())
	for device_id in pads:
		print(
			"  [%d] %s (guid: %s)" % [
				device_id,
				Input.get_joy_name(device_id),
				Input.get_joy_guid(device_id),
			]
		)

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		print(
			"Player: Pad podłączony [%d] %s" % [device_id, Input.get_joy_name(device_id)]
		)
	else:
		print("Player: Pad odłączony [%d]" % device_id)
	_log_connected_joypads()

# ============================================================================
# 2. INPUT — mysz, dotyk i gamepad
# ============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not GameViewportHelper.is_point_in_game_area(get_tree(), event.position):
			return
		_touch_firing = event.pressed
		if event.pressed:
			_begin_relative_touch(event.position)
		else:
			_touch_grab_offset = Vector3.ZERO

	elif event is InputEventScreenDrag:
		if not GameViewportHelper.is_point_in_game_area(get_tree(), event.position):
			return
		_update_relative_touch(event.position)

	elif event is InputEventMouseMotion:
		if not GameViewportHelper.is_point_in_game_area(get_tree(), event.position):
			return
		var pos = _screen_to_world(event.position)
		if pos != Vector3.ZERO:
			touch_target = pos

func _begin_relative_touch(screen_pos: Vector2) -> void:
	var finger_world := _screen_to_world(screen_pos)
	if finger_world == Vector3.ZERO:
		return
	_touch_grab_offset = Vector3(
		finger_world.x - global_position.x,
		0.0,
		finger_world.z - global_position.z
	)
	touch_target = global_position

func _update_relative_touch(screen_pos: Vector2) -> void:
	var finger_world := _screen_to_world(screen_pos)
	if finger_world == Vector3.ZERO:
		return
	touch_target = Vector3(
		finger_world.x - _touch_grab_offset.x,
		0.0,
		finger_world.z - _touch_grab_offset.z
	)

# Pomocnik: rzut ekran → płaszczyzna Y=0 (współrzędne okna głównego → SubViewport gry)
func _screen_to_world(screen_pos: Vector2) -> Vector3:
	return GameViewportHelper.screen_to_world_on_plane(get_tree(), screen_pos, 0.0)

# ============================================================================
# 3. FIZYKA
# ============================================================================

func _physics_process(delta: float):
	power = min(max_power, power + regen * delta)
	_update_dodge(delta)

	var prev_x: float = global_position.x
	var using_touch := false

	var stick := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if stick.length() > 0.0:
		touch_target = Vector3.ZERO
		var deflection := stick.length()
		var curved := pow(deflection, gamepad_response_exponent)
		var active_speed := (
			gamepad_l2_move_speed
			if Input.is_action_pressed("move_l2")
			else gamepad_move_speed
		)
		var target_velocity := stick.normalized() * curved * active_speed
		_gamepad_velocity = _gamepad_velocity.move_toward(
			target_velocity, gamepad_acceleration * delta
		)
	elif touch_target != Vector3.ZERO:
		_gamepad_velocity = Vector2.ZERO
		using_touch = true
		global_position.x = touch_target.x
		global_position.z = touch_target.z
	else:
		_gamepad_velocity = _gamepad_velocity.move_toward(
			Vector2.ZERO, gamepad_deceleration * delta
		)

	if _gamepad_velocity.length() > 0.0:
		global_position.x += _gamepad_velocity.x * delta
		global_position.z += _gamepad_velocity.y * delta

	_clamp_to_screen()

	var velocity_x: float
	if using_touch:
		velocity_x = (global_position.x - prev_x) / maxf(delta, 0.0001)
	else:
		velocity_x = _gamepad_velocity.x

	is_firing = (
		not is_dodging
		and (
			Input.is_action_pressed("fire")
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			or _touch_firing
		)
	)
	weapon_system.set_firing(is_firing)
	if Input.is_action_just_pressed("combo_shot"):
		weapon_system.shoot_combo()
	_update_tilt(velocity_x, delta)

func _update_dodge(delta: float) -> void:
	match _dodge_phase:
		DodgePhase.GROUNDED:
			if Input.is_action_just_pressed("dodge"):
				_dodge_phase = DodgePhase.DESCENDING
				is_dodging = true
		DodgePhase.DESCENDING:
			global_position.y = move_toward(
				global_position.y, -dodge_depth, dodge_descend_speed * delta
			)
			if global_position.y <= -dodge_depth + 0.001:
				global_position.y = -dodge_depth
				_dodge_phase = DodgePhase.UNDER
				_dodge_timer = dodge_duration
		DodgePhase.UNDER:
			_dodge_timer -= delta
			if _dodge_timer <= 0.0:
				_dodge_phase = DodgePhase.ASCENDING
		DodgePhase.ASCENDING:
			global_position.y = move_toward(global_position.y, 0.0, dodge_ascend_speed * delta)
			if global_position.y >= -0.001:
				global_position.y = 0.0
				is_dodging = false
				_dodge_phase = DodgePhase.COOLDOWN
				_dodge_timer = dodge_cooldown
		DodgePhase.COOLDOWN:
			_dodge_timer -= delta
			if _dodge_timer <= 0.0:
				_dodge_phase = DodgePhase.GROUNDED

	collision_layer = 0 if is_dodging else PLAYER_COLLISION_LAYER
	_update_dodge_pitch(delta)

func _update_dodge_pitch(delta: float) -> void:
	var target_pitch: float = dodge_pitch if is_dodging else 0.0
	ship_model.rotation.x = lerpf(ship_model.rotation.x, target_pitch, delta * 10.0)

func _update_tilt(velocity_x: float, delta: float) -> void:
	var target: float = clampf(velocity_x * tilt_velocity_factor, -0.8, 0.8)
	ship_model.rotation.z = lerpf(ship_model.rotation.z, target, delta * 10.0)

func _clamp_to_screen():
	var clamped_x := clampf(global_position.x, -max_bound_x, max_bound_x)
	var clamped_z := clampf(global_position.z, -max_bound_z, max_bound_z)
	if clamped_x != global_position.x:
		_gamepad_velocity.x = 0.0
	if clamped_z != global_position.z:
		_gamepad_velocity.y = 0.0
	global_position.x = clamped_x
	global_position.z = clamped_z

# ============================================================================
# 4. OBRAŻENIA / ŚMIERĆ / DEBUG
# ============================================================================

func take_damage(amount: int) -> void:
	if damage_system:
		damage_system.take_damage(amount)
		return
	push_warning("Player: Brak DamageSystem — obrażenia pominięte")

## Zbieranie lootu wyrzuconego przez wrogów (HUD odczytuje score co klatkę).
func collect_pickup(amount: int) -> void:
	score += amount

func die() -> void:
	queue_free()

func _process(_delta):
	if Input.is_action_just_pressed("ui_home"):
		print("Player: --- DEBUG GRACZA ---")
		print("Player: Statek ID: ", ship_id)
		print("Player: Pozycja 3D: ", global_position)
		print("Player: Pancerz: ", armor, "/", max_armor)
