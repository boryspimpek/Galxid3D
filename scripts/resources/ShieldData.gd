class_name ShieldData
extends Resource

@export var shield_index: int = 0
@export var shield_name: String = ""
@export var protection: int = 0
@export var shield_wait: float = 5.0
@export var shield_regen_cost: int = 0
## Ile punktów tarczy wraca na jeden tick regeneracji.
@export var shield_regen_amount: float = 10.0
@export var cost: int = 0

@export_group("Audio")
## ID dźwięku przy trafieniu w tarczę (SoundManager, bus Impacts). 0 = cisza.
@export var hit_sound: int = 27
