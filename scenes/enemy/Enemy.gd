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


# --- METODY WBUDOWANE (LIFECYCLE) ---

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5
	
	enemy_velocity = Vector3(float(xmove), float(ymove), float(zmove))
	
	if has_node("VisibleOnScreenNotifier3D"):
		$VisibleOnScreenNotifier3D.screen_exited.connect(_on_screen_exited)

	is_firing = true

func _process(delta: float) -> void:
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


# --- OBSŁUGA SYGNAŁÓW (SIGNALS) ---

func _on_screen_exited() -> void:
	queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(armor)
		die()
