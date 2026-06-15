class_name WeaponComboShotData
extends Resource

@export var enabled: bool = true
## Minimalne combo zabójstw (HitComboManager) wymagane do strzału.
@export var min_kill_combo: int = 4
@export var damage: int = 25
@export var power_use: int = 50
@export var velocity: Vector3 = Vector3(0, 0, -60)
@export var cooldown: float = 0.35
## 0 = ProjectileX, 1 = Projectile.tscn, 2+ = ProjectileN.tscn
@export var projectile: int = 0
