# diary_web

Web-Umsetzungen der Ports aus `diary_core` für die PWA (Entscheidung D16, `docs/10-pwa.md`). Nur `dart:js_interop` und `package:web`, kein `dart:html`; läuft ausschließlich im Browser und wird von der App über einen bedingten Import eingebunden.

| Baustein | Aufgabe |
|---|---|
| `IndexedDbStore` | Promise-/Event-Brücke zu IndexedDB: Datenbank `tagebuch`, Stores `keys`, `records`, `files`, `meta`; Schreibzugriffe warten auf `complete` der Transaktion |
| `WebMasterKeyStore` (`DekWrapper`) | WebCrypto AES-256-GCM, `extractable: false`, als `CryptoKey` in IndexedDB (`master-v1`); `wrap` = `nonce(12) || AES-GCM(dek, aad = Zweck)`, wie `KeyWrap` mit `AeadId.aes256Gcm`; `destroy()` für "Alles löschen" |
| `EncryptedRecordStore` | JSON-Datensätze unter `<Sammlung>/<ID>`, verschlüsselt mit einem gewrappten Datensatz-Schlüssel (`records-v1`), AAD = Schlüssel (kein Vertauschen möglich); `changes`-Strom für `watch…` |
| `EncryptedFileStore` | Audio als Chunk-AEAD-Datei (`diary_chunkfile`, AES-256-GCM, 32-KiB-Chunks) im Store `files`; Dateischlüssel pro Datei, gewrappt mit Zweck `chunkfile-v1`, Blob im Kopf und in `Recording.fileKeyWrapped`; Lesen nur in den Speicher |
| `Web…Repository` | `JournalRepository`, `EntryRepository` (mit `watchMonth`), `RecordingRepository`, `TranscriptRepository`, `SettingsRepository` auf dem `EncryptedRecordStore`; `Codecs` serialisiert die Modelle |
| `WebSearchRepository` | Index im Speicher: Transkripte gefaltet (`ß → ss`, Kleinschreibung, Diakritika entfernt wie in `diary_storage`), Teilworttreffer, Sprungziel = Start des ersten passenden Segments |
| `MediaRecorderCapture` (`AudioRecorderPort`) | `getUserMedia` ohne Echo-/Rauschunterdrückung, `MediaRecorder` mit erstem unterstützten MIME aus `audio/webm;codecs=opus`, `audio/mp4;codecs=mp4a.40.2`, `audio/mp4` (`pickMimeType` als reine Funktion), `timeslice` 1 s; `AnalyserNode` alle 100 ms für Pegel und PCM (16 kHz über `LinearResampler`); `stop()` schreibt die Datei über den `EncryptedFileStore`, beendet die Mikrofon-Tracks und liefert `RecordedAudio` mit Wellenform |
| `WebAudioPlayer` (`DiaryPlayer`) | entschlüsselte Bytes → `Blob` → Objekt-URL → `HTMLAudioElement`; Play/Pause/Seek/Geschwindigkeit, `position`- und `playing`-Ströme; `dispose` gibt die URL frei |
| `WebStorageInfo` | `navigator.storage.persist()/persisted()/estimate()`, `isStandalone()`, `isIos()` |
| `IcsReminder`, `downloadText` | ICS-Datei (VEVENT, `RRULE:FREQ=DAILY`, VALARM) als Ersatz für die Benachrichtigung; Download über Blob-URL |

## Tests

```sh
export PATH=/opt/flutter/bin:$PATH
export CHROME_EXECUTABLE=/opt/pw-browsers/chromium-1243/chrome-linux64/chrome   # in dieser Umgebung
flutter test --platform chrome
```

Jeder Test löscht seine IndexedDB-Datenbank vorher (`IndexedDbStore.deleteDatabase`). Geprüft werden: Master-Key wrap/unwrap, falscher Zweck scheitert, Schlüssel nicht exportierbar (`exportKey` wirft), `destroy`; Datensätze put/get/getAll/delete, überleben Schließen und erneutes Öffnen, liegen verschlüsselt vor, vertauschter Schlüssel scheitert an der AAD; Dateien im Round-Trip und mit der Dart-Referenz `ChunkFileReader` lesbar, fremder Schlüssel scheitert; Repositories (ein Eintrag je Tag, Monat mit `watchMonth`, Löschen liefert Dateinamen, Audio löschen, Einstellungen), Suche ("Strasse" findet "Straße", Sprungziel), `pickMimeType`, ICS-Inhalt, Codecs, Textfaltung.

**Grenze:** `MediaRecorderCapture` und `WebAudioPlayer` sind headless nur bis zur Konstruktion und Formatwahl prüfbar (kein Mikrofon, kein Blob einer echten Aufnahme). Der Weg Mikrofon → Datei → Wiedergabe mit Sprung wird auf einem Telefon geprüft (Prüfkriterium W3 in `docs/10-pwa.md`).

## Grenzen der Web-Fassung

- Der Master-Key ist nicht exportierbar, aber ohne Hardware-Schutz (kein Keychain/Keystore); wer das entsperrte Gerät hat, kann die PWA öffnen (D16, Punkt 2 und 4).
- Browser dürfen Origin-Speicher räumen; die App ruft `persist()` auf und zeigt den Status. Backup ist Pflicht (D16, Punkt 3).
- Audiodateien liegen als Ganzes in IndexedDB und werden zum Abspielen vollständig entschlüsselt; OPFS mit chunkweisem Lesen ist die Ausbaustufe für lange Aufnahmen.
- Der PCM-Abgriff über `AnalyserNode` liefert Momentaufnahmen, keinen lückenlosen Strom; für die echte Erkennung (W5) kommt ein `AudioWorklet`.
- WebM aus `MediaRecorder` trägt oft keine Dauer; der Player greift dann auf `Recording.duration` zurück.
