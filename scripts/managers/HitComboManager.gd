extends Node

signal combo_changed(combo: int)

var combo: int = 0


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)


func register_kill() -> void:
	combo += 1
	combo_changed.emit(combo)


func spend_combo() -> void:
	if combo == 0:
		return
	combo = 0
	combo_changed.emit(0)


func _on_scene_changed() -> void:
	spend_combo()
