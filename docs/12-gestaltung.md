# Gestaltung und Bewegung

Stand: 27. Oktober 2026

Wie die App aussieht und sich bewegt. Grundlage sind die Design-Engineering-Regeln von Emil Kowalski (Sammlung [emilkowalski/skills](https://github.com/emilkowalski/skills): `emil-design-eng`, `animate`, `apple-design`, `mobile-native`, `animation-performance`, `review-animations`), übersetzt für Flutter und die PWA. Die Regeln dort sind für CSS geschrieben; hier steht, was sie in dieser App konkret bedeuten. Ergänzt `03-produktkonzept.md` (Abschnitt 9, Barrierefreiheit) und `10-pwa.md`.

## 1. Haltung

- **Ruhe vor Reiz.** Die App wird jeden Abend geöffnet, oft müde. Wenig Farbe, viel Fläche, eine Schrift, keine Konfetti. Stimmung der App: ruhig, warm, verlässlich. Jede Bewegung dient dieser Stimmung oder entfällt.
- **Unsichtbare Details zählen zusammen.** Die Nutzerin bemerkt die einzelne Regel nicht; sie bemerkt, dass sich die App "richtig" anfühlt. Deshalb gelten die Werte unten überall gleich, nicht "ungefähr".
- **Weniger Bewegung ist meist besser.** Vor jeder Animation die vier Fragen: Wie oft sieht man sie? Wozu dient sie? Bleibt sie unter 300 ms? Stört sie beim Lesen? Fällt eine Antwort durch, gibt es keine Animation.

## 2. Wann etwas animiert

| Häufigkeit | Beispiel in der App | Entscheidung |
|---|---|---|
| Dutzende Male am Tag | Wechsel der Reiter Heute, Kalender, Mehr, Einstellungen | Keine Animation (IndexedStack), nur die Markierung der Leiste |
| Oft | Tippen auf Tasten, Karten, Kalendertage | Nur Rückmeldung: 97 % Größe beim Aufsetzen des Fingers, 120 ms zurück |
| Gelegentlich | Routenwechsel, Blätter (Aufnahme, Schreiben), Dialoge, Einblenden von Listen | Standard: 220 bis 320 ms, kräftiges Ease-out |
| Selten, erstes Mal | Onboarding, leere Zustände, Backup erfolgreich | Hier darf etwas Freude hin (gestaffeltes Erscheinen), weiter nichts |

Zweck muss benennbar sein: **Rückmeldung** (die Taste hat gehört), **räumliche Konsistenz** (Blatt kommt von unten, geht nach unten), **Zustand zeigen** (Aufnahme läuft), **harten Wechsel vermeiden** (Inhalt erscheint nicht aus dem Nichts). "Sieht gut aus" ist kein Zweck.

## 3. Tokens (`app/lib/app/motion.dart`)

| Token | Wert | Wofür |
|---|---|---|
| `Motion.press` | 120 ms | Drücken und Loslassen |
| `Motion.quick` | 160 ms | Farb- und Zustandswechsel (Kalendertag gewählt, Umschalter) |
| `Motion.enter` | 220 ms | Einblenden von Inhalt |
| `Motion.page` | 280 ms | Routen innerhalb der App |
| `Motion.sheet` | 320 ms | Vollbild-Blätter von unten |
| `Motion.stagger` | 45 ms | Versatz zwischen Listenelementen (30 bis 80 ms erlaubt) |
| `Motion.easeOut` | `Cubic(0.23, 1, 0.32, 1)` | Alles, was erscheint oder verschwindet |
| `Motion.easeInOut` | `Cubic(0.77, 0, 0.175, 1)` | Bewegung auf dem Bildschirm |
| `Motion.drawer` | `Cubic(0.32, 0.72, 0, 1)` | Blätter, Schubladen (iOS-Kurve) |
| `Motion.pressScale` | 0,97 | Zielgröße beim Drücken |

Regeln: nie Ease-in in der Oberfläche; nie aus Größe 0 erscheinen (mindestens 0,95 plus Deckkraft); Austritt auf demselben Weg wie Eintritt; nur Deckkraft und Transformation animieren, keine Größe, keine Abstände (Ausnahme: ausklappende Abschnitte).

## 4. Bausteine (`app/lib/widgets/`)

- **`Pressable`**: Rückmeldung beim Drücken. Reagiert auf `pointerDown`, nicht erst auf das Loslassen; bricht ab, wenn der Finger mehr als 10 px zieht (Scrollen). Mit "Reduce Motion" sinkt nur die Deckkraft.
- **`Reveal`**: Einblenden beim ersten Aufbau (Deckkraft 0 auf 1, 8 px von unten), optional gestaffelt über `index`. Blockiert nie die Bedienung. Mit "Reduce Motion" nur Deckkraft.
- **`SurfaceCard`**: Karte als weiche Fläche, Radius 20. Hell: zwei halbtransparente Schatten (weit und leise, eng und etwas dichter) statt Rahmen. Dunkel: Haarlinie statt Schatten, weil Schatten dort verschwinden. Tippbar mit Ink und `Pressable`.

## 5. Fläche, Farbe, Tiefe

- Material 3 aus dem Saatton Lehm (`#9C6B4A`); hell und dunkel aus demselben Schema, kein Oberflächen-Tint (`surfaceTintColor` transparent).
- Hierarchie über Flächenstufen (`surface`, `surfaceContainerLow`, `surfaceContainerHigh`), nicht über Linien. Trennlinien nur wo nötig und dann mit 60 % Deckkraft.
- Akzentfarbe (`primary`) nur für die eine Hauptaktion je Bildschirm (Aufnahmetaste, Stopptaste, gewählter Tag) und kleine Kennzeichen.
- Farbe trägt nie allein Bedeutung (Kalender: Punkt und Fettdruck zusätzlich).

## 6. Schrift

Eine Schrift (Inter, gebündelt, D16). Laufweite je Größe, nicht ein Wert für alles: große Grade enger (Display −1,5 bis Headline −0,3), Fließtext neutral mit Zeilenhöhe 1,45 bis 1,5, Beschriftungen leicht gesperrt (+0,3). Hierarchie über Gewicht (600 für Titel) und Größe zusammen, nicht über Größe allein. Die Schriftgröße des Systems wird nie überschrieben; Layouts müssen mit 200 % Text funktionieren. Zahlen, die sich ändern (Zähler der Aufnahme), mit Tabellenziffern.

## 7. Bedienelemente

- Tasten: Radius 14, Höhe mindestens 52 (die Hauptaktion), Ink plus `Pressable`-Rückmeldung; Beschriftung 600.
- Eingabefelder: gefüllte Fläche ohne Rahmen, Fokus mit 1,5 px in `primary`; Mindesthöhe 48.
- Untere Leiste: Fläche in `surface` mit Haarlinie oben, Stadium-Markierung, 72 hoch.
- Dialoge und Blätter: Radius 24, Fläche `surfaceContainerLow`, Griff bei Bottom-Sheets.

## 8. Routen

iOS schiebt von rechts (Cupertino-Übergang mit Parallaxe), alle anderen Plattformen blenden nach vorn (Material 3 "Fade forwards"). Vollbild-Blätter (Aufnahme, Schreiben) kommen von unten und gehen nach unten. Schließen ist immer dort, wo geöffnet wurde (links oben das X).

## 9. Reduce Motion

Weniger und sanfter, nicht nichts: Deckkraft- und Farbwechsel bleiben, Ortswechsel (Schieben, Staffelung, Pegelbalken) entfallen. Erkannt über `MediaQuery.disableAnimationsOf` (die PWA übernimmt `prefers-reduced-motion`). Kein Element wackelt oder pulsiert dauerhaft; nichts blinkt schneller als einmal pro Sekunde.

## 10. Web / PWA ("fühlt sich installiert an")

Baseline in `app/web/index.html`:

- `-webkit-tap-highlight-color: transparent`: kein grauer Blitz beim Tippen (Rückmeldung kommt aus der App).
- `overscroll-behavior: none`: kein Ziehen-zum-Aktualisieren, kein Gummiband der Seite.
- `-webkit-text-size-adjust: 100%`: keine Schriftvergrößerung im Querformat.
- `viewport-fit=cover` und `interactive-widget=resizes-content`: Fläche bis unter die Aussparung, Tastatur verkleinert die Ansicht statt zu verdecken.
- `theme-color` je Farbschema in der Farbe des oberen Seitenrands (`#FFF8F5` hell, `#19120D` dunkel), dieselben Werte als Hintergrund vor dem ersten Frame und im Manifest, damit beim Start nichts blitzt.
- Ladehinweis blendet in 200 ms aus, sobald Flutter den ersten Frame meldet (`flutter-first-frame`).
- Nie `user-scalable=no` oder `maximum-scale=1`.

Was nur auf dem Gerät prüfbar ist: haftende Hover-Zustände, Tipp-Verzögerung, Tastatur, Safe Areas im installierten Modus. Deshalb Prüfliste in `11-installation-pwa.md` nach jeder größeren Änderung auf einem echten Telefon durchgehen.

## 11. Prüfliste vor dem Commit

| Prüfen | Erwartung |
|---|---|
| Neue Animation | Zweck benannt, Dauer aus `Motion`, Kurve aus `Motion`, Reduce-Motion-Pfad vorhanden |
| Neue Taste oder Karte | Rückmeldung beim Drücken (`Pressable` oder Material-Ink mit `animationDuration: Motion.press`) |
| Erscheinender Inhalt | `Reveal` oder begründet sofort da; nie aus Größe 0 |
| Liste erscheint | gestaffelt, Versatz 45 ms, ohne Blockade |
| Fläche mit Tiefe | `SurfaceCard` statt Rahmen |
| Text | Stil aus dem `TextTheme`, keine eigene Laufweite |
| Web | CSP unverändert, keine Inline-Skripte, `tool/check_no_network.sh` grün |
