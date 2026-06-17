class_name WeaponComboShotData
extends Resource

@export var enabled: bool = true
## Próg combo ustala slot w WeaponData (combo_shot_1 = 5, _2 = 10, …). Pole zachowane dla kompatybilności zasobów.
@export var min_kill_combo: int = 5
@export var damage: int = 25
@export var power_use: int = 50
@export var velocity: Vector3 = Vector3(0, 0, -60)
@export var cooldown: float = 0.35
## Indeks sceny power_N.tscn (1 = power_1.tscn, 2 = power_2.tscn, …).
@export var projectile: int = 1
