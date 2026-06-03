extends Node3D

## Odtwarza animację po aktywacji wroga i kompensuje LevelScroll,
## żeby ruch na ekranie był poziomy (jak przy EnemyPath).
##
## speed_curve (opcjonalna): oś X 0..1 = postęp animacji, Y = mnożnik prędkości
## (1.0 = normalnie). Kompensacja scrolla jest zawsze w czasie rzeczywistym —
## niezależnie od speed_scale — więc zmiana prędkości animacji nie psuje osi Z.

@export var animation_name: StringName = &"slide"
@export var compensate_level_scroll: bool = true

@export_group("Prędkość")
## Stały mnożnik, gdy speed_curve jest pusta.
@export var playback_speed: float = 1.0
## Krzywa prędkości w trakcie ruchu (jak speed_curve w EnemyPath3D).
@export var speed_curve: Curve

@onready var _anim: AnimationPlayer = $AnimationPlayer

var _enemy: Node
var _level_scroll: Node3D
var _sliding: bool = false


func _ready() -> void:
	_level_scroll = _find_level_scroll()
	_enemy = _find_enemy()
	if _enemy == null:
		push_warning("%s: brak wroga w grupie 'enemies'." % name)
		return

	_anim.animation_finished.connect(_on_animation_finished)
	set_physics_process(false)

	if _enemy.is_combat_active():
		_start_slide()
	else:
		_enemy.combat_activated.connect(_start_slide, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	if not _sliding:
		return

	if compensate_level_scroll:
		_apply_scroll_compensation(delta)

	_update_playback_speed()


func _start_slide() -> void:
	if _sliding:
		return
	_sliding = true
	set_physics_process(_needs_physics_process())
	_anim.speed_scale = _sample_speed_multiplier(0.0)
	_anim.play(animation_name)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name != animation_name:
		return
	_sliding = false
	set_physics_process(false)
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


func _needs_physics_process() -> bool:
	return compensate_level_scroll or speed_curve != null


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
