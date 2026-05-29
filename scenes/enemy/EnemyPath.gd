extends PathFollow3D

@export var speed: float = 10.0 # jednostki 3D na sekundę wzdłuż krzywej
@export var loop_path: bool = true
@export var face_movement: bool = true
@export var wait_for_screen: bool = true

var _path_active: bool = false


func _ready() -> void:
	if not wait_for_screen:
		_path_active = true
		return

	_path_active = false
	set_process(false)

	var notifier := _find_screen_notifier()
	if notifier == null:
		_path_active = true
		set_process(true)
		return

	notifier.screen_entered.connect(_on_screen_entered)
	if notifier.is_on_screen():
		_on_screen_entered()


func _find_screen_notifier() -> VisibleOnScreenNotifier3D:
	for child in get_children():
		var found := _find_screen_notifier_in(child)
		if found:
			return found
	return null


func _find_screen_notifier_in(node: Node) -> VisibleOnScreenNotifier3D:
	if node is VisibleOnScreenNotifier3D:
		return node
	for child in node.get_children():
		var found := _find_screen_notifier_in(child)
		if found:
			return found
	return null


func _on_screen_entered() -> void:
	if _path_active:
		return
	_path_active = true
	set_process(true)


func _process(delta: float):
	if not _path_active:
		return

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