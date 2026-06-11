extends EnemyWeaponData
class_name BurstEnemyWeaponData

# ============================================================================
# BURST WEAPON DATA - ogień seriami.
# burst_count strzałów co burst_interval, potem przerwa fire_rate i powtórka.
# ============================================================================

const KEY_SHOTS_LEFT := &"burst_shots_left"

@export var burst_count: int = 3
@export var burst_interval: float = 0.12


func on_begin_firing(state: Dictionary) -> void:
	state[KEY_SHOTS_LEFT] = burst_count


func fire(enemy: Node3D, muzzles: Array[Marker3D], state: Dictionary) -> void:
	super.fire(enemy, muzzles, state)
	state[KEY_SHOTS_LEFT] = int(state.get(KEY_SHOTS_LEFT, burst_count)) - 1


func get_next_fire_delay(state: Dictionary) -> float:
	if int(state.get(KEY_SHOTS_LEFT, 0)) > 0:
		return burst_interval
	state[KEY_SHOTS_LEFT] = burst_count
	return fire_rate
