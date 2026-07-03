extends FacePlayer
class_name DelayedFacePlayer

# ============================================================================
# DELAYED FACE PLAYER - FacePlayer który aktywuje się dopiero na końcu ścieżki
# lub po określonym czasie (delay_seconds). Dopóki nieaktywny, EnemyPathFollow
# używa ROTATION_ORIENTED (obrót wzdłuż krzywej).
# ============================================================================

## Aktywuj FacePlayer gdy wróg dotrze do końca ścieżki (progress_ratio >= 1.0).
@export var activate_at_path_end: bool = true
## Alternatywa: aktywuj po X sekundach (ignorowane gdy activate_at_path_end = true).
@export var delay_seconds: float = 0.0

var facing_active: bool = false
var _delay_timer: float = 0.0


func process_facing(delta: float) -> void:
	if facing_active:
		super.process_facing(delta)
		return

	if activate_at_path_end:
		var pf := _get_path_follow()
		if pf != null and pf.progress_ratio >= 1.0:
			facing_active = true
	elif delay_seconds > 0.0:
		_delay_timer += delta
		if _delay_timer >= delay_seconds:
			facing_active = true


func _get_path_follow() -> PathFollow3D:
	if _enemy == null:
		return null
	var parent := _enemy.get_parent()
	if parent is PathFollow3D:
		return parent as PathFollow3D
	return null
