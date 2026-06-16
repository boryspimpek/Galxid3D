class_name PlayAreaConfig
extends Resource

## Wspólna konfiguracja granic planszy. Wszystkie wartości to połówki zakresu (±) wokół Z=0 / X=0.

@export_group("Player movement")
## Clamp pozycji gracza na osi X (±).
@export var player_half_x: float = 40.0
## Clamp pozycji gracza na osi Z (±).
@export var player_half_z: float = 20.0

@export_group("Visible play area")
## Ramka PlayAreaFrame — widoczny kadr kamery na osi X (±).
@export var frame_half_x: float = 27.0
## Ramka PlayAreaFrame — widoczny kadr kamery na osi Z (±).
@export var frame_half_z: float = 15.0

@export_group("Level scroll ruler")
## Szerokość szyn linijki (±X) — może być węższa niż frame dla czytelności podziałki.
@export var ruler_half_x: float = 27.0
## Podświetlona strefa gry na linijce (±Z).
@export var ruler_play_half_z: float = 15.0

@export_group("Enemy activation")
## Wróg aktywuje się gdy global_position.z >= ta wartość (ujemna Z = wjazd z góry kadru).
@export var scroll_activation_z: float = -17.0
