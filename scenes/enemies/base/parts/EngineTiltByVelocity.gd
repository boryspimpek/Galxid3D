extends Node
class_name EngineTiltByVelocity

## Części do obracania (ścieżki od korzenia wroga, np. "EnemyModel/ThrusterA").
@export var target_nodes: Array[NodePath]
## Prędkość, przy której osiągamy kąt max_angle_degrees.
@export var speed_threshold: float = 6.0
## Kąt (w stopniach) przy prędkości 0.
@export var min_angle_degrees: float = 0.0
## Kąt (w stopniach) przy prędkości >= speed_threshold.
@export var max_angle_degrees: float = -90.0
## Oś obrotu w lokalnym układzie celu (0 = X, 1 = Y, 2 = Z).
@export_enum("X", "Y", "Z") var tilt_axis: int = 0
## Szybkość wygładzania interpolacji.
@export var smooth: float = 8.0

var _enemy: Node3D
var _targets: Array[Node3D] = []
var _last_position: Vector3
var _has_last: bool = false


func _ready() -> void:
	# _ready() dzieci wołany jest przed _ready() rodzica, więc wróg może jeszcze
	# nie być w grupie "enemies". Bierzemy bezpośredniego rodzica jako wroga.
	_enemy = get_parent() as Node3D

	# Jeśli ktoś umieści komponent głębiej, szukaj pierwszego Node3D w górę.
	var node := get_parent()
	while _enemy == null and node != null:
		_enemy = node as Node3D
		node = node.get_parent()

	if _enemy == null:
		push_warning("%s: nie znaleziono wroga wśród rodziców." % name)
		return

	for path in target_nodes:
		var target := _enemy.get_node_or_null(path) as Node3D
		if target != null:
			_targets.append(target)
		else:
			push_warning("%s: nie znaleziono celu: %s" % [name, path])

	_last_position = _enemy.global_position
	_has_last = true


func _physics_process(delta: float) -> void:
	if _enemy == null or _targets.is_empty():
		return

	var velocity := Vector3.ZERO
	if _has_last:
		velocity = (_enemy.global_position - _last_position) / maxf(delta, 0.0001)
	_last_position = _enemy.global_position
	_has_last = true

	var speed := velocity.length()
	var t := clampf(speed / maxf(speed_threshold, 0.0001), 0.0, 1.0)
	var target_angle := deg_to_rad(lerpf(min_angle_degrees, max_angle_degrees, t))
	var alpha := 1.0 - exp(-smooth * delta) if smooth > 0.0 else 1.0

	for target in _targets:
		match tilt_axis:
			0:
				target.rotation.x = lerp_angle(target.rotation.x, target_angle, alpha)
			1:
				target.rotation.y = lerp_angle(target.rotation.y, target_angle, alpha)
			2:
				target.rotation.z = lerp_angle(target.rotation.z, target_angle, alpha)
