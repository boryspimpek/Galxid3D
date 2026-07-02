class_name WeaponShotPelletData
extends Resource

## Obrót kierunku strzału względem bazowego velocity (stopnie, oś Y — fan w płaszczyźnie XZ).
@export var angle_deg: float = 0.0
## Przesunięcie punktu spawnu w lokalnej przestrzeni Muzzle (równoległe salwy, skrzydłowe działa).
@export var spawn_offset: Vector3 = Vector3.ZERO
## Mnożnik prędkości bazowego velocity (1.0 = bez zmian).
@export var velocity_scale: float = 1.0
## Indeks sceny pocisku dla tego pelletu (0 = użyj bazowego z WeaponPowerLevelData).
@export var projectile_override: int = 0
