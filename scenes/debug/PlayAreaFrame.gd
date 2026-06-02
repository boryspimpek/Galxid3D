@tool
extends Node3D

## Ramka granic planszy (X/Z) — do podglądu w edytorze przy ustawianiu Path3D.
## Domyślne wartości jak w Player.tscn (max_bound_x / max_bound_z).

@export var max_bound_x: float = 8.75:
	set(value):
		max_bound_x = value
		_update_frame()

@export var max_bound_z: float = 15.45:
	set(value):
		max_bound_z = value
		_update_frame()

@export var border_thickness: float = 0.15:
	set(value):
		border_thickness = value
		_update_frame()

@export var border_height: float = 0.05:
	set(value):
		border_height = value
		_update_frame()

@export var y_offset: float = 0.02:
	set(value):
		y_offset = value
		_update_frame()


func _ready() -> void:
	_update_frame()


func _update_frame() -> void:
	if not is_inside_tree():
		return

	var edge_pos_z := get_node_or_null("EdgePosZ") as MeshInstance3D
	var edge_neg_z := get_node_or_null("EdgeNegZ") as MeshInstance3D
	var edge_neg_x := get_node_or_null("EdgeNegX") as MeshInstance3D
	var edge_pos_x := get_node_or_null("EdgePosX") as MeshInstance3D
	if edge_pos_z == null:
		return

	var t := maxf(0.01, border_thickness)
	var h := maxf(0.01, border_height)
	var bx := maxf(0.1, max_bound_x)
	var bz := maxf(0.1, max_bound_z)
	var y := y_offset

	var width := bx * 2.0
	var depth := bz * 2.0

	_set_edge(edge_pos_z, Vector3(0.0, y, bz - t * 0.5), Vector3(width, h, t))
	_set_edge(edge_neg_z, Vector3(0.0, y, -bz + t * 0.5), Vector3(width, h, t))
	_set_edge(edge_neg_x, Vector3(-bx + t * 0.5, y, 0.0), Vector3(t, h, depth))
	_set_edge(edge_pos_x, Vector3(bx - t * 0.5, y, 0.0), Vector3(t, h, depth))


func _set_edge(edge: MeshInstance3D, pos: Vector3, size: Vector3) -> void:
	edge.position = pos
	edge.scale = size
