# Galaxid3D (GALAXID FREE)

Projekt gry 3D w **Godot 4.6** (renderer: **Forward+**). Repo zawiera sceny, skrypty GDScript i assety potrzebne do uruchomienia prototypu/gry typu space‑shooter.

## Uruchomienie

- Otwórz projekt w **Godot 4.6**.
- Uruchom (`Play`) — główna scena jest ustawiona w `project.godot` jako `3dworld.tscn` (UID: `uid://c0rjf6bfsduht`).

## Konfiguracja projektu (skrót)

Źródło: `project.godot`.

- **Nazwa aplikacji**: `GALAXID FREE`
- **Main scene**: `res://3dworld.tscn` (UID `uid://c0rjf6bfsduht`)
- **FPS cap**: 60
- **Okno / orientacja**:
  - viewport: 1080×1920
  - override: 600×800
  - tryb stretch: `canvas_items`
  - emulacja dotyku z myszy: włączona
- **Fizyka 3D**: `Jolt Physics`
- **Windows renderer driver**: `d3d12`

## Autoloady (singletons)

Źródło: sekcja `[autoload]` w `project.godot`.

- `DataManager`: `res://scripts/core/DataManager.gd`
- `GameConstants`: `res://scripts/core/GameConstants.gd`
- `SoundManager`: `res://scripts/managers/SoundManager.gd`

## Struktura (najczęściej używane)

- `3dworld.tscn`: główna scena gry (`Node3D` o nazwie `Game`) z m.in.:
  - `Player` (`res://scenes/player/Player.tscn`)
  - `PlanetSpawner` (`res://scenes/planets/PlanetSpawner.gd`)
  - `Path3D` + `PathFollow3D*` ze skryptem `res://scenes/enemy/EnemyPath.gd`
  - instancje przeciwników `res://scenes/enemies/starfighter.tscn`
  - `PlayAreaFrame` (`res://scenes/debug/PlayAreaFrame.tscn`)
- `scenes/`: sceny gry (player, enemy, planets, debug, projectile, …)
- `scripts/`: logika współdzielona / singletons (core, managers, …)
- `assets/`: grafika, audio, ikony, importy

## Przykład logiki przeciwnika

Plik: `scenes/enemy/Enemy.gd`.

- Przeciwnik rozszerza `Area3D`, dodaje się do grupy `enemies`.
- Strzelanie w pętli `_process` oparte o `fire_rate` i timer.
- Pociski tworzone przez `GameConstants.enemy_projectile_scene`.
- Dźwięki przez `SoundManager` (trafienie/wybuch/broń).
- Kolizja z graczem:
  - gracz jest w grupie `player`
  - na wejściu w ciało przeciwnik zadaje obrażenia (`body.take_damage(armor)`) i ginie.

## Notatki dla pracy z AI (żeby szybciej startować rozmowy)

Jeśli prosisz asystenta o zmiany, podaj:

- **Godot wersja**: 4.6
- **Scena startowa**: `3dworld.tscn`
- **Singletony**: `DataManager`, `GameConstants`, `SoundManager`
- **Miejsca w projekcie**:
  - logika przeciwników: `scenes/enemy/`
  - logika pocisków: `scenes/projectile/`
  - globalne stałe/spawn scen: `scripts/core/GameConstants.gd`

