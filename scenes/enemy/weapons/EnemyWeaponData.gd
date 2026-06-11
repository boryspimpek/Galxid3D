extends Resource
class_name EnemyWeaponData

# ============================================================================
# ENEMY WEAPON DATA - zasób parametrów broni wroga (wzorzec jak MovementData).
# Przypisujesz go do wroga przez @export weapon_data na korzeniu Enemy —
# różne instancje w scenie głównej mogą mieć osobne zasoby i parametry.
# Węzeł Weapon nadal określa WZÓR ognia (SimpleShoot, BurstShot itd.).
# ============================================================================

@export var damage: int = 1
@export var fire_rate: float = 250.0
@export var fire_on_activate: bool = false
@export var projectile_velocity: Vector3 = Vector3(0, 0, 8)
@export_range(0, 10, 1) var aim: int = 0
@export var sound: int = 1
