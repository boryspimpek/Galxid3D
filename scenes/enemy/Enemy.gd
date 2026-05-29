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
## Po pierwszej aktywacji nie wyłączaj (np. wrogowie na Path3D).
@export var lock_activation_once: bool = false

enum ActivationBoundsMode {
	PLAY_AREA,    ## prostokąt planszy + notifier (wrogowie prosto w dół)
	SCROLL_LINE,  ## linia Z u góry kadru — jak linijka 2D (wrogowie na Path3D)
	SCREEN_ONLY,  ## tylko VisibleOnScreenNotifier3D
}
@export var activation_bounds_mode: ActivationBoundsMode = ActivationBoundsMode.PLAY_AREA

@export_group("Granice — Play Area")
@export var play_area_max_x: float = 10.0
@export var play_area_max_z: float = 17.0

@export_group("Granice — Scroll Line")
## Górna krawędź kadru. Wróg aktywuje się gdy global_position.z >= tej wartości.
## Ustaw na minus max_bound_z z PlayAreaFrame.
@export var scroll_activation_z: float = -17.0

var _screen_notifier: VisibleOnScreenNotifier3D
var _activation_locked: bool = false

signal combat_activated
signal combat_deactivated


# --- METODY WBUDOWANE (LIFECYCLE) ---

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5
	
	enemy_velocity = Vector3(float(xmove), float(ymove), float(zmove))

	if get_parent() is PathFollow3D:
		lock_activation_once = true
		activation_bounds_mode = ActivationBoundsMode.SCROLL_LINE
	
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


func is_combat_active() -> bool:
	return _is_active


## Ile jednostek brakuje do linii aktywacji (0 = właśnie teraz).
func get_scroll_distance_remaining() -> float:
	return scroll_activation_z - global_position.z


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
	if _activation_locked:
		return
	if _should_be_active():
		_activate()
		if lock_activation_once:
			_activation_locked = true
	else:
		_deactivate()


func _should_be_active() -> bool:
	match activation_bounds_mode:
		ActivationBoundsMode.SCROLL_LINE:
			return global_position.z >= scroll_activation_z
		ActivationBoundsMode.PLAY_AREA:
			if _screen_notifier and not _screen_notifier.is_on_screen():
				return false
			return _is_in_play_area()
		ActivationBoundsMode.SCREEN_ONLY:
			if _screen_notifier:
				return _screen_notifier.is_on_screen()
			return true
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
