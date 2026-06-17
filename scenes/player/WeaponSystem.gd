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
var is_combo_firing: bool = false
var _ready_to_fire: bool = false
var _combo_shot_timer: float = 0.0
var _active_beam: Area3D = null
var _active_beam_projectile_id: int = -1
var _beam_power_timer: float = 0.0
var _locked_combo_shot: WeaponComboShotData = null
var _combo_active_timer: float = 0.0
var _combo_session_duration: float = 0.0
var _combo_session_tier_combo: int = 0
var _was_combo_firing: bool = false

signal combo_session_changed(remaining: float, total: float, active: bool, tier_combo: int)
## Maks. czas życia muzzle flash (s) — krótki, żeby nie zostawał w świecie za graczem.
const MUZZLE_FLASH_MAX_LIFETIME := 0.12

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
	_combo_shot_timer = max(0.0, _combo_shot_timer - delta)
	if is_firing and fire_timer <= 0.0:
		shoot()
	_process_combo(delta)
	_was_combo_firing = is_combo_firing
		
func load_weapon_config():
	current_weapon_index = player.front_weapon_index
	print("WeaponSystem: próbuję załadować broń ID=", current_weapon_index)
	
	weapon_data = DataManager.get_weapon_by_id(current_weapon_index)
	
	if weapon_data == null:
		push_error("WeaponSystem: Nie znaleziono broni o ID: ", current_weapon_index)
	else:
		print("WeaponSystem: Załadowano broń - weapon_id=", current_weapon_index)
	_despawn_beam()
	_locked_combo_shot = null
	_combo_active_timer = 0.0
	_combo_session_duration = 0.0
	_combo_session_tier_combo = 0
	_notify_combo_session()

func set_firing(firing: bool):
	is_firing = firing


func set_combo_firing(firing: bool) -> void:
	is_combo_firing = firing

func _get_combo_shot_data() -> WeaponComboShotData:
	return _locked_combo_shot


func can_shoot_combo() -> bool:
	if _locked_combo_shot == null:
		return false
	return _combo_shot_timer <= 0.0 and not player.is_dodging


func _wants_combo_fire() -> bool:
	return is_combo_firing


func _combo_just_pressed() -> bool:
	return is_combo_firing and not _was_combo_firing


func _try_lock_combo_shot() -> WeaponComboShotData:
	if weapon_data == null:
		return null
	return weapon_data.get_best_available_combo_shot(HitComboManager.combo)


func _has_combo_session() -> bool:
	return _locked_combo_shot != null


func _process_combo(delta: float) -> void:
	_tick_combo_session(delta)

	if not _has_combo_session():
		if not _combo_just_pressed():
			return
		_try_start_combo_session()
		return

	if not _wants_combo_fire():
		_pause_combo_fire()
		return

	_fire_locked_combo(delta)


func _tick_combo_session(delta: float) -> void:
	if not _has_combo_session():
		return
	_combo_active_timer = maxf(0.0, _combo_active_timer - delta)
	_notify_combo_session()
	if _combo_active_timer <= 0.0:
		_end_combo_session()


func _try_start_combo_session() -> void:
	var combo_at_activation := HitComboManager.combo
	var available := _try_lock_combo_shot()
	if available == null:
		return
	_locked_combo_shot = available
	_combo_session_tier_combo = combo_at_activation
	_combo_session_duration = maxf(available.active_duration, 0.01)
	_combo_active_timer = _combo_session_duration
	HitComboManager.spend_combo()
	_notify_combo_session()


func _pause_combo_fire() -> void:
	_despawn_beam()


func _fire_locked_combo(delta: float) -> void:
	var combo_data := _locked_combo_shot
	if combo_data == null:
		return

	if combo_data.delivery_mode == WeaponComboShotData.ComboDeliveryMode.BEAM:
		_update_beam(combo_data, delta)
		return

	_despawn_beam()
	if not can_shoot_combo():
		return
	shoot_combo()


func _end_combo_session() -> void:
	_clear_combo_session()


func _clear_combo_session() -> void:
	_locked_combo_shot = null
	_combo_active_timer = 0.0
	_combo_session_duration = 0.0
	_combo_session_tier_combo = 0
	_despawn_beam()
	_notify_combo_session()


func _notify_combo_session() -> void:
	var active := _has_combo_session()
	combo_session_changed.emit(
		_combo_active_timer if active else 0.0,
		_combo_session_duration,
		active,
		_combo_session_tier_combo,
	)


func _update_beam(combo_data: WeaponComboShotData, delta: float) -> void:
	if player.is_dodging:
		if _active_beam:
			_active_beam.visible = false
		return

	if combo_data.power_use > 0:
		_beam_power_timer = maxf(0.0, _beam_power_timer - delta)
		if player.power < combo_data.power_use:
			_despawn_beam()
			return
		if _beam_power_timer <= 0.0:
			player.power -= combo_data.power_use
			player.notify_power_changed()
			_beam_power_timer = combo_data.beam_damage_interval

	_ensure_beam_instance(combo_data)
	if _active_beam == null:
		return
	_active_beam.visible = true
	if _active_beam.has_method("configure"):
		_active_beam.configure(combo_data.damage, combo_data.beam_damage_interval)


func _ensure_beam_instance(combo_data: WeaponComboShotData) -> void:
	if _active_beam != null and _active_beam_projectile_id == combo_data.projectile:
		return
	_despawn_beam()
	var scene := SceneRegistry.get_player_combo_projectile_scene(combo_data.projectile)
	_active_beam = scene.instantiate() as Area3D
	muzzle.add_child(_active_beam)
	_active_beam_projectile_id = combo_data.projectile
	if _active_beam.has_method("configure"):
		_active_beam.configure(combo_data.damage, combo_data.beam_damage_interval)


func _despawn_beam() -> void:
	if _active_beam:
		_active_beam.queue_free()
	_active_beam = null
	_active_beam_projectile_id = -1
	_beam_power_timer = 0.0


func shoot_combo() -> void:
	if weapon_data == null:
		load_weapon_config()
	var combo_data := _get_combo_shot_data()
	if combo_data == null:
		return
	if not can_shoot_combo():
		return
	if player.power < combo_data.power_use:
		return

	player.power -= combo_data.power_use
	player.notify_power_changed()
	spawn_shot(
		combo_data.projectile,
		combo_data.damage,
		combo_data.velocity,
		combo_data.pellets,
		true,
	)
	SoundManager.play_weapon_sound(weapon_data.sound)
	_combo_shot_timer = combo_data.cooldown

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
	player.notify_power_changed()
	
	spawn_shot(
		power_level_data.projectile,
		power_level_data.damage,
		power_level_data.velocity,
		power_level_data.pellets,
	)
	SoundManager.play_weapon_sound(weapon_data.sound)
	fire_timer = power_level_data.fire_rate


func spawn_shot(
	projectile_id: int,
	damage: int,
	base_velocity: Vector3,
	pellets: Array[WeaponShotPelletData],
	combo_shot: bool = false,
) -> void:
	if pellets.is_empty():
		_spawn_single_projectile(
			muzzle.global_position,
			base_velocity,
			projectile_id,
			damage,
			combo_shot,
		)
		_spawn_muzzle_flash(base_velocity)
		return

	for pellet in pellets:
		var velocity := _pellet_velocity(base_velocity, pellet)
		var spawn_pos: Vector3 = muzzle.global_position + muzzle.global_basis * pellet.spawn_offset
		_spawn_single_projectile(spawn_pos, velocity, projectile_id, damage, combo_shot)
	_spawn_muzzle_flash(base_velocity)


func _spawn_single_projectile(
	spawn_position: Vector3,
	velocity: Vector3,
	projectile_id: int,
	damage: int,
	combo_shot: bool = false,
) -> void:
	var projectile_scene := SceneRegistry.get_player_combo_projectile_scene(projectile_id) \
		if combo_shot \
		else SceneRegistry.get_player_projectile_scene(projectile_id)
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_position
	projectile.velocity = velocity
	projectile.damage = damage


func _pellet_velocity(base_velocity: Vector3, pellet: WeaponShotPelletData) -> Vector3:
	var direction := base_velocity
	if direction.length_squared() < 0.0001:
		direction = Vector3(0.0, 0.0, -1.0)
	else:
		direction = direction.normalized()
	var speed: float = base_velocity.length() * pellet.velocity_scale
	return direction.rotated(Vector3.UP, deg_to_rad(pellet.angle_deg)) * speed


func _spawn_muzzle_flash(velocity: Vector3) -> void:
	if weapon_data == null:
		return
	var scene := weapon_data.muzzle_flash_scene
	if scene == null:
		return

	var flash := scene.instantiate()
	# Dziecko Muzzle — błysk jedzie z graczem, nie zostaje w świecie w miejscu strzału.
	muzzle.add_child(flash)
	if flash is Node3D:
		(flash as Node3D).transform = _muzzle_flash_local_transform(velocity)

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
	# instance_id zamiast capture węzła — lambda nie trzyma referencji po queue_free().
	var flash_id := flash.get_instance_id()
	var cleanup := func(_anim_name: StringName = &"") -> void:
		var node := instance_from_id(flash_id)
		if node:
			node.queue_free()

	var anim := flash.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim:
		anim.animation_finished.connect(cleanup, CONNECT_ONE_SHOT)

	get_tree().create_timer(MUZZLE_FLASH_MAX_LIFETIME).timeout.connect(cleanup, CONNECT_ONE_SHOT)


func _muzzle_flash_local_transform(velocity: Vector3) -> Transform3D:
	var world_basis := _muzzle_flash_basis(velocity)
	var local_basis := muzzle.global_basis.inverse() * world_basis
	return Transform3D(local_basis, Vector3.ZERO)


func _muzzle_flash_basis(velocity: Vector3) -> Basis:
	var direction := velocity
	if direction.length_squared() < 0.0001:
		direction = Vector3(0.0, 0.0, -1.0)
	else:
		direction = direction.normalized()

	# BinbunVFX muzzle flash: efekt „wylatuje” wzdłuż lokalnej osi +X.
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
