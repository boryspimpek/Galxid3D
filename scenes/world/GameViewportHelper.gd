class_name GameViewportHelper
extends RefCounted

## Wspólne mapowanie wejścia i kamery dla gry renderowanej w SubViewport.


static func get_shell(tree: SceneTree) -> Control:
	return tree.get_first_node_in_group("game_shell") as Control


static func get_game_viewport(tree: SceneTree) -> SubViewport:
	var shell := get_shell(tree)
	if shell and shell.has_method(&"get_game_viewport"):
		return shell.get_game_viewport()
	return tree.get_first_node_in_group("game_viewport") as SubViewport


static func get_game_camera(tree: SceneTree) -> Camera3D:
	var game_viewport := get_game_viewport(tree)
	if game_viewport:
		return game_viewport.get_camera_3d()
	return tree.root.get_viewport().get_camera_3d()


static func is_point_in_game_area(tree: SceneTree, root_pos: Vector2) -> bool:
	var shell := get_shell(tree)
	if shell and shell.has_method(&"is_point_in_game_area"):
		return shell.is_point_in_game_area(root_pos)
	return true


static func root_to_game_viewport_pos(tree: SceneTree, root_pos: Vector2) -> Vector2:
	var shell := get_shell(tree)
	if shell and shell.has_method(&"root_to_game_viewport_pos"):
		return shell.root_to_game_viewport_pos(root_pos)
	return root_pos


static func screen_to_world_on_plane(
	tree: SceneTree,
	root_pos: Vector2,
	plane_y: float = 0.0
) -> Vector3:
	if not is_point_in_game_area(tree, root_pos):
		return Vector3.ZERO

	var camera := get_game_camera(tree)
	if camera == null:
		return Vector3.ZERO

	var viewport_pos := root_to_game_viewport_pos(tree, root_pos)
	if viewport_pos.x < 0.0:
		return Vector3.ZERO

	var ray_origin := camera.project_ray_origin(viewport_pos)
	var ray_direction := camera.project_ray_normal(viewport_pos)
	var plane := Plane(Vector3.UP, plane_y)
	var hit = plane.intersects_ray(ray_origin, ray_direction)
	return hit if hit != null else Vector3.ZERO


static func get_render_viewport(tree: SceneTree) -> Viewport:
	var game_viewport := get_game_viewport(tree)
	if game_viewport:
		return game_viewport
	return tree.root.get_viewport()
