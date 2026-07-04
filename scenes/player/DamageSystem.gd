extends Node

# ============================================================================
# DAMAGE SYSTEM - Obsługa obrażeń i kolizji
# ============================================================================

const FLASH_COLOR := Color(1.0, 0.0, 0.0, 0.25)
const FLASH_FADE_TIME := 0.35

var player: CharacterBody3D
var _flash_rect: ColorRect
var _flash_tween: Tween

func _ready():
	player = get_parent()
	_create_flash_overlay()

func _create_flash_overlay():
	var layer := CanvasLayer.new()
	layer.layer = 20
	_flash_rect = ColorRect.new()
	_flash_rect.color = FLASH_COLOR
	_flash_rect.modulate.a = 0.0
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_flash_rect)
	add_child(layer)

func _flash_screen():
	if _flash_rect == null:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_rect.modulate.a = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_rect, "modulate:a", 0.0, FLASH_FADE_TIME)

func take_damage(amount: int):
	if player.is_dodging:
		return
	if amount <= 0:
		return

	player.armor -= amount
	if player.armor > 0:
		var hit_sound: int = player.ship_data.hit_sound if player.ship_data else 19
		SoundManager.play_hit_sound(hit_sound)
		CameraShakeManager.shake(0.4, 0.25)
		_flash_screen()
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
