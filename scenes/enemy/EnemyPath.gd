extends PathFollow3D

@export var speed: float = 10.0 # jednostki 3D na sekundę wzdłuż krzywej
@export var loop_path: bool = true
@export var face_movement: bool = true

func _process(delta: float):
	# PathFollow3D automatycznie ustawia swoją pozycję na podstawie `progress`.
	progress += speed * delta

	if loop_path:
		progress = fposmod(progress, get_baked_length_safe())
	else:
		progress = clamp(progress, 0.0, get_baked_length_safe())

	if face_movement:
		# obrót zgodnie z tangentem ścieżki (w Godot 4 wystarczy włączyć też `rotation_mode` w Inspectorze)
		rotation_mode = PathFollow3D.ROTATION_ORIENTED

func get_baked_length_safe() -> float:
	var p := get_parent()
	if p is Path3D and p.curve:
		return max(0.001, p.curve.get_baked_length())
	return 0.001