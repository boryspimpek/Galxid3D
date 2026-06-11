extends Node
class_name EnemyWeapon

# ============================================================================
# ENEMY WEAPON - bazowy komponent strzelania wroga.
# Zawiera uniwersalną logikę: odliczanie timera, pętlę ognia, dźwięk,
# celowanie (aim) oraz tworzenie pojedynczego pocisku.
# Konkretny WZÓR ognia (ile pocisków, w jakich kierunkach) implementuje
# podklasa, nadpisując metodę fire() — np. SimpleShoot.
# ============================================================================

@export var damage: int = 1
@export var fire_rate: float = 250.0
## Pierwszy strzał od razu po aktywacji; kolejne nadal w rytmie fire_rate.
@export var fire_on_activate: bool = false
@export var projectile_velocity: Vector3 = Vector3(0, 0, 8)
@export_range(0, 10, 1) var aim: int = 0
@export var sound: int = 1

const AIM_MAX := 10

var is_firing: bool = false
var fire_timer: float = 0.0

var _enemy: Node3D
var _muzzles: Array[Marker3D] = []


func _ready() -> void:
	_enemy = get_parent() as Node3D
	_collect_muzzles()


func _physics_process(delta: float) -> void:
	fire_timer = max(0.0, fire_timer - delta)
	if is_firing and fire_timer <= 0.0:
		fire()
		SoundManager.play_weapon_sound(sound)
		fire_timer = _next_fire_delay()


## Włącza/wyłącza ogień. Domyślnie odczekujemy pełny cykl (fire_rate) przed pierwszym strzałem.
func set_firing(firing: bool) -> void:
	if firing and not is_firing:
		fire_timer = 0.0 if fire_on_activate else fire_rate
	is_firing = firing


## Punkt rozszerzenia — nadpisz w podklasie (np. SimpleShoot), żeby zdefiniować
## własny wzór ognia. Baza sama z siebie nie strzela.
func fire() -> void:
	pass


## Punkt rozszerzenia — odstęp do kolejnego wywołania fire().
## Domyślnie stały rytm (fire_rate); np. BurstShot zwraca krótszy odstęp w serii.
func _next_fire_delay() -> float:
	return fire_rate


## Tworzy pojedynczy pocisk z danego muzzla (z uwzględnieniem celowania aim).
func spawn_projectile(from_muzzle: Marker3D) -> void:
	var projectile_scene := GameConstants.enemy_projectile_scene
	var projectile := projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = from_muzzle.global_position
	projectile.velocity = _compute_projectile_velocity(projectile_velocity, from_muzzle)
	projectile.damage = damage


func _collect_muzzles() -> void:
	_muzzles.clear()
	if _enemy == null:
		return
	var m1 := _enemy.get_node_or_null("Muzzle") as Marker3D
	if m1:
		_muzzles.append(m1)
	var m2 := _enemy.get_node_or_null("Muzzle2") as Marker3D
	if m2:
		_muzzles.append(m2)


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
