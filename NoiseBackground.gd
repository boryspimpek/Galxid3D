extends MeshInstance3D

## Czas trzymania jednej palety po zakończeniu przejścia (sekundy).
@export var hold_duration: float = 6.0
## Czas płynnej zmiany między paletami (sekundy).
@export var transition_duration: float = 4.0
## Amplituda oscylacji offset.z szumu (im mniejsza, tym subtelniej).
@export var noise_z_amplitude: float = 50.0
## Czas pełnego cyklu oscylacji offset.z (sekundy).
@export var noise_z_period: float = 120.0
## Co ile sekund odświeżać teksturę po zmianie offsetu (niższe = płynniej, wyższe obciążenie GPU).
@export var noise_offset_refresh_interval: float = 0.12

# Każda paleta = 4 kolory (zgodnie z punktami gradientu w scenie).
const PALETTES: Array = [
	# Głęboka przestrzeń — granat, stonowany błękit
	[
		Color(0.04, 0.06, 0.16, 1.0),
		Color(0.14, 0.2, 0.42, 1.0),
		Color(0.06, 0.24, 0.48, 1.0),
		Color(0.02, 0.03, 0.09, 1.0),
	],
	# Głęboka noc — indigo, fiolet
	[
		Color(0.05, 0.0, 0.22, 1.0),
		Color(0.15, 0.05, 0.55, 1.0),
		Color(0.0, 0.35, 0.55, 1.0),
		Color(0.02, 0.0, 0.12, 1.0),
	],
	# Zachód słońca — czerwień, pomarańcz
	[
		Color(0.35, 0.0, 0.15, 1.0),
		Color(0.55, 0.12, 0.05, 1.0),
		Color(0.1, 0.02, 0.35, 1.0),
		Color(0.12, 0.0, 0.05, 1.0),
	],
	# Zorza — morski, zielonkawy
	[
		Color(0.0, 0.12, 0.18, 1.0),
		Color(0.0, 0.45, 0.35, 1.0),
		Color(0.05, 0.15, 0.5, 1.0),
		Color(0.0, 0.08, 0.1, 1.0),
	],
	# Mgławica różowa
	[
		Color(0.28, 0.02, 0.22, 1.0),
		Color(0.55, 0.08, 0.35, 1.0),
		Color(0.15, 0.05, 0.45, 1.0),
		Color(0.1, 0.0, 0.15, 1.0),
	],
	# Lodowa — cyjan, błękit
	[
		Color(0.0, 0.1, 0.2, 1.0),
		Color(0.1, 0.35, 0.55, 1.0),
		Color(0.2, 0.5, 0.65, 1.0),
		Color(0.0, 0.06, 0.14, 1.0),
	],
	# Bursztyn / ogień
	[
		Color(0.25, 0.05, 0.0, 1.0),
		Color(0.65, 0.28, 0.02, 1.0),
		Color(0.35, 0.08, 0.02, 1.0),
		Color(0.12, 0.02, 0.0, 1.0),
	],
	# Fioletowa otchłań
	[
		Color(0.12, 0.0, 0.28, 1.0),
		Color(0.35, 0.1, 0.55, 1.0),
		Color(0.08, 0.2, 0.5, 1.0),
		Color(0.06, 0.0, 0.18, 1.0),
	],
	# Szmaragdowa mgła
	[
		Color(0.0, 0.15, 0.12, 1.0),
		Color(0.05, 0.42, 0.22, 1.0),
		Color(0.0, 0.25, 0.38, 1.0),
		Color(0.0, 0.08, 0.06, 1.0),
	],
	# Stare złoto / brąz
	[
		Color(0.2, 0.1, 0.05, 1.0),
		Color(0.45, 0.32, 0.08, 1.0),
		Color(0.15, 0.2, 0.35, 1.0),
		Color(0.08, 0.05, 0.02, 1.0),
	],
	# Ultrafiolet / neon
	[
		Color(0.18, 0.0, 0.35, 1.0),
		Color(0.4, 0.0, 0.7, 1.0),
		Color(0.0, 0.35, 0.55, 1.0),
		Color(0.05, 0.0, 0.2, 1.0),
	],
	# Księżycowa — srebro, szaro-niebieski
	[
		Color(0.12, 0.12, 0.18, 1.0),
		Color(0.35, 0.38, 0.45, 1.0),
		Color(0.08, 0.15, 0.32, 1.0),
		Color(0.06, 0.06, 0.1, 1.0),
	],
]

var _gradient: Gradient
var _noise_texture: NoiseTexture2D
var _fast_noise: FastNoiseLite
var _noise_z_base: float
var _noise_z_phase: float = 0.0
var _noise_offset_refresh_timer: float = 0.0
var _palette_index: int = 0
var _texture_refresh_queued: bool = false


func _ready() -> void:
	_setup_runtime_material()
	set_process(true)
	_run_color_cycle()


func _process(delta: float) -> void:
	if _fast_noise == null or noise_z_period <= 0.0:
		return

	_noise_z_phase += (TAU / noise_z_period) * delta
	var offset := _fast_noise.offset
	offset.z = _noise_z_base + sin(_noise_z_phase) * noise_z_amplitude
	_fast_noise.offset = offset

	_noise_offset_refresh_timer += delta
	if _noise_offset_refresh_timer >= noise_offset_refresh_interval:
		_noise_offset_refresh_timer = 0.0
		_queue_texture_refresh()


func _setup_runtime_material() -> void:
	var source_mat := mesh.material as StandardMaterial3D
	var source_noise := source_mat.albedo_texture as NoiseTexture2D

	_noise_texture = source_noise.duplicate(true) as NoiseTexture2D
	_gradient = (_noise_texture.color_ramp as Gradient).duplicate(true) as Gradient
	_fast_noise = (_noise_texture.noise as FastNoiseLite).duplicate(true) as FastNoiseLite
	_noise_z_base = _fast_noise.offset.z

	_noise_texture.color_ramp = _gradient
	_noise_texture.noise = _fast_noise
	_gradient.changed.connect(_queue_texture_refresh)

	var mat := source_mat.duplicate(true) as StandardMaterial3D
	mat.albedo_texture = _noise_texture
	material_override = mat

	_apply_palette(PALETTES[0])


func _apply_palette(palette: Array) -> void:
	for point_index in _gradient.get_point_count():
		_gradient.set_color(point_index, palette[point_index])
	_refresh_noise_texture()


func _run_color_cycle() -> void:
	while is_inside_tree():
		await get_tree().create_timer(hold_duration).timeout
		if not is_inside_tree():
			return
		var next_index := (_palette_index + 1) % PALETTES.size()
		await _tween_palette(PALETTES[next_index])
		_palette_index = next_index


func _tween_palette(target_colors: Array) -> void:
	var tween := create_tween().set_parallel(true)
	var point_count := _gradient.get_point_count()

	for point_index in point_count:
		var from_color := _gradient.get_color(point_index)
		var to_color: Color = target_colors[point_index]
		tween.tween_method(_point_color_tween(point_index), from_color, to_color, transition_duration)

	await tween.finished


func _point_color_tween(point_index: int) -> Callable:
	return func(color: Color) -> void:
		_set_gradient_point(point_index, color)


func _set_gradient_point(point_index: int, color: Color) -> void:
	_gradient.set_color(point_index, color)


func _queue_texture_refresh() -> void:
	if _texture_refresh_queued:
		return
	_texture_refresh_queued = true
	call_deferred(&"_refresh_noise_texture")


func _refresh_noise_texture() -> void:
	_texture_refresh_queued = false
	# Ponowne przypisanie wymusza regenerację tekstury (brak update() w Godot 4.6).
	_noise_texture.noise = _fast_noise
	_noise_texture.color_ramp = _gradient
