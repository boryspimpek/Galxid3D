extends Node

# ============================================================================
# DAMAGE SYSTEM - Obsługa obrażeń i kolizji
# ============================================================================

var player: CharacterBody3D

func _ready():
	player = get_parent()

func take_damage(amount: int):
	if player.is_dodging:
		return
	if amount <= 0:
		return

	player.armor -= amount
	if player.armor > 0:
		var hit_sound: int = player.ship_data.hit_sound if player.ship_data else 19
		SoundManager.play_hit_sound(hit_sound)
	if player.armor <= 0:
		player.armor = 0
		_on_player_death()
	player.notify_armor_changed()

func _on_player_death():
	if get_tree():
		get_tree().call_group("hud", "show_game_over")
	if player and player.has_method("die"):
		player.die()
	else:
		player.queue_free()
