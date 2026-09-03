# 00 · Anforderungen und Leitplanken

Stand: 3. September 2026 · Status: Entwurf zur Abstimmung

## 1. Ausgangslage

Gewünscht ist eine neue App für iOS und Android, mit der man den eigenen Tag **per Sprache** in ein Tagebuch aufnimmt, ohne zu tippen. Zu einer festen, frei änderbaren Uhrzeit erinnert die App; man spricht ins Mikrofon, die App nimmt auf, transkribiert und kann Aufnahme und Text später wieder ausgeben.

Zwei Dinge sind nicht verhandelbar:

1. **Alles bleibt lokal auf dem Gerät.** Keine Cloud, keine Server, keine Konten. Datensicherheit hat Vorrang vor jeder Komfortfunktion.
2. **Geräteübergreifend nur auf ausdrücklichen Wunsch**, und dann als komprimierte, verschlüsselte Datei, deren Übergabe per QR-Code initiiert wird.

Später soll die App dem Inhaber einen wirtschaftlichen Nutzen bringen. Sie braucht einen Namen und wird auf GitHub entwickelt.

## 2. Muss-Anforderungen (aus dem Auftrag)

| Nr. | Anforderung | Herkunft |
|-----|-------------|----------|
| M1 | Tägliche Sprachaufnahme statt Schreiben | Auftrag |
| M2 | Erinnerung zu einer festen, vom Nutzer änderbaren Uhrzeit | Auftrag |
| M3 | Aufnahme "in einfacher Art und Weise": ein Tipp, sprechen, fertig | Auftrag |
| M4 | Transkription der Aufnahme | Auftrag |
| M5 | Wiedergabe: Audio abspielen und Text lesen | Auftrag |
| M6 | Verarbeitung und Speicherung ausschließlich lokal, nachweisbar keine Cloud | Auftrag |
| M7 | Datensicherheit als oberstes Designziel (Verschlüsselung, Zugriffsschutz) | Auftrag |
| M8 | Optionaler Gerätewechsel/Zweitgerät: komprimierte, verschlüsselte Datei, Übergabe per QR-Code | Auftrag |
| M9 | iOS und Android | Auftrag |
| M10 | Wirtschaftliche Verwertbarkeit für den Inhaber | Auftrag |
| M11 | Ein tragfähiger Name (App, Repo, Domain) | Auftrag |
| M12 | Entwicklung offen nachvollziehbar auf GitHub | Auftrag |

## 3. Interpretationen und Annahmen

Diese Punkte sind meine Lesart des Auftrags. Sie sind bewusst als Annahmen markiert, damit sie widersprochen werden können.

- **A1 · Transkription heißt On-Device-Transkription.** M4 und M6 zusammen erlauben keinen Cloud-Dienst für Speech-to-Text. Die App nutzt ausschließlich Spracherkennung, die auf dem Gerät läuft, und muss im Flugmodus funktionieren. Das ist zugleich der einfachste Nachweis für Nutzer.
- **A2 · Der QR-Code transportiert Schlüssel und Verbindung, nicht die Daten.** Ein einzelner QR-Code fasst knapp 3 KB. Ein Jahr Tagebuch mit Audio ist um Größenordnungen größer. Der QR-Code enthält deshalb den Verschlüsselungsschlüssel (bzw. den Pairing-Code) und die Verbindungsinformation; die verschlüsselte, komprimierte Datei wandert über einen lokalen Kanal (gleiches WLAN, Bluetooth, Dateiübergabe). Für reine Textexporte ist ein animierter QR-Strom als Fallback denkbar. Details im Technikkonzept.
- **A3 · "Fester Zeitpunkt" ist eine Erinnerung, kein Zwang.** Aufnehmen ist jederzeit möglich; die Uhrzeit steuert die Erinnerung. Nachträgliches Aufnehmen für gestern ist erlaubt.
- **A4 · Ein Eintrag = ein Tag, aber mehrere Aufnahmen pro Tag sind möglich.** Kurze Ergänzungen im Tagesverlauf gehören zum selben Tageseintrag.
- **A5 · Audio wird behalten, nicht nur der Text.** Die Stimme ist Teil der Erinnerung. Nutzer können pro Eintrag oder global entscheiden, ob Audio aufbewahrt wird (Speicherplatz).
- **A6 · Kein Konto, keine Telemetrie, keine Werbung, keine Drittanbieter-SDKs mit Netzwerkzugriff.** Die App fordert idealerweise gar keine Netzwerkberechtigung an, die sie nicht für den lokalen Transfer braucht.
- **A7 · Sprachen zuerst Deutsch und Englisch.** Weitere Sprachen folgen der Verfügbarkeit lokaler Modelle. Schweizerdeutsch wird als eigenes Thema geführt.
- **A8 · Der Verlust des Geräts darf nicht der Verlust des Tagebuchs sein.** Ohne Cloud braucht es ein einfaches, verschlüsseltes lokales Backup (Dateiexport), das Nutzer selbst ablegen. Das ist dieselbe Datei wie beim Gerätewechsel (M8).

## 4. Nicht-Ziele (bewusst nicht Teil des Produkts)

- Kein Cloud-Sync, auch kein "optionaler" Sync über eigene Server.
- Keine Social-Funktionen, kein Teilen in Netzwerke.
- Keine serverseitige KI. Auswertungen (Zusammenfassungen, Suche) nur, wenn sie vollständig lokal laufen.
- Keine medizinischen Aussagen oder Diagnosen (Abgrenzung zum Medizinprodukt).
- Kein Tracking, keine A/B-Test-SDKs, keine Crash-Reporter mit automatischem Upload.

## 5. Erfolgskriterien für die erste Version

- Vom Öffnen der App bis zum Start der Aufnahme höchstens ein Tipp.
- Transkription in Deutsch und Englisch ohne Netz, nachweisbar im Flugmodus.
- Eintrag ist nach dem Sperren des Geräts nur mit Gerätecode/Biometrie lesbar; Daten liegen verschlüsselt auf dem Dateisystem.
- Gerätewechsel iOS↔Android in unter fünf Minuten ohne Cloud.
- App-Store-Datenschutzlabel "Es werden keine Daten erfasst" und Google Play Data Safety "Keine Daten werden erhoben" sind wahr und belegbar.

## 6. Offene Entscheidungen

| Thema | Optionen | Wer entscheidet |
|-------|----------|-----------------|
| Name | Shortlist in `08-namensfindung.md` | Inhaber |
| Lizenz des Quellcodes | Proprietär mit öffentlichem Repo, Open Core, vollständig Open Source (z. B. AGPL) | Inhaber; Empfehlung im Geschäftsmodell |
| Technologie-Stack | Zweimal nativ, Kotlin Multiplatform, Flutter | Empfehlung im Technikkonzept |
| Preismodell | Einmalkauf, Abo, Hybrid | Empfehlung im Geschäftsmodell |
