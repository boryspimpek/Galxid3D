extends EnemyMovement
class_name LinearMove

# ============================================================================
# LINEAR MOVE - prosty ruch ze stałą prędkością wzdłuż osi.
# Odpowiednik dotychczasowego mechanizmu xmove/ymove/zmove z Enemy.
# (jednostki 3D na sekundę). Zostaw 0,0,0 dla wrogów sterowanych ścieżką.
# ============================================================================

@export var xmove: int = 0
@export var ymove: int = 0
@export var zmove: int = 0

var _velocity: Vector3


func _ready() -> void:
	super._ready()
	_velocity = Vector3(float(xmove), float(ymove), float(zmove))


func process_movement(delta: float) -> void:
	if _enemy:
		_enemy.global_position += _velocity * delta
