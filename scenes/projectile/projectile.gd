extends Area3D

# --- Parametry pocisku (ustawiane przez WeaponSystem) ---
var _velocity: Vector3 = Vector3.ZERO

@export var velocity: Vector3 = Vector3.ZERO:
	get:
		return _velocity
	set(value):
		_velocity = value
		_align_to_velocity()

@export var damage: int = 3
var homing: bool = false
var turn_speed: float = 3.0
var homing_angle_deg: float = 360.0

func _ready():
	for child in get_children():
		if child is VisibleOnScreenNotifier3D:
			child.screen_exited.connect(queue_free)

func _physics_process(delta: float):
	if homing:
		_steer_towards_nearest_enemy(delta)
	position += _velocity * delta


func _steer_towards_nearest_enemy(delta: float) -> void:
	var target := _find_enemy_in_cone()
	if target == null:
		return
	var speed := _velocity.length()
	if speed < 0.0001:
		return
	var to_target := (target.global_position - global_position).normalized()
	var new_dir := (_velocity / speed).slerp(to_target, clampf(turn_speed * delta, 0.0, 1.0)).normalized()
	_velocity = new_dir * speed
	_align_to_velocity()


func _find_enemy_in_cone() -> Node3D:
	var nearest: Node3D = null
	var nearest_dist := INF
	var cos_half := cos(deg_to_rad(homing_angle_deg * 0.5))
	var forward := _velocity.normalized() if _velocity.length_squared() > 0.0001 else Vector3(0, 0, -1)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D:
			var to_e := (e as Node3D).global_position - global_position
			var d := to_e.length_squared()
			if d < nearest_dist and to_e.normalized().dot(forward) >= cos_half:
				nearest_dist = d
				nearest = e as Node3D
	return nearest


func _align_to_velocity() -> void:
	if _velocity.length_squared() < 0.0001 or not is_inside_tree():
		return
	var direction := _velocity.normalized()
	var up := Vector3.UP
	if absf(direction.dot(up)) > 0.999:
		up = Vector3.RIGHT
	look_at(global_position + direction, up)

func _on_area_entered(area: Area3D):
	if area.is_in_group("enemies"):
		area.take_damage(damage, global_position)
		queue_free()

func _on_body_entered(_body: Node3D):
	queue_free()
