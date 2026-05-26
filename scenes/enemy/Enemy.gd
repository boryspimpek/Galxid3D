extends Area2D

# -- Statystyki --
@export var armor: int = 1
@export var esize: int = 0
@export var value: int = 0

# -- Ruch bazowy --
@export var xmove: int = 0
@export var ymove: int = 0

velocity: Vector2 = Vector2(float(xmove), float(ymove))

var _player: Node2D

# ============================================================================
# INICJALIZACJA
# ============================================================================

func _ready():
	add_to_group("enemies")
	collision_layer = 2
	collision_mask  = 5

	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	$VisibleOnScreenNotifier2D.screen_entered.connect(_on_screen_entered)
	_player = get_tree().get_first_node_in_group("player")
	set_process(false)


func _on_screen_entered():
	set_process(true)
	if get_parent() is PathFollow2D and get_parent().has_method("activate"):
		get_parent().activate()

func _on_screen_exited():
	if get_parent() is PathFollow2D:
		if get_parent().remove_at_end:
			return
	queue_free()


# ============================================================================
# PĘTLA GŁÓWNA
# ============================================================================

func _process(delta: float):
	if not (get_parent() is PathFollow2D):
		position += velocity * delta

# ============================================================================
# SYSTEM OBRAŻEŃ I ŚMIERCI
# ============================================================================

func take_damage(amount: int):
	armor -= amount
	if armor <= 0:
		die()
	else:
		SoundManager.play_sound(3)
		_flash_hit()

func _flash_hit():
	modulate = Color(50, 50, 50, 1)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.06)

func die():
	var parent := _get_level_parent()
	if parent:
		var explosion: Node2D = GameConstants.explosion_scene.instantiate()
		explosion.position = (parent as Node2D).to_local(global_position)
		parent.add_child(explosion)
	SoundManager.play_sound(9 if esize == 1 else 8)
	queue_free()

func _get_level_parent() -> Node:
	var p = get_parent()
	while p and (p is PathFollow2D or p is Path2D):
		p = p.get_parent()
	return p

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		var ds = body.get_node_or_null("DamageSystem")
		if ds:
			ds.take_damage(armor)
		die()
