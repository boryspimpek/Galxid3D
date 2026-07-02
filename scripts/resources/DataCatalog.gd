class_name DataCatalog
extends Resource

const SidekickDataClass = preload("res://scripts/resources/SidekickData.gd")

@export var ships: Array[ShipData] = []
@export var weapons: Array[WeaponData] = []
@export var generators: Array[GeneratorData] = []
@export var sidekicks: Array[SidekickDataClass] = []
