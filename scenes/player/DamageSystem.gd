extends Node

# ============================================================================
# DAMAGE SYSTEM - Obsługa obrażeń i kolizji
# ============================================================================

var player: CharacterBody3D
var shield_system: Node

func _ready():
	player = get_parent()
	shield_system = player.get_node("ShieldSystem")

func take_damage(amount: int):
	if player.is_dodging:
		return
	# print("--- HIT  dmg=%d  shield=%.1f  armor=%d" % [amount, shield_system.shield if shield_system else 0.0, player.armor])
	if shield_system and shield_system.shield > 0:
		var shield_absorbed: float = minf(float(amount), float(shield_system.shield))
		shield_system.take_shield_damage(shield_absorbed)
		amount -= int(shield_absorbed)
		# print("    tarcza pochłonęła %.0f  shield=%.1f" % [shield_absorbed, shield_system.shield])

	if amount > 0:
		player.armor -= amount
		if player.armor > 0:
			var hit_sound: int = player.ship_data.hit_sound if player.ship_data else 19
			SoundManager.play_hit_sound(hit_sound)
		# print("    przebicie do pancerza -%d  armor=%d" % [amount, player.armor])
		if player.armor <= 0:
			player.armor = 0
			_on_player_death()

func _on_player_death():
	if get_tree():
		get_tree().call_group("hud", "show_game_over")
	if player and player.has_method("die"):
		player.die()
	else:
		player.queue_free()
