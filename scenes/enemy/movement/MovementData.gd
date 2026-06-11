extends Resource
class_name MovementData

# ============================================================================
# MOVEMENT DATA - bazowy ZASÓB ruchu wroga (wzorzec jak EnemyWeaponData).
# Przypisujesz go do wroga przez @export movement_data — różne instancje
# mogą mieć różne zasoby (i różne parametry) edytowane wprost na korzeniu.
# Konkretny sposób ruchu implementuje podklasa, nadpisując get_velocity().
#
# WAŻNE: trzymaj tu tylko PARAMETRY. Zasób bywa współdzielony między wrogami,
# więc stan czasu (elapsed) żyje na wrogu i jest przekazywany do get_velocity().
# ============================================================================

## Zwraca prędkość (jednostki 3D/s) w danym momencie życia ruchu.
func get_velocity(_elapsed: float) -> Vector3:
	return Vector3.ZERO
