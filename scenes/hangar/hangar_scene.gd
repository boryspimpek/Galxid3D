class_name HangarScene
extends Control

const ShipCardScene = preload("res://scenes/hangar/ship_card.tscn")
const ShipCardType = preload("res://scenes/hangar/ship_card.gd")
const GeneratorCardScene = preload("res://scenes/hangar/generator_card.tscn")
const GeneratorCardType = preload("res://scenes/hangar/generator_card.gd")

@export_dir var ships_folder: String = "res://data/ships"
@export_dir var generators_folder: String = "res://data/generators"

@onready var ship_grid: GridContainer = $MainMargin/MainLayout/RightPanel/RightMargin/RightContent/ShipSection/ShipGrid
@onready var generator_grid: GridContainer = $MainMargin/MainLayout/RightPanel/RightMargin/RightContent/GeneratorSection/GeneratorGrid

@onready var cash_value: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/Cash/CashValue
@onready var selected_ship_title: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedShip/ShipMargin/ShipContent/SectionTitle
@onready var selected_ship_texture: TextureRect = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedShip/ShipMargin/ShipContent/TextureRect
@onready var selected_ship_name: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedShip/ShipMargin/ShipContent/ShipName
@onready var selected_ship_armor: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedShip/ShipMargin/ShipContent/Armor/Armor
@onready var selected_ship_price: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedShip/ShipMargin/ShipContent/Price/Price

@onready var selected_generator_title: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedGenerator/GeneratorMargin/GeneratorContent/SectionTitle
@onready var selected_generator_texture: TextureRect = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedGenerator/GeneratorMargin/GeneratorContent/TextureRect
@onready var selected_generator_name: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedGenerator/GeneratorMargin/GeneratorContent/GeneratorName
@onready var selected_generator_energy: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedGenerator/GeneratorMargin/GeneratorContent/Energy/Energy
@onready var selected_generator_price: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/SelectedGenerator/GeneratorMargin/GeneratorContent/Price/Price
@onready var total_value: Label = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/TotalCostSection/MarginContainer/VBoxContainer/TotalValue
@onready var buy_button: Button = $MainMargin/MainLayout/LeftPanel/LeftMargin/LeftContent/Button

var selected_ship_data: ShipData
var selected_generator_data: GeneratorData

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    cash_value.text = "%d CR" % GameState.credits
    buy_button.pressed.connect(_on_buy_button_pressed)
    load_cards()
    _focus_first_ship_card()

func load_cards() -> void:
    for child in ship_grid.get_children():
        child.queue_free()
    for child in generator_grid.get_children():
        child.queue_free()

    var ships := load_resources(ships_folder)
    print("Loaded ships: ", ships.size())
    ships.sort_custom(func(a, b): return a.ship_index < b.ship_index)
    for ship in ships:
        var card: ShipCardType = ShipCardScene.instantiate()
        ship_grid.add_child(card)
        card.setup(ship)
        card.selected.connect(_on_ship_selected)
        print("Added ship card: ", ship.ship_name)

    var generators := load_resources(generators_folder)
    print("Loaded generators: ", generators.size())
    generators.sort_custom(func(a, b): return a.generator_index < b.generator_index)
    for generator in generators:
        var card: GeneratorCardType = GeneratorCardScene.instantiate()
        generator_grid.add_child(card)
        card.setup(generator)
        card.selected.connect(_on_generator_selected)
        print("Added generator card: ", generator.generator_name)

    _restore_selection()
    _setup_focus_navigation()

func load_resources(folder: String) -> Array:
    var resources: Array = []
    var dir := DirAccess.open(folder)
    if dir == null:
        push_error("Cannot open folder: " + folder)
        return resources

    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if file_name.ends_with(".tres"):
            var resource := load(folder + "/" + file_name)
            if resource:
                resources.append(resource)
            else:
                push_warning("Failed to load resource: " + folder + "/" + file_name)
        file_name = dir.get_next()
    dir.list_dir_end()
    return resources

func _on_ship_selected(ship: ShipData) -> void:
    selected_ship_data = ship
    selected_ship_title.text = "Selected Ship"
    selected_ship_name.text = ship.ship_name
    selected_ship_armor.text = str(ship.armor)
    selected_ship_price.text = "%d CR" % ship.cost
    selected_ship_texture.texture = ship.graphics
    _update_total_cost()

func _on_generator_selected(generator: GeneratorData) -> void:
    selected_generator_data = generator
    selected_generator_title.text = "Selected Generator"
    selected_generator_name.text = generator.generator_name
    selected_generator_energy.text = str(generator.power)
    selected_generator_price.text = "%d CR" % generator.cost
    selected_generator_texture.texture = generator.graphics
    _update_total_cost()

func _update_total_cost() -> void:
    var total := 0
    if selected_ship_data:
        total += selected_ship_data.cost
    if selected_generator_data:
        total += selected_generator_data.cost
    total_value.text = "%d CR" % total

func _restore_selection() -> void:
    var ship := DataManager.get_ship_by_id(GameState.ship_id)
    if ship:
        _on_ship_selected(ship)
    var generator := DataManager.get_generator_by_id(GameState.generator_id)
    if generator:
        _on_generator_selected(generator)

func _on_buy_button_pressed() -> void:
    if selected_ship_data:
        GameState.ship_id = selected_ship_data.ship_index
    if selected_generator_data:
        GameState.generator_id = selected_generator_data.generator_index
    print("Hangar: bought ship ", GameState.ship_id, ", generator ", GameState.generator_id)
    _return_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("back") or event.is_action_pressed("ui_cancel"):
        _return_to_main_menu()


func _focus_first_ship_card() -> void:
    if ship_grid.get_child_count() == 0:
        return
    var first_card := ship_grid.get_child(0) as Control
    if first_card:
        first_card.grab_focus()


func _setup_focus_navigation() -> void:
    var generator_count := generator_grid.get_child_count()
    if generator_count > 0 and buy_button != null:
        var buy_path := buy_button.get_path()
        var columns := generator_grid.columns
        var bottom_row_start := maxi(0, generator_count - columns)
        for i in range(bottom_row_start, generator_count):
            var card := generator_grid.get_child(i) as Control
            if card:
                card.focus_neighbor_bottom = buy_path
        buy_button.focus_neighbor_top = generator_grid.get_child(generator_count - 1).get_path()


func _return_to_main_menu() -> void:
    get_tree().change_scene_to_file("res://main.tscn")
