extends CharacterBody3D

@export_group("Loadout")
@export var ship_id: int = 1
@export var front_weapon_index: int = 1
@export var front_power_level: int = 1
@export var rear_weapon_index: int = 1
@export var rear_power_level: int = 1
@export var generator_id: int = 1
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
var _power_per_kill: float = 0.0
var ship_data: ShipData = null

@export_group("Gamepad movement")
@export var gamepad_move_speed: float = 30.0
@export var gamepad_l2_move_speed: float = 12.0
@export var gamepad_acceleration: float = 70.0
@export var gamepad_deceleration: float = 100.0
@export_range(1.0, 3.0, 0.05) var gamepad_response_exponent: float = 1.4
@export var tilt_velocity_factor: float = 0.025

@export_group("Dodge")
@export var dodge_duration: float = 0.35
@export var dodge_cooldown: float = 0.6
## Minimalne wciśnięcie R2 (0–1), żeby dodge nie odpalał się od lekkiego dotknięcia spustu.
@export_range(0.3, 0.95, 0.05) var dodge_trigger_threshold: float = 0.65

enum DodgePhase { GROUNDED, ROLLING, COOLDOWN }

const PLAYER_COLLISION_LAYER := 1

signal score_changed(score: int)
signal armor_changed(current: int, maximum: int)
signal power_changed(current: float, maximum: float)

var is_dodging := false

@onready var weapon_system: Node = $WeaponSystem
@onready var damage_system: Node = $DamageSystem
@onready var ship_model: Node3D = $Blaze

var _sidekicks: Array[Node] = []

var main_camera: Camera3D

# ── Dotyk: cel w świecie + offset (palec nie musi być nad modelem) ──
var touch_target := Vector3.ZERO
var _touch_firing := false
var _touch_grab_offset := Vector3.ZERO  # różnica palec↔statek w momencie dotknięcia
var _gamepad_velocity := Vector2.ZERO
var _dodge_phase: DodgePhase = DodgePhase.GROUNDED
var _dodge_timer: float = 0.0
var _dodge_trigger_armed: bool = true

# ============================================================================
# 1. INICJALIZACJA
# ============================================================================

func _ready():
	add_to_group("player")
	main_camera = GameViewportHelper.get_game_camera(get_tree())
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	await get_tree().process_frame
	load_ship_data()
	apply_ship_stats()
	init_power_regeneration()
	_log_connected_joypads()
	_spawn_sidekicks()

func _spawn_sidekicks() -> void:
	_sidekicks.clear()
	if left_sidekick_id > 0:
		var scene := SceneRegistry.get_sidekick_scene(left_sidekick_id)
		if scene != null:
			var sk := scene.instantiate()
			sk.formation_offset = Vector3(-2.0, 0.0, 0.0)
			add_child(sk)
			_sidekicks.append(sk)
	if right_sidekick_id > 0:
		var scene := SceneRegistry.get_sidekick_scene(right_sidekick_id)
		if scene != null:
			var sk := scene.instantiate()
			sk.formation_offset = Vector3(2.0, 0.0, 0.0)
			add_child(sk)
			_sidekicks.append(sk)


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
	notify_armor_changed()

func init_power_regeneration():
	regen = DataManager.get_generator_regeneration(generator_id)
	max_power = DataManager.get_generator_power(generator_id)
	_power_per_kill = DataManager.get_generator_power_per_kill(generator_id)
	power = 0.0
	notify_power_changed()


func add_power_from_kill() -> void:
	if _power_per_kill <= 0.0:
		return
	var previous := power
	power = minf(max_power, power + _power_per_kill)
	if power != previous:
		notify_power_changed()

func notify_score_changed() -> void:
	score_changed.emit(score)


func notify_armor_changed() -> void:
	armor_changed.emit(armor, max_armor)


func notify_power_changed() -> void:
	power_changed.emit(power, max_power)

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

	var primary_input := (
		not is_dodging
		and (
			Input.is_action_pressed("fire")
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			or _touch_firing
		)
	)
	weapon_system.set_fire_mode(_resolve_fire_mode(primary_input))
	if primary_input and not is_dodging:
		for sk in _sidekicks:
			sk.shoot()
	_update_tilt(velocity_x, delta)
	notify_power_changed()

func _resolve_fire_mode(primary_input: bool) -> int:
	if is_dodging:
		return weapon_system.FireMode.NONE
	if Input.is_action_pressed("special_shot_4"):
		return weapon_system.FireMode.SPECIAL_4
	if Input.is_action_pressed("special_shot_3"):
		return weapon_system.FireMode.SPECIAL_3
	if Input.is_action_pressed("special_shot_2"):
		return weapon_system.FireMode.SPECIAL_2
	if Input.is_action_pressed("special_shot_1"):
		return weapon_system.FireMode.SPECIAL_1
	if primary_input:
		return weapon_system.FireMode.PRIMARY
	return weapon_system.FireMode.NONE


func _is_dodge_trigger_pressed() -> bool:
	return Input.get_action_raw_strength("dodge") >= dodge_trigger_threshold


func _consume_dodge_trigger_press() -> bool:
	var pressed := _is_dodge_trigger_pressed()
	if not pressed:
		_dodge_trigger_armed = true
		return false
	if not _dodge_trigger_armed:
		return false
	_dodge_trigger_armed = false
	return true


func _update_dodge(delta: float) -> void:
	match _dodge_phase:
		DodgePhase.GROUNDED:
			if _consume_dodge_trigger_press():
				_dodge_phase = DodgePhase.ROLLING
				_dodge_timer = dodge_duration
				is_dodging = true
		DodgePhase.ROLLING:
			_dodge_timer -= delta
			if _dodge_timer <= 0.0:
				_dodge_timer = 0.0
				is_dodging = false
				_dodge_phase = DodgePhase.COOLDOWN
				_dodge_timer = dodge_cooldown
		DodgePhase.COOLDOWN:
			_dodge_timer -= delta
			if _dodge_timer <= 0.0:
				_dodge_phase = DodgePhase.GROUNDED

	collision_layer = 0 if is_dodging else PLAYER_COLLISION_LAYER
	_update_dodge_roll()

func _update_dodge_roll() -> void:
	if _dodge_phase == DodgePhase.ROLLING and dodge_duration > 0.0:
		var progress := 1.0 - (_dodge_timer / dodge_duration)
		ship_model.rotation.z = progress * TAU
	else:
		ship_model.rotation.z = lerpf(ship_model.rotation.z, 0.0, 0.25)

func _update_tilt(velocity_x: float, delta: float) -> void:
	if is_dodging:
		return
	var target: float = clampf(velocity_x * tilt_velocity_factor, -0.8, 0.8)
	ship_model.rotation.z = lerpf(ship_model.rotation.z, target, delta * 10.0)

func _clamp_to_screen():
	var area := DataManager.get_play_area_config()
	if area == null:
		return
	var clamped_x := clampf(global_position.x, -area.player_half_x, area.player_half_x)
	var clamped_z := clampf(global_position.z, -area.player_half_z, area.player_half_z)
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

## Zbieranie lootu wyrzuconego przez wrogów.
func collect_pickup(amount: int) -> void:
	score += amount
	notify_score_changed()

func die() -> void:
	queue_free()

func _process(_delta):
	if Input.is_action_just_pressed("ui_home"):
		print("Player: --- DEBUG GRACZA ---")
		print("Player: Statek ID: ", ship_id)
		print("Player: Pozycja 3D: ", global_position)
		print("Player: Pancerz: ", armor, "/", max_armor)
