extends Node

var player: CharacterBody3D

var shield: float = 0.0
var shield_max: float = 0.0
var shield_regen_cost: int = 0
var shield_regen_amount: float = 10.0
var shield_wait: float = 0.0
var _wait_timer: float = 0.0
var _hit_sound: int = 27

func _ready():
	player = get_parent()
	await get_tree().process_frame
	load_shield_config()

func load_shield_config():
	var shield_data = DataManager.get_shield_by_id(player.shield_id)
	if shield_data:
		shield_regen_cost = shield_data.shield_regen_cost
		shield_regen_amount = shield_data.shield_regen_amount
		shield_wait = shield_data.shield_wait
		shield     = float(shield_data.protection)
		shield_max = float(shield_data.protection)
		_hit_sound = shield_data.hit_sound
		print(
			"ShieldSystem: shield=", shield, "/", shield_max,
			" regen=", shield_regen_amount, " regen_cost=", shield_regen_cost,
			" wait=", shield_wait, "s"
		)
	else:
		push_warning("ShieldSystem: brak danych tarczy (shield_id=%d)" % player.shield_id)

func _physics_process(delta: float):
	if _wait_timer > 0.0:
		_wait_timer -= delta

	if shield < shield_max and _wait_timer <= 0.0:
		if player.power >= shield_regen_cost:
			player.power -= shield_regen_cost
			shield = minf(shield + shield_regen_amount, shield_max)
			_wait_timer = shield_wait

func reload():
	load_shield_config()

func take_shield_damage(amount: float):
	shield = max(shield - amount, 0.0)
	SoundManager.play_hit_sound(_hit_sound)
