extends EnemyWeaponData
class_name HomingEnemyWeaponData

# ============================================================================
# HOMING WEAPON DATA - pociski śledzą gracza po wystrzeleniu.
# Zamiast aim (jednorazowa korekta kąta przy spawnie) używa homing:
# pocisk aktywnie skręca w kierunku gracza przez cały czas lotu.
# ============================================================================

## Szybkość skrętu pocisku w kierunku gracza (rad/s). Im wyżej, tym ostrzej skręca.
@export var homing_turn_speed: float = 3.0
## Czas (sekundy) przez który pocisk śledzi gracza. Po upływie leci prosto.
@export var homing_duration: float = 1.5


func fire(enemy: Node3D, muzzles: Array[Marker3D], _state: Dictionary) -> void:
	for from_muzzle in muzzles:
		_spawn_homing_projectile(enemy, from_muzzle)


func _spawn_homing_projectile(enemy: Node3D, from_muzzle: Marker3D) -> void:
	var projectile_scene := SceneRegistry.enemy_projectile_scene
	var projectile := projectile_scene.instantiate()
	enemy.get_tree().current_scene.add_child(projectile)
	projectile.global_position = from_muzzle.global_position
	projectile.velocity = _compute_projectile_velocity(enemy, projectile_velocity, from_muzzle)
	projectile.damage = damage
	projectile.homing = true
	projectile.turn_speed = homing_turn_speed
	projectile.homing_duration = homing_duration
