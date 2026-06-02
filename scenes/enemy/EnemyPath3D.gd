extends Path3D
class_name EnemyPath3D

@export var speed: float = 5.0 # jednostki 3D na sekundę wzdłuż krzywej
## Opcjonalny mnożnik prędkości wzdłuż ścieżki (oś X: 0..1 = progress/baked_length).
## Jeśli puste, poruszanie jest ze stałą prędkością `speed`.
@export var speed_curve: Curve
## Odejmuje przesunięcie LevelScroll od wroga — ścieżkę układasz tak, jak ma wyglądać na ekranie.
@export var compensate_level_scroll: bool = true

## Wymusza "przechył" (roll/bank) na zakrętach nawet dla płaskiej ścieżki (top-down).
@export var bank_enabled: bool = false
## Maksymalny przechył w stopniach.
@export_range(0.0, 89.0, 0.1) var bank_max_degrees: float = 45.0
## Jak mocno bank reaguje na zakręt (większe = mocniej).
@export_range(0.0, 10.0, 0.01) var bank_strength: float = 2.0
## Dystans (w jednostkach progress) użyty do estymacji skrętu.
@export_range(0.001, 100.0, 0.001) var bank_lookahead: float = 1.0
## Szybkość wygładzania przechyłu (większe = szybciej dogania).
@export_range(0.0, 30.0, 0.1) var bank_smooth: float = 10.0

