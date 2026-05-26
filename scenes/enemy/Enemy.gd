extends Area3D

@export var armor: int = 1

# -- Ruch bazowy --
@export var xmove: int = 0
@export var ymove: int = 0
@export var zmove: int = 0

var velocity: Vector3

func _ready():
	add_to_group("enemies")
	collision_layer = 2
	collision_mask  = 5
	velocity = Vector3(float(xmove), float(ymove), float(zmove))

func _process(delta: float):
	position += velocity * delta

