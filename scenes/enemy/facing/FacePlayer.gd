extends EnemyFacing
class_name FacePlayer

# ============================================================================
# FACE PLAYER - płynnie obraca wroga (yaw wokół Y) w stronę gracza.
# Obraca cały korzeń wroga, więc muzzle też celują w gracza (działa jak
# fizyczne celowanie). Kamera jest top-down, dlatego liczy się tylko yaw.
# ============================================================================

## Szybkość wygładzania obrotu (większe = szybciej dogania gracza).
@export var turn_smooth: float = 6.0
## Korekta, jeśli "dziób" modelu nie jest skierowany w +Z (np. 180 dla -Z).
@export var yaw_offset_degrees: float = 0.0


func process_facing(delta: float) -> void:
	if _enemy == null:
		return

	var player := _enemy.get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	var to_player := player.global_position - _enemy.global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		return

	# atan2(x, z): yaw, przy którym lokalna oś +Z wskazuje na gracza.
	var target_yaw := atan2(to_player.x, to_player.z) + deg_to_rad(yaw_offset_degrees)

	var alpha := 1.0 - exp(-turn_smooth * delta) if turn_smooth > 0.0 else 1.0
	var r := _enemy.rotation
	r.y = lerp_angle(r.y, target_yaw, alpha)
	_enemy.rotation = r
