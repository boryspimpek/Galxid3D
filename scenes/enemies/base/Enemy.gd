extends Area3D

# --- ZMIENNE EKSPORTOWANE (@EXPORT) ---
@export_group("Combat")
@export var armor: int = 1
## Zasób broni (EnemyWeaponData / BurstEnemyWeaponData / CircleEnemyWeaponData).
## Jak movement_data — zostaw pusty, jeśli wróg nie strzela.
@export var weapon_data: EnemyWeaponData

@export_group("Movement")
## Zasób ruchu (np. LinearMoveData). Edytowalny per instancja na korzeniu wroga.
## Zostaw pusty dla wrogów sterowanych ścieżką (Path3D).
@export var movement_data: MovementData

@export_group("General")
@export var value: int = 2

@export_group("Visual")
## Scena wybuchu po śmierci — przeciągnij scenę VFX z FileSystem.
@export var explosion_scene: PackedScene
## Efekt trafienia (np. Binbun vfx_hit_01) — odtwarzany przy każdym nieśmiertelnym trafieniu.
@export var hit_effect_scene: PackedScene
## Przesunięcie popupu obrażeń w lokalnych osiach wroga (Z− = tył / „wyżej” na ekranie).
var popup_spawn_offset_local: Vector3 = Vector3(0.0, 0.35, -1.2)
## Losowy rozrzut ± w lokalnych osiach wroga (X = boki, Y = góra, Z = przód/tył).
var popup_spawn_jitter_local: Vector3 = Vector3(0.25, 0.0, 0.35)

# --- REFERENCJE WĘZŁÓW (@ONREADY) ---
@onready var ship_model: Node3D = $EnemyModel

# --- ZMIENNE WEWNĘTRZNE (LOGIKA) ---
var _is_active: bool = false
## Czas (s) odkąd ruch jest aktywny — przekazywany do MovementData.get_velocity().
var _move_elapsed: float = 0.0
var _weapon_firing: bool = false
var _fire_timer: float = 0.0
## Stan wzorca broni (np. licznik serii burst) — zasób weapon_data jest bezstanowy.
var _weapon_state: Dictionary = {}
var _muzzles: Array[Marker3D] = []
## Opcjonalny komponent orientacji (dziecko dziedziczące po EnemyFacing).
var _facing: EnemyFacing

@export_group("Activation")
@export var activate_on_scroll_line: bool = true
@export var despawn_off_screen: bool = true
## Górna krawędź kadru. Wróg aktywuje się gdy global_position.z >= tej wartości.
## Ustaw jak PlayAreaConfig.scroll_activation_z (domyślnie -17.0).
@export var scroll_activation_z: float = -17.0

var _screen_notifier: VisibleOnScreenNotifier3D

signal combat_activated
signal combat_deactivated


# --- METODY WBUDOWANE (LIFECYCLE) ---

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON

	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5

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


# --- METODY PUBLICZNE (API ENEMY) ---

func set_firing(firing: bool) -> void:
	if firing and not _weapon_firing and weapon_data:
		weapon_data.on_begin_firing(_weapon_state)
		_fire_timer = 0.0 if weapon_data.fire_on_activate else weapon_data.fire_rate
	_weapon_firing = firing


func is_combat_active() -> bool:
	return _is_active


## Wymusza walkę bez linii scrolla (np. fale slide sterowane przez animation.gd).
func activate_combat() -> void:
	activate_on_scroll_line = false
	_activate()


## Ile jednostek brakuje do linii aktywacji (0 = właśnie teraz).
func get_scroll_distance_remaining() -> float:
	return scroll_activation_z - global_position.z


func take_damage(amount: int, hit_world_position: Variant = null) -> void:
	_spawn_damage_popup(amount, hit_world_position)
	var will_die := armor - amount <= 0
	if not will_die:
		_spawn_hit_effect(hit_world_position)
		SoundManager.play_hit_sound(3)
	armor -= amount
	if will_die:
		die()


func die() -> void:
	HitComboManager.register_kill()
	SoundManager.play_sound(9)
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


## Wyrzuca `value` pickupów z pozycji wroga w losowych kierunkach (płaszczyzna XZ).
func _spawn_pickups() -> void:
	var pickup_scene := SceneRegistry.pickup_scene
	if pickup_scene == null or value <= 0:
		return

	var scene_root := get_tree().current_scene
	# Kamera jest top-down (patrzy w dół osi Y), więc niższe Y renderuje się
	# "pod" eksplozją (Y=0). Przesuwamy loot w dół, by nie przysłaniał wybuchu.
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


# --- BROŃ (weapon_data) ---

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


# --- AKTYWACJA (linia scrolla) ---

func _refresh_activation() -> void:
	if global_position.z >= scroll_activation_z:
		_activate()
	else:
		_deactivate()


func _activate() -> void:
	if _is_active:
		return
	_is_active = true
	_move_elapsed = 0.0
	set_firing(true)
	# PathFollow odpina się w EnemyPathFollow; wrogowie bez ścieżki — tutaj.
	if not get_parent() is PathFollow3D:
		LevelScroll3D.detach_to_active_scene(self)
	combat_activated.emit()


func _deactivate() -> void:
	if not _is_active:
		return
	_is_active = false
	set_firing(false)
	combat_deactivated.emit()


# --- OBSŁUGA SYGNAŁÓW (SIGNALS) ---

func _on_screen_exited() -> void:
	_deactivate()
	if despawn_off_screen:
		print("[Enemy] despawn off-screen: ", name, " @ z=", global_position.z)
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(armor)
		die()
