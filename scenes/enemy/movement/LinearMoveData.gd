extends MovementData
class_name LinearMoveData

# ============================================================================
# LINEAR MOVE DATA - prosty ruch ze stałą prędkością wzdłuż osi.
# Odpowiednik dotychczasowego xmove/ymove/zmove (jednostki 3D na sekundę).
# Zostaw 0,0,0 dla wrogów sterowanych ścieżką (Path3D).
# ============================================================================

@export var xmove: int = 0
@export var ymove: int = 0
@export var zmove: int = 0


func get_velocity(_elapsed: float) -> Vector3:
	return Vector3(float(xmove), float(ymove), float(zmove))
