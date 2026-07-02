extends CharacterBody3D

# ============================================================================
# SIDEKICK - lata obok playera, strzela razem z nim
# ============================================================================

const WeaponPowerLevelDataClass = preload("res://scripts/resources/WeaponPowerLevelData.gd")
const WeaponDataClass = preload("res://scripts/resources/WeaponData.gd")

@export_group("Loadout")
@export var weapon_index: int = 1
@export var power_level: int = 1

@export_group("Formation")
## Offset względem pozycji playera (np. Vector3(-2,0,0) = lewy bok)
@export var formation_offset: Vector3 = Vector3(-2.0, 0.0, 0.0)
## Szybkość śledzenia pozycji docelowej (lerp speed)
@export var follow_speed: float = 10.0

var player: Node3D
var _muzzle: Marker3D
var _weapon_data: WeaponDataClass
var _fire_timer: float = 0.0
var _ready_to_fire: bool = false

const MUZZLE_FLASH_MAX_LIFETIME := 0.12


func _ready() -> void:
	player = get_parent() as Node3D
	_muzzle = get_node_or_null("Muzzle")
	await get_tree().process_frame
	_load_weapon()
	_ready_to_fire = true


func _load_weapon() -> void:
	_weapon_data = DataManager.get_weapon_by_id(weapon_index)
	if _weapon_data == null:
		push_error("Sidekick: Nie znaleziono broni o ID: ", weapon_index)


func _physics_process(delta: float) -> void:
	_follow_player(delta)
	_fire_timer = maxf(0.0, _fire_timer - delta)


func _follow_player(delta: float) -> void:
	if player == null:
		return
	var target := player.global_position + formation_offset
	global_position = global_position.lerp(target, clampf(follow_speed * delta, 0.0, 1.0))


func shoot() -> void:
	if not _ready_to_fire or _weapon_data == null or _muzzle == null:
		return
	if _fire_timer > 0.0:
		return
	var pld: WeaponPowerLevelDataClass = _weapon_data.get_power_level_data(power_level)
	if pld == null:
		return
	var current_power: float = player.get("power")
	if current_power < pld.power_use:
		return
	player.set("power", current_power - pld.power_use)
	player.call("notify_power_changed")
	_spawn_fire(pld)
	SoundManager.play_weapon_sound(_weapon_data.sound)
	_fire_timer = pld.fire_rate


func _spawn_fire(pld: WeaponPowerLevelDataClass) -> void:
	if pld.pellets.is_empty():
		_spawn_single_projectile(
			_muzzle.global_position, pld.velocity,
			pld.projectile, pld.damage, pld.homing, pld.homing_turn_speed
		)
		_spawn_muzzle_flash(pld.velocity)
		return
	for pellet in pld.pellets:
		var dir := pld.velocity.normalized() if pld.velocity.length_squared() > 0.0001 else Vector3(0, 0, -1)
		var speed: float = pld.velocity.length() * pellet.velocity_scale
		var vel := dir.rotated(Vector3.UP, deg_to_rad(pellet.angle_deg)) * speed
		var spawn_pos: Vector3 = _muzzle.global_position + _muzzle.global_basis * pellet.spawn_offset
		_spawn_single_projectile(spawn_pos, vel, pld.projectile, pld.damage, pld.homing, pld.homing_turn_speed)
	_spawn_muzzle_flash(pld.velocity)


func _spawn_single_projectile(
	spawn_pos: Vector3,
	vel: Vector3,
	projectile_id: int,
	dmg: int,
	homing: bool,
	homing_turn_speed: float,
) -> void:
	var scene := SceneRegistry.get_player_projectile_scene(projectile_id)
	var projectile = scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos
	projectile.velocity = vel
	projectile.damage = dmg
	if homing:
		projectile.homing = true
		projectile.turn_speed = homing_turn_speed


func _spawn_muzzle_flash(flash_velocity: Vector3) -> void:
	if _weapon_data == null or _weapon_data.muzzle_flash_scene == null:
		return
	var flash := _weapon_data.muzzle_flash_scene.instantiate()
	_muzzle.add_child(flash)
	if flash is Node3D:
		var dir := flash_velocity.normalized() if flash_velocity.length_squared() > 0.0001 else Vector3(0, 0, -1)
		var up := Vector3.UP
		if absf(dir.dot(up)) > 0.999:
			up = Vector3.RIGHT
		(flash as Node3D).look_at(_muzzle.global_position + dir, up)
	if flash.get("speed_scale") != null:
		flash.set("speed_scale", 1.75)
	if flash.has_method("play"):
		flash.set("autoplay", false)
		flash.set("one_shot", true)
		flash.play()
	var flash_id := flash.get_instance_id()
	var cleanup := func(_n: StringName = &"") -> void:
		var node := instance_from_id(flash_id)
		if node:
			node.queue_free()
	var anim := flash.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim:
		anim.animation_finished.connect(cleanup, CONNECT_ONE_SHOT)
	get_tree().create_timer(MUZZLE_FLASH_MAX_LIFETIME).timeout.connect(cleanup, CONNECT_ONE_SHOT)
