extends Area3D

# --- ZMIENNE EKSPORTOWANE (@EXPORT) ---
@export_group("Combat")
@export var armor: int = 1
@export var damage: int = 1
@export var fire_rate: float = 250.0
@export_range(0, 10, 1) var aim: int = 0
const AIM_MAX := 10
@export var projectile_velocity: Vector3 = Vector3(0, 0, 60)

@export_group("Movement")
@export var xmove: int = 0
@export var ymove: int = 0
@export var zmove: int = 0

@export_group("General")
@export var sound: int = 1
@export var esize: int = 1
@export var value: int = 2

# --- REFERENCJE WĘZŁÓW (@ONREADY) ---
@onready var ship_model: Node3D = $EnemyModel
@onready var muzzle: Marker3D = $Muzzle

# --- ZMIENNE WEWNĘTRZNE (LOGIKA) ---
var _muzzles: Array[Marker3D] = []
var enemy_velocity: Vector3
var fire_timer: float = 0.0
var is_firing: bool = false
var _is_active: bool = false

@export_group("Activation")
@export var activate_on_scroll_line: bool = true
@export var despawn_off_screen: bool = true
## Górna krawędź kadru. Wróg aktywuje się gdy global_position.z >= tej wartości.
## Ustaw na minus max_bound_z z PlayAreaFrame (np. -17.0).
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

	enemy_velocity = Vector3(float(xmove), float(ymove), float(zmove))

	_muzzles = [muzzle]
	var muzzle2 := get_node_or_null("Muzzle2") as Marker3D
	if muzzle2:
		_muzzles.append(muzzle2)

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

	fire_timer = max(0.0, fire_timer - delta)
	if is_firing and fire_timer <= 0.0:
		shoot()

	global_position += enemy_velocity * delta


# --- METODY PUBLICZNE (API ENEMY) ---

func set_firing(firing: bool) -> void:
	is_firing = firing


func is_combat_active() -> bool:
	return _is_active


## Wymusza walkę bez linii scrolla (np. fale slide sterowane przez animation.gd).
func activate_combat() -> void:
	activate_on_scroll_line = false
	_activate()


## Ile jednostek brakuje do linii aktywacji (0 = właśnie teraz).
func get_scroll_distance_remaining() -> float:
	return scroll_activation_z - global_position.z


func take_damage(amount: int) -> void:
	armor -= amount
	if armor <= 0:
		die()
	else:
		# 003_S_ENEMY_HIT.wav
		SoundManager.play_hit_sound(3)


func die() -> void:
	SoundManager.play_sound(9 if esize == 1 else 8)
	var explosion_scene := GameConstants.get_explosion_scene(esize)
	if explosion_scene:
		var explosion := explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		if explosion is Node3D:
			explosion.global_position = global_position
	queue_free()


# --- OBSŁUGA STRZELANIA ---

func shoot() -> void:
	for from_muzzle in _muzzles:
		create_projectile(damage, projectile_velocity, from_muzzle)
	SoundManager.play_weapon_sound(sound)

	fire_timer = fire_rate


func create_projectile(dmg: int, proj_velocity: Vector3, from_muzzle: Marker3D) -> void:
	var projectile_scene = GameConstants.enemy_projectile_scene
	var projectile = projectile_scene.instantiate()

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = from_muzzle.global_position
	projectile.velocity = _compute_projectile_velocity(proj_velocity, from_muzzle)
	projectile.damage = dmg


func _compute_projectile_velocity(base_velocity: Vector3, from_muzzle: Marker3D) -> Vector3:
	if aim <= 0:
		return base_velocity

	var bullet_speed := base_velocity.length()
	if bullet_speed < 0.001:
		return base_velocity

	var base_dir := base_velocity / bullet_speed
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return base_velocity

	var to_player := player.global_position - from_muzzle.global_position
	if to_player.length_squared() < 0.0001:
		return base_velocity

	var aim_weight := clampf(float(aim) / float(AIM_MAX), 0.0, 1.0)
	var final_dir := base_dir.lerp(to_player.normalized(), aim_weight).normalized()
	return final_dir * bullet_speed


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
	is_firing = true
	fire_timer = fire_rate
	# PathFollow odpina się w EnemyPath; wrogowie bez ścieżki — tutaj.
	if not get_parent() is PathFollow3D:
		LevelScroll3D.detach_to_active_scene(self)
	combat_activated.emit()


func _deactivate() -> void:
	if not _is_active:
		return
	_is_active = false
	is_firing = false
	combat_deactivated.emit()


# --- OBSŁUGA SYGNAŁÓW (SIGNALS) ---

func _on_screen_exited() -> void:
	_deactivate()
	if despawn_off_screen:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(armor)
		die()
