extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	anim.animation_finished.connect(func(_name): queue_free())
	anim.play("explode")

