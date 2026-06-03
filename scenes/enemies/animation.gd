extends Node3D

## Odtwarza animację poziomą i kompensuje LevelScroll (jak EnemyPath).
##
## SCENE_SCROLL_LINE (domyślny): animacja startuje, gdy **origin sceny** minie
## scroll_activation_z. Wroga ustaw nisko (ujemne lokalne Z) — wejdzie w kadr
## z boku, gdy scena trafi na linię górną kadru.
##
## ENEMY_SCROLL_LINE: stary tryb — start po combat_activated wroga.

enum ActivationMode {
	SCENE_SCROLL_LINE,
	ENEMY_SCROLL_LINE,
}

@export var animation_name: StringName = &"slide"
@export var compensate_level_scroll: bool = true

@export_group("Aktywacja")
@export var activation_mode: ActivationMode = ActivationMode.SCENE_SCROLL_LINE
## Linia górna kadru — dla SCENE_SCROLL_LINE liczy się global Z **tego węzła**.
@export var scroll_activation_z: float = -17.0
@export var warn_if_active_on_spawn: bool = true

@export_group("Prędkość")
@export var playback_speed: float = 1.0
@export var speed_curve: Curve

@onready var _anim: AnimationPlayer = $AnimationPlayer

var _enemy: Node
var _level_scroll: Node3D
var _sliding: bool = false
var _awaiting_scene_activation: bool = true


func _ready() -> void:
	_level_scroll = _find_level_scroll()
	_anim.animation_finished.connect(_on_animation_finished)
	set_process(false)
	call_deferred("_setup_activation")


func _setup_activation() -> void:
	_enemy = _find_enemy()
	if _enemy == null:
		push_warning("%s: brak wroga w grupie 'enemies'." % name)
		return

	match activation_mode:
		ActivationMode.SCENE_SCROLL_LINE:
			_setup_scene_scroll_activation()
		ActivationMode.ENEMY_SCROLL_LINE:
			_setup_enemy_scroll_activation()


func _setup_scene_scroll_activation() -> void:
	_enemy.activate_on_scroll_line = false
	if _enemy.is_combat_active():
		_enemy._deactivate()

	if warn_if_active_on_spawn:
		var remaining: float = scroll_activation_z - global_position.z
		if remaining <= 0.0:
			push_warning(
				"%s: scena już za linią aktywacji (%.1f). Przesuń instancję w -Z pod LevelScroll."
				% [name, remaining]
			)

	_awaiting_scene_activation = true
	set_process(true)


func _setup_enemy_scroll_activation() -> void:
	if _enemy.is_combat_active():
		_start_slide()
	else:
		_enemy.combat_activated.connect(_start_slide, CONNECT_ONE_SHOT)


func _process(delta: float) -> void:
	if not _sliding:
		if (
			activation_mode == ActivationMode.SCENE_SCROLL_LINE
			and _awaiting_scene_activation
			and global_position.z >= scroll_activation_z
		):
			_trigger_wave()
		return

	if compensate_level_scroll:
		_apply_scroll_compensation(delta)

	_update_playback_speed()


func _trigger_wave() -> void:
	if not _awaiting_scene_activation or _sliding:
		return
	_awaiting_scene_activation = false

	if _enemy.has_method("activate_combat"):
		_enemy.activate_combat()
	elif _enemy.has_method("_activate"):
		_enemy.activate_on_scroll_line = false
		_enemy._activate()

	_start_slide()


func _start_slide() -> void:
	if _sliding:
		return
	_sliding = true
	set_process(_needs_process())
	_anim.speed_scale = _sample_speed_multiplier(0.0)
	_anim.play(animation_name)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name != animation_name:
		return
	_sliding = false
	set_process(
		activation_mode == ActivationMode.SCENE_SCROLL_LINE and _awaiting_scene_activation
	)
	_anim.speed_scale = 1.0


func _apply_scroll_compensation(delta: float) -> void:
	if _level_scroll == null:
		return
	var scroll_speed: Variant = _level_scroll.get("scroll_speed")
	if scroll_speed == null or float(scroll_speed) == 0.0:
		return
	var scroll_delta: Vector3 = _level_scroll.global_transform.basis.z * float(scroll_speed) * delta
	global_position -= scroll_delta


func _update_playback_speed() -> void:
	if not _anim.is_playing():
		return
	_anim.speed_scale = _sample_speed_multiplier(_get_animation_progress())


func _sample_speed_multiplier(progress: float) -> float:
	var mul: float = maxf(0.0, playback_speed)
	if speed_curve:
		mul *= maxf(0.0, speed_curve.sample_baked(progress))
	return mul


func _get_animation_progress() -> float:
	var length: float = _anim.current_animation_length
	if length <= 0.0:
		return 0.0
	return clampf(_anim.current_animation_position / length, 0.0, 1.0)


func _needs_process() -> bool:
	if _sliding:
		return compensate_level_scroll or speed_curve != null
	return activation_mode == ActivationMode.SCENE_SCROLL_LINE and _awaiting_scene_activation


func _find_enemy() -> Node:
	for child in get_children():
		if child.is_in_group("enemies"):
			return child
	return null


func _find_level_scroll() -> Node3D:
	var node := get_parent()
	while node:
		var script: Script = node.get_script()
		if script and script.resource_path.get_file() == "LevelScroll3D.gd":
			return node as Node3D
		node = node.get_parent()
	return null
