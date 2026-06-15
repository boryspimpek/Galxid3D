extends Node

# ============================================================================
# SCENE REGISTRY - Preload scen gameplayowych i resolver ścieżek pocisków gracza.
# ============================================================================

const DEFAULT_PLAYER_PROJECTILE := preload("res://scenes/projectile/Projectile.tscn")
const COMBO_PLAYER_PROJECTILE_PATH := "res://scenes/projectile/ProjectileX.tscn"

var enemy_projectile_scene: PackedScene
var pickup_scene: PackedScene
var _player_projectile_scene_cache: Dictionary = {}

func _ready():
	enemy_projectile_scene = preload("res://scenes/enemy_projectile/EnemyProjectile.tscn")
	pickup_scene = preload("res://scenes/pickup/Pickup.tscn")

func get_player_projectile_scene(projectile_id: int) -> PackedScene:
	var id: int = int(projectile_id)
	if id == 1:
		return DEFAULT_PLAYER_PROJECTILE

	var path: String
	if id == 0:
		path = COMBO_PLAYER_PROJECTILE_PATH
	else:
		path = "res://scenes/projectile/Projectile%d.tscn" % id
		if not ResourceLoader.exists(path):
			return DEFAULT_PLAYER_PROJECTILE

	if _player_projectile_scene_cache.has(path):
		return _player_projectile_scene_cache[path]

	var scene := load(path) as PackedScene
	_player_projectile_scene_cache[path] = scene
	return scene
