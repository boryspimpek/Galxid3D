class_name GeneratorCard
extends Control

@export var generator_data: GeneratorData

@onready var generator_index_label: Label = $CardMargin/CardContrnt/GeneratorIndex
@onready var texture_rect: TextureRect = $CardMargin/CardContrnt/TextureRect
@onready var generator_name_label: Label = $CardMargin/CardContrnt/GeneratorName
@onready var energy_label: Label = $CardMargin/CardContrnt/Energy/Energy
@onready var cost_label: Label = $CardMargin/CardContrnt/Cost/Cost

signal selected(generator_data: GeneratorData)

func _ready() -> void:
	if generator_data:
		setup(generator_data)
	gui_input.connect(_on_gui_input)

func setup(data: GeneratorData) -> void:
	generator_data = data
	generator_index_label.text = "%02d" % data.generator_index
	generator_name_label.text = data.generator_name
	energy_label.text = str(data.power)
	cost_label.text = "%d CR" % data.cost
	texture_rect.texture = data.graphics

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(generator_data)
