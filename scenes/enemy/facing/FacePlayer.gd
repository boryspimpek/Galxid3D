extends EnemyFacing
class_name FacePlayer

# ============================================================================
# FACE PLAYER - płynnie obraca wroga (yaw wokół Y) w stronę gracza.
# Działa też na wrogach pod PathFollow3D (EnemyPath) — dodaj węzeł „Facing”
# ze skryptem FacePlayer; EnemyFollow wtedy nie obraca PathFollow za wrogiem.
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

	var target_yaw := atan2(to_player.x, to_player.z) + deg_to_rad(yaw_offset_degrees)
	var alpha := 1.0 - exp(-turn_smooth * delta) if turn_smooth > 0.0 else 1.0
	var bank_z := _enemy.rotation.z
	var global_r := _enemy.global_rotation
	global_r.x = 0.0
	global_r.y = lerp_angle(global_r.y, target_yaw, alpha)
	_enemy.global_rotation = global_r
	_enemy.rotation.z = bank_z
