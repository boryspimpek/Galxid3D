extends Node
class_name EnemyFacing

# ============================================================================
# ENEMY FACING - bazowy komponent orientacji (obrotu) wroga.
# Oddzielony od ruchu (movement_data = translacja) i broni. Enemy woła
# process_facing() co klatkę fizyki, gdy wróg jest aktywny. Konkretny sposób
# orientacji implementuje podklasa (np. FacePlayer, FacePath).
#
# Komponent jest OPCJONALNY - dodaj węzeł "Facing" tylko tym wrogom, którzy
# mają się obracać. Na Path3D: FacePlayer (w stronę gracza) lub FacePath
# (wzdłuż ścieżki). Bez Facing EnemyPath obraca PathFollow (ROTATION_ORIENTED).
# ============================================================================

var _enemy: Node3D


func _ready() -> void:
	var parent := get_parent()
	if parent != null and parent.is_in_group("enemies"):
		_enemy = parent as Node3D
	elif parent is PathFollow3D:
		for sibling in parent.get_children():
			if sibling.is_in_group("enemies"):
				_enemy = sibling as Node3D
				push_warning(
					"%s: węzeł Facing powinien być dzieckiem wroga, nie rodzeństwem PathFollow3D."
					% sibling.name
				)
				return
	_enemy = parent as Node3D


## Punkt rozszerzenia — nadpisz w podklasie. Baza nie obraca wrogiem.
func process_facing(_delta: float) -> void:
	pass
