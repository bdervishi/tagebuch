# Übungen für Bewegungspausen

`exercises.json`: gebündelte Übungen für die Karte "Zeit für Bewegung" und den Bildschirm "Bewegung" (D24). Kein Netz, keine Fremdquelle zur Laufzeit, keine Videos oder Bilder.

Regeln für Einträge:

- Jede Übung hat `id` (fortlaufend `m001` …), `category` aus der Liste oben in der Datei (`stretch`, `walk`, `strength`, `breathe`), `minutes` (Dauer in Minuten, unter einer Minute als Bruch wie `0.5`), Titel `de`/`en` und eine kurze Anleitung `howDe`/`howEn` in zwei bis drei Sätzen.
- Nur Alltagsbewegung, die ohne Gerät, ohne Umziehen und ohne Platz geht: aufstehen, dehnen, gehen, Treppe, Atmung. Keine Übungen, die Technik oder Aufsicht brauchen.
- Keine medizinischen Versprechen, keine Wirkungsbehauptungen ("senkt den Blutdruck", "gegen Rückenschmerzen"), keine Kalorien, keine Leistungsziele. Die Texte beschreiben nur, was zu tun ist, und sagen, wo man vorsichtig sein soll.
- Der Hinweis `notice` ("Bei Schmerzen abbrechen; bei Beschwerden ärztlichen Rat einholen.") steht in der Datei und in der App; er bleibt bei jeder Änderung erhalten.
- Texte sind eigene Formulierungen (CC0); nichts aus Büchern oder Kursunterlagen übernehmen.
- Eigene Übungen der Nutzerin liegen nicht hier, sondern verschlüsselt im Datensatz-Store (Einstellung `ownExercises`).
