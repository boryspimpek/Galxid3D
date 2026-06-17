class_name WeaponComboShotData
extends Resource

enum ComboDeliveryMode {
	BURST,
	BEAM,
}

@export var enabled: bool = true
## Próg combo ustala slot w WeaponData (combo_shot_1 = 5, _2 = 10, …). Pole zachowane dla kompatybilności zasobów.
@export var min_kill_combo: int = 5
@export var damage: int = 25
@export var power_use: int = 50
@export var velocity: Vector3 = Vector3(0, 0, -60)
@export var cooldown: float = 0.35
## Indeks sceny power_N.tscn (1 = power_1.tscn, 2 = power_2.tscn, …).
@export var projectile: int = 1
## Wzorzec salwy. Pusta tablica = jeden pocisk (velocity + projectile powyżej).
@export var pellets: Array[WeaponShotPelletData] = []
## BURST = salwy przy trzymaniu fire/combo_shot; BEAM = stały promień przy aktywnym progu combo.
@export var delivery_mode: ComboDeliveryMode = ComboDeliveryMode.BURST
## Odstęp między tikami obrażeń (tylko BEAM).
@export var beam_damage_interval: float = 0.08
