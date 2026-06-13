extends DirectionalLight3D

func _ready():
	# Kod pozwala ominąć blokadę edytora i wymusza ujemną energię
	light_energy = -1.0
