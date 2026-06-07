extends EnemyWeapon
class_name SimpleShoot

# ============================================================================
# SIMPLE SHOOT - najprostszy wzór ognia.
# Wystrzeliwuje po jednym pocisku z każdego muzzla, prosto przed siebie
# (kierunek modyfikuje tylko wspólna logika aim z EnemyWeapon).
# ============================================================================

func fire() -> void:
	for from_muzzle in _muzzles:
		spawn_projectile(from_muzzle)
