extends MeshInstance3D

## Współczynnik prędkości względem LevelScroll (oś Z):
## 0 = tło stoi w miejscu w świecie, 1 = jedzie razem z poziomem (jak zwykłe dziecko).
@export_range(-1.0, 2.0, 0.01) var scroll_factor: float = 0.5

var _level_scroll: LevelScroll3D


func _ready() -> void:
	_level_scroll = LevelScroll3D._find_level_scroll(self) as LevelScroll3D
	if _level_scroll == null:
		push_warning("%s: brak rodzica LevelScroll3D — scroll_factor ignorowany." % name)


func _process(delta: float) -> void:
	if _level_scroll == null:
		return
	# Rodzic już przesuwa węzeł pełną prędkością scroll_speed — korygujemy do scroll_factor.
	position.z += _level_scroll.scroll_speed * (scroll_factor - 1.0) * delta
