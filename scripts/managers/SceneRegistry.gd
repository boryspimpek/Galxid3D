extends Node

# ============================================================================
# SCENE REGISTRY - Preload scen gameplayowych i resolver ścieżek pocisków gracza.
# ============================================================================

const DEFAULT_PLAYER_PROJECTILE := preload("res://scenes/projectile/projectile_1.tscn")
const DEFAULT_SPECIAL_PROJECTILE := preload("res://scenes/projectile/power_1.tscn")
var enemy_projectile_scene: PackedScene
var pickup_scene: PackedScene
var _player_projectile_scene_cache: Dictionary = {}
var _sidekick_scene_cache: Dictionary = {}

func _ready():
	enemy_projectile_scene = preload("res://scenes/enemy_projectile/EnemyProjectile.tscn")
	pickup_scene = preload("res://scenes/pickup/Pickup.tscn")

func get_player_projectile_scene(projectile_id: int) -> PackedScene:
	return _resolve_player_projectile_scene(
		projectile_id,
		"projectile",
		DEFAULT_PLAYER_PROJECTILE
	)


func get_sidekick_scene(sidekick_id: int) -> PackedScene:
	var sk_data := DataManager.get_sidekick_by_id(sidekick_id)
	if sk_data == null:
		return null
	var path: String = sk_data.get("scene_path")
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("SceneRegistry: Brak sceny sidekicka dla ID=", sidekick_id, " path=", path)
		return null
	if _sidekick_scene_cache.has(path):
		return _sidekick_scene_cache[path]
	var scene := load(path) as PackedScene
	_sidekick_scene_cache[path] = scene
	return scene


func get_player_special_projectile_scene(projectile_id: int) -> PackedScene:
	return _resolve_player_projectile_scene(
		projectile_id,
		"power",
		DEFAULT_SPECIAL_PROJECTILE
	)


func _resolve_player_projectile_scene(
	projectile_id: int,
	scene_prefix: String,
	default_scene: PackedScene
) -> PackedScene:
	var id := maxi(int(projectile_id), 1)
	var path := "res://scenes/projectile/%s_%d.tscn" % [scene_prefix, id]
	if not ResourceLoader.exists(path):
		return default_scene

	if _player_projectile_scene_cache.has(path):
		return _player_projectile_scene_cache[path]

	var scene := load(path) as PackedScene
	_player_projectile_scene_cache[path] = scene
	return scene
