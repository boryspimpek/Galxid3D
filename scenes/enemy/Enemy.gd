extends Area3D

# --- ZMIENNE EKSPORTOWANE (@EXPORT) ---
@export_group("Statystyki")
@export var armor: int = 1
@export var damage: int = 1
@export var fire_rate: float = 2.0
@export var projectile_velocity: Vector3 = Vector3(0, 0, 60)
@export var aim: int = 0
@export var sound: int = 1
@export var esize: int = 1

@export_group("Ruch Bazowy")
@export var xmove: int = 0
@export var ymove: int = 0
@export var zmove: int = 0

# --- REFERENCJE WĘZŁÓW (@ONREADY) ---
@onready var ship_model: Node3D = $EnemyModel
@onready var muzzle: Marker3D = $Muzzle

# --- ZMIENNE WEWNĘTRZNE (LOGIKA) ---
var enemy_velocity: Vector3
var fire_timer: float = 0.0
var is_firing: bool = false
var _is_active: bool = false

@export_group("Aktywacja")
@export var activate_on_screen: bool = true
@export var despawn_off_screen: bool = true
## Ogranicza aktywację do prostokąta gry (jak PlayAreaFrame), nie całego frustum kamery.
@export var use_play_area_bounds: bool = true
@export var play_area_max_x: float = 10.0
@export var play_area_max_z: float = 17.0

var _screen_notifier: VisibleOnScreenNotifier3D


# --- METODY WBUDOWANE (LIFECYCLE) ---

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5
	
	enemy_velocity = Vector3(float(xmove), float(ymove), float(zmove))
	
	_screen_notifier = get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if _screen_notifier:
		# Notifier musi mieć visible=true — inaczej Godot nie emituje sygnałów.
		_screen_notifier.visible = true
		_screen_notifier.screen_exited.connect(_on_screen_exited)

	if activate_on_screen:
		_deactivate()
		set_process(true)
	else:
		_activate()


func _process(delta: float) -> void:
	if activate_on_screen:
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


func take_damage(amount: int) -> void:
	armor -= amount
	if armor <= 0:
		die()
	else:
		SoundManager.play_sound(3)


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
	create_projectile(damage, projectile_velocity)
	SoundManager.play_weapon_sound(sound)

	fire_timer = fire_rate


func create_projectile(dmg: int, proj_velocity: Vector3) -> void:
	var projectile_scene = GameConstants.enemy_projectile_scene
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.velocity = proj_velocity
	projectile.damage = dmg


# --- AKTYWACJA (VisibleOnScreenNotifier3D + granice planszy) ---

func _refresh_activation() -> void:
	if _should_be_active():
		_activate()
	else:
		_deactivate()


func _should_be_active() -> bool:
	if _screen_notifier == null:
		return true
	if not _screen_notifier.is_on_screen():
		return false
	if use_play_area_bounds:
		return _is_in_play_area()
	return true


func _is_in_play_area() -> bool:
	return (
		absf(global_position.x) <= play_area_max_x
		and absf(global_position.z) <= play_area_max_z
	)


func _activate() -> void:
	if _is_active:
		return
	_is_active = true
	is_firing = true
	fire_timer = fire_rate


func _deactivate() -> void:
	_is_active = false
	is_firing = false


# --- OBSŁUGA SYGNAŁÓW (SIGNALS) ---

func _on_screen_exited() -> void:
	_deactivate()
	if despawn_off_screen:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(armor)
		die()
