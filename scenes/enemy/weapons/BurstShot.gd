extends EnemyWeapon
class_name BurstShot

# ============================================================================
# BURST SHOT - ogień seriami.
# Wystrzeliwuje `burst_count` strzałów w krótkich odstępach `burst_interval`,
# a potem robi długą przerwę (`fire_rate` z bazy) i powtarza:
# seria - przerwa - seria - przerwa ...
# Każdy strzał (jak w SimpleShoot) to po jednym pocisku z każdego muzzla.
# ============================================================================

## Liczba strzałów w jednej serii.
@export var burst_count: int = 3
## Odstęp między kolejnymi strzałami w obrębie serii (sekundy).
@export var burst_interval: float = 0.12

var _shots_left: int = 0


func _ready() -> void:
	super._ready()
	_shots_left = burst_count


func set_firing(firing: bool) -> void:
	# Każda aktywacja zaczyna nową serię od początku.
	if firing and not is_firing:
		_shots_left = burst_count
	super.set_firing(firing)


func fire() -> void:
	for from_muzzle in _muzzles:
		spawn_projectile(from_muzzle)
	_shots_left -= 1


func _next_fire_delay() -> float:
	if _shots_left > 0:
		return burst_interval
	# Koniec serii: długa przerwa i reset licznika na następną serię.
	_shots_left = burst_count
	return fire_rate
