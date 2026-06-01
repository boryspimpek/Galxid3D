extends Node3D

## Przesuwa całą zawartość poziomu w stronę gracza (oś Z).
## Umieść pod tym węzłem: Path3D, wrogów, planety, tło itd.
## Gracz, kamera i HUD zostają na scenie głównej (rodzic tego węzła).

@export var scroll_speed: float = 1.0
# @export var auto_scroll: bool = true
@export var start_offset_z: float = 0.0

func _ready() -> void:
	if start_offset_z != 0.0:
		position.z = start_offset_z

func _physics_process(delta: float) -> void:
	position.z += scroll_speed * delta
