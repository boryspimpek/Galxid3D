@tool
extends Node3D

## Przedłużona ramka wzdłuż Z (pod LevelScroll) z podziałką dystansu i czasu scrolla.
## Umieść jako dziecko LevelScroll — współrzędne Z zgadzają się z falami i Path3D.

@export_group("Zakres")
@export var max_bound_x: float = 8.75:
	set(value):
		max_bound_x = value
		_queue_update()

@export var z_min: float = -120.0:
	set(value):
		z_min = value
		_queue_update()

@export var z_max: float = 80.0:
	set(value):
		z_max = value
		_queue_update()

## Wewnątrz ±tej wartości — podświetlony odcinek (jak PlayAreaFrame max_bound_z).
@export var play_area_half_z: float = 15.45:
	set(value):
		play_area_half_z = value
		_queue_update()

@export_group("Podziałka")
@export var tick_spacing: float = 10.0:
	set(value):
		tick_spacing = value
		_queue_update()

@export var major_tick_every: int = 5:
	set(value):
		major_tick_every = maxi(1, value)
		_queue_update()

@export var show_distance_labels: bool = true:
	set(value):
		show_distance_labels = value
		_queue_update()

@export var show_time_labels: bool = true:
	set(value):
		show_time_labels = value
		_queue_update()

## Z = 0 na linijce; czas = (z - time_origin_z) / scroll_speed [s].
@export var time_origin_z: float = 0.0:
	set(value):
		time_origin_z = value
		_queue_update()

@export_group("Scroll")
@export var scroll_speed: float = 3.0:
	set(value):
		scroll_speed = value
		_queue_update()

@export var auto_scroll_speed: bool = true:
	set(value):
		auto_scroll_speed = value
		_queue_update()

@export_group("Wygląd")
@export var rail_thickness: float = 0.08:
	set(value):
		rail_thickness = value
		_queue_update()

@export var rail_height: float = 0.04:
	set(value):
		rail_height = value
		_queue_update()

@export var tick_size: float = 0.35:
	set(value):
		tick_size = value
		_queue_update()

@export var y_offset: float = 0.02:
	set(value):
		y_offset = value
		_queue_update()

@export var label_pixel_size: float = 0.012:
	set(value):
		label_pixel_size = value
		_queue_update()

@export var label_side: float = 1.0:
	set(value):
		label_side = value
		_queue_update()

@export var color_rail: Color = Color(0.35, 0.75, 1.0, 0.75):
	set(value):
		color_rail = value
		_queue_update()

@export var color_play_zone: Color = Color(0.2, 1.0, 0.4, 0.9):
	set(value):
		color_play_zone = value
		_queue_update()

@export var color_tick: Color = Color(0.5, 0.85, 1.0, 0.9):
	set(value):
		color_tick = value
		_queue_update()

@export var color_tick_major: Color = Color(1.0, 0.95, 0.5, 0.95):
	set(value):
		color_tick_major = value
		_queue_update()

@export var color_origin: Color = Color(1.0, 0.45, 0.35, 1.0):
	set(value):
		color_origin = value
		_queue_update()

const GENERATED_NAME := "Generated"

var _box_mesh: BoxMesh
var _update_queued: bool = false


func _ready() -> void:
	_queue_update()


func _queue_update() -> void:
	if not is_inside_tree():
		return
	if _update_queued:
		return
	_update_queued = true
	call_deferred("_update_ruler")


func _update_ruler() -> void:
	_update_queued = false
	if not is_inside_tree():
		return

	_clear_generated()

	var z_lo := minf(z_min, z_max)
	var z_hi := maxf(z_min, z_max)
	var bx := maxf(0.1, max_bound_x)
	var play_z := maxf(0.0, play_area_half_z)
	var t := maxf(0.01, rail_thickness)
	var h := maxf(0.01, rail_height)
	var y := y_offset
	var depth := z_hi - z_lo
	var z_center := (z_lo + z_hi) * 0.5

	var gen := Node3D.new()
	gen.name = GENERATED_NAME
	add_child(gen)
	if Engine.is_editor_hint():
		gen.owner = get_tree().edited_scene_root if get_tree() else owner

	var mat_rail := _make_material(color_rail)
	var mat_play := _make_material(color_play_zone)

	# Boczne szyny na całym zakresie Z
	_add_box(gen, Vector3(-bx + t * 0.5, y, z_center), Vector3(t, h, depth), mat_rail)
	_add_box(gen, Vector3(bx - t * 0.5, y, z_center), Vector3(t, h, depth), mat_rail)

	# Podświetlenie strefy gry (±play_area_half_z)
	if play_z > 0.0:
		var play_depth := play_z * 2.0
		_add_box(gen, Vector3(-bx + t * 0.5, y, 0.0), Vector3(t, h, play_depth), mat_play)
		_add_box(gen, Vector3(bx - t * 0.5, y, 0.0), Vector3(t, h, play_depth), mat_play)
		_add_box(gen, Vector3(0.0, y, play_z - t * 0.5), Vector3(bx * 2.0 - t, h, t), mat_play)
		_add_box(gen, Vector3(0.0, y, -play_z + t * 0.5), Vector3(bx * 2.0 - t, h, t), mat_play)

	var spacing := maxf(0.5, tick_spacing)
	var tick_index := 0
	var z := snappedf(z_lo, spacing)
	if z < z_lo:
		z += spacing

	var label_x := bx + 0.6 * signf(label_side if label_side != 0.0 else 1.0)

	while z <= z_hi + 0.001:
		var is_major := tick_index % major_tick_every == 0
		var is_origin := absf(z) < 0.001
		var tick_len := tick_size * (1.6 if is_major else 1.0)
		var tick_col := color_origin if is_origin else (color_tick_major if is_major else color_tick)
		var mat_tick := _make_material(tick_col)

		_add_box(gen, Vector3(-bx, y, z), Vector3(tick_len, h, t * 0.6), mat_tick)
		_add_box(gen, Vector3(bx, y, z), Vector3(tick_len, h, t * 0.6), mat_tick)

		if show_distance_labels or show_time_labels:
			_add_label(gen, Vector3(label_x, y, z), _format_tick_label(z, is_major))

		z += spacing
		tick_index += 1


func _format_tick_label(z: float, is_major: bool) -> String:
	var parts: PackedStringArray = []
	if show_distance_labels:
		parts.append("Z %s" % _format_number(z))
	if show_time_labels and _get_scroll_speed() > 0.0:
		var t_sec := (z - time_origin_z) / _get_scroll_speed()
		parts.append("%ss" % _format_number(t_sec))
	if parts.is_empty():
		return ""
	if not is_major and parts.size() > 1:
		return parts[0]
	return "\n".join(parts)


func _format_number(value: float) -> String:
	if absf(value - roundf(value)) < 0.05:
		return str(int(roundf(value)))
	return "%0.1f" % value


func _get_scroll_speed() -> float:
	if not auto_scroll_speed:
		return scroll_speed
	var node: Node = self
	while node:
		var script: Script = node.get_script()
		if script and script.resource_path.get_file() == "LevelScroll3D.gd":
			var spd: Variant = node.get("scroll_speed")
			if spd != null:
				return float(spd)
			return scroll_speed
		node = node.get_parent()
	return scroll_speed


func _clear_generated() -> void:
	var old := get_node_or_null(GENERATED_NAME)
	if old:
		old.queue_free()


func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.disable_receive_shadows = true
	return mat


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = _get_box_mesh()
	mesh_inst.material_override = material
	mesh_inst.position = pos
	mesh_inst.scale = size
	parent.add_child(mesh_inst)
	if Engine.is_editor_hint() and get_tree():
		mesh_inst.owner = get_tree().edited_scene_root


func _add_label(parent: Node3D, pos: Vector3, text: String) -> void:
	if text.is_empty():
		return
	var label := Label3D.new()
	label.text = text
	label.pixel_size = label_pixel_size
	label.position = pos
	label.rotation_degrees.x = -90.0
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.92, 0.96, 1.0, 0.95)
	label.outline_size = 8
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.font_size = 48
	parent.add_child(label)
	if Engine.is_editor_hint() and get_tree():
		label.owner = get_tree().edited_scene_root


func _get_box_mesh() -> BoxMesh:
	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
	return _box_mesh
