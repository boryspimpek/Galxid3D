extends Node3D

## Obrót planety: AnimationPlayer (spin). Ten skrypt tylko przesuwa planetę wzdłuż Z.
@export var spin_speed: float = 0.1:
	set(value):
		spin_speed = value
		_apply_spin_speed()
@export var speed: float = 1.0

const BASE_SPIN_SPEED := 0.1

@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_apply_spin_speed()


func _apply_spin_speed() -> void:
	if _animation_player:
		_animation_player.speed_scale = spin_speed / BASE_SPIN_SPEED


func _process(delta: float) -> void:
	global_position.z += speed * delta
