# 10 · PWA zuerst: Web-Fassung

Stand: 27. Oktober 2026 · Status: Entwurf (W5 Browser-Erkennung eingebaut, Messung W1 offen)

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
| Erinnerung | lokale Benachrichtigung / Alarm | kein Push ohne Server; Termin in Google Kalender oder Outlook per vorbefülltem Link (D18), ICS-Kalendereintrag, Systemwecker, Hinweis beim Öffnen | M2 nur teilweise erfüllt |
| QR-Gerätewechsel | Kamera nativ | `BarcodeDetector` oder Code eintippen; Datei per Download/Dateiauswahl | gleiche Containerdatei |
| App-Sperre | Biometrie oder Gerätecode, Schlüssel gebunden (D5) | eigener PIN als Bildschirmsperre, Schlüssel nicht gebunden (D23) | ehrlicher Hinweistext in den Einstellungen; Biometrie erst im Store |
| Biometrie, Widgets, Sperrbildschirm-Steuerung | ja | nein | Argumente für die Store-Apps |

## 4. Architektur der Web-Fassung

```
app/ (Flutter Web, PWA)
 ├─ web/manifest.json, index.html mit CSP, Service Worker (offline-first)
 ├─ web/stt/stt_worker.js      Web Worker der Erkennung (ES-Modul): transformers.js + ONNX Runtime aus web/stt/vendor/,
 │                             Modell aus models/<Name>/ desselben Origins (Dateiliste web/stt/MODELS.md, Lizenzen vendor/LICENSES.md)
 └─ lib/services/create_services_web.dart   Verdrahtung der Web-Implementierungen (bedingter Import)
packages/diary_stt_web/       WasmSttEngine (SttEngine + AudioFileTranscriberPort): startet den Worker, dekodiert die Aufnahme
                              mit OfflineAudioContext zu 16-kHz-Mono-Float32, Sprach-Mapping, Segmente aus den Zeitstempeln
packages/diary_web/       Web-spezifische Umsetzungen der Ports aus diary_core (nur dart:js_interop und package:web)
 ├─ IndexedDbStore        Promise-/Event-Brücke zu IndexedDB: Datenbank `tagebuch`, Stores keys, records, files, meta
 ├─ WebMasterKeyStore     WebCrypto AES-256-GCM, extractable=false, als CryptoKey in IndexedDB; wrappt alle Schlüssel (DekWrapper)
 ├─ EncryptedRecordStore  verschlüsselte JSON-Datensätze (Sammlungen entries, recordings, transcripts, notes, goals, milestones, books, passages, settings), AAD = <Sammlung>/<ID>
 ├─ EncryptedFileStore    Audio als Chunk-AEAD-Datei (diary_chunkfile) im Store `files`; OPFS als spätere Ausbaustufe
 ├─ Web…Repository        Repositories aus diary_core auf dem EncryptedRecordStore, WebSearchRepository mit Index im Speicher
 ├─ MediaRecorderCapture  Aufnahme, Pegel, Wellenform; PCM-Abgriff über AnalyserNode (AudioWorklet folgt mit der Erkennung, W5)
 ├─ WebAudioPlayer        Wiedergabe aus dem Speicher (Blob-URL), Geschwindigkeit 0,8 bis 2,0
 ├─ WebStorageInfo        navigator.storage.persist/estimate, installiert?, iOS?
 ├─ IcsReminder           Kalenderdatei für die tägliche Erinnerung, Download über Blob-URL
 ├─ WebAudioFiles         Audio für den Container lesen/schreiben (Ports AudioFileSource/AudioFileSink aus diary_core)
 ├─ downloadBytes/pickFile Containerdatei herunterladen (Blob-URL) und wählen (<input type=file>), nur im Speicher
 └─ QrCameraScanner       QR-Code per BarcodeDetector aus dem Kamerabild (Platform-View), Rückfall Texteingabe
```

Schlüsselhierarchie wie D5: Der WebCrypto-Master-Key wrappt pro Aufnahme einen zufälligen Dateischlüssel (Zweck `chunkfile-v1`) und einmalig den Datensatz-Schlüssel (Zweck `records-v1`); die Audiodatei wird mit `diary_chunkfile` (AES-256-GCM, `AeadId.aes256Gcm`, damit WebCrypto und die Dart-Referenz dasselbe Format lesen) geschrieben. Weil der Master-Key die Anwendung nie als Bytes erreicht, bietet `diary_chunkfile` die Varianten `ChunkFileWriter.withWrappedFileKey` und `ChunkFileReader.openWith`; das Byte-Layout bleibt identisch, und der gewrappte Dateischlüssel steht sowohl im Dateikopf als auch in `Recording.fileKeyWrapped` (Crypto-Shredding löscht den Datensatz-Blob). Datensätze (JSON) werden einzeln mit `nonce || AES-256-GCM(JSON)` verschlüsselt; Zusatzdaten sind `<Sammlung>/<ID>`, damit Datensätze nicht vertauscht werden können.

Abweichung vom ursprünglichen Bild (Stand W2/W3): Audiodateien liegen als Ganzes im IndexedDB-Store `files`, nicht im Origin Private File System. Für Tagebuchaufnahmen (3 Minuten bei 32 kbit/s sind rund 0,7 MB) reicht das; die Datei wird zum Abspielen vollständig in den Speicher entschlüsselt. OPFS mit chunkweisem Lesen bleibt die Ausbaustufe für sehr lange Aufnahmen (Plus, 30 Minuten). Der PCM-Abgriff läuft über einen `AnalyserNode` (Momentaufnahmen alle 100 ms): genug für Pegel, Wellenform und die Fake-Erkennung, nicht lückenlos. Die echte Erkennung (W5) braucht ihn nicht: `MediaRecorderCapture` liefert die komprimierte Aufnahme nach dem Stopp ohnehin als Ganzes im Arbeitsspeicher (`RecordedAudio.plaintextBytes`, nie auf dem Dateisystem); `RecordDayUseCase` gibt sie an den `AudioFileTranscriberPort` (`WasmSttEngine.transcribeAudio`), der sie im Hauptthread mit `OfflineAudioContext(sampleRate: 16000).decodeAudioData` zu 16-kHz-Mono-PCM dekodiert und an den Worker überträgt. Ein `AudioWorklet` bleibt nur für eine spätere Live-Vorschau nötig.

### Spracherkennung im Browser (W5, experimentell)

- **Bausteine:** transformers.js 4.3.1 (`transformers.min.js`, ESM) und ONNX Runtime Web 1.31.1 (WASM-Dateien `ort-wasm-simd-threaded.asyncify.*`, dazu `ort-wasm-simd-threaded.*` für Safari vor 26 ohne WebGPU) liegen in `app/web/stt/vendor/` (43 MB, im Git). Modell `onnx-community/whisper-base` (mehrsprachig) wird vom Pages-Workflow beim Veröffentlichen von Hugging Face geladen und unter `models/onnx-community/whisper-base/` ausgeliefert; die App selbst spricht nie mit huggingface.co oder einem CDN. dtype je Gerät: WebGPU Encoder fp32 + Decoder q8 (rund 140 MB), WASM beide q8 (rund 60 MB); Herleitung der Dateinamen in `app/web/stt/MODELS.md`.
- **Ablauf:** Aufnahme stoppen → Aufnahme sofort gespeichert → Erkennung im Hintergrund (`stop(awaitTranscript: false)`, `TranscriptionJobs` in der App) → Eintrag zeigt "Transkription läuft …" → Transkript mit `engine = web_whisper_base`. Schlägt die Erkennung fehl oder fehlt der Text, bietet der Eintrag "Erneut transkribieren" (liest das Audio entschlüsselt in den Speicher). Einstellungen: Abschnitt "Spracherkennung (experimentell)" mit Schalter "Transkription aktiv" (Standard an), Status (bereit, lädt mit Fortschritt, nicht verfügbar mit Grund) und Hinweis zu Dauer und Modellgröße. Ist die Engine nicht verfügbar, greift die Fake-Erkennung als Rückfall (Platzhaltertext).
- **Kein Netz, zweifach:** Ein Worker erbt die `<meta>`-CSP des Dokuments nicht zwingend (die CSP eines Workers kommt aus den Antwort-Headern seines Skripts, die statisches Hosting nicht setzt). Deshalb setzt `stt_worker.js` `env.allowRemoteModels = false`, zeigt `localModelPath` und `wasmPaths` auf eigene Pfade relativ zum Worker und umhüllt `env.fetch` mit einem Wächter, der jede Anfrage an einen fremden Origin verwirft. Der Netz-Wächter (`tool/check_no_network.sh`, Punkt 6) prüft diese Zeilen; `app/web/stt/vendor/` ist von der URL-Prüfung ausgenommen, weil das unveränderte Bundle Voreinstellungen mit huggingface.co und einem CDN enthält, die durch die obigen Zeilen nie wirksam werden.
- **Grenzen:** Erkennung erst nach der Aufnahme, keine Wort-Zeitstempel (Segmente aus `return_timestamps`), ohne WebGPU auf einem Mittelklasse-Telefon voraussichtlich ein Vielfaches der Aufnahmedauer; Cross-Origin-Isolation fehlt auf GitHub Pages, deshalb läuft ONNX Runtime einsträngig. Der echte Modelllauf konnte in der Entwicklungsumgebung nicht geprüft werden (huggingface.co und CDNs gesperrt); geprüft sind Worker-Protokoll, Dekodierung, Sprach-Mapping, Segmente und die App-Verdrahtung (Tests mit Stub-Worker im Chromium).

Suche: Beim ersten Suchen werden alle Transkripte entschlüsselt in den Speicher geladen (ein Jahr Text liegt bei rund 1 MB) und gefaltet; Umlaute und ß werden wie in `diary_storage` normalisiert (Kopie der Regeln in `diary_web/src/text_normalization.dart`, gemeinsam zu pflegen). Jede Änderung macht den Index ungültig. Ab mehreren Jahren Daten wäre sqlite3 im Browser (drift mit WASM und OPFS) die Ausbaustufe; der Index läge dann unverschlüsselt im OPFS, deshalb erst nach Bewertung.

Backup und Gerätewechsel (W4): `TransferUseCase` in `diary_core` packt Einträge, Aufnahmen, Transkripte, Notizen (D17), Ziele und Etappen (D19), Bücher und Passagen (D21) und Einstellungen als `db.ndjson` plus Audio-Rohbytes in den Container aus `diary_container` (Cipher-Kennung 2, XChaCha20-Poly1305 je 64-KiB-Nachricht, Argon2id oder X25519/HKDF); die App bietet dafür Einstellungen → Daten und die Karte "Zeit für ein Backup" auf "Heute". Der QR-Code wird mit `package:qr` (reines Dart) gezeichnet; die Datei wandert über den Download-Ordner bzw. das Teilen-Blatt des Browsers. Format und Abweichungen vom Konzept: `06-geraetewechsel-qr-transfer.md` Abschnitt 13.

Tests: `packages/diary_web/test` läuft mit `flutter test --platform chrome` im Chromium (Master-Key, Datensätze überleben Schließen und Öffnen, Dateien mit der Dart-Referenz lesbar, Repositories, Suche, ICS, Backup- und Transfer-Round-Trip zwischen zwei IndexedDB-Datenbanken). MediaRecorder und Player sind headless nur bis zur Konstruktion prüfbar (kein Mikrofon, keine echte Aufnahme); der Weg Mikrofon → Datei → Wiedergabe wird auf dem Telefon geprüft (Prüfkriterium W3).

## 5. Bekannte Lücken der Web-Fassung

1. **Tägliche Erinnerung (M2):** Ohne Push-Server keine Benachrichtigung bei geschlossener App. Angebotener Ersatz: Termin in Google Kalender, Outlook.com oder Microsoft 365 über einen vorbefüllten Link (D18; nur Titel und Uhrzeit im Link, Google mit täglicher Wiederholung, Outlook ohne), ICS-Kalendereintrag für Apple Kalender und andere, Systemwecker, Hinweis beim Öffnen. Vollständig erst mit den Store-Apps.
2. **Transkriptionsqualität und -dauer:** Eingebaut ist Whisper base (60 bis 140 MB Download je Gerät); es braucht auf einem Mittelklasse-Telefon ohne WebGPU voraussichtlich ein Vielfaches der Aufnahmedauer. Spike W1 misst Dauer je Aufnahmeminute, Wortfehlerrate und Download auf iPhone und Android-Mittelklasse (Vorlage `docs/stt-web-messprotokoll.md`) und entscheidet zwischen whisper-tiny, whisper-base, whisper-small (Alternativen in `app/web/stt/MODELS.md`) und ggf. Moonshine-Web, und ab welchem Gerät die Erkennung standardmäßig an ist. Bis dahin ist die Transkription als experimentell gekennzeichnet und abschaltbar; der Nutzer kann Einträge auch ohne Text führen.
3. **Speicherräumung:** iOS entfernt Daten nicht installierter Web-Apps nach sieben Tagen Inaktivität; installierte PWAs sind ausgenommen, solange sie installiert bleiben. Die App verlangt die Installation vor der ersten Aufnahme, ruft `navigator.storage.persist()` auf und erinnert an Backups.
4. **Schlüsselschutz:** Der Master-Key liegt als nicht exportierbarer WebCrypto-Schlüssel im Browser-Speicher ohne Hardware-Schutz. Die App-Sperre mit PIN (D23; Einstellungen, Schutz) ist eine Bildschirmsperre: Sie schützt gegen Mitlesen am entsperrten Telefon (Sperre beim Start und nach Hintergrundzeit, Sichtschutz-Schleier, Wartezeiten nach Fehlversuchen), nicht gegen Zugriff auf den Browser-Speicher; sie bindet den Schlüssel nicht. Biometrie und Schlüsselbindung kommen erst mit den Store-Apps (D5). Bei vergessenem PIN gibt es keine Hintertür: "App zurücksetzen" löscht alle lokalen Daten, danach hilft nur das Backup mit Passphrase; die Sperre wandert nicht ins Backup. Argon2id des PIN-Hashes läuft in reinem Dart und ist im Browser langsam, deshalb moderate Parameter (4 MiB, t = 3); Messung auf dem Telefon offen.
5. **Aufnahme nur im Vordergrund:** Bildschirm-aus oder App-Wechsel beendet die Aufnahme auf iOS. Die App speichert bis dahin Aufgenommenes (Chunk-Datei bleibt bis zum letzten vollständigen Chunk lesbar).

## 6. Reihenfolge

| Schritt | Inhalt | Prüfkriterium |
|---------|--------|---------------|
| W0 | Web-Plattform, PWA-Manifest (mit Schnellaktionen `shortcuts`: Aufnehmen, Sprachnotiz, Kurznotiz, Schreiben über `?start=aufnahme|sprachnotiz|kurznotiz|schreiben`, D22), Service Worker, CSP, Icons, Installationshinweis | erledigt (27. 10. 2026): `tool/build_web.sh` baut ohne CDN; eigener Service Worker (`tool/generate_sw.py`, Flutter 3.47 liefert nur noch einen Stub) lädt 27 Kern-Dateien (19 MB) vor; Offline-Neustart im Chromium mit Playwright geprüft; Lighthouse auf dem Telefon offen |
| W1 (Spike) | Whisper im Browser: Dauer und Wortfehlerrate auf iPhone und Android-Mittelklasse, Modellwahl | Messung mit dem W5-Einbau: (a) CI-Protokoll des Pages-Workflows: alle Modelldateien geladen, echte Größen (`ls -l`), Build enthält `stt/`; (b) auf iPhone (Safari) und Android-Mittelklasse (Chrome) je 1-, 3- und 5-Minuten-Aufnahme in Hochdeutsch: Dauer der Erkennung je Aufnahmeminute (Faktor zur Aufnahmedauer), Wortfehlerrate gegen ein mitgeschriebenes Referenztranskript (WER = (Ersetzungen + Auslassungen + Einfügungen) / Wörter der Referenz), Beschleunigung (WebGPU oder WASM, die Einstellungen zeigen sie), Modell-Downloadgröße und -dauer beim ersten Start, Verhalten im Flugmodus nach dem ersten Laden; Ergebnisse in `docs/stt-web-messprotokoll.md`, daraus Entscheidung Modell (tiny/base/small) und Mindestgerät |
| W2 | `diary_web`: WebCrypto-Schlüssel, verschlüsselte Datensätze, Audio als Chunk-Datei in IndexedDB, Tests im Chromium | Daten überleben Neuladen; Chunk-Dateien mit Dart-Referenz lesbar (umgesetzt, Tests grün) |
| W3 | Aufnahme und Wiedergabe im Browser, Wellenform, Einträge mit echtem Audio; App auf die Ports umgestellt | 3-Minuten-Aufnahme auf iPhone und Android, Wiedergabe mit Sprung (Code umgesetzt; Telefon-Test offen) |
| W4 | Backup-Datei und Import, QR-Gerätewechsel über Datei | Round-Trip zwischen zwei Browsern (umgesetzt: Container mit Cipher-Kennung 2, Tests im Chromium zwischen zwei Datenbanken grün; Format und Abweichungen in `06-geraetewechsel-qr-transfer.md` Abschnitt 13) |
| W5 | Transkription eingebaut (Worker, Vendor, Modell-Download in der CI, Einstellungen, "Erneut transkribieren"), Suche | Code und Tests umgesetzt (Stub-Worker im Chromium, Use-Case- und App-Tests). Offen auf dem Telefon: Flugmodus-Test (Aufnahme, Erkennung, Suche nach dem ersten Laden offline), Erkennung eines echten Satzes mit Zeitstempeln, "Erneut transkribieren" nach Fehler, Download-Anzeige mit Fortschritt; Messwerte nach W1 |
| W6 | Veröffentlichung auf GitHub Pages, Anleitung "Installieren" | Inhaber nutzt die App täglich |

Danach die Store-Spikes S1 bis S7 aus `09-roadmap.md`.

## 7. Offene Fragen

- Modellwahl und Mindestgerät für die Browser-Erkennung (W1); eingebaut ist whisper-base.
- Ob die WASM-Dateien von onnxruntime-web 1.31.1 mit dem in transformers.js 4.3.1 eingebetteten onnxruntime-web 1.31.0-dev.20260914 im echten Lauf zusammenpassen (statisch geprüft: alle genutzten `_Ort*`-Exporte vorhanden; Lauf in CI/Telefon offen, siehe `app/web/stt/vendor/LICENSES.md`).
- Ob Safari auf iOS den Worker mit `type: 'module'` und `OfflineAudioContext` bei 16 kHz wie erwartet bedient (Rückfall-Resampling in Dart ist vorhanden).
- Ob Safari auf iOS den `BarcodeDetector` bereitstellt oder der QR-Code eingetippt werden muss.
- Verhalten des Origin Private File System auf iOS bei großen Audiodateien (Speicherkontingent, Räumung).
- Ob die Store-Apps später den Browser-Speicher der PWA übernehmen können (nein, geplant ist der Weg über die Backup-Datei).

## 8. Service Worker und Aktualisierung

Flutter 3.47 erzeugt keinen Offline-Service-Worker mehr, sondern nur einen Stub, der sich selbst deregistriert. Die PWA bringt deshalb einen eigenen mit (`tool/generate_sw.py`, aufgerufen von `tool/build_web.sh`, registriert durch `app/web/sw_register.js`):

- Kern-Dateien (App-Shell, CanvasKit, Schriften, Icons; rund 19 MB) werden bei der Installation vorgeladen; die Cache-Version ist eine Prüfsumme über diese Dateien, alte Versionen werden beim Aktivieren gelöscht.
- Alles Weitere vom eigenen Origin (Laufzeit und Modelle der Spracherkennung) wird beim ersten Abruf zwischengespeichert und danach aus dem Cache bedient; fremde Origins werden nie angefasst.
- Neue Versionen werden beim nächsten Start mit Netz im Hintergrund geladen und gelten ab dem übernächsten Start (`skipWaiting` + `clients.claim`); ein Hinweis "Neu laden" in der Oberfläche ist ein offener Punkt.
- Geprüft im Chromium (Playwright): nach dem ersten Laden sind 27 Dateien im Cache; mit getrennter Verbindung startet die App vollständig (`main.dart.js` und CanvasKit aus dem Cache, Oberfläche gerendert).

