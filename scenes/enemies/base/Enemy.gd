extends Area3D

@export_group("Combat")
@export var armor: int = 1
@export var weapon_data: EnemyWeaponData
@export var hit_sound: int = 3
@export var explosion_sound: int = 9

@export_group("Movement")
@export var movement_data: MovementData

@export_group("General")
@export var value: int = 2

@export_group("Visual")
@export var explosion_scene: PackedScene
@export var hit_effect_scene: PackedScene
var popup_spawn_offset_local: Vector3 = Vector3(0.0, 0.35, -1.2)
var popup_spawn_jitter_local: Vector3 = Vector3(0.25, 0.0, 0.35)

@onready var ship_model: Node3D = $EnemyModel

var _is_active: bool = false
var _move_elapsed: float = 0.0
var _weapon_firing: bool = false
var _fire_timer: float = 0.0
## weapon_data jest bezstanowy — stan wzorca (np. seria burst) trzymamy tutaj.
var _weapon_state: Dictionary = {}
var _muzzles: Array[Marker3D] = []
var _facing: EnemyFacing

@export_group("Activation")
@export var activate_on_scroll_line: bool = true
@export var despawn_off_screen: bool = true

var _screen_notifier: VisibleOnScreenNotifier3D
var _scroll_activation_z: float = -17.0

signal combat_activated
signal combat_deactivated


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON

	var play_area := DataManager.get_play_area_config()
	if play_area:
		_scroll_activation_z = play_area.scroll_activation_z

	add_to_group("enemies")

	_collect_muzzles()
	_facing = _find_facing()

	_screen_notifier = get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if _screen_notifier:
		_screen_notifier.visible = true
		_screen_notifier.screen_exited.connect(_on_screen_exited)

	set_physics_process(true)
	if activate_on_scroll_line:
		_deactivate()
	else:
		_activate()

	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if activate_on_scroll_line:
		_refresh_activation()

	if not _is_active:
		return

	if movement_data:
		global_position += movement_data.get_velocity(_move_elapsed) * delta
		_move_elapsed += delta

	if weapon_data:
		_process_weapon(delta)

	if _facing:
		_facing.process_facing(delta)


func set_firing(firing: bool) -> void:
	if firing and not _weapon_firing and weapon_data:
		weapon_data.on_begin_firing(_weapon_state)
		_fire_timer = 0.0 if weapon_data.fire_on_activate else weapon_data.fire_rate
	_weapon_firing = firing


func is_combat_active() -> bool:
	return _is_active


## Aktywacja fali z EnemyPath3D (SCENE_SCROLL_LINE) — nie po pozycji Z wroga.
func activate_combat() -> void:
	activate_on_scroll_line = false
	_activate()


func get_scroll_distance_remaining() -> float:
	return _scroll_activation_z - global_position.z


func take_damage(amount: int, hit_world_position: Variant = null) -> void:
	_spawn_damage_popup(amount, hit_world_position)
	var will_die := armor - amount <= 0
	if not will_die:
		_spawn_hit_effect(hit_world_position)
		SoundManager.play_hit_sound(hit_sound)
	armor -= amount
	if will_die:
		die()


func die() -> void:
	HitComboManager.register_kill()
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_power_from_kill"):
		player.add_power_from_kill()
	SoundManager.play_sound(explosion_sound)
	if explosion_scene:
		var death_pos := global_position
		var explosion := explosion_scene.instantiate()
		if explosion.has_signal("finished"):
			explosion.finished.connect(explosion.queue_free)
		get_tree().current_scene.add_child(explosion)
		if explosion is Node3D:
			explosion.global_position = death_pos
	_spawn_pickups()
	queue_free()


func _spawn_damage_popup(amount: int, hit_world_position: Variant) -> void:
	var pos := global_position
	if hit_world_position is Vector3:
		pos = hit_world_position

	var jitter := Vector3(
		randf_range(-popup_spawn_jitter_local.x, popup_spawn_jitter_local.x),
		randf_range(-popup_spawn_jitter_local.y, popup_spawn_jitter_local.y),
		randf_range(-popup_spawn_jitter_local.z, popup_spawn_jitter_local.z)
	)
	pos += global_transform.basis * (popup_spawn_offset_local + jitter)
	DamagePopup.spawn(get_tree(), pos, amount)


func _spawn_hit_effect(hit_world_position: Variant) -> void:
	if hit_effect_scene == null:
		return

	var hit := hit_effect_scene.instantiate()
	add_child(hit)
	if hit is Node3D:
		var local_pos := Vector3.ZERO
		if hit_world_position is Vector3:
			local_pos = to_local(hit_world_position)
		(hit as Node3D).position = local_pos

	if hit.get("one_shot") != null:
		hit.set("one_shot", true)
	if hit.get("autoplay") != null:
		hit.set("autoplay", false)
	if hit.has_signal("finished"):
		hit.finished.connect(hit.queue_free)
	if hit.has_method("play"):
		hit.play()


func _spawn_pickups() -> void:
	var pickup_scene := SceneRegistry.pickup_scene
	if pickup_scene == null or value <= 0:
		return

	var scene_root := get_tree().current_scene
	# Kamera top-down: niższe Y renderuje się pod eksplozją — loot schodzimy w dół.
	var spawn_offset := Vector3(0.0, -2.0, 0.0)
	for i in value:
		var pickup := pickup_scene.instantiate()
		scene_root.add_child(pickup)
		if pickup is Node3D:
			pickup.global_position = global_position + spawn_offset

		var angle := randf() * TAU
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var speed := randf_range(4.0, 8.0)
		if pickup.has_method("launch"):
			pickup.launch(dir, speed)


func _process_weapon(delta: float) -> void:
	_fire_timer = max(0.0, _fire_timer - delta)
	if not _weapon_firing or _fire_timer > 0.0:
		return
	weapon_data.fire(self, _muzzles, _weapon_state)
	SoundManager.play_weapon_sound(weapon_data.sound)
	_fire_timer = weapon_data.get_next_fire_delay(_weapon_state)


func _collect_muzzles() -> void:
	_muzzles.clear()
	var m1 := get_node_or_null("Muzzle") as Marker3D
	if m1:
		_muzzles.append(m1)
	var m2 := get_node_or_null("Muzzle2") as Marker3D
	if m2:
		_muzzles.append(m2)


func _find_facing() -> EnemyFacing:
	for child in get_children():
		if child is EnemyFacing:
			return child
	var parent := get_parent()
	if parent is PathFollow3D:
		for sibling in parent.get_children():
			if sibling is EnemyFacing:
				return sibling
	return null


func _refresh_activation() -> void:
	if global_position.z >= _scroll_activation_z:
		_activate()
	else:
		_deactivate()


func _activate() -> void:
	if _is_active:
		return
	_is_active = true
	_move_elapsed = 0.0
	set_firing(true)
	# PathFollow odpina EnemyPathFollow; wrogowie bez ścieżki — tutaj.
	if not get_parent() is PathFollow3D:
		LevelScroll3D.detach_to_active_scene(self)
	combat_activated.emit()


func _deactivate() -> void:
	if not _is_active:
		return
	_is_active = false
	set_firing(false)
	combat_deactivated.emit()


func _on_screen_exited() -> void:
	_deactivate()
	if despawn_off_screen:
		print("[Enemy] despawn off-screen: ", name, " @ z=", global_position.z)
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(armor)
		die()
