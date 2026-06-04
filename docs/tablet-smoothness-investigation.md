# Podsumowanie: płynność wrogów na tablecie (Galaxid3D)

Dokument zbiera całą ścieżkę diagnostyki — od pierwszego szarpania po finalny model ruchu w produkcji.

---

## 1. Z czym mieliśmy problem

### Objawy

- Na **tablecie (~10")** wrogowie na falach (`PathFollow3D`, szybkość ~8–12) wyglądali na **poszarpanych / lekko rozmazanych** w locie.
- **Gracz** na tym samym urządzeniu był **płynny**.
- Na **PC** w edytorze często było OK lub trudniej zauważyć różnicę.
- Po pierwszej próbie „naprawy” (`_process` zamiast `_physics_process`) szarpanie czasem maleło, ale pojawił się **kontrast**: gracz gładki, wrogowie gorzej.

### Osobny problem: pierwszy strzał wroga

- Przy **pierwszym** strzale wroga w sesji krótki **hitch** (freeze).
- **Nie** był to dźwięk (`SoundManager` cache) — winny **pierwszy spawn `EnemyProjectile`** (GPUParticles3D → kompilacja shaderów na GPU).
- **Fix:** warmup w `GameConstants.gd` (niewidoczny pocisk poza kadrem na starcie poziomu).

### Co na początku **nie** było główną przyczyną

| Hipoteza | Test | Wynik |
|----------|------|--------|
| TAA / MSAA | wyłączone w grze i teście | bez istotnej różnicy na tablecie |
| Sam model GLB / shader | Blaze w teście | **płynnie** przy dobrym pipeline ruchu |
| `Area3D` vs `CharacterBody3D` w izolacji | kapsułki w `SmoothEnemyTest` | prawie **bez różnicy** |
| Sam rozmiar ekranu jako „błąd gry” | ten sam APK: telefon vs tablet | na **telefonie (~5")** prawie OK → głównie **wyświetlanie / skalowanie** |

---

## 2. Architektura ruchu w grze (kontekst)

### Gracz

- `CharacterBody3D`, **poza** `LevelScroll`
- Ruch w `_physics_process`, w projekcie `physics_interpolation=true` → silnik wygładza między tickami (~60 Hz)

### Wrogowie na fali (przed fixem)

- Dzieci **`LevelScroll`** — cała fala jedzie w Z jak na taśmie (dojazd do kadru)
- `EnemyPath` na `PathFollow3D`: `progress` po krzywej **+ kompensacja scrolla** (`global_position` na anchorze, żeby „odjąć” ruch taśmy)
- To były **dwa nakładające się ruchy** w innym rytmie niż gracz
- Po eksperymencie: `_process` + interpolacja **OFF** na ścieżce → jeszcze większy rozjazd z graczem

### `LevelScroll` — po co w ogóle

- Nie przewija całej mapy (tło, planety, gracz stoją osobno)
- Przesuwa **paczkę fal** ustawionych w `-Z`, żeby dojechały do gracza i przekroczyły `scroll_activation_z` → aktywacja walki

---

## 3. Testy i obserwacje

### Scena: `scenes/debug/smooth_enemy_test.tscn` (F6)

Zbudowana do **izolacji** przyczyn na tablecie.

#### Sondy kolorowe (opcjonalne, `show_test_probes`)

| Kolor | Węzeł | Co testowało |
|-------|--------|----------------|
| **Niebieski** | `ProbePlayerTouch` | `CharacterBody3D` + sterowanie dotykiem — **jak gracz** |
| **Zielony** | `ProbeCharacter` | `CharacterBody3D` + auto patrol + interpolacja |
| **Pomarańczowy** | `ProbeAreaPhysics` | `Area3D` + `_physics_process` — jak prosty `Enemy.gd` |
| **Czerwony** | `ProbeAreaProcess` | `Area3D` + `_process` |
| **Żółty** | `ProbeNewEnemy` | `test_enemy_new.gd` — **pipeline gracza**, lot w **+Z** (jak szybka fala), potem ten sam **Blaze GLB** |

**Obserwacja:** niebieski = player; **żółty (i zielony/czerwony) gładkie**; różnice między sondami trudne do zauważenia.

**Wniosek:** tablet **potrafi** gładki szybki ruch; sam typ `Area3D` / `_process` vs `_physics_process` **nie tłumaczy** problemu z prawdziwej gry.

#### Żółty — dlaczego był „OK”

- **Nie** używał `PathFollow3D`, `LevelScroll`, kompensacji
- `CharacterBody3D` + `global_position` w `_physics_process` + **`physics_interpolation_mode = ON`**
- Ten sam model Blaze GLB — **model nie był winny**

#### Test z modelem GLB na żółtym

- Podmiana kapsuły na `blaze_2_model.tscn` → nadal **płynnie** przy pierwszym przejeździe
- Potwierdzenie: problem nie leży w mesh/shaderze samym w sobie

#### Patologia po ~30 s w teście (ważne, ale inny temat)

- Po ok. **30 s** psuło się **wszystko**: kulki, Blaze, nawet niebieski (player)
- Niezależnie od trajektorii; **wyłączenie TAA** nic nie dawało
- **Interpretacja:** obciążenie urządzenia / thermal throttling / spadek FPS w **pętli testowej** (te same obiekty non-stop), **nie** typowy gameplay (wróg krótko na ekranie)
- W produkcji **nie** zakładamy, że cała gra po 30 min będzie tak sama jak ten test

#### Twardy loop vs ping-pong (TAA)

- Stara trajektoria `fmod` robiła **teleport** w Z co okrążenie → przy TAA narastały „duchy” po wielu przejazdach
- Zmiana na **ping-pong** w `patrol_paths.gd` — osobny temat testowy, nie główna przyczyna 30 s degradacji

---

### Test ścieżki **bez scrolla** (kluczowy)

**Pliki:** `test_wave_path_only.tscn`, `test_enemy_path.gd` (`TestEnemyPath`), węzeł `PathOnlyWave` w `smooth_enemy_test.tscn`

| Element | Test path-only | Gra (przed fixem) |
|--------|----------------|-------------------|
| Krzywa | wave 2 z `3dworld` | ta sama |
| Model | 3× `blaze_2` | ta sama |
| `LevelScroll` | **brak** | tak |
| Kompensacja scrolla | **brak** | tak |
| Tick | `_physics_process` | `_process` |
| Interpolacja | **ON** | OFF |
| Skrypt | `TestEnemyPath` | `EnemyPath` |

**Obserwacja:** Blaze na **tej samej krzywej** w teście był **gładki** jak żółty.

**Wniosek:** szarpanie w `3dworld` nie wynikało z `PathFollow3D`, GLB ani samej krzywej — tylko z **scroll + kompensacja + niespójny tick/interpolacja**.

---

### Test ze scrollem (odrzucony w dalszej pracy)

- `test_level_scroll_wave2.tscn` — fala jak w grze **z** scrollem i kompensacją
- Celowo **usunięty** z testu, gdy ustaliliśmy: najpierw ścieżka sama w sobie, potem produkcja bez kompensacji

---

### Inne testy użytkownika

- Scena **tylko z wrogami**, bez TAA/MSAA — **to samo** na tablecie
- **Ten sam APK** na telefonie vs tablecie — telefon **ostrszy** → wskazówka na **viewport 1080×1920 + stretch** na większym panelu, nie na „złą logikę”

---

## 4. Wnioski końcowe

### Techniczne (najważniejsze)

1. **Tablet nie jest „za słaby”** — żółty i path-only pokazały, że szybki ruch + Blaze mogą być gładkie.
2. **Gracz ≠ wróg na fali** — nie chodzi o to, że „wróg musi być `CharacterBody3D`”, tylko o **jeden spójny ruch** z interpolacją, bez drugiego ruchu scrolla w tle.
3. **Winowajca w grze:** `LevelScroll` **po aktywacji** + **`_apply_scroll_compensation`** + rozjazd `_process` / brak interpolacji vs gracz.
4. **`Enemy.gd` + interpolacja** — dotyczy głównie prostych wrogów; **fale jadą przez `EnemyPath.gd`**.

### Model produkcyjny (uzgodniony i wdrożony)

| Faza | Zachowanie |
|------|------------|
| **Przed aktywacją** | Fala pod `LevelScroll` — dojazd do kadru (scroll **zostaje**) |
| **Po aktywacji** | **Odpinanie** od scrolla (`detach_to_active_scene` / własny `Path3D` na root dla `PathFollow`) |
| **Ruch po aktywacji** | Tylko `progress` + bank, jak w teście path-only: **`_physics_process` + interpolacja ON** |
| **Kompensacja** | **Usunięta** — po odpinaniu niepotrzebna |

**`LevelScroll` nie usuwamy** — służy tylko do **dowiezienia fal** przed walką.

### Co zostaje „akceptowalnym kompromisem”

- **Telefon vs tablet** — część różnicy to **hardware / skalowanie**, nie da się w 100% wyrównać APK-em.
- **Rozmycie przy bardzo szybkim ruchu** na dużym panelu może być widoczne nawet przy dobrym kodzie — ale **szarpanie co klatkę** miało być naprawione przez detach + physics interpolation.
- **30 s degradacja w teście** — artefakt długiej pętli na urządzeniu, nie model jednego wroga w poziomie.

### Osobno: pierwszy strzał

- Warmup `EnemyProjectile` na starcie poziomu — żeby hitch nie trafiał w pierwszą walkę.

---

## 5. Pliki wartościowe (ślad pracy)

| Plik | Rola |
|------|------|
| `scenes/debug/smooth_enemy_test.tscn` | Scena F6, domyślnie `PathOnlyWave` |
| `scenes/debug/test_enemy_new.gd` | Żółty — pipeline gracza |
| `scenes/debug/test_enemy_path.gd` | Path-only — wzorzec produkcji |
| `scenes/debug/test_wave_path_only.tscn` | Krzywa wave 2, 3× Blaze |
| `scenes/enemy/EnemyPath.gd` | Produkcja: detach, bez kompensacji |
| `scenes/world/LevelScroll3D.gd` | Scroll tylko pre-aktywacja |
| `scenes/enemy/Enemy.gd` | Detach przy aktywacji (jeśli nie na PathFollow) |
| `scenes/enemies/animation.gd` | Slide: detach przy starcie |
| `scripts/core/GameConstants.gd` | Warmup pocisku wroga |

---

## 6. Jedno zdanie na koniec

**Problem:** wrogowie mieli podwójny ruch (taśma + ścieżka + kompensacja) w innym rytmie niż gracz. **Dowód:** żółty i path-only były gładkie na tablecie. **Rozwiązanie:** scroll tylko do aktywacji, potem ścieżka jak w teście — bez kompensacji, z interpolacją fizyki.
