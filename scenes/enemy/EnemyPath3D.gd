extends Path3D
class_name EnemyPath3D

@export var speed: float = 5.0 # jednostki 3D na sekundę wzdłuż krzywej
## Opcjonalny mnożnik prędkości wzdłuż ścieżki (oś X: 0..1 = progress/baked_length).
## Jeśli puste, poruszanie jest ze stałą prędkością `speed`.
@export var speed_curve: Curve
## Odejmuje przesunięcie LevelScroll od wroga — ścieżkę układasz tak, jak ma wyglądać na ekranie.
@export var compensate_level_scroll: bool = true

