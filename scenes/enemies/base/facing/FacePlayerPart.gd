extends EnemyFacing
class_name FacePlayerPart

## Model/część, którą ma obracać w stronę gracza (ścieżka od korzenia wroga).
@export var target_node: NodePath
## Szybkość wygładzania obrotu.
@export var turn_smooth: float = 6.0
## Korekta, jeśli "dziób" modelu nie patrzy w +Z.
@export var yaw_offset_degrees: float = 0.0

var _target: Node3D


func _ready() -> void:
	super._ready()
	if _enemy == null:
		return
	_target = _enemy.get_node_or_null(target_node) as Node3D
	if _target == null:
		push_warning("%s: target_node nie znaleziono: %s" % [name, target_node])


func process_facing(delta: float) -> void:
	if _enemy == null or _target == null:
		return

	var player := _enemy.get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	var to_player := player.global_position - _target.global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		return

	var target_yaw := atan2(to_player.x, to_player.z) + deg_to_rad(yaw_offset_degrees)
	var alpha := 1.0 - exp(-turn_smooth * delta) if turn_smooth > 0.0 else 1.0

	# Odejmujemy yaw kadłuba, żeby armata obracała się niezależnie od ruchu statku.
	var ship_yaw := _enemy.global_rotation.y
	var local_yaw := target_yaw - ship_yaw
	var local_rot := _target.rotation
	local_rot.y = lerp_angle(local_rot.y, local_yaw, alpha)
	_target.rotation = local_rot
