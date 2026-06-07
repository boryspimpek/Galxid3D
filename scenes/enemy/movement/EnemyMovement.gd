extends Node
class_name EnemyMovement

# ============================================================================
# ENEMY MOVEMENT - bazowy komponent ruchu wroga.
# Uniwersalny punkt zaczepienia: Enemy wywołuje process_movement() co klatkę
# fizyki, gdy wróg jest aktywny. Konkretny SPOSÓB ruchu (liniowy, kołowy,
# sinusoidalny, ...) implementuje podklasa, nadpisując process_movement().
#
# Uwaga: ruch po Path3D (EnemyFollow / EnemyPath3D) działa niezależnie -
# tam pozycję steruje PathFollow3D. Ten komponent dotyczy ruchu "własnego"
# wroga; dla wrogów na ścieżce zostaw domyślny LinearMove z zerową prędkością.
# ============================================================================

var _enemy: Node3D


func _ready() -> void:
	_enemy = get_parent() as Node3D


## Punkt rozszerzenia — nadpisz w podklasie. Baza nie rusza wrogiem.
func process_movement(_delta: float) -> void:
	pass
