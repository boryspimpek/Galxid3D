class_name PatrolPaths

## Wspólna trajektoria dla wszystkich sond w SmoothEnemyTest (ta sama prędkość kątowa).


static func figure_eight(t: float, radius: float) -> Vector3:
	var w := 2.2
	return Vector3(
		sin(t * w) * radius,
		0.0,
		sin(t * w * 1.37) * radius * 0.55
	)


static func toward_camera(t: float, speed: float, span: float = 32.0) -> Vector3:
	## Lot w Z tam-i-z powrót (bez skoku pozycji — ważne przy TAA w project.godot).
	var dist := t * speed
	var period := span * 2.0
	var phase := fmod(dist, period)
	var z: float = phase if phase <= span else (period - phase)
	return Vector3(0.0, 0.0, z - span * 0.5)


static func toward_camera_hard_loop(t: float, speed: float, span: float = 32.0) -> Vector3:
	## Stary wariant: skok z końca na początek co obrót — psuje TAA po wielu pętlach.
	var z := fmod(t * speed, span) - span * 0.5
	return Vector3(0.0, 0.0, z)
