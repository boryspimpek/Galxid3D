extends Resource
class_name BossWeaponPhase

# ============================================================================
# BOSS WEAPON PHASE - jeden krok cyklu broni bossa.
# Boss przechodzi przez tablicę faz: strzela weapon przez duration sekund,
# potem czeka cooldown_after i przechodzi do kolejnej fazy (zapętlone).
# ============================================================================

## Broń używana w tej fazie (Burst, Circle, Spread, Homing...).
@export var weapon: EnemyWeaponData
## Czas aktywnego strzelania (sekundy).
@export var duration: float = 3.0
## Przerwa po fazie, przed aktywacją kolejnej broni (sekundy).
@export var cooldown_after: float = 1.0
## Indeksy muzzli używanych w tej fazie (0 = Muzzle, 1 = Muzzle2, 2 = Muzzle3).
## Pusta tablica = wszystkie muzzle.
@export var muzzle_indices: Array[int] = []
