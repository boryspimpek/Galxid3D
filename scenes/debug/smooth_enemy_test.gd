extends Node3D

## Scena testowa płynności na tablecie (F6).
##
## PathOnlyWave — blaze na krzywej wave 2, BEZ LevelScroll i kompensacji
## (TestEnemyPath: _physics_process + physics_interpolation).
##
## Sondy (opcjonalnie): show_test_probes w inspektorze.


@export var show_test_probes: bool = false


func _ready() -> void:
	_apply_probe_visibility()
	print("SmoothEnemyTest: PathOnlyWave = ścieżka bez scrolla. Probes=", show_test_probes)


func _apply_probe_visibility() -> void:
	for n in [
		"ProbeAreaProcess",
		"ProbeAreaPhysics",
		"ProbeCharacter",
		"ProbePlayerTouch",
	]:
		var node := get_node_or_null(n)
		if node:
			node.visible = show_test_probes
