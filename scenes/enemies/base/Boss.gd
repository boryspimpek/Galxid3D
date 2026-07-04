extends "res://scenes/enemies/base/Enemy.gd"

# ============================================================================
# BOSS - wróg z cyklicznym systemem broni.
# Zamiast pojedynczego weapon_data przechodzi przez weapon_phases:
# każda faza to broń + czas trwania + przerwa + wybór muzzli.
# Po ostatniej fazie cykl wraca do pierwszej.
# Zostaw weapon_data (z Enemy) pusty — bossem steruje cykl faz.
# ============================================================================

@export_group("Boss Weapon Cycle")
@export var weapon_phases: Array[BossWeaponPhase] = []

var _phase_index: int = -1
var _phase_timer: float = 0.0
var _phase_in_cooldown: bool = false
var _phase_fire_timer: float = 0.0
## Osobny stan wzorca per faza — te same zasoby broni nie mieszają sobie stanu.
var _phase_states: Array[Dictionary] = []
var _phase_muzzles: Array[Marker3D] = []


func _ready() -> void:
	super._ready()
	_phase_states.clear()
	for phase in weapon_phases:
		_phase_states.append({})


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _is_active or not _weapon_firing:
		return
	if weapon_phases.is_empty():
		return
	_process_phase_cycle(delta)


func set_firing(firing: bool) -> void:
	if firing and not _weapon_firing and not weapon_phases.is_empty():
		_start_phase(0)
	super.set_firing(firing)


func _process_phase_cycle(delta: float) -> void:
	_phase_timer -= delta

	if _phase_in_cooldown:
		if _phase_timer <= 0.0:
			_start_phase((_phase_index + 1) % weapon_phases.size())
		return

	var phase := weapon_phases[_phase_index]
	if phase != null and phase.weapon != null:
		_phase_fire_timer = max(0.0, _phase_fire_timer - delta)
		if _phase_fire_timer <= 0.0:
			var state := _phase_states[_phase_index]
			phase.weapon.fire(self, _phase_muzzles, state)
			SoundManager.play_weapon_sound(phase.weapon.sound)
			_phase_fire_timer = phase.weapon.get_next_fire_delay(state)

	if _phase_timer <= 0.0:
		_phase_in_cooldown = true
		_phase_timer = phase.cooldown_after if phase != null else 0.0


func _start_phase(index: int) -> void:
	_phase_index = index
	_phase_in_cooldown = false

	var phase := weapon_phases[index]
	if phase == null or phase.weapon == null:
		# Faza bez broni = pauza w cyklu.
		_phase_timer = phase.duration if phase != null else 0.0
		return

	_phase_timer = phase.duration
	_phase_muzzles = _resolve_phase_muzzles(phase)

	var state := _phase_states[index]
	phase.weapon.on_begin_firing(state)
	_phase_fire_timer = 0.0 if phase.weapon.fire_on_activate else phase.weapon.get_initial_fire_delay(state)


func _resolve_phase_muzzles(phase: BossWeaponPhase) -> Array[Marker3D]:
	if phase.muzzle_indices.is_empty():
		return _muzzles
	var result: Array[Marker3D] = []
	for i in phase.muzzle_indices:
		if i >= 0 and i < _muzzles.size():
			result.append(_muzzles[i])
		else:
			push_warning("%s: muzzle_indices zawiera nieistniejący indeks %d (muzzli: %d)" % [name, i, _muzzles.size()])
	return result
