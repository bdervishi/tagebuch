# 10 · PWA zuerst: Web-Fassung

Stand: 27. Oktober 2026 · Status: Entwurf

## 1. Warum zuerst eine Web-App

Der Inhaber will das Tagebuch sofort auf dem eigenen Smartphone nutzen, ohne Entwicklerkonten, Store-Prüfung und Testgeräte-Verteilung. Eine installierbare Web-App (PWA) aus derselben Flutter-Codebasis erfüllt das: Sie wird von einem statischen Host geladen (GitHub Pages reicht, siehe `ressourcen.md`), über "Zum Home-Bildschirm" installiert, läuft danach offline und speichert alles im Browser-Speicher des Geräts. Die Store-Apps für iOS und Android (D1 bis D15) folgen aus demselben Code; die Web-Fassung ist ihr Vorläufer, kein Ersatz (D16).

## 2. Was gleich bleibt

- Eine Codebasis (Flutter), dieselben Pakete: `diary_core`, `diary_crypto`, `diary_chunkfile`, `diary_container`, Oberfläche und Lokalisierung.
- Dieselben Dateiformate: Audio als Chunk-AEAD-Datei, Backup und Gerätewechsel als Container (D6). Eine Backup-Datei aus der Web-Fassung lässt sich später in der Store-App importieren und umgekehrt.
- Kein Server sieht Daten. Das Hosting liefert nur die App-Dateien und die Modelldateien; die Content-Security-Policy erlaubt Verbindungen nur zum eigenen Origin.

## 3. Was auf dem Web anders ist

| Thema | Store-App (Ziel) | Web-Fassung | Folge |
|-------|------------------|-------------|-------|
| Speicherort | App-Container, SQLCipher | IndexedDB und Origin Private File System der installierten PWA | Metadaten als einzeln verschlüsselte Datensätze statt SQLCipher; Suche im Speicher der App |
| Master-Key | Keychain / Keystore, Hardware | WebCrypto-Schlüssel, nicht exportierbar, in IndexedDB | Kein Hardware-Schutz; Passphrase fürs Backup empfohlen |
| Datenverlust | nur bei Geräteverlust | zusätzlich Browser-Speicherräumung, "Website-Daten löschen", Deinstallation | Backup ist Pflichtfunktion der ersten Fassung |
| Spracherkennung | SpeechTranscriber, sherpa-onnx | WebAssembly-Modell im Browser (Whisper über ONNX Runtime Web), langsamer | Erkennung nach der Aufnahme, als "experimentell" markiert bis Spike W1 |
| Aufnahme | AAC-LC/M4A, Hintergrund möglich | MediaRecorder: WebM/Opus (Chrome), MP4/AAC (Safari); nur Vordergrund | Codec je Aufnahme gespeichert; Bildschirm an lassen |
| Erinnerung | lokale Benachrichtigung / Alarm | kein Push ohne Server; ICS-Kalendereintrag, Systemwecker, Hinweis beim Öffnen | M2 nur teilweise erfüllt |
| QR-Gerätewechsel | Kamera nativ | `BarcodeDetector` oder Code eintippen; Datei per Download/Dateiauswahl | gleiche Containerdatei |
| Biometrie, Widgets, Sperrbildschirm | ja | nein | Argumente für die Store-Apps |

## 4. Architektur der Web-Fassung

```
app/ (Flutter Web, PWA)
 ├─ web/manifest.json, index.html mit CSP, Service Worker (offline-first)
 └─ lib/services/create_services_web.dart   Verdrahtung der Web-Implementierungen (bedingter Import)
packages/diary_web/       Web-spezifische Umsetzungen der Ports aus diary_core (nur dart:js_interop und package:web)
 ├─ IndexedDbStore        Promise-/Event-Brücke zu IndexedDB: Datenbank `tagebuch`, Stores keys, records, files, meta
 ├─ WebMasterKeyStore     WebCrypto AES-256-GCM, extractable=false, als CryptoKey in IndexedDB; wrappt alle Schlüssel (DekWrapper)
 ├─ EncryptedRecordStore  verschlüsselte JSON-Datensätze (Einträge, Aufnahmen, Transkripte, Einstellungen), AAD = <Sammlung>/<ID>
 ├─ EncryptedFileStore    Audio als Chunk-AEAD-Datei (diary_chunkfile) im Store `files`; OPFS als spätere Ausbaustufe
 ├─ Web…Repository        Repositories aus diary_core auf dem EncryptedRecordStore, WebSearchRepository mit Index im Speicher
 ├─ MediaRecorderCapture  Aufnahme, Pegel, Wellenform; PCM-Abgriff über AnalyserNode (AudioWorklet folgt mit der Erkennung, W5)
 ├─ WebAudioPlayer        Wiedergabe aus dem Speicher (Blob-URL), Geschwindigkeit 0,8 bis 2,0
 ├─ WebStorageInfo        navigator.storage.persist/estimate, installiert?, iOS?
 ├─ WasmSttEngine         Whisper über transformers.js / ONNX Runtime Web (Spike W1, noch nicht gebaut)
 └─ IcsReminder           Kalenderdatei für die tägliche Erinnerung, Download über Blob-URL
```

Schlüsselhierarchie wie D5: Der WebCrypto-Master-Key wrappt pro Aufnahme einen zufälligen Dateischlüssel (Zweck `chunkfile-v1`) und einmalig den Datensatz-Schlüssel (Zweck `records-v1`); die Audiodatei wird mit `diary_chunkfile` (AES-256-GCM, `AeadId.aes256Gcm`, damit WebCrypto und die Dart-Referenz dasselbe Format lesen) geschrieben. Weil der Master-Key die Anwendung nie als Bytes erreicht, bietet `diary_chunkfile` die Varianten `ChunkFileWriter.withWrappedFileKey` und `ChunkFileReader.openWith`; das Byte-Layout bleibt identisch, und der gewrappte Dateischlüssel steht sowohl im Dateikopf als auch in `Recording.fileKeyWrapped` (Crypto-Shredding löscht den Datensatz-Blob). Datensätze (JSON) werden einzeln mit `nonce || AES-256-GCM(JSON)` verschlüsselt; Zusatzdaten sind `<Sammlung>/<ID>`, damit Datensätze nicht vertauscht werden können.

Abweichung vom ursprünglichen Bild (Stand W2/W3): Audiodateien liegen als Ganzes im IndexedDB-Store `files`, nicht im Origin Private File System. Für Tagebuchaufnahmen (3 Minuten bei 32 kbit/s sind rund 0,7 MB) reicht das; die Datei wird zum Abspielen vollständig in den Speicher entschlüsselt. OPFS mit chunkweisem Lesen bleibt die Ausbaustufe für sehr lange Aufnahmen (Plus, 30 Minuten). Der PCM-Abgriff läuft über einen `AnalyserNode` (Momentaufnahmen alle 100 ms): genug für Pegel, Wellenform und die Fake-Erkennung, nicht lückenlos; die echte Erkennung (W5) braucht den `AudioWorklet`.

Suche: Beim ersten Suchen werden alle Transkripte entschlüsselt in den Speicher geladen (ein Jahr Text liegt bei rund 1 MB) und gefaltet; Umlaute und ß werden wie in `diary_storage` normalisiert (Kopie der Regeln in `diary_web/src/text_normalization.dart`, gemeinsam zu pflegen). Jede Änderung macht den Index ungültig. Ab mehreren Jahren Daten wäre sqlite3 im Browser (drift mit WASM und OPFS) die Ausbaustufe; der Index läge dann unverschlüsselt im OPFS, deshalb erst nach Bewertung.

Tests: `packages/diary_web/test` läuft mit `flutter test --platform chrome` im Chromium (Master-Key, Datensätze überleben Schließen und Öffnen, Dateien mit der Dart-Referenz lesbar, Repositories, Suche, ICS). MediaRecorder und Player sind headless nur bis zur Konstruktion prüfbar (kein Mikrofon, keine echte Aufnahme); der Weg Mikrofon → Datei → Wiedergabe wird auf dem Telefon geprüft (Prüfkriterium W3).

## 5. Bekannte Lücken der Web-Fassung

1. **Tägliche Erinnerung (M2):** Ohne Push-Server keine Benachrichtigung bei geschlossener App. Angebotener Ersatz: ICS-Kalendereintrag, Systemwecker, Hinweis beim Öffnen. Vollständig erst mit den Store-Apps.
2. **Transkriptionsqualität und -dauer:** Whisper small im Browser braucht auf einem Mittelklasse-Telefon ein Vielfaches der Aufnahmedauer und mehrere hundert Megabyte Modell-Download. Spike W1 entscheidet zwischen Whisper base, Whisper small und Moonshine-Web und legt fest, ab welchem Gerät die Erkennung angeboten wird. Bis dahin ist die Transkription als experimentell gekennzeichnet; der Nutzer kann Einträge auch ohne Text führen.
3. **Speicherräumung:** iOS entfernt Daten nicht installierter Web-Apps nach sieben Tagen Inaktivität; installierte PWAs sind ausgenommen, solange sie installiert bleiben. Die App verlangt die Installation vor der ersten Aufnahme, ruft `navigator.storage.persist()` auf und erinnert an Backups.
4. **Schlüsselschutz:** Wer das entsperrte Telefon in der Hand hat, kann die PWA öffnen; eine App-Sperre per Passphrase ist auf dem Web deshalb Standard (Zeitfenster wie D5), Biometrie gibt es nicht.
5. **Aufnahme nur im Vordergrund:** Bildschirm-aus oder App-Wechsel beendet die Aufnahme auf iOS. Die App speichert bis dahin Aufgenommenes (Chunk-Datei bleibt bis zum letzten vollständigen Chunk lesbar).

## 6. Reihenfolge

| Schritt | Inhalt | Prüfkriterium |
|---------|--------|---------------|
| W0 | Web-Plattform, PWA-Manifest, Service Worker, CSP, Icons, Installationshinweis | `flutter build web` baut; Lighthouse-PWA-Prüfung bestanden; offline startbar |
| W1 (Spike) | Whisper im Browser: Dauer und Wortfehlerrate auf iPhone und Android-Mittelklasse, Modellwahl | Tabelle in `docs/`, Entscheidung Modell und Mindestgerät |
| W2 | `diary_web`: WebCrypto-Schlüssel, verschlüsselte Datensätze, Audio als Chunk-Datei in IndexedDB, Tests im Chromium | Daten überleben Neuladen; Chunk-Dateien mit Dart-Referenz lesbar (umgesetzt, Tests grün) |
| W3 | Aufnahme und Wiedergabe im Browser, Wellenform, Einträge mit echtem Audio; App auf die Ports umgestellt | 3-Minuten-Aufnahme auf iPhone und Android, Wiedergabe mit Sprung (Code umgesetzt; Telefon-Test offen) |
| W4 | Backup-Datei und Import, QR-Gerätewechsel über Datei | Round-Trip zwischen zwei Browsern |
| W5 | Transkription aus W1 eingebaut, Suche | Flugmodus-Test im Browser: alle Schritte offline |
| W6 | Veröffentlichung auf GitHub Pages, Anleitung "Installieren" | Inhaber nutzt die App täglich |

Danach die Store-Spikes S1 bis S7 aus `09-roadmap.md`.

## 7. Offene Fragen

- Modellwahl und Mindestgerät für die Browser-Erkennung (W1).
- Ob Safari auf iOS den `BarcodeDetector` bereitstellt oder der QR-Code eingetippt werden muss.
- Verhalten des Origin Private File System auf iOS bei großen Audiodateien (Speicherkontingent, Räumung).
- Ob die Store-Apps später den Browser-Speicher der PWA übernehmen können (nein, geplant ist der Weg über die Backup-Datei).
