extends Area3D

# --- ZMIENNE EKSPORTOWANE (@EXPORT) ---
@export_group("Combat")
@export var armor: int = 1

@export_group("Movement")
## Zasób ruchu (np. LinearMoveData). Edytowalny per instancja na korzeniu wroga.
## Zostaw pusty dla wrogów sterowanych ścieżką (Path3D).
@export var movement_data: MovementData

@export_group("General")
@export var esize: int = 1
@export var value: int = 2

# --- REFERENCJE WĘZŁÓW (@ONREADY) ---
@onready var ship_model: Node3D = $EnemyModel

# --- ZMIENNE WEWNĘTRZNE (LOGIKA) ---
var _is_active: bool = false
## Czas (s) odkąd ruch jest aktywny — przekazywany do MovementData.get_velocity().
var _move_elapsed: float = 0.0
## Komponent strzelania (dziecko ze skryptem dziedziczącym po EnemyWeapon).
var _weapon: EnemyWeapon
## Opcjonalny komponent orientacji (dziecko dziedziczące po EnemyFacing).
var _facing: EnemyFacing

@export_group("Activation")
@export var activate_on_scroll_line: bool = true
@export var despawn_off_screen: bool = true
## Górna krawędź kadru. Wróg aktywuje się gdy global_position.z >= tej wartości.
## Ustaw na minus max_bound_z z PlayAreaFrame (np. -17.0).
@export var scroll_activation_z: float = -17.0

var _screen_notifier: VisibleOnScreenNotifier3D

signal combat_activated
signal combat_deactivated


# --- METODY WBUDOWANE (LIFECYCLE) ---

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON

	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5

	_weapon = _find_weapon()
	_facing = _find_facing()

	_screen_notifier = get_node_or_null("VisibleOnScreenNotifier3D") as VisibleOnScreenNotifier3D
	if _screen_notifier:
		_screen_notifier.visible = true
		_screen_notifier.screen_exited.connect(_on_screen_exited)

	set_physics_process(true)
	if activate_on_scroll_line:
		_deactivate()
	else:
		_activate()

	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if activate_on_scroll_line:
		_refresh_activation()

	if not _is_active:
		return

	if movement_data:
		global_position += movement_data.get_velocity(_move_elapsed) * delta
		_move_elapsed += delta

	if _facing:
		_facing.process_facing(delta)


# --- METODY PUBLICZNE (API ENEMY) ---

func set_firing(firing: bool) -> void:
	if _weapon:
		_weapon.set_firing(firing)


func is_combat_active() -> bool:
	return _is_active


## Wymusza walkę bez linii scrolla (np. fale slide sterowane przez animation.gd).
func activate_combat() -> void:
	activate_on_scroll_line = false
	_activate()


## Ile jednostek brakuje do linii aktywacji (0 = właśnie teraz).
func get_scroll_distance_remaining() -> float:
	return scroll_activation_z - global_position.z


func take_damage(amount: int) -> void:
	armor -= amount
	if armor <= 0:
		die()
	else:
		# 003_S_ENEMY_HIT.wav
		SoundManager.play_hit_sound(3)


func die() -> void:
	SoundManager.play_sound(9)
	var explosion_scene := GameConstants.get_explosion_scene(esize)
	if explosion_scene:
		var explosion := explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		if explosion is Node3D:
			explosion.global_position = global_position
	_spawn_pickups()
	queue_free()


## Wyrzuca `value` pickupów z pozycji wroga w losowych kierunkach (płaszczyzna XZ).
func _spawn_pickups() -> void:
	var pickup_scene := GameConstants.pickup_scene
	if pickup_scene == null or value <= 0:
		return

	var scene_root := get_tree().current_scene
	# Kamera jest top-down (patrzy w dół osi Y), więc niższe Y renderuje się
	# "pod" eksplozją (Y=0). Przesuwamy loot w dół, by nie przysłaniał wybuchu.
	var spawn_offset := Vector3(0.0, -2.0, 0.0)
	for i in value:
		var pickup := pickup_scene.instantiate()
		scene_root.add_child(pickup)
		if pickup is Node3D:
			pickup.global_position = global_position + spawn_offset

		var angle := randf() * TAU
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var speed := randf_range(4.0, 8.0)
		if pickup.has_method("launch"):
			pickup.launch(dir, speed)


# --- BROŃ (komponent strzelania) ---

func _find_weapon() -> EnemyWeapon:
	for child in get_children():
		if child is EnemyWeapon:
			return child
	return null


func _find_facing() -> EnemyFacing:
	for child in get_children():
		if child is EnemyFacing:
			return child
	return null


# --- AKTYWACJA (linia scrolla) ---

func _refresh_activation() -> void:
	if global_position.z >= scroll_activation_z:
		_activate()
	else:
		_deactivate()


func _activate() -> void:
	if _is_active:
		return
	_is_active = true
	_move_elapsed = 0.0
	set_firing(true)
	# PathFollow odpina się w EnemyPath; wrogowie bez ścieżki — tutaj.
	if not get_parent() is PathFollow3D:
		LevelScroll3D.detach_to_active_scene(self)
	combat_activated.emit()


func _deactivate() -> void:
	if not _is_active:
		return
	_is_active = false
	set_firing(false)
	combat_deactivated.emit()


# --- OBSŁUGA SYGNAŁÓW (SIGNALS) ---

func _on_screen_exited() -> void:
	_deactivate()
	if despawn_off_screen:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(armor)
		die()
