@tool
extends Node3D

## Ramka granic widocznego kadru (X/Z) — do podglądu w edytorze przy ustawianiu Path3D.

const DEFAULT_CONFIG_PATH := "res://data/play_area/default.tres"

@export var play_area: PlayAreaConfig:
	set(value):
		play_area = value
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


func _get_config() -> PlayAreaConfig:
	if play_area != null:
		return play_area
	return load(DEFAULT_CONFIG_PATH) as PlayAreaConfig


func _update_frame() -> void:
	if not is_inside_tree():
		return

	var config := _get_config()
	if config == null:
		return

	var edge_pos_z := get_node_or_null("EdgePosZ") as MeshInstance3D
	var edge_neg_z := get_node_or_null("EdgeNegZ") as MeshInstance3D
	var edge_neg_x := get_node_or_null("EdgeNegX") as MeshInstance3D
	var edge_pos_x := get_node_or_null("EdgePosX") as MeshInstance3D
	if edge_pos_z == null:
		return

	var t := maxf(0.01, border_thickness)
	var h := maxf(0.01, border_height)
	var bx := maxf(0.1, config.frame_half_x)
	var bz := maxf(0.1, config.frame_half_z)
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
