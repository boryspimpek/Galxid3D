class_name WeaponPowerLevelData
extends Resource

@export var damage: int = 1
@export var fire_rate: float = 0.2
@export var power_use: int = 0
## Indeks sceny projectile_N.tscn (1 = projectile_1.tscn, 2 = projectile_2.tscn, …).
@export var projectile: int = 1
@export var velocity: Vector3 = Vector3(0, 0, -50)
## Wzorzec salwy. Pusta tablica = jeden pocisk (velocity + projectile powyżej).
@export var pellets: Array[WeaponShotPelletData] = []
@export_group("Homing")
@export var homing: bool = false
## Szybkość skrętu pocisku (rad/s). Działa tylko gdy homing = true.
@export var homing_turn_speed: float = 3.0
