extends Node
class_name EnemyFacing

# ============================================================================
# ENEMY FACING - bazowy komponent orientacji (obrotu) wroga.
# Oddzielony od ruchu (movement_data = translacja) i broni. Enemy woła
# process_facing() co klatkę fizyki, gdy wróg jest aktywny. Konkretny sposób
# orientacji implementuje podklasa (np. FacePlayer).
#
# Komponent jest OPCJONALNY - dodaj węzeł "Facing" tylko tym wrogom, którzy
# mają się obracać. Wrogowie na Path3D zwykle go nie potrzebują (orientację
# steruje ścieżka), więc nie ma go w bazowym Enemy.tscn.
# ============================================================================

var _enemy: Node3D


func _ready() -> void:
	_enemy = get_parent() as Node3D


## Punkt rozszerzenia — nadpisz w podklasie. Baza nie obraca wrogiem.
func process_facing(_delta: float) -> void:
	pass
