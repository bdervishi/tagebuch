# Rechercheberichte

Stand: 3. September 2026

Diese Berichte sind die Rohstoffe für die Konzeptdokumente in `docs/`. Sie wurden am 3. September 2026 von parallel arbeitenden Recherche-Agenten mit Websuche und Quellenlektüre erstellt und anschließend teilweise faktengeprüft (`verifikation.json`).

## Einschränkungen der Quellenlage

Die Recherche lief in einer Umgebung mit eingeschränktem Netzzugang. Nicht erreichbar waren unter anderem apple.com, support.apple.com, apps.apple.com, play.google.com, huggingface.co, Wikipedia, Reddit, Hacker News sowie viele Nachrichten- und Herstellerseiten. Gelesen wurden stattdessen die Entwicklerdokumentationen von Apple (auch über die JSON-Endpunkte von developer.apple.com) und Android, Quellcode, READMEs, Issues und Releases auf GitHub sowie Suchmaschinen-Auszüge. Konsequenzen:

- Store-Preise, Sternebewertungen und Downloadzahlen sind aus Suchauszügen rekonstruiert und in den Berichten als prüfpflichtig (`mustVerify`) markiert.
- Die Kollisionsprüfung der Namen konnte App Store, Play Store und Markenregister nicht direkt abfragen; geprüft wurden DNS, GitHub und Paketregister, ergänzt um eine manuelle Websuche (`namensfindung/nachpruefung.md`).
- Wo eine Aussage in `verifikation.json` als `korrigiert`, `widerlegt` oder `unklar` steht, gilt die dortige Fassung.

## Dateien

| Datei | Inhalt |
|-------|--------|
| `wettbewerb-voice-first.md` | Voice-first-Tagebuch- und Sprachnotiz-Apps |
| `wettbewerb-mainstream.md` | Etablierte Tagebuch-Apps, Apple Journal, Google Recorder, Samsung |
| `nutzerfeedback.md` | Beschwerden und Wünsche aus Issue-Trackern und Foren |
| `technik-ios.md` | On-Device-Spracherkennung und Plattform-APIs auf iOS 26 |
| `technik-android.md` | On-Device-Spracherkennung und Plattform-APIs auf Android |
| `technik-stack-sicherheit.md` | Framework-Vergleich, Verschlüsselung, Schlüsselverwahrung, Bedrohungsmodell |
| `technik-qr-transfer.md` | QR-Kapazität, animierte QR-Codes, lokale Übertragungskanäle, Containerformate |
| `geschaeftsmodell.md` | Preis-Benchmarks, Plattformabgaben, Monetarisierungsvarianten, Go-to-Market |
| `recht-compliance.md` | DSGVO/nDSG, Store-Pflichten, Exportkontrolle, Medizinprodukt-Abgrenzung, Barrierefreiheit |
| `innovationsluecken.md` | Differenzierungsideen mit Belegen und Aufwandsschätzung |
| `nachrecherche-nutzerstimmen-stores.md` | Nachrecherche: echte Nutzerstimmen und Store-Kennzahlen DE/AT/CH (stark eingeschränkt durch Netzsperren) |
| `nachrecherche-audio-container.md` | Nachrecherche: Audio-Codec, Container, verschlüsselte Wiedergabe auf iOS und Android |
| `verifikation.json` | Ergebnisse der Faktenprüfung von 30 priorisierten Aussagen (18 bestätigt, 12 präzisiert) |
| `namensfindung/ergebnis.json` | Namenskandidaten, Kollisionsprüfung, Jurywertung |
| `namensfindung/nachpruefung.md` | Manuelle Nachprüfung der Favoriten |
