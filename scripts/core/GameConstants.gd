extends Node

# ============================================================================
# GAME CONSTANTS - Centralne miejsce dla stałych używanych w całej grze
# ============================================================================

# ---- Sceny pocisków ----
var enemy_projectile_scene: PackedScene
var player_projectile_scene: PackedScene
var _player_projectile_scene_cache: Dictionary = {}

# ---- Scena eksplozji ----
var explosion_scene: PackedScene
var _explosion_scene_cache: Dictionary = {}

# ---- Scena pickupa (loot z wrogów) ----
var pickup_scene: PackedScene

func _ready():
	enemy_projectile_scene = preload("res://scenes/enemy_projectile/EnemyProjectile.tscn")
	player_projectile_scene = preload("res://scenes/projectile/Projectile.tscn")
	pickup_scene = preload("res://scenes/pickup/Pickup.tscn")
	explosion_scene = get_explosion_scene(1)

func get_player_projectile_scene(projectile_id: int) -> PackedScene:
	var id: int = int(max(1, projectile_id))
	var path := "res://scenes/projectile/Projectile.tscn" if id == 1 else ("res://scenes/projectile/Projectile%d.tscn" % id)
	if not ResourceLoader.exists(path):
		path = "res://scenes/projectile/Projectile.tscn"
	if _player_projectile_scene_cache.has(path):
		return _player_projectile_scene_cache[path]
	var scene := load(path) as PackedScene
	_player_projectile_scene_cache[path] = scene
	return scene


func get_explosion_scene(size: int) -> PackedScene:
	var s: int = int(max(1, size))
	var path := "res://scenes/explosions/explode.tscn" if s == 1 else ("res://scenes/explosions/explode%d.tscn" % s)
	if not ResourceLoader.exists(path):
		path = "res://scenes/explosions/explode.tscn"
	if _explosion_scene_cache.has(path):
		return _explosion_scene_cache[path]
	var scene := load(path) as PackedScene
	_explosion_scene_cache[path] = scene
	return scene
