class_name ShipCard
extends Control

@export var ship_data: ShipData

@onready var ship_index_label: Label = $CardMargin/CardContrnt/ShipIndex
@onready var texture_rect: TextureRect = $CardMargin/CardContrnt/TextureRect
@onready var ship_name_label: Label = $CardMargin/CardContrnt/ShipName
@onready var armor_label: Label = $CardMargin/CardContrnt/Armor/Armor
@onready var cost_label: Label = $CardMargin/CardContrnt/Cost/Cost

signal selected(ship_data: ShipData)

func _ready() -> void:
	if ship_data:
		setup(ship_data)
	gui_input.connect(_on_gui_input)

func setup(data: ShipData) -> void:
	ship_data = data
	ship_index_label.text = "%02d" % data.ship_index
	ship_name_label.text = data.ship_name
	armor_label.text = str(data.armor)
	cost_label.text = "%d CR" % data.cost
	texture_rect.texture = data.graphics

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(ship_data)
