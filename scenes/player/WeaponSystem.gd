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
	
	create_projectile(
		power_level_data.projectile,
		power_level_data.damage,
		power_level_data.velocity
	)
	_spawn_muzzle_flash(power_level_data.velocity)
	SoundManager.play_weapon_sound(weapon_data.sound)
	fire_timer = power_level_data.fire_rate

func create_projectile(projectile_id: int, damage: int, velocity: Vector3):
	var projectile_scene = GameConstants.get_player_projectile_scene(projectile_id)
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.velocity = velocity
	projectile.damage = damage


func _spawn_muzzle_flash(velocity: Vector3) -> void:
	var scene := weapon_data.muzzle_flash_scene
	if scene == null:
		return

	var flash := scene.instantiate()
	get_tree().current_scene.add_child(flash)
	if flash is Node3D:
		flash.global_transform = _muzzle_flash_transform(velocity)

	if flash is VFXController:
		flash.autoplay = false
		flash.one_shot = true
		flash.play()

	var anim := flash.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim:
		anim.animation_finished.connect(func(_name: StringName) -> void:
			flash.queue_free()
		, CONNECT_ONE_SHOT)


func _muzzle_flash_transform(velocity: Vector3) -> Transform3D:
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

	return Transform3D(basis, muzzle.global_position)
