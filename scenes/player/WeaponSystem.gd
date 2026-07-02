extends Node

# ============================================================================
# WEAPON SYSTEM - Logika strzelania
# ============================================================================

const WeaponDataClass = preload("res://scripts/resources/WeaponData.gd")

enum FireMode {
	NONE,
	PRIMARY,
	SPECIAL_1,
	SPECIAL_2,
	SPECIAL_3,
	SPECIAL_4,
}

# --- Referencje ---
var player: CharacterBody3D
var front_muzzle: Marker3D
var rear_muzzle: Marker3D
var muzzle: Marker3D

# --- Dane broni ---
var front_weapon_data: WeaponDataClass
var rear_weapon_data: WeaponDataClass
var weapon_data: WeaponDataClass
var current_weapon_index: int = 1

# --- Strzelanie ---
var fire_mode: FireMode = FireMode.NONE
var fire_timer: float = 0.0
var rear_fire_timer: float = 0.0
var _ready_to_fire: bool = false
var _special_shot_timers: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _active_beam: Area3D = null
var _active_beam_projectile_id: int = -1
var _beam_power_timer: float = 0.0

## Maks. czas życia muzzle flash (s) — krótki, żeby nie zostawał w świecie za graczem.
const MUZZLE_FLASH_MAX_LIFETIME := 0.12


func _ready():
	player = get_parent()
	front_muzzle = player.get_node("Muzzle")
	rear_muzzle = player.get_node_or_null("Muzzle2")
	muzzle = front_muzzle
	await get_tree().process_frame
	load_weapon_config()
	_ready_to_fire = true


func _physics_process(delta: float):
	if not _ready_to_fire:
		return
	fire_timer = maxf(0.0, fire_timer - delta)
	rear_fire_timer = maxf(0.0, rear_fire_timer - delta)
	for i in WeaponDataClass.SPECIAL_SHOT_COUNT:
		_special_shot_timers[i] = maxf(0.0, _special_shot_timers[i] - delta)
	_process_fire_mode(delta)


func load_weapon_config():
	front_weapon_data = DataManager.get_weapon_by_id(player.front_weapon_index)
	rear_weapon_data = DataManager.get_weapon_by_id(player.rear_weapon_index)
	weapon_data = front_weapon_data
	current_weapon_index = player.front_weapon_index
	print("WeaponSystem: próbuję załadować broń ID=", current_weapon_index)

	if front_weapon_data == null:
		push_error("WeaponSystem: Nie znaleziono broni frontowej o ID: ", current_weapon_index)
	else:
		print("WeaponSystem: Załadowano broń frontową - weapon_id=", current_weapon_index)

	if player.rear_weapon_index != 0:
		if rear_weapon_data == null:
			push_error("WeaponSystem: Nie znaleziono broni tylnej o ID: ", player.rear_weapon_index)
		else:
			print("WeaponSystem: Załadowano broń tylną - weapon_id=", player.rear_weapon_index)

	_despawn_beam()
	fire_timer = 0.0
	rear_fire_timer = 0.0
	for i in WeaponDataClass.SPECIAL_SHOT_COUNT:
		_special_shot_timers[i] = 0.0


func set_fire_mode(mode: FireMode) -> void:
	fire_mode = mode


func _process_fire_mode(delta: float) -> void:
	if player.is_dodging or fire_mode == FireMode.NONE:
		_despawn_beam()
		return

	match fire_mode:
		FireMode.PRIMARY:
			_despawn_beam()
			if fire_timer <= 0.0:
				shoot()
		FireMode.SPECIAL_1:
			_process_special_shot(1, delta)
		FireMode.SPECIAL_2:
			_process_special_shot(2, delta)
		FireMode.SPECIAL_3:
			_process_special_shot(3, delta)
		FireMode.SPECIAL_4:
			_process_special_shot(4, delta)


func _process_special_shot(slot: int, delta: float) -> void:
	var shot_data := _get_special_shot_data(slot)
	if shot_data == null:
		_despawn_beam()
		return

	if shot_data.delivery_mode == WeaponSpecialShotData.SpecialDeliveryMode.BEAM:
		_update_beam(shot_data, delta)
		return

	_despawn_beam()
	if not _can_shoot_special(slot):
		return
	shoot_special(slot)


func _get_special_shot_data(slot: int) -> WeaponSpecialShotData:
	if weapon_data == null:
		return null
	var shot := weapon_data.get_special_shot(slot)
	if shot == null or not shot.enabled:
		return null
	return shot


func _can_shoot_special(slot: int) -> bool:
	var index := slot - 1
	if index < 0 or index >= _special_shot_timers.size():
		return false
	return _special_shot_timers[index] <= 0.0


func shoot_special(slot: int) -> void:
	if weapon_data == null:
		load_weapon_config()
	var shot_data := _get_special_shot_data(slot)
	if shot_data == null:
		return
	if not _can_shoot_special(slot):
		return
	if player.power < shot_data.power_use:
		return

	player.power -= shot_data.power_use
	player.notify_power_changed()
	spawn_shot(
		shot_data.projectile,
		shot_data.damage,
		shot_data.velocity,
		shot_data.pellets,
		true,
	)
	SoundManager.play_weapon_sound(weapon_data.sound)
	_special_shot_timers[slot - 1] = shot_data.cooldown


func shoot():
	if front_weapon_data == null:
		push_error("WeaponSystem: front_weapon_data jest null, próbuję załadować ponownie...")
		load_weapon_config()
		if front_weapon_data == null:
			return

	var front_power_level_data = front_weapon_data.get_power_level_data(player.front_power_level)
	var front_cost = front_power_level_data.power_use
	if player.power < front_cost:
		return

	player.power -= front_cost
	_spawn_weapon_fire(front_muzzle, front_weapon_data, front_power_level_data)
	SoundManager.play_weapon_sound(front_weapon_data.sound)
	fire_timer = front_power_level_data.fire_rate

	if rear_weapon_data != null and rear_muzzle != null and rear_fire_timer <= 0.0:
		var rear_power_level_data = rear_weapon_data.get_power_level_data(player.rear_power_level)
		if player.power >= rear_power_level_data.power_use:
			player.power -= rear_power_level_data.power_use
			_spawn_weapon_fire(rear_muzzle, rear_weapon_data, rear_power_level_data)
			rear_fire_timer = rear_power_level_data.fire_rate

	player.notify_power_changed()


func _update_beam(shot_data: WeaponSpecialShotData, delta: float) -> void:
	if shot_data.power_use > 0:
		_beam_power_timer = maxf(0.0, _beam_power_timer - delta)
		if player.power < shot_data.power_use:
			_despawn_beam()
			return
		if _beam_power_timer <= 0.0:
			player.power -= shot_data.power_use
			player.notify_power_changed()
			_beam_power_timer = shot_data.beam_damage_interval

	_ensure_beam_instance(shot_data)
	if _active_beam == null:
		return
	_active_beam.visible = true
	if _active_beam.has_method("configure"):
		_active_beam.configure(shot_data.damage, shot_data.beam_damage_interval)


func _ensure_beam_instance(shot_data: WeaponSpecialShotData) -> void:
	if _active_beam != null and _active_beam_projectile_id == shot_data.projectile:
		return
	_despawn_beam()
	var scene := SceneRegistry.get_player_special_projectile_scene(shot_data.projectile)
	_active_beam = scene.instantiate() as Area3D
	muzzle.add_child(_active_beam)
	_active_beam_projectile_id = shot_data.projectile
	if _active_beam.has_method("configure"):
		_active_beam.configure(shot_data.damage, shot_data.beam_damage_interval)


func _despawn_beam() -> void:
	if _active_beam:
		_active_beam.queue_free()
	_active_beam = null
	_active_beam_projectile_id = -1
	_beam_power_timer = 0.0


func spawn_shot(
	projectile_id: int,
	damage: int,
	base_velocity: Vector3,
	pellets: Array[WeaponShotPelletData],
	special_shot: bool = false,
	from_muzzle: Marker3D = null,
	weapon_data_ref: WeaponData = null,
	homing: bool = false,
	homing_turn_speed: float = 3.0,
) -> void:
	if from_muzzle == null:
		from_muzzle = muzzle
	if pellets.is_empty():
		_spawn_single_projectile(
			from_muzzle.global_position,
			base_velocity,
			projectile_id,
			damage,
			special_shot,
			homing,
			homing_turn_speed,
		)
		_spawn_muzzle_flash(base_velocity, from_muzzle, weapon_data_ref)
		return

	for pellet in pellets:
		var velocity := _pellet_velocity(base_velocity, pellet)
		var spawn_pos: Vector3 = from_muzzle.global_position + from_muzzle.global_basis * pellet.spawn_offset
		var pid := pellet.projectile_override if pellet.projectile_override > 0 else projectile_id
		_spawn_single_projectile(spawn_pos, velocity, pid, damage, special_shot, homing, homing_turn_speed)
	_spawn_muzzle_flash(base_velocity, from_muzzle, weapon_data_ref)


func _spawn_single_projectile(
	spawn_position: Vector3,
	velocity: Vector3,
	projectile_id: int,
	damage: int,
	special_shot: bool = false,
	homing: bool = false,
	homing_turn_speed: float = 3.0,
) -> void:
	var projectile_scene := SceneRegistry.get_player_special_projectile_scene(projectile_id) \
		if special_shot \
		else SceneRegistry.get_player_projectile_scene(projectile_id)
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_position
	projectile.velocity = velocity
	projectile.damage = damage
	if homing:
		projectile.homing = true
		projectile.turn_speed = homing_turn_speed


func _spawn_weapon_fire(
	from_muzzle: Marker3D,
	weapon_data_ref: WeaponData,
	power_level_data: WeaponPowerLevelData,
	special_shot: bool = false,
) -> void:
	spawn_shot(
		power_level_data.projectile,
		power_level_data.damage,
		power_level_data.velocity,
		power_level_data.pellets,
		special_shot,
		from_muzzle,
		weapon_data_ref,
		power_level_data.homing,
		power_level_data.homing_turn_speed,
	)

func _pellet_velocity(base_velocity: Vector3, pellet: WeaponShotPelletData) -> Vector3:
	var direction := base_velocity
	if direction.length_squared() < 0.0001:
		direction = Vector3(0.0, 0.0, -1.0)
	else:
		direction = direction.normalized()
	var speed: float = base_velocity.length() * pellet.velocity_scale
	return direction.rotated(Vector3.UP, deg_to_rad(pellet.angle_deg)) * speed


func _spawn_muzzle_flash(
	velocity: Vector3,
	from_muzzle: Marker3D = null,
	weapon_data_ref: WeaponData = null,
) -> void:
	if weapon_data_ref == null:
		weapon_data_ref = weapon_data
	if weapon_data_ref == null:
		return
	if from_muzzle == null:
		from_muzzle = muzzle
	var scene := weapon_data_ref.muzzle_flash_scene
	if scene == null:
		return

	var flash := scene.instantiate()
	from_muzzle.add_child(flash)
	if flash is Node3D:
		(flash as Node3D).transform = _muzzle_flash_local_transform(velocity, from_muzzle)

	_try_play_vfx_flash(flash)
	_schedule_flash_cleanup(flash)


func _try_play_vfx_flash(flash: Node) -> void:
	if flash.get("speed_scale") != null:
		flash.set("speed_scale", 1.75)
	if not flash.has_method("play"):
		return
	flash.set("autoplay", false)
	flash.set("one_shot", true)
	flash.play()


func _schedule_flash_cleanup(flash: Node) -> void:
	var flash_id := flash.get_instance_id()
	var cleanup := func(_anim_name: StringName = &"") -> void:
		var node := instance_from_id(flash_id)
		if node:
			node.queue_free()

	var anim := flash.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim:
		anim.animation_finished.connect(cleanup, CONNECT_ONE_SHOT)

	get_tree().create_timer(MUZZLE_FLASH_MAX_LIFETIME).timeout.connect(cleanup, CONNECT_ONE_SHOT)


func _muzzle_flash_local_transform(velocity: Vector3, from_muzzle: Marker3D) -> Transform3D:
	var world_basis := _muzzle_flash_basis(velocity)
	var local_basis := from_muzzle.global_basis.inverse() * world_basis
	return Transform3D(local_basis, Vector3.ZERO)


func _muzzle_flash_basis(velocity: Vector3) -> Basis:
	var direction := velocity
	if direction.length_squared() < 0.0001:
		direction = Vector3(0.0, 0.0, -1.0)
	else:
		direction = direction.normalized()

	var x_axis := direction
	var up := Vector3.UP
	var z_axis := x_axis.cross(up)
	if z_axis.length_squared() < 0.0001:
		z_axis = Vector3.RIGHT
	else:
		z_axis = z_axis.normalized()
	var y_axis := z_axis.cross(x_axis).normalized()

	var basis := Basis(x_axis, y_axis, z_axis)
	var offset := weapon_data.muzzle_flash_rotation_offset
	if offset != Vector3.ZERO:
		basis = basis * Basis.from_euler(Vector3(
			deg_to_rad(offset.x),
			deg_to_rad(offset.y),
			deg_to_rad(offset.z),
		))

	return basis
