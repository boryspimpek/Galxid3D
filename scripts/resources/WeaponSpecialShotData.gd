class_name WeaponSpecialShotData
extends Resource

enum SpecialDeliveryMode {
	BURST,
	BEAM,
}

@export var enabled: bool = true
@export var damage: int = 1
@export var power_use: int = 50
@export var velocity: Vector3 = Vector3(0, 0, -60)
@export var cooldown: float = 0.15
## Indeks sceny power_N.tscn (1 = power_1.tscn, 2 = power_2.tscn, …).
@export var projectile: int = 1
## Wzorzec salwy. Pusta tablica = jeden pocisk (velocity + projectile powyżej).
@export var pellets: Array[WeaponShotPelletData] = []
## BURST = salwy przy trzymaniu przycisku; BEAM = stały promień przy trzymaniu R1.
@export var delivery_mode: SpecialDeliveryMode = SpecialDeliveryMode.BURST
## Odstęp między tikami obrażeń (tylko BEAM).
@export var beam_damage_interval: float = 0.05
@export_group("Homing")
@export var homing: bool = false
## Szybkość skrętu pocisku (rad/s). Działa tylko gdy homing = true.
@export var homing_turn_speed: float = 3.0
## Maksymalny kąt stożka dociągania (stopnie). Pocisk przyciąga tylko wrogów w tym kącie przed sobą.
@export var homing_angle_deg: float = 20.0
