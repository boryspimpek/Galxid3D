extends Area3D

var damage: int = 3
var _damage_interval: float = 0.08
var _tick_timer: float = 0.0


func configure(p_damage: int, damage_interval: float) -> void:
	damage = p_damage
	_damage_interval = maxf(damage_interval, 0.02)


func _ready() -> void:
	monitoring = true


func _physics_process(delta: float) -> void:
	_tick_timer = maxf(0.0, _tick_timer - delta)
	if _tick_timer > 0.0:
		return
	_tick_timer = _damage_interval

	for area in get_overlapping_areas():
		if not area.is_in_group("enemies"):
			continue
		if area.has_method("take_damage"):
			area.take_damage(damage, global_position)
