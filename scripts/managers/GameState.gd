extends Node

# Stan gracza trzymany przez całą rozgrywkę.
# Dostępny z każdej sceny jako autoload.

var credits: int = 10000

# Wybrane ID, które hangar zapisuje, a gra później przekazuje Playerowi.
var ship_id: int = 1
var generator_id: int = 1

# Przykład rozszerzenia w przyszłości:
# var front_weapon_index: int = 1
# var middle_weapon_index: int = 0
# var rear_weapon_index: int = 1
