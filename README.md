# Galaxid3D (GALAXID FREE)

Prototyp trójwymiarowej gry typu space-shooter z widokiem z góry, przygotowany w **Godot 4.6** z rendererem **Forward+**. Projekt zawiera kompletną pętlę rozgrywki: menu startowe, hangar, przewijany poziom, formacje przeciwników, walkę, wynik, combosy, loot i ekran końca gry.

## Uruchomienie

- Otwórz katalog projektu w **Godot 4.6**.
- Uruchom projekt przyciskiem `Play` (`F6`/`F5` w zależności od kontekstu edytora).
- Sceną startową jest `res://main.tscn`. Zawiera ona pełnoekranowy `SubViewport` z `GameWorld`, HUD oraz główne menu.

## Konfiguracja projektu (skrót)

Źródło: `project.godot`.

- **Nazwa aplikacji**: `GALAXID FREE`
- **Scena startowa**: `res://main.tscn`
- **Renderer**: Forward+; sterownik Windows `d3d12`
- **Rozdzielczość wewnętrzna gry**: `1920×1080`; okno ma override `1300×730`
- **Skalowanie interfejsu**: `canvas_items`
- **Orientacja urządzeń mobilnych**: pozioma
- **Sterowanie dotykowe z myszy**: włączone
- **Fizyka 3D**: Jolt Physics z interpolacją fizyki

## Sterowanie

- **Mysz / dotyk**: ruch statku po obszarze gry; lewy przycisk myszy lub przytrzymanie dotyku uruchamia ogień podstawowy.
- **Pad**: lewy drążek lub D-pad porusza statkiem, `A` strzela, `R2` wykonuje unik, a `L2` zmienia prędkość ruchu.
- **Broń specjalna**: `W` lub przycisk `X` uruchamia pierwszy slot, `Q` lub przycisk `Y` trzeci slot; pozostałe sloty są przypisane do przycisków pada.
- **Pauza / powrót**: `Esc` lub przyciski pada otwierają pauzę albo wracają z ekranów opcji i sterowania.

## Autoloady (singletons)

Źródło: sekcja `[autoload]` w `project.godot`.

- `DataManager`: ładuje katalog statków, broni, generatorów, sidekicków i konfigurację obszaru gry.
- `SceneRegistry`: udostępnia i buforuje sceny pocisków, sidekicków oraz pickupów.
- `SoundManager`: odtwarza efekty dźwiękowe na niezależnych kanałach broni, eksplozji i trafień.
- `HitComboManager`: liczy serię eliminacji i resetuje ją po zmianie sceny.
- `CameraShakeManager`: realizuje ekranowe drgania kamery po trafieniach.
- `GameState`: przechowuje wybór statku, generatora i kredyty podczas sesji.

## Struktura projektu

- `main.tscn`: scena wejściowa z `GameShell`, `SubViewport`, HUD-em, graczem, przewijanym poziomem, formacjami i muzyką.
- `scenes/player/`: statek gracza, system obrażeń, uzbrojenie i sceny pomocników.
- `scenes/enemies/`: wspólna logika przeciwników (`base/`), typy jednostek (`types/`) oraz gotowe formacje i bossowie (`formations/`).
- `scenes/ui/`: HUD, menu startowe, pauza, opcje, ekran sterowania i ekran końca gry.
- `scenes/hangar/`: wybór statku i generatora przed rozgrywką.
- `scripts/managers/`: singletony i współdzielone systemy gry.
- `scripts/resources/` oraz `data/`: definicje i katalogi danych statków, broni, generatorów, sidekicków oraz konfiguracji planszy.
- `assets/`: modele, materiały, efekty VFX, grafika interfejsu i audio.

## Rozgrywka

- **Statek i wyposażenie**: gracz wybiera w hangarze statek oraz generator energii. Dane są ładowane z katalogu danych, a wybrane identyfikatory są przekazywane przez `GameState`.
- **Broń**: system posiada trzy niezależne sloty uzbrojenia podstawowego (przedni, środkowy i tylny) oraz do czterech strzałów specjalnych. Specjale mogą tworzyć pociski albo aktywować wiązkę; zużywają energię generatora.
- **Sidekicki**: opcjonalni pomocnicy są instancjonowani po bokach statku i strzelają razem z ogniem podstawowym.
- **Unik**: czasowo wyłącza warstwę kolizji gracza, zatrzymuje ogień i wykonuje animację obrotu z cooldownem.
- **Żywotność i energia**: HUD aktualizuje pancerz, energię i wynik na podstawie sygnałów gracza. Trafienie wywołuje dźwięk, błysk ekranu oraz drganie kamery; wyczerpanie pancerza otwiera ekran końca gry.
- **Punktacja i combo**: zabici przeciwnicy zwiększają wynik, energię za eliminację i licznik serii. Od serii pięciu trafień HUD pokazuje animowany wskaźnik `HIT x…` ze zmiennym kolorem.
- **Loot**: przeciwnicy pozostawiają pickupy; po wyrzuceniu dryfują, a w zasięgu przyciągania lecą do gracza.

## Przeciwnicy, fale i przewijanie poziomu

- `LevelScroll3D` przesuwa zawartość poziomu wzdłuż osi `+Z`. Pod nim znajdują się formacje, bossowie i elementy tła; kamera oraz gracz pozostają poza przewijanym węzłem.
- Przeciwnik `Enemy` jest `Area3D` należącym do grupy `enemies`. Po przekroczeniu linii aktywacji rozpoczyna ruch i ostrzał, a po opuszczeniu ekranu może zostać usunięty.
- Formacje osadzone na ścieżkach mogą aktywować wrogów wspólnie; po aktywacji aktywne jednostki są odpinane od `LevelScroll`, aby kontynuować własny ruch.
- Obsługiwane są typy odporne na broń podstawową, połączenia śmierci jednostek, efekty trafień i eksplozji, pociski przeciwników, punktacja oraz drop pickupów.
- Aktualna scena poziomu zawiera kolejne formacje uderzeniowe i bossów, m.in. `begining`, `protector_strike`, `rocketer_strike`, `boss_devastator`, `hank_strike`, `finisher` i `cyclon_boss_2`.

## Interfejs i audio

- HUD uruchamia rozgrywkę z menu startowego i udostępnia przejście do hangaru, opcji oraz ekranu sterowania.
- Pauza zatrzymuje drzewo scen; ekran game over pokazuje końcowy wynik i pozwala rozpocząć rundę od nowa.
- Opcje pozwalają osobno regulować głośność muzyki i efektów dźwiękowych.
- Układ audio zawiera magistrale `Music`, `SFX`, `Weapons`, `Explosions` i `Impacts`; muzyka poziomu jest zapętlona.

## Rozwój projektu

- Edytuj parametry projektu przez interfejs Godot, szczególnie wpisy w `project.godot` dotyczące inputu, autoloadów i eksportu.
- Dane balansu są rozdzielone od logiki: dodawaj statki, generatory, broń i sidekicki przez zasoby w `data/` oraz ich katalog.
- Przy dodawaniu pocisku gracza zachowaj nazewnictwo `projectile_<id>.tscn` lub `power_<id>.tscn`, aby `SceneRegistry` mógł odnaleźć go automatycznie.
- Nowe fale i elementy scenografii należy umieszczać pod `LevelScroll` w `main.tscn`; gracz i kamera nie powinny być jego dziećmi.

