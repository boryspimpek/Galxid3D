extends LinearMoveData
class_name TimedMoveData

# ============================================================================
# TIMED MOVE DATA - ruch liniowy (jak LinearMoveData), ale z limitem.
# Po przekroczeniu limitu prędkość spada do zera (wróg się zatrzymuje).
# Limit można podać jako CZAS (sekundy) albo DYSTANS (jednostki 3D) - przy
# stałej prędkości to równoważne (dystans = prędkość * czas), więc wybierz
# co wygodniejsze w danej sytuacji.
# ============================================================================

enum LimitMode { TIME, DISTANCE }

## Czy limit liczyć w sekundach, czy w przebytym dystansie.
@export var limit_mode: LimitMode = LimitMode.TIME
## Wartość limitu: sekundy (TIME) lub jednostki 3D (DISTANCE). 0 = bez limitu.
@export var limit: float = 2.0


func get_velocity(elapsed: float) -> Vector3:
	var base := super.get_velocity(elapsed)
	if limit <= 0.0:
		return base

	match limit_mode:
		LimitMode.TIME:
			return base if elapsed < limit else Vector3.ZERO
		LimitMode.DISTANCE:
			var speed := base.length()
			if speed < 0.001:
				return base
			return base if speed * elapsed < limit else Vector3.ZERO

	return base
