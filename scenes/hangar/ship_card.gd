class_name ShipCard
extends Control

@export var ship_data: ShipData

@onready var ship_index_label: Label = $CardMargin/CardContrnt/ShipIndex
@onready var texture_rect: TextureRect = $CardMargin/CardContrnt/TextureRect
@onready var ship_name_label: Label = $CardMargin/CardContrnt/ShipName
@onready var armor_label: Label = $CardMargin/CardContrnt/Armor/Armor
@onready var cost_label: Label = $CardMargin/CardContrnt/Cost/Cost

signal selected(ship_data: ShipData)

var _normal_style: StyleBox
var _focus_style: StyleBox


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	_normal_style = get_theme_stylebox("panel", "PanelContainer")
	_focus_style = _normal_style.duplicate()
	if _focus_style is StyleBoxFlat:
		var style := _focus_style as StyleBoxFlat
		style.bg_color = Color(0.25, 0.45, 0.65, 1)
		style.border_color = Color(0.85, 0.95, 1, 1)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.shadow_color = Color(0.35, 0.8, 1, 0.5)
		style.shadow_size = 14

	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

	if ship_data:
		setup(ship_data)
	gui_input.connect(_on_gui_input)


func _on_focus_entered() -> void:
	add_theme_stylebox_override("panel", _focus_style)


func _on_focus_exited() -> void:
	remove_theme_stylebox_override("panel")


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
	elif event.is_action_pressed("ui_accept"):
		selected.emit(ship_data)
