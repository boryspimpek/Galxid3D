extends Path3D
class_name EnemyPath3D

## SCENE_SCROLL_LINE: start, gdy punkt aktywacji minie scroll_activation_z.
## Punkt: węzeł „ActivationOrigin”, rodzic Node3D (root sceny) lub ten Path3D.
## Dla packed scene użyj root Node3D + opcjonalny ActivationOrigin (jak animation.gd).
## ENEMY_SCROLL_LINE: każdy wróg aktywuje się po swojej pozycji Z (domyślne fale).
enum ActivationMode {
	SCENE_SCROLL_LINE,
	ENEMY_SCROLL_LINE,
}

signal wave_activated

const ACTIVATION_ORIGIN_NAME := "ActivationOrigin"

@export_group("Aktywacja")
@export var activation_mode: ActivationMode = ActivationMode.ENEMY_SCROLL_LINE
## Opcjonalnie: inny węzeł niż ActivationOrigin / rodzic Node3D (ścieżka od tego Path3D).
@export var activation_origin: NodePath
@export var warn_if_active_on_spawn: bool = true

@export_group("Ruch")
@export var speed: float = 6.0 # jednostki 3D na sekundę wzdłuż krzywej
## Opcjonalny mnożnik prędkości wzdłuż ścieżki (oś X: 0..1 = progress/baked_length).
## Jeśli puste, poruszanie jest ze stałą prędkością `speed`.
@export var speed_curve: Curve

@export_group("Bank")
## Wymusza "przechył" (roll/bank) na zakrętach nawet dla płaskiej ścieżki (top-down).
@export var bank_enabled: bool = false
## Maksymalny przechył w stopniach.
@export_range(0.0, 89.0, 0.1) var bank_max_degrees: float = 45.0
## Jak mocno bank reaguje na zakręt (większe = mocniej).
@export_range(0.0, 10.0, 0.01) var bank_strength: float = 2.0
## Dystans (w jednostkach progress) użyty do estymacji skrętu.
@export_range(0.001, 100.0, 0.001) var bank_lookahead: float = 1.0
## Szybkość wygładzania przechyłu (większe = szybciej dogania).
@export_range(0.0, 30.0, 0.1) var bank_smooth: float = 10.0

var _awaiting_scene_activation: bool = false
var _wave_activated: bool = false
var _scroll_activation_z: float = -17.0


func _ready() -> void:
	call_deferred("_setup_activation")


func uses_scene_activation() -> bool:
	return activation_mode == ActivationMode.SCENE_SCROLL_LINE


func is_wave_activated() -> bool:
	return _wave_activated


func _setup_activation() -> void:
	var play_area := DataManager.get_play_area_config()
	if play_area:
		_scroll_activation_z = play_area.scroll_activation_z

	if activation_mode != ActivationMode.SCENE_SCROLL_LINE:
		return

	for enemy in _find_enemies():
		enemy.activate_on_scroll_line = false
		if enemy.is_combat_active():
			enemy._deactivate()

	if warn_if_active_on_spawn:
		var remaining: float = _scroll_activation_z - _get_activation_origin().global_position.z
		if remaining <= 0.0:
			push_warning(
				"%s: punkt aktywacji już za linią (%.1f). Przesuń root sceny lub ActivationOrigin w -Z."
				% [name, remaining]
			)

	_awaiting_scene_activation = true
	_wave_activated = false
	set_process(true)


func _process(_delta: float) -> void:
	if not _awaiting_scene_activation or _wave_activated:
		return
	if _get_activation_origin().global_position.z >= _scroll_activation_z:
		_trigger_wave()


func _get_activation_origin() -> Node3D:
	if not activation_origin.is_empty():
		var custom := get_node_or_null(activation_origin) as Node3D
		if custom:
			return custom

	var parent := get_parent()
	if parent:
		var marker := parent.get_node_or_null(ACTIVATION_ORIGIN_NAME) as Node3D
		if marker:
			return marker
		if parent is Node3D and not parent is Path3D:
			return parent as Node3D

	return self


func _trigger_wave() -> void:
	if _wave_activated:
		return
	_wave_activated = true
	_awaiting_scene_activation = false
	set_process(false)

	for enemy in _find_enemies():
		enemy.activate_combat()

	wave_activated.emit()


func _find_enemies() -> Array[Node]:
	var result: Array[Node] = []
	for node in find_children("*", "", true, false):
		if node.is_in_group("enemies"):
			result.append(node)
	return result
