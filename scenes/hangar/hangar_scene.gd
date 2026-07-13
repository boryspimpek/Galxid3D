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

var selected_ship_data: ShipData
var selected_generator_data: GeneratorData

func _ready() -> void:
    load_cards()

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

func _on_generator_selected(generator: GeneratorData) -> void:
    selected_generator_data = generator
    selected_generator_title.text = "Selected Generator"
    selected_generator_name.text = generator.generator_name
    selected_generator_energy.text = str(generator.power)
    selected_generator_price.text = "%d CR" % generator.cost
    selected_generator_texture.texture = generator.graphics
