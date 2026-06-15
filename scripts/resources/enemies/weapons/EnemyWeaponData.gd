extends Resource
class_name EnemyWeaponData

# ============================================================================
# ENEMY WEAPON DATA - zasób broni wroga (wzorzec jak MovementData).
# Przypisujesz go przez @export weapon_data na korzeniu Enemy.
# Podklasa określa wzór ognia (domyślnie: po jednym pocisku z każdego muzzla).
# Stan czasu/strzałów żyje na wrogu (_weapon_state) — zasób może być współdzielony.
# ============================================================================

@export var damage: int = 1
@export var fire_rate: float = 250.0
@export var fire_on_activate: bool = false
@export var projectile_velocity: Vector3 = Vector3(0, 0, 8)
@export_range(0, 10, 1) var aim: int = 0
@export var sound: int = 1

const AIM_MAX := 10


## Wywoływane przy włączeniu ognia — reset stanu wzorca (np. seria burst).
func on_begin_firing(_state: Dictionary) -> void:
	pass


## Wzorzec ognia — nadpisz w podklasie (np. BurstEnemyWeaponData).
func fire(enemy: Node3D, muzzles: Array[Marker3D], _state: Dictionary) -> void:
	for from_muzzle in muzzles:
		spawn_projectile(enemy, from_muzzle)


## Odstęp do kolejnego strzału (sekundy).
func get_next_fire_delay(_state: Dictionary) -> float:
	return fire_rate


func spawn_projectile(enemy: Node3D, from_muzzle: Marker3D) -> void:
	spawn_projectile_at(
		enemy,
		from_muzzle.global_position,
		_compute_projectile_velocity(enemy, projectile_velocity, from_muzzle)
	)


func spawn_projectile_at(enemy: Node3D, global_pos: Vector3, velocity: Vector3) -> void:
	var projectile_scene := SceneRegistry.enemy_projectile_scene
	var projectile := projectile_scene.instantiate()
	enemy.get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_pos
	projectile.velocity = velocity
	projectile.damage = damage


func _compute_projectile_velocity(enemy: Node3D, base_velocity: Vector3, from_muzzle: Marker3D) -> Vector3:
	if aim <= 0:
		return base_velocity

	var bullet_speed := base_velocity.length()
	if bullet_speed < 0.001:
		return base_velocity

	var base_dir := base_velocity / bullet_speed
	var player := enemy.get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return base_velocity

	var to_player := player.global_position - from_muzzle.global_position
	if to_player.length_squared() < 0.0001:
		return base_velocity

	var aim_weight := clampf(float(aim) / float(AIM_MAX), 0.0, 1.0)
	var final_dir := base_dir.lerp(to_player.normalized(), aim_weight).normalized()
	return final_dir * bullet_speed
