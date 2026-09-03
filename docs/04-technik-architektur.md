# 04 · Technik und Architektur

Stand: 3. September 2026 · Status: Entwurf

Dieses Dokument beschreibt, wie die App technisch gebaut wird: Stack, lokale Spracherkennung auf beiden Plattformen, Audio-Pipeline, Datenmodell, verschlüsselte Speicherung, Suche, optionale lokale Zusammenfassungen, Erinnerungen, Repository-Struktur, CI und Teststrategie. Es setzt die Anforderungen aus `00-anforderungen.md` (M1 bis M12, A1 bis A8) um. Das Containerformat für Backup und Gerätewechsel ist hier nur so weit beschrieben, wie die Speicherschicht davon abhängt; Details stehen in `06-geraetewechsel-qr-transfer.md`. Preise werden hier nicht genannt (siehe `07-geschaeftsmodell.md`).

Hinweis zur Quellenlage: Die Faktenprüfung (`docs/recherche/verifikation.json`, 30 Aussagen: 18 bestätigt, 12 präzisiert) ist eingearbeitet; wo sie eine Aussage präzisiert hat, steht hier die präzisierte Fassung mit Verweis auf den Eintrag. Ebenfalls eingearbeitet sind die Nachrecherchen zum Audio-Container (`docs/recherche/nachrecherche-audio-container.md`) und zu Nutzerstimmen (`docs/recherche/nachrecherche-nutzerstimmen-stores.md`), die am 3. September 2026 zur Umstellung von D4 auf AAC-LC und Chunk-AEAD geführt haben [85][107]. Zahlen, die nur aus Sekundärquellen stammen und nicht in der Faktenprüfung enthalten sind, bleiben mit "(unverifiziert)" oder "(Annahme)" gekennzeichnet (D15).

## 1. Stack-Entscheidung

**Empfehlung: Flutter (stable 3.47.x) als eine Codebasis, ergänzt um drei kleine native Brücken**, weil Flutter das einzige Cross-Platform-Ökosystem ist, in dem alle für dieses Produkt kritischen Bausteine als gepflegte Pakete existieren: AEAD (XChaCha20-Poly1305 je Chunk für die Audiodateien, `secretstream` für den Transfer-Container) und Argon2id (`sodium` 4.1.0+1 mit libsodium 1.0.22 [17]), PCM-Streaming-Aufnahme (`record` 7.1.1 [14]), SQLCipher (`sqlite3` 3.5.2 mit `source: sqlcipher`, SQLCipher 4.18.0, plus `drift` 2.34.4 [15][16]) und Secure Storage (`flutter_secure_storage` 11.0.0 [18]). Flutter 3.47.2 ist seit dem 27. August 2026 stable [13].

Die drei nativen Brücken sind bewusst klein gehalten:

| Brücke | Sprache | Aufgabe |
|---|---|---|
| (a) STT iOS | Swift | Plugin für `SpeechAnalyzer`/`SpeechTranscriber`/`DictationTranscriber` (iOS 26); dafür gibt es kein etabliertes Flutter-Plugin [12] |
| (b) STT Android | Kotlin | Anbindung von sherpa-onnx (Dart-Paket `sherpa_onnx` 1.13.7 existiert [10]; die Brücke kapselt Modellverwaltung über Play Asset Delivery und den Foreground Service) |
| (c) Schlüsselverwahrung | Swift/Kotlin | Feinheiten, die `flutter_secure_storage` nicht abdeckt: `SecAccessControl` (`.biometryCurrentSet`), StrongBox mit TEE-Fallback, `BiometricPrompt.CryptoObject` |

**Alternativen (kurz, nicht empfohlen):**

| Alternative | Warum nicht als erste Wahl |
|---|---|
| Zweimal nativ (SwiftUI + Jetpack Compose) | Beste Plattformintegration (SpeechAnalyzer, CryptoKit, Keystore direkt), aber zwei UI-Codebasen und doppelte Wartung für einen Indie-Entwickler. CryptoKit bietet zudem kein XChaCha20 [21]. **Rückfalloption:** Zeigt ein Spike, dass die nativen Brücken zu groß werden, ist zweimal nativ die zweite Wahl. |
| Kotlin Multiplatform + Compose Multiplatform 1.12 | Technisch sauber, aber genau dort ohne Bibliotheken, wo der Aufwand liegt: Audio, STT, Keychain/Keystore, SQLCipher auf iOS; `kotlin-multiplatform-libsodium` warnt selbst vor Produktionseinsatz, `cryptography-kotlin` hat kein Argon2 [19][20] |
| React Native / Expo | `react-native-libsodium` ohne `crypto_secretstream`, `crypto_pwhash` nur für Web; Streaming-AEAD und PCM-Streaming müssten in nativen Modulen selbst gebaut werden [22] |

## 2. On-Device-Spracherkennung

Grundsatz aus A1: Transkription läuft ausschließlich auf dem Gerät und muss im Flugmodus funktionieren. Die einzigen Netzkontakte sind Modell-Downloads durch das Betriebssystem bzw. den Play Store (D14); die Modelle werden bei Bedarf geladen und vom System beziehungsweise vom Store aktualisiert, nicht nur einmalig (siehe 2.1).

### 2.1 iOS

**Empfehlung: `SpeechTranscriber` (iOS 26+) als Primärpfad**, weil das Modell im Systemspeicher liegt, außerhalb des App-Prozesses läuft, keine App-Größe und keinen App-RAM kostet, von Apple aktualisiert wird und kein Längenlimit dokumentiert ist [1][3]. Das alte `SFSpeechRecognizer` scheidet aus: kein `SpeechAnalyzer`-Streaming, und Apple warnt selbst, dass On-Device-Anfragen (`requiresOnDeviceRecognition`) weniger genau sind als die Servererkennung [4]. Das oft zitierte Ein-Minuten-Limit und die Tageskontingente gelten laut Apple nur für die serverbasierte Erkennung, nicht für den On-Device-Modus (WWDC 2019, Session 256) [83]; sie sind daher kein Argument gegen `SFSpeechRecognizer`, wohl aber ein Grund, den Servermodus nie zu verwenden.

Ablauf im Plugin:

1. Locale über `SpeechTranscriber.supportedLocale(equivalentTo:)` aus der Nutzerwahl (de-DE, de-AT, de-CH, en-*) auflösen; nie `Locale.current` direkt verwenden (Unterstrich-Falle `en_US`) [8].
2. Prüfen, ob das Asset installiert ist (`AssetInventory`), sonst `assetInstallationRequest` auslösen; der Download kommt von Apple-Servern, wird im Onboarding erklärt und braucht WLAN [2]. Das System verwaltet die Assets selbst: Es aktualisiert sie automatisch, teilt sie mit anderen Apps und kann ungenutzte Assets wieder entfernen; pro App gibt es nur eine begrenzte Zahl locale-spezifischer Asset-Reservierungen [2]. Die App muss den Installationsstand deshalb vor jeder Transkription prüfen, nicht nur im Onboarding.
3. `SpeechAnalyzer` mit `SpeechTranscriber` (Preset `.transcription`, optional `.progressiveTranscription` für eine Live-Vorschau) und `SpeechDetector` (VAD, `SensitivityLevel.medium`) aufsetzen [3][5].
4. PCM-Puffer als `AsyncSequence<AnalyzerInput>` einspeisen; `attributeOptions: [.audioTimeRange, .transcriptionConfidence]` setzen, damit jeder Run des `AttributedString` einen `CMTimeRange` trägt (die einzigen beiden Fälle von `ResultAttributeOption`) [102]. Daraus entstehen Wort-Zeitstempel für den mitlaufenden Text bei der Wiedergabe; Apple zeigt genau dieses Muster ("highlighting each word as it's played back") in der WWDC25-Session 277 [101]. Segmente und Wörter werden getrennt gespeichert (Abschnitt 4).
5. Pro Locale einmalig einen kurzen Validierungslauf durchführen, weil `supportedLocales` nachweislich schon falsche Einträge enthielt (Arabisch, Januar 2026) [7].

Sprachabdeckung: Apple veröffentlicht keine statische Liste. Eine empirische Abfrage (VoiceInk, macOS 26.4) zeigt unter anderem de-DE, de-AT, de-CH sowie en-AU/CA/IN/IE/NZ/SG/ZA/GB/US [6]. `de-CH` ist nach unserer Annahme Standarddeutsch mit Schweizer Orthografie und kein Mundart-Modell (D12); Apple macht dazu keine Aussage, die Annahme ist plausibel, aber unbelegt und wird im Spike S1 mit Mundart- und Standardaudio geprüft. Weil `supportedLocales` über die iOS-26.x-Versionen nicht stabil war, gilt der Test nur für die getestete OS-Version [7].

**Fallback 1: `DictationTranscriber` (Preset `.longDictation`)** auf iOS-26-Geräten, auf denen `SpeechTranscriber.isAvailable` false ist. Nach Forenberichten betrifft das iPhone 11, 11 Pro, 11 Pro Max, iPhone SE (2. Gen.) sowie iPads mit A12/A13 und den Simulator; iPhone 12, SE (3. Gen.), 14 Pro und 15 Pro funktionieren. Apple dokumentiert keine Geräteliste; die Erklärung "16-Kern-Neural-Engine ab A14 nötig" ist eine Community-Hypothese ohne Apple-Bestätigung (Faktenprüfung Eintrag 3) [9]. `DictationTranscriber` nutzt die Systemdiktat-Modelle, hat kein Ein-Minuten-Limit mehr und verlangt keine manuelle Sprachaktivierung [11].

**Optionales Zusatzpaket "Hohe Genauigkeit": WhisperKit** (MIT, Release v1.1.0 vom 6. August 2026) mit dem Modell `large-v3-v20240930_626MB` (626 MB Download, von Argmax als Standard für maximale mehrsprachige Genauigkeit empfohlen) [23][24]. Gerätegrenze: Laut `fallbackModelSupportConfig` in `Models.swift` ist dieses Modell erst ab A15 (iPhone 13) freigegeben; A14 (iPhone 12) erhält höchstens `small`, A12/A13 (iPhone 11, SE 2) nur `tiny`/`base` [25]. Die ältere Maintainer-Aussage "A14 and newer can run all models" [84] widerspricht dem Code; maßgeblich ist die Remote-Config (`config.json` im Hugging-Face-Repository), der Fallback greift nur ohne diese. Das Zusatzpaket wird deshalb auf iOS ab iPhone 13 (A15) angeboten; ob die Remote-Config A14 doch freigibt, prüft der Spike S1. Sprache fest setzen, VAD-Chunking nutzen, weil bei Auto-Detect für Deutsch Sprachwechsel und Halluzinationen berichtet werden [26]. Nur im Vordergrund oder mit `audio`-Background-Mode ausführen, weil die Neural Engine im Hintergrund nicht garantiert ist [27]. Kein Whisper-Zwang im MVP.

Mindestanforderung: iOS 26, empfohlen iPhone 12 oder neuer (D13); das Zusatzpaket "Hohe Genauigkeit" auf iOS ab iPhone 13 (A15), siehe oben.

### 2.2 Android

Auf Android gibt es keine systemweite Garantie, dass `SpeechRecognizer` lokal bleibt: Die Klassenbeschreibung warnt, die Implementierung "is likely to stream audio to remote servers"; `createOnDeviceSpeechRecognizer()` (API 31+) bindet an einen vom Hersteller festgelegten Dienst, für Samsung, Xiaomi und andere ist nicht belegt, welcher Dienst das ist oder ob `isOnDeviceRecognitionAvailable()` überhaupt true liefert [28][29].

**Empfehlung: gebündelte Engine sherpa-onnx (Apache 2.0, v1.13.7 vom 1. September 2026) mit Moonshine German Small Streaming und English Small Streaming**, weil nur eine eigene Engine das Datenschutzversprechen technisch selbst kontrolliert: Die App wird ohne `android.permission.INTERNET` ausgeliefert, und das Betriebssystem setzt diesen Verzicht durch [30][31]. Moonshine-Streaming-Modelle sind MIT-lizenziert, je 123 M Parameter, Deutsch-WER 7,5 % (FLEURS + MLS), Englisch-WER 7,84 % [32][33].

| Stufe | Modell | Größe | RAM-Richtwert | Deutsch-WER | Lizenz |
|---|---|---|---|---|---|
| Standard | Moonshine German/English Small Streaming | 123 M Parameter je Sprache; Dateigröße quantisiert grob 150 bis 250 MB je Sprache (unverifiziert) | ab 4 GB Geräte-RAM | 7,5 % | MIT [32] |
| Low-End-Fallback | Moonshine German/English Tiny Streaming | 34 M Parameter | unter 4 GB Geräte-RAM | 12,0 % | MIT [32] |
| Zusatzpaket "Hohe Genauigkeit" | Parakeet TDT 0.6B v3 int8 | ≈ 640 MB (Encoder 622 MB, Decoder 12 MB, Joiner 6,1 MB) | ≈ 1,23 GB Prozess-RAM beim Laden (Einzelmessung in sherpa-onnx-Issue #2626 auf iOS, ohne Antwort der Maintainer; Faktenprüfung Eintrag 27) [106], ab 6 GB Geräte-RAM | ≈ 4 % (4,26 % FLEURS, 4,13 % CoVoST) | CC-BY-4.0 laut NVIDIA, im Spike auf der Modellkarte verifizieren [34][35] |

Fallback-Kette:

1. Moonshine Small (Standard); bei RTF-Problemen oder unter 4 GB RAM Moonshine Tiny.
2. Vom Nutzer aktivierbar: `createOnDeviceSpeechRecognizer()` mit `RecognitionSupport`-Prüfung auf `installedOnDeviceLanguages` für de-DE/en-US, mit klarem Hinweis, dass eine Google- oder Hersteller-Komponente arbeitet [28].
3. ML Kit GenAI Speech Recognition (`1.0.0-alpha1`) wird nicht verwendet: Alpha-Status, dokumentierter Ausfall bei langen Streams (48 von 1 234 Wörtern erkannt), keine Zeitstempel [36].

Zeitstempel für den mitlaufenden Text (D3, D4): Moonshine liefert in sherpa-onnx keine Zeitstempel; der Codebefund der Nachrecherche zeigt, dass `Convert()` in der Moonshine-Implementierung keinen Timestamp-Code enthält [85][103]. Im MVP kommen die Segmentgrenzen auf Android deshalb aus der VAD-Segmentierung vor dem Modell (Sprechpausen als Segmentgrenzen, Text je Segment), nicht aus dem Modell. Wortgenaue Zeitstempel gibt es erst mit dem Zusatzpaket: Parakeet TDT liefert über die C-API Token-Zeitstempel (`timestamps`, `durations`, `segment_timestamps`; Zeit = `frame_shift_ms/1000 × subsampling_factor × frame`), die zu Wörtern zusammengeführt werden müssen (Token mit führendem `▁` beginnt ein Wort) [85][103]. Die Zeitstempel-Genauigkeit von Parakeet TDT auf deutscher Sprache ist im Spike S2 zu messen (offene Frage 15).

Modellauslieferung: Play Asset Delivery, `fast-follow` für das Standardpaket, `on-demand` für "Hohe Genauigkeit"; beide zählen nicht zur angezeigten App-Größe [37]. Ob Play Asset Delivery ohne `INTERNET`-Permission der App funktioniert, ist ein offener Spike-Punkt (Play Core läuft im Play-Store-Prozess, was es plausibel macht; unverifiziert). Für F-Droid (D10) werden die Modelle als separate Dateien mitgeliefert oder im Onboarding aus dem F-Droid-Repository geladen; das ist im Build-Konzept zu klären.

Mindestanforderungen: minSdk 31 (Android 12), nur arm64-v8a (auf armeabi-v7a wurden 2026 SIGBUS-Abstürze beim Initialisieren von ONNX Runtime gemeldet, Issues #3508 und #3534, ein 32-Bit-Build wird von den Maintainern nicht gepflegt; Faktenprüfung Eintrag 26 [31]), Richtwert 4 GB RAM, Zusatzpaket ab 6 GB RAM und 1 GB freiem Speicher. Target API 36 ist seit 31. August 2026 Pflicht; ab 1. Februar 2027 müssen native Bibliotheken 16-KB-Seiten unterstützen (NDK r28+, AGP 8.5.1+) [38][39]. Android 17 führt RAM-abhängige App-Speicherlimits ein, was für große Modelle relevant ist [40].

### 2.3 Gemeinsame Regeln für beide Plattformen

- Feste Sprachwahl pro Eintrag (Standard aus den Einstellungen), kein Auto-Detect.
- VAD und Stille-Filter vor jedem Modell, um Halluzinationen bei Stille zu vermeiden.
- Das Audio bleibt die Wahrheit: Transkripte werden als Version je Engine gespeichert und können mit einem besseren Modell neu erzeugt werden.
- Transkription läuft nach der Aufnahme (Batch) im Vordergrund oder in einem Foreground Service; eine Live-Vorschau ist optional und darf das Ergebnis nicht ersetzen.
- Zeitstempel sind Teil des Transkripts, nicht der Wiedergabe: Jede Engine schreibt, was sie liefert (Wörter auf iOS über `audioTimeRange`, Segmente aus der VAD auf Android mit Moonshine, Wörter mit Parakeet); die Wiedergabe markiert die feinste vorhandene Ebene und leitet die Position aus dem Player ab, nicht aus der Wanduhr, damit die Markierung auch bei 0,8- oder 2,0-facher Geschwindigkeit stimmt [85].
- Bekannte Deutsch-Schwächen des Apple-Diktats (Komposita in Einzelwörter zerlegt, Leerzeichen vor und nach Bindestrichen, Interpunktionswörter doppelt; Forenbericht Mai 2026) gehören als Testfälle in den STT-Regressionskorpus (Abschnitt 11), weil `DictationTranscriber` dieselben Diktatmodelle nutzt [107][113]. Eine automatische "Korrektur" ohne Kennzeichnung gibt es nicht; der Nutzer sieht, was die Engine erkannt hat, und kann bearbeiten.
- Keine Schweizerdeutsch-Feinabstimmungen: Die verfügbaren Whisper-Fine-Tunes für Mundart (apexAI-Switzerland large-v3, Flurin17 large-v3-turbo) stehen nur unter CC-BY-NC-4.0 und sind für ein kommerzielles Produkt nicht nutzbar; es bleibt bei Standarddeutsch mit dem Hinweis aus D12 [107][108].

## 3. Audio-Pipeline

**Empfehlung (D4): Aufnahme als PCM im Arbeitsspeicher; daraus parallel ein 16-kHz-Mono-Strom für die Transkription und ein AAC-LC-Strom in M4A (mono, 24 kHz, 32 kbit/s); Audiodateien chunkweise mit AEAD verschlüsselt, damit die Wiedergabe seekbar ist; PCM geht nie auf die Platte.**

Warum nicht Opus in Ogg (die Empfehlung des ersten Entwurfs): Die Nachrecherche zum Audio-Container hat den Konflikt belegt [85]. `kAudioFormatOpus` existiert zwar seit iOS 11 [44], aber AudioToolbox kennt keinen Ogg-Dateityp, `AVAudioFile` schreibt Opus deshalb ausschließlich in CAF [86]; `AVAudioPlayer` öffnet Ogg nicht ("This media format is not supported", Fehler -11828) [87]; die Opus-Bitrate ist über `AVAudioRecorder` nicht steuerbar (rdar://49315600, Apple DTS: "there is no way to control bitrate for Opus"; nur als Suchauszug lesbar) [88]. Android wiederum nimmt Ogg/Opus ab API 29 nativ auf und spielt es ab, kann aber CAF nicht öffnen (Media3 listet CAF nicht) [45][89]. Ein plattformidentisches Opus-Format hätte auf iOS libopus als eigenes xcframework für Encoder und Decoder verlangt. AAC-LC in M4A nehmen beide Plattformen nativ auf und spielen es ab, die Bitrate ist beidseitig steuerbar, es braucht weder Remux noch FFI; Signal nutzt für Sprachnachrichten dasselbe Format (AAC-LC, 32 kbit/s, mono) [92]. Opus in Ogg (20 bis 24 kbit/s, iOS mit libopus-xcframework, Android mit `MediaRecorder` OGG/OPUS) bleibt die spätere Speicher-Optimierung; das Datenmodell trägt den Codec je Aufnahme (Abschnitt 4).

### 3.1 Aufnahme

1. PCM-Abgriff im Speicher: `record` liefert einen PCM-16-Bit-Stream [14]; falls dessen Format- oder Latenzverhalten im Spike S6 nicht reicht, greift die native Brücke direkt auf `AVAudioEngine` (Input-Tap) bzw. `AudioRecord` zu (D4). Aufnahmerate 24 kHz mono; der 16-kHz-Strom für die STT-Engine entsteht durch Resampling (`AVAudioConverter` bzw. eigener Resampler in der Brücke). iOS: `AVAudioSession` Kategorie `.playAndRecord` (`.record` würde jede andere Ausgabe stummschalten), Option `allowBluetoothHFP` für Headset-Mikrofone (das neue `bluetoothHighQualityRecording` aus iOS 26 ist laut Apple "not currently supported in the European Union") [109][110], `UIBackgroundModes = audio`, damit die Aufnahme bei gesperrtem Bildschirm weiterläuft [41]. Android: Foreground Service mit `foregroundServiceType="microphone"` (Manifest-Berechtigung `FOREGROUND_SERVICE_MICROPHONE` plus erteilte Laufzeitberechtigung `RECORD_AUDIO`), `setPrivacySensitive(true)`; ein Start aus dem Hintergrund wirft seit Android 12 `ForegroundServiceStartNotAllowedException` und ab Android 14 für While-in-use-Typen zusätzlich `SecurityException`, ausgenommen sind unter anderem Starts über Benachrichtigung oder App-Widget; aus `BOOT_COMPLETED` darf ein Mikrofon-Dienst ab Zielversion 14 nicht gestartet werden (Faktenprüfung Eintrag 30) [42][43].
2. Der PCM-Strom speist drei Senken: (a) Ringpuffer 16 kHz für die Transkriptions-Engine; (b) AAC-LC-Encoder (iOS `AVAudioConverter` mit `kAudioFormatMPEG4AAC`, Android `MediaCodec` `audio/mp4a-latm`), mono, 24 kHz, 32 kbit/s, Hörtest 24 bis 48 kbit/s im Spike S6; (c) Pegelmesser für die Wellenform: dBov je Puffer, am Ende auf 100 Werte resampled, wie Element X es vormacht [104]. Die 100 Werte werden verschlüsselt mit den Metadaten gespeichert (Abschnitt 4), weil eine nachträgliche Berechnung eine Volldekodierung der verschlüsselten Datei bräuchte [85].
3. Die AAC-Frames werden über die Chunk-AEAD-Dateischicht (Abschnitt 5.1) geschrieben: Dateikopf mit Kopf-Nonce und dem mit dem Master-Key gewrappten Dateischlüssel, Inhalt in 32-KiB-Chunks mit je eigener Nonce und Auth-Tag, Zusatzdaten (AAD) = Chunk-Nummer (64 Bit, Big-Endian) + Kopf-Nonce gegen Umsortieren; das ist das Cryptomator-Muster [90]. Die Schicht bietet eine wahlfrei les- und schreibbare "virtuelle Datei"; damit liegt zu keinem Zeitpunkt Klartext-Audio auf dem Dateisystem, auch nicht temporär (D4).
4. Containerschreiben ohne Klartextdatei: iOS schreibt das M4A über `AudioFileInitializeWithCallbacks`/`AudioFileOpenWithCallbacks` (eigene Lese-, Schreib- und Größen-Callbacks auf die virtuelle Datei) [112]. Auf Android verlangt `MediaMuxer` einen Dateideskriptor; der Weg (speichergestützter Deskriptor über `SharedMemory`, dessen Inhalt beim Abschluss chunkweise verschlüsselt wird, oder Media3-`Mp4Muxer` auf einen eigenen Kanal) ist ein Spike-Punkt (offene Frage 14). Rückfall, falls das M4A-Schreiben ohne Klartext zu aufwendig wird: AAC im ADTS-Rohstrom (framebasiert, kein Index am Dateiende; AudioToolbox kennt `kAudioFileAAC_ADTSType`, Media3 liest ADTS über `AdtsExtractor`, Signal speichert Sprachnachrichten genau so) [86][89][92]. Die Entscheidung ändert nur die Containerhülle, nicht Codec, Verschlüsselung oder Rechenbasis.
5. Unterbrechungen (Anruf, App-Kill): Weil M4A seinen Index (`moov`) erst beim Abschluss erhält, sichert der Encoder die AAC-Frames während der Aufnahme fortlaufend in die verschlüsselte Datei (ADTS-Rahmen oder fragmentiertes MP4) und finalisiert den Container beim Stopp; bricht die App ab, wird die Datei beim nächsten Start bis zum letzten vollständig authentifizierten Chunk gelesen, der Container nachgebaut und der Eintrag als "unvollständig" markiert (`state = truncated`). Welche der beiden Zwischenformen es wird, entscheidet der Spike S6 (offene Frage 14); das Erfolgskriterium ist unverändert: keine verlorene Aufnahme in allen Abbruchfällen.

### 3.2 Wiedergabe

Grundregel: kein Klartext auf der Platte, seekbar ohne Vollentschlüsselung, Hintergrund- und Sperrbildschirm-fähig, Geschwindigkeit 0,8 bis 2,0 (D4).

- **Android:** Media3 1.11 `ExoPlayer` mit einer eigenen `DataSource`, die bei `open(DataSpec)` den Chunk-Index `position ÷ 32768` berechnet, den Chunk entschlüsselt und authentifiziert und den Rest ab `position mod 32768` liefert; Media3 zeigt dasselbe Prinzip für unauthentifiziertes AES-CTR in `AesCipherDataSource`, Signal in `ModernDecryptingPartInputStream` [91][93]. Der Player läuft in einem `MediaSessionService` mit `foregroundServiceType="mediaPlayback"` und den Berechtigungen `FOREGROUND_SERVICE` und `FOREGROUND_SERVICE_MEDIA_PLAYBACK`; die Benachrichtigung mit Steuerung entsteht automatisch [95]. Das ist Pflicht wegen der Android-17-Regeln für Hintergrundaudio: Ohne sichtbare Activity oder Foreground Service wird Wiedergabe stumm unterdrückt und Audiofokus verweigert; Google nennt `MediaSessionService` ausdrücklich als "not likely to be impacted"; Test mit `adb shell cmd audio set-enable-hardening throw` [94]. Geschwindigkeit über `Player.setPlaybackParameters(PlaybackParameters(speed, 1.0f))` (Pitch 1,0 = Time-Stretch) [96].
- **iOS:** `AVAudioPlayer` hat keine Datenquellen-Abstraktion und entfällt. Stattdessen `AVAudioEngine` mit `AVAudioPlayerNode`: Die Chunks werden entschlüsselt, über `AudioFileOpenWithCallbacks`/`AVAudioConverter` zu `AVAudioPCMBuffer` dekodiert und mit `scheduleBuffer(_:completionHandler:)` eingeplant [97][112]. Seek = Chunk-Index berechnen, Decoder neu aufsetzen, ab der nächsten Paketgrenze dekodieren (bei AAC ein bis zwei Pakete Priming) [85]. Geschwindigkeit über `AVAudioUnitTimePitch.rate` im Engine-Graphen (technisch 1/32 bis 32, in der Oberfläche 0,8 bis 2,0) [98]. Sperrbildschirm und Kopfhörertasten über `MPNowPlayingInfoCenter` (`PlaybackDuration`, `ElapsedPlaybackTime`, `PlaybackRate`) und `MPRemoteCommandCenter` (`play`, `pause`, `togglePlayPause`, `skipForward/Backward`, `changePlaybackPosition`, `changePlaybackRate`); das funktioniert mit `AVAudioEngine`, solange die Audio-Session aktiv ist [99][100].
- **Mitlaufender Text:** Ein Timer liest die Player-Position und markiert das Wort (iOS, Parakeet) oder Segment (Android mit Moonshine), dessen Zeitspanne die Position enthält; Sprünge aus der Suche setzen die Position auf `start_ms` des Treffers (Abschnitt 6). Wellenform aus den 100 gespeicherten Werten, ohne die Datei zu lesen.
- Warum nicht `secretstream` für Audiodateien: `crypto_secretstream_xchacha20poly1305` ist strikt sequenziell, ein Seek müsste von vorn bis zur Zielposition entschlüsseln [46][85]. Es bleibt dem Transfer-Container vorbehalten, der ohnehin sequenziell gelesen wird (D6, `06-geraetewechsel-qr-transfer.md`).

### 3.3 Speicherbedarf

**Eigene Rechnung (Rechenbasis D4/D6).** Annahmen: mono, konstante Bitrate, 365 Tage.

| Größe | Rechnung | Ergebnis |
|---|---|---|
| PCM 24 kHz/16 Bit (Aufnahme) | 48 000 Byte/s × 60 | 2,88 MB/min (nur flüchtig im RAM) |
| PCM 16 kHz/16 Bit (STT-Strom) | 32 000 Byte/s × 60 | 1,92 MB/min (nur flüchtig im RAM) |
| AAC-LC 24 kbit/s | 24 000 bit/s ÷ 8 × 60 | 0,18 MB/min |
| **AAC-LC 32 kbit/s (Standard)** | 32 000 bit/s ÷ 8 × 60 | **0,24 MB/min** |
| AAC-LC 48 kbit/s | 48 000 bit/s ÷ 8 × 60 | 0,36 MB/min |
| **3 min/Tag, 32 kbit/s** | 0,24 × 3 × 365 | **0,72 MB/Tag, ≈ 263 MB/Jahr** |
| 3 min/Tag, 48 kbit/s | 0,36 × 3 × 365 | 1,08 MB/Tag, ≈ 394 MB/Jahr |
| 5 min/Tag, 32 kbit/s | 0,24 × 5 × 365 | 1,2 MB/Tag, ≈ 438 MB/Jahr |
| Späterer Opus-Pfad, 3 min/Tag, 16 bis 24 kbit/s | 0,12 bis 0,18 × 3 × 365 | 0,36 bis 0,54 MB/Tag, ≈ 131 bis 197 MB/Jahr |
| Verschlüsselungs-Overhead | 28 Byte (AES-GCM: 12 Byte Nonce + 16 Byte Tag) bis 40 Byte (XChaCha20: 24 Byte Nonce + 16 Byte Tag) je 32-KiB-Chunk + Dateikopf unter 100 Byte | ≈ 0,1 %, vernachlässigbar [90] |
| Wellenform | 100 Werte × 1 bis 4 Byte | unter 1 KB je Aufnahme |
| Transkript | ≈ 1 KB/min Rohtext (120 bis 150 Wörter/min, ≈ 7 Byte/Wort) | ≈ 1,1 MB/Jahr bei 3 min/Tag; mit Segment- und Wort-Zeitstempeln 3 bis 5 MB |

AAC-LC arbeitet hier mit konstanter Bitrate; einen VBR- oder DTX-Gewinn wie bei Opus (weitere 10 bis 20 % [47]) gibt es nicht, dafür ist die Größe exakt planbar. Der Mehrverbrauch gegenüber dem Opus-Pfad (rund 66 bis 132 MB/Jahr bei 3 min/Tag) ist für den Gerätespeicher unkritisch, für den Transfer-Container relevant (D6). Ein Nutzer, der Audio global oder pro Eintrag löscht (A5, D4), behält nur den Text und liegt damit im einstelligen MB-Bereich pro Jahr. Die Standardbitrate (24, 32 oder 48 kbit/s) wird im Spike S6 per Blind-Hörtest und Transkriptionsvergleich bestätigt; 32 kbit/s ist die Rechenbasis (offene Frage 6).

## 4. Datenmodell

Ein Eintrag entspricht einem Kalendertag in einem Tagebuch (A4); mehrere Aufnahmen pro Eintrag sind möglich; jede Aufnahme hat null bis n Transkripte (je Engine/Modellversion). Das Schema ist von Anfang an auf mehrere Tagebücher ausgelegt (D9), auch wenn das MVP nur eines zeigt.

| Tabelle | Wichtige Spalten | Anmerkungen |
|---|---|---|
| `journal` | `id`, `title`, `created_at`, `default_locale` | MVP: genau ein Datensatz |
| `entry` | `id`, `journal_id`, `day` (ISO-Datum, lokale Zeitzone), `created_at`, `updated_at`, `title` (optional), `mood` (optional, vom Nutzer gesetzt), `pinned` | Unique auf (`journal_id`, `day`); nachträgliche Einträge für vergangene Tage erlaubt (A3) |
| `recording` | `id`, `entry_id`, `started_at`, `duration_ms`, `codec` (`aac_lc`; später `opus`), `container` (`m4a`, `adts`, später `ogg`), `sample_rate`, `bitrate`, `file_name`, `file_key_wrapped` (DEK, mit Master-Key gewrappt), `size_bytes`, `waveform` (BLOB, 100 Pegelwerte, bei der Aufnahme berechnet), `state` (`complete`, `truncated`, `audio_deleted`) | Audio kann gelöscht werden, der Datensatz bleibt für den Text erhalten; Codec und Container je Aufnahme, damit der spätere Opus-Pfad (D4) neben Altdateien bestehen kann |
| `transcript` | `id`, `recording_id`, `engine` (`apple_speechtranscriber`, `apple_dictation`, `sherpa_moonshine_small`, `sherpa_parakeet_v3`, `whisperkit_large_v3_v20240930`, `android_system`), `model_version`, `locale`, `created_at`, `text`, `is_primary`, `edited_by_user` | Mehrere Versionen pro Aufnahme; genau eine ist primär |
| `transcript_segment` | `transcript_id`, `idx`, `start_ms`, `end_ms`, `text`, `confidence`, `boundary_source` (`engine`, `vad`) | Für Wiedergabe mit Mitlauf-Markierung und für Sprünge aus der Suche; auf Android mit Moonshine stammen die Grenzen aus der VAD, nicht aus dem Modell (D3) |
| `transcript_word` | `transcript_id`, `segment_idx`, `idx`, `start_ms`, `end_ms`, `text`, `confidence` | Nur wenn die Engine Wort-Zeitstempel liefert (iOS `audioTimeRange`, Parakeet-Token zu Wörtern zusammengeführt); fehlt die Tabelle für ein Transkript, markiert die Wiedergabe Segmente |
| `tag` | `id`, `name`, `color` | Vom Nutzer angelegt |
| `entry_tag` | `entry_id`, `tag_id` | n:m |
| `transcript_fts` | FTS5, external content auf `transcript.text` | siehe Abschnitt 6 |
| `setting` | `key`, `value` | Erinnerungszeit, Locale, Audio-Aufbewahrung, Sperr-Timeout |
| `keyring` | `id`, `purpose` (`master_wrapped`, `db_key_wrapped`), `blob`, `created_at` | Nur auf Android; iOS hält den Master-Key im Keychain |

Zeitangaben werden als UTC-Millisekunden plus IANA-Zeitzone gespeichert; `entry.day` ist das lokale Datum zum Aufnahmezeitpunkt, damit ein Eintrag um 0:30 Uhr auf Wunsch noch "gestern" zugeordnet werden kann.

## 5. Speicherung und Verschlüsselung

### 5.1 Schichten

| Schicht | Verfahren | Schlüssel |
|---|---|---|
| Datenbank (Metadaten, Transkripte, FTS-Index) | SQLCipher 4.18.0 über `drift` + `sqlite3` (`source: sqlcipher`); `PRAGMA key` als 32-Byte-Raw-Key `x'…'`, damit kein PBKDF2 beim Öffnen; `secure_delete` an; Laufzeitprüfung `PRAGMA cipher_version` [15][16][48] | DB-Key (256 Bit), mit Master-Key gewrappt |
| Audiodateien | Chunk-AEAD mit wahlfreiem Zugriff nach Cryptomator-Muster [90]: Dateikopf (Formatversion, Kopf-Nonce, mit dem Master-Key gewrappter DEK), Inhalt in 32-KiB-Chunks, je Chunk eigene zufällige Nonce und Auth-Tag, AAD = Chunk-Nummer (64 Bit BE) + Kopf-Nonce; Primitive `crypto_aead_xchacha20poly1305_ietf` aus libsodium (Referenz, Dart und beide Brücken) oder AES-256-GCM, wenn ein Spike zeigt, dass die Plattform-Primitive (CryptoKit, `javax.crypto`) im Player messbar schneller sind [17][85] | pro Aufnahme ein zufälliger 256-Bit-Dateischlüssel (DEK), mit Master-Key gewrappt |
| Transfer-Container (D6) | libsodium `crypto_secretstream_xchacha20poly1305`, 64-KiB-Chunks, sequenziell, erkennt Abschneiden und Umsortieren [46] | Container-Schlüssel aus X25519/HKDF oder Passphrase (Argon2id), siehe `06-geraetewechsel-qr-transfer.md` |
| Master-Key | 256 Bit aus dem CSPRNG; wrappt DB-Key und DEKs mit `crypto_secretbox` | iOS: Keychain `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`, optional `SecAccessControl(.biometryCurrentSet)` [49][50]; Android: gewrappt mit AES-256-GCM-Schlüssel im Keystore (StrongBox, TEE-Fallback, `setUserAuthenticationParameters` 30 bis 60 s), Blob in `getNoBackupFilesDir()` [51][52] |

Warum Envelope-Verschlüsselung: Löschen wird zu Crypto-Shredding (DEK vernichten, SQLCipher `secure_delete`), Schlüsselrotation berührt nur die Wrapping-Ebene, und der Export-Container (D6) kann DEKs unverändert übernehmen. Warum Chunk-AEAD statt `secretstream` für Dateien: Jeder Chunk ist unabhängig entschlüsselbar und authentifiziert, der Player springt per Chunk-Index an jede Position, ohne davor liegende Daten zu lesen; die AAD aus Chunk-Nummer und Kopf-Nonce verhindert, dass Chunks vertauscht oder aus einer anderen Datei eingesetzt werden; Abschneiden am Dateiende wird über die im Kopf oder in der Datenbank hinterlegte Länge erkannt. `secretstream` erkennt all das ebenfalls, aber nur sequenziell [46][85]. Warum XChaCha20-Poly1305 als Referenz: 192-Bit-Nonce ohne Zählerverwaltung, gleichbleibende Geschwindigkeit ohne Hardware-AES und identische Testvektoren in Dart, Swift und Kotlin über libsodium; AES-GCM bleibt dort, wo der Keystore selbst rechnet [17]. Das Format wird selbst implementiert (wenige hundert Zeilen), nicht über `org.cryptomator:cryptolib` (AGPLv3 oder kommerzielle Lizenz) [111]; Jetpack Security (`EncryptedFile`) ist seit `security-crypto` 1.1.0 vollständig deprecated und kein Zukunftspfad [105].

### 5.2 Plattformschutz

- iOS: Datenbank und Audio in `NSFileProtectionComplete`; ein laufender Aufnahmepuffer, der nie auf die Platte geht, braucht keine Ausnahme [53]. `ThisDeviceOnly` bedeutet: ein iCloud-Backup enthält nur Chiffrat ohne Schlüssel; das Onboarding erklärt, dass nur der eigene verschlüsselte Export (D6) ein Tagebuch auf ein neues Gerät bringt [54].
- Android: `android:allowBackup="false"` plus `dataExtractionRules` mit `cloud-backup` und `device-transfer` ausgeschlossen; Auto Backup wäre mit 25 MB pro App ohnehin ungeeignet [55].
- App-Sperre per Biometrie/Gerätecode mit kurzem Timeout; Privacy-Overlay beim Wechsel in den Hintergrund (iOS) und `FLAG_SECURE` (Android) über `screen_protector` [56][57].
- Keine Aussperrung nach Biometrie-Änderung: `.biometryCurrentSet` (iOS) und `setInvalidatedByBiometricEnrollment(true)` (Android) machen den Schlüssel nach einem neu registrierten Fingerabdruck oder Gesicht unbrauchbar. Genau diese Aussperrung ist eine der häufigsten echten Store-Beschwerden bei Tagebuch-Apps ("added another fingerprint ... all apps that relied on fingerprint unlock had to have their locks reset") [107][114]. Deshalb ist die Biometrie nur ein Komfortpfad vor dem Gerätecode: Der Master-Key bleibt über den Gerätecode-Pfad (`kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` ohne Biometrie-Bindung bzw. Keystore-Schlüssel mit `setUserAuthenticationParameters(…, AUTH_DEVICE_CREDENTIAL | AUTH_BIOMETRIC_STRONG)`) erreichbar; die Biometrie-gebundene Variante aus D5 ist eine Option in den Einstellungen mit Hinweis auf diese Folge [49][50][52].
- Schlüsselmaterial im Prozess nur als `SecureKey`/`Uint8List` aus `package:sodium` (mlock, Nullen nach Gebrauch), nie als `String` [17][58].
- Keine Root-/Jailbreak-Sperre; nur ein Hinweis, wenn `KeyInfo.getSecurityLevel()` keinen Hardware-Schutz meldet, damit GrapheneOS- und Custom-ROM-Nutzer nicht ausgesperrt werden [59].
- Optionale Passphrase (Argon2id, 64 MiB, t=3, p=1, Salt 16 Byte) ausschließlich für Export und Wiederherstellung [60][61].

### 5.3 Löschen

Eintrag löschen = DEK der Aufnahmen aus `recording` entfernen, Dateien unlinken, Transkript-Zeilen löschen (SQLCipher `secure_delete` überschreibt freie Seiten). "Alles löschen" = Master-Key aus Keychain/Keystore entfernen und Datenbankdatei löschen. Auf Flash-Speicher ist das der einzig belastbare Weg [58].

## 6. Lokale Suche

**Empfehlung: SQLite FTS5 in der SQLCipher-Datenbank**, weil der Index damit automatisch verschlüsselt ist und keine zweite Speicherschicht entsteht [48].

- Virtuelle Tabelle `transcript_fts(text, content='transcript', content_rowid='id')` mit Triggern für Insert/Update/Delete; Tokenizer `unicode61` mit `remove_diacritics 2`, damit "Straße" und "Strasse" sowie Umlautvarianten zusammenfinden.
- Treffer werden über `transcript_segment` auf die Zeitposition im Audio abgebildet: Suche nach "Zahnarzt" springt in der Wiedergabe an die Stelle.
- Filter kombinierbar mit Datum, Tag und Tagebuch; Sortierung nach `bm25()` oder Datum.
- Größenordnung: Der FTS5-Index liegt erfahrungsgemäß in der Größenordnung des Textes selbst; bei rund 1 MB Rohtext pro Jahr bleibt er im einstelligen MB-Bereich (eigene Schätzung).
- Einfache Rückblicke ohne KI (D8): "Vor einem Jahr" (Abfrage auf `entry.day`), Monatsübersicht, Wortzahl aus `transcript.text`, Kalender mit Markierung aufgenommener Tage.

## 7. Lokale Zusammenfassungen (optionale Stufe, nicht MVP)

Das MVP enthält keine generative KI (D8). Für Version 1.x gilt:

**iOS: Apple Foundation Models (iOS 26+), nur mit Opt-in und nur auf Apple-Intelligence-Geräten.**

- Verfügbarkeit zur Laufzeit über `SystemLanguageModel.default.availability` prüfen (`.deviceNotEligible`, `.appleIntelligenceNotEnabled`, `.modelNotReady`); bei Nichtverfügbarkeit wird die Funktion ausgeblendet, nicht ausgegraut [62].
- Modell: 3 Milliarden Parameter, 2-Bit-quantisiert [63]. Kontextfenster: 4 096 Token pro Session beim 26.x-Modell [64]; unter iOS 27 liefert `SystemLanguageModel().contextSize` auf neueren Geräten 8 192 (welche Geräte, sagt Apple nicht genau) [82]. Der Wert wird deshalb zur Laufzeit per `contextSize` (ab 26.4, back-deployed) abgefragt, nicht fest kodiert. Apples Faustregel "ein Token entspricht drei bis vier Zeichen" gilt für "Latin alphabet languages such as English"; für deutsche Komposita ist sie nur eine Näherung, die Stückelung langer Transkripte in mehrere Sessions rechnet deshalb mit `tokenCount(for:)` statt mit Zeichen [64].
- Sprache: `supportsLocale(_:)` prüfen; Instruktion "The person's locale is de_DE" plus "You MUST respond in German" [65]. Deutsch ist seit iOS 18.4 (31. März 2025) unterstützt; Guardrails wirken nur für unterstützte Sprachen und sind seit 26.4 in der Stufe konfigurierbar (Faktenprüfung Eintrag 9) [65][67]; Geräteliste iPhone 15 Pro/Pro Max und neuer (unverifiziert, Apple-Support-Artikel nicht erreichbar) [66].
- Guardrails: Tagebuchthemen (Trauer, Krankheit, Krisen) können `guardrailViolation` oder `refusal` auslösen; die App fängt beides ab und zeigt eine neutrale Meldung ohne Wertung. `permissiveContentTransformations` für reine Zusammenfassungen prüfen [67].
- Drei Modellversionen (26.0 bis 26.3, 26.4, 27.0): Prompts werden je Version getestet [62].
- `PrivateCloudComputeLanguageModel` (iOS 27 beta) wird nicht verwendet, weil es ein Server-Aufruf ist [68].

**Android: kein Gemini Nano.** ML Kit GenAI Summarization unterstützt nur Englisch, Japanisch und Koreanisch, ist auf Flaggschiff-Geräte begrenzt und verlangt einen gesperrten Bootloader [69][70]. Alternative in einer späteren Version: ein kleines eigenes On-Device-Modell über dieselbe Laufzeit wie die STT-Engine; Auswahl und Lizenz sind offen.

Keine Stimmungs-Diagnostik aus der Stimme, keine medizinischen Aussagen (Nicht-Ziel in `00-anforderungen.md`).

## 8. Erinnerungen

Eine tägliche Erinnerung zu einer frei wählbaren Uhrzeit, mit den Aktionen "Aufnehmen", "In 1 Stunde", "Heute nicht"; kein Streak-Druck (D7). Benachrichtigungen enthalten nie Tagebuchinhalt (D5).

### 8.1 iOS

- `UNCalendarNotificationTrigger(dateMatching: [hour, minute], repeats: true)`; bei Änderung der Uhrzeit wird die Anfrage ersetzt [71].
- `UNNotificationCategory` mit drei Aktionen; "Aufnehmen" öffnet die App in den Aufnahmezustand (ein Tipp, dann läuft die Aufnahme, M3). "In 1 Stunde" plant einen einmaligen `UNTimeIntervalNotificationTrigger`.
- Interruption Level `timeSensitive` nur nach ausdrücklicher Nutzerwahl; benötigt die Capability `com.apple.developer.usernotifications.time-sensitive` [72].
- Zusätzliche Einstiege ohne Benachrichtigung: Control (Sperrbildschirm, Action Button). Der Intent muss `AudioRecordingIntent` adoptieren (Pflicht, eine Live Activity zu starten und aktiv zu halten, sonst stoppt iOS die Aufnahme [73]) und zugleich `LiveActivityIntent`, damit das System den App-Prozess ohne Öffnen der App startet [80]. Apple dokumentiert die Kombination nicht ausdrücklich, und ein Forumsbericht (Thread 815725) meldet, dass ein Kaltstart der Aufnahme aus dem Hintergrund per Intent scheitert, solange die Audio-Session nicht zuvor im Vordergrund lief [81]. Der Spike testet das auf dem Gerät; scheitert es, öffnet das Control die App per `openAppWhenRun` direkt im Aufnahmezustand (ein Tipp mehr, M3 bleibt erfüllt).

### 8.2 Android

- `POST_NOTIFICATIONS` wird im Kontext angefragt (bei Zielversion 33+ sind Benachrichtigungen bei Neuinstallation aus) [74].
- Planung mit `AlarmManager.setAlarmClock()`: feuert auch im Doze, zeigt das Wecker-Symbol und passt zur Semantik "vom Nutzer gewählte Uhrzeit" [75]. `setAlarmClock` ist einmalig; der `BroadcastReceiver` plant nach jedem Auslösen den nächsten Tag.
- Berechtigung: `SCHEDULE_EXACT_ALARM` anfragen (`canScheduleExactAlarms()` prüfen, auf `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` reagieren). Bei Ablehnung transparent auf `setWindow()` mit ±10 Minuten zurückfallen und das in den Einstellungen anzeigen. `USE_EXACT_ALARM` nur, wenn die Play-Policy-Einordnung als Erinnerungs-App abgesichert ist (offene Frage) [75].
- Neu planen bei `BOOT_COMPLETED`, `TIME_SET`, `TIMEZONE_CHANGED` und nach App-Update (`MY_PACKAGE_REPLACED`).
- Die Benachrichtigung hat die Aktion "Aufnehmen", die den Microphone-Foreground-Service direkt startet; der Start aus einer Benachrichtigung ist eine dokumentierte Ausnahme von der Hintergrundstart-Beschränkung [43].
- Herstellerspezifische Akku-Optimierung (Samsung, Xiaomi, Huawei, OnePlus) kann Alarme unterdrücken; das Onboarding hat einen Schritt "Erinnerungen zuverlässig machen" mit Deep-Links in die jeweiligen Einstellungen [76].

## 9. Projektstruktur des Repositories

Repository `tagebuch` (D11), Monorepo mit Flutter-Workspaces. Der Krypto- und Containerkern ist eine eigene, separat auditierbare Dart-Bibliothek (D10).

```
tagebuch/
├─ app/                        Flutter-App (UI, Navigation, Einstellungen)
├─ packages/
│  ├─ diary_core/              Domänenmodell, Anwendungsfälle, keine Plattformabhängigkeit
│  ├─ diary_crypto/            Envelope-Schlüssel, Key-Wrapping, Argon2id, HKDF, Testvektoren
│  ├─ diary_chunkfile/         Chunk-AEAD-Dateiformat mit wahlfreiem Zugriff (Abschnitt 5.1): Dart-Referenz,
│  │                           Swift- und Kotlin-Leser für Player und AudioFile-Callbacks, gemeinsame Testvektoren
│  ├─ diary_container/         Export-/Transfer-Container (D6): secretstream-Strom, Manifest, zstd
│  ├─ diary_storage/           drift-Schema, Migrationen, FTS5, SQLCipher-Anbindung
│  ├─ diary_audio/             Aufnahme (PCM-Abgriff, Resampling, AAC-LC-Encoder, Wellenform, Schreiben über
│  │                           diary_chunkfile), Wiedergabe (Media3-DataSource + MediaSessionService,
│  │                           AVAudioEngine-Player, Sperrbildschirm, Geschwindigkeit, Mitlauf-Markierung)
│  ├─ diary_stt/               Plattform-Interface, Engine-Registry, Modellverwaltung
│  ├─ diary_stt_ios/           Swift-Plugin: SpeechAnalyzer, DictationTranscriber, optional WhisperKit
│  ├─ diary_stt_android/       Kotlin-Plugin: sherpa-onnx, Play Asset Delivery, Foreground Service
│  ├─ diary_keys/              Brücke (c): SecAccessControl, StrongBox, BiometricPrompt.CryptoObject
│  └─ diary_reminders/         Notifications, AlarmManager, Neuplanung
├─ models/                     Modellmanifeste (Hash, Größe, Lizenz), keine Modellbinärdateien im Git
├─ test_assets/                Synthetische oder freigegebene Testaufnahmen, keine echten Tagebücher
├─ docs/                       Diese Konzeptdokumente, Threat Model, Datenflussdiagramm
├─ fastlane/ und android/, ios/ Signatur- und Store-Konfiguration ohne Geheimnisse
└─ .github/workflows/          CI (siehe Abschnitt 10)
```

Regeln: `diary_crypto`, `diary_container` und der Dart-Teil von `diary_chunkfile` haben keine Flutter-Abhängigkeit und sind aus der Kommandozeile testbar; die nativen Leser in `diary_chunkfile` müssen dieselben Testvektoren bestehen wie die Dart-Referenz; jedes Paket hat eine eigene `CHANGELOG.md`; native Brücken enthalten nur Plattformcode, keine Geschäftslogik.

## 10. CI ohne Datenabfluss

Ziel: Der Build beweist, dass die App nichts sendet, und die CI selbst verarbeitet niemals Nutzerdaten.

1. **GitHub Actions** (Linux für Analyse, Tests und Android-Build; macOS-Runner für iOS-Build). Läufe auf jedem Pull Request: `dart format --set-exit-if-changed`, `flutter analyze`, Unit- und Widget-Tests, Paket-Tests der Kernbibliotheken.
2. **Netz-Wächter im Build:** Ein Skript schlägt fehl, wenn `android.permission.INTERNET` im gemergten `AndroidManifest.xml` auftaucht, wenn `pubspec.lock` ein Paket aus einer Sperrliste enthält (HTTP-Clients, Analytics, Crash-Reporter, Werbe-SDKs) oder wenn `Info.plist` Netzwerk-Entitlements enthält, die das MVP nicht braucht (`com.apple.developer.networking.*`, `NSLocalNetworkUsageDescription`). Für die spätere WLAN-Übertragung (D6, Version 1.x) wird die Sperrliste bewusst und sichtbar angepasst.
3. **Abhängigkeits-Pinning:** `pubspec.lock` eingecheckt, Dependabot nur mit manueller Freigabe, Prüfung neuer Pakete auf Netzwerkzugriff im Review.
4. **Geheimnisse:** Keine Signaturschlüssel im Repository; Store-Signierung läuft lokal beim Inhaber oder in einem separaten, geschützten Workflow. Testdaten sind synthetisch (TTS-generierte Sätze) oder eigens eingesprochene, freigegebene Clips; niemals echte Tagebücher.
5. **Reproduzierbarer Android-Build** (D10): Docker-Image mit fixierten Versionen, Vergleich des CI-APK mit dem Store-APK nach dem Signal-Muster (`apkdiff` ignoriert Signaturen) [77]; F-Droid-Metadaten im Repository. iOS-Reproduzierbarkeit ist wegen App-Store-Signatur und Umverpackung praktisch nicht erreichbar [78].
6. **Keine Cloud-Gerätefarmen mit Nutzerdaten:** Gerätetests laufen auf eigenen Geräten des Inhabers; falls eine Gerätefarm für Kompatibilitätstests genutzt wird, nur mit synthetischen Testdaten.

## 11. Teststrategie

| Ebene | Inhalt | Werkzeug |
|---|---|---|
| Unit (Krypto) | Chunk-AEAD-Dateien: Chunk n entschlüsselt ohne Chunks 0 bis n-1, vertauschte oder aus einer anderen Datei eingesetzte Chunks scheitern an der AAD, verändertes Byte scheitert am Tag, abgeschnittene Datei wird erkannt; dieselben Testvektoren in Dart, Swift und Kotlin; secretstream für den Transfer-Container (Truncation/Umsortierung erkannt); Wrapping, Argon2id-Parameter, Crypto-Shredding macht Datei unlesbar | `package:test`, XCTest, JUnit; Vektoren aus libsodium-Doku und eigene Chunk-Vektoren in `diary_chunkfile` |
| Unit (Storage) | Migrationen vorwärts, FTS5-Trigger, `secure_delete`, Öffnen mit falschem Schlüssel schlägt fehl | drift-Testdatenbank in Memory und auf Datei |
| Unit (Container) | Round-Trip Export/Import, Manifest-Hash, Versionsprüfung, iOS↔Android-Kompatibilität mit denselben Testdateien | Kommandozeile |
| Integration (Audio) | Aufnahme 10 s, 5 min, 30 min; Abbruch nach n Sekunden; App-Kill während Aufnahme (Datei bis zum letzten vollständigen Chunk lesbar, `state = truncated`); keine Klartextdatei im App-Sandbox-Verzeichnis (Dateisystem-Scan nach M4A-`ftyp`-, ADTS-Sync- und WAV-Magic-Bytes, auch in Cache- und Temp-Verzeichnissen); Wellenform mit 100 Werten vorhanden | `integration_test` auf Gerät |
| Hörtest (Spike S6, dann Regression) | Blind-Vergleich AAC-LC 24/32/48 kbit/s mono 24 kHz an mindestens fünf Stimmen (Zimmerakustik, Handy-Mikrofon, Headset über HFP); Transkriptions-WER je Bitrate gegen das PCM-Original; Entscheidung dokumentiert | manuell mit Protokoll, WER-Skript aus der STT-Regression |
| Wiedergabe | Seek an 20 zufällige Positionen einer 30-Minuten-Datei: gelesene Bytes höchstens zwei Chunks (kein Vollentschlüsseln), Position gegen Segment-/Wort-Zeitstempel ±100 ms; Geschwindigkeit 0,8 und 2,0 hält die Mitlauf-Markierung synchron; Hintergrund-Wiedergabe mit gesperrtem Bildschirm, Steuerung über Sperrbildschirm und Kopfhörer; Android 17 mit `adb shell cmd audio set-enable-hardening throw` (Wiedergabe darf nicht stumm werden) [94] | `integration_test`, Media3-Testhelfer, manuelles Protokoll |
| STT-Regression | Fester Korpus (Deutsch de-DE/de-AT/de-CH, Englisch; eingesprochen von Freiwilligen mit Einwilligung, plus TTS-Sätze), WER je Engine und Modellversion, Zielwerte pro Gerät; Laufzeit (RTF) und Spitzen-RAM protokolliert; eigene Testsätze für die bekannten Deutsch-Schwächen des Apple-Diktats (Komposita, Bindestriche, Interpunktionswörter) [113]; Zeitstempel-Abweichung je Engine gegen manuell gesetzte Wortgrenzen | eigenes Skript, Ergebnisse als Tabelle in `docs/` |
| Erinnerungen | Uhrzeit ändern, Zeitzone wechseln, Neustart, Doze (`adb shell dumpsys deviceidle force-idle`), Ablehnung von `SCHEDULE_EXACT_ALARM`, Herstellergeräte (Samsung, Xiaomi) | manuell mit Protokoll, teilweise `adb` |
| Sicherheit | App-Switcher-Snapshot leer, Screenshot geblockt, Sperre nach Timeout, Keystore-Schutzstufe, Backup-Ausschluss (`adb backup` liefert nichts) | OWASP-MASTG-Testfälle [57][58] |
| Barrierefreiheit | VoiceOver/TalkBack für den gesamten Aufnahme- und Wiedergabefluss, Schriftskalierung, Kontrast | manuelle Checkliste |

**Flugmodus-Test (Nachweis für M6 und D14):** Vor jedem Release auf mindestens einem iPhone und zwei Android-Geräten (ein Pixel, ein Samsung):

1. Frische Installation; Onboarding bis zum Modell-Download mit WLAN.
2. Flugmodus ein, WLAN und Bluetooth aus.
3. Aufnahme 3 Minuten Deutsch, 1 Minute Englisch; Transkription abwarten; Wiedergabe; Suche nach einem gesprochenen Wort; Erinnerung stellen; Export-Container erzeugen; Neustart des Geräts; App öffnen und Eintrag lesen.
4. Erwartung: Alle Schritte gelingen ohne Fehlermeldung zum Netz.
5. Ergänzend ohne Flugmodus: Gerät hinter einem Abhör-Proxy (mitmproxy mit installiertem Zertifikat) durch dieselben Schritte führen; erwartetes Ergebnis sind null Verbindungen aus dem App-Prozess (auf Android zusätzlich `dumpsys package` zeigt keine `INTERNET`-Permission). Das Protokoll wird mit Datum, Gerät, OS-Version und Build-Hash in `docs/` abgelegt und ist die Grundlage für die Store-Datenschutzangaben.

## 12. Offene Fragen

1. Funktioniert Play Asset Delivery, wenn die App keine `INTERNET`-Permission hat? (Spike, entscheidet über die Modellauslieferung auf Android.)
2. Tatsächliche `.ort`-Dateigrößen, RAM-Bedarf und RTF von Moonshine Small auf einem Snapdragon-6/7-Gerät; Zielwert RTF ≤ 0,5.
3. Modelllizenz Parakeet TDT 0.6B v3 (CC-BY-4.0?) und Attributionspflichten in der App.
4. Offizielle Hardware-Untergrenze und Locale-Liste für `SpeechTranscriber`; Verhalten von `AssetInventory`, wenn das System ungenutzte Assets wieder entfernt.
5. Gemessene Deutsch-WER von `SpeechTranscriber` gegen Moonshine Small und WhisperKit large-v3-v20240930 auf identischem Tagebuch-Audio; dabei auch prüfen, wie `de-CH` mit Standard- und Mundartaudio umgeht (Annahme aus 2.1).
6. AAC-LC-Standardbitrate 24, 32 oder 48 kbit/s (Rechenbasis 32 kbit/s): Blind-Hörtest und Transkriptionsvergleich im Spike S6.
7. Nutzt `flutter_secure_storage` 11 auf Android StrongBox oder nur TEE? Entscheidet über den Umfang von Brücke (c).
8. Play-Policy-Einordnung für `USE_EXACT_ALARM` als Erinnerungs-App.
9. Exportkontrolle: libsodium und SQLCipher sind keine Betriebssystem-Kryptografie; `ITSAppUsesNonExemptEncryption` und ein möglicher Self-Classification-Report sind mit `05-sicherheit-und-datenschutz.md`, Abschnitt 5.4, abzustimmen [79].
10. Modellauslieferung für den F-Droid-Build ohne Play Asset Delivery.
11. Apple-Intelligence-Geräteliste, Refusal-Quote des Foundation-Modells bei typischen Tagebuchthemen in Deutsch und welche Geräte unter iOS 27 `contextSize` 8 192 melden (nur für Version 1.x relevant).
12. WhisperKit: Gibt die Remote-Config (`config.json`) das 626-MB-Modell auf A14 (iPhone 12) frei, oder bleibt es bei der Fallback-Grenze A15? Entscheidet über die Geräteuntergrenze des Zusatzpakets auf iOS.
13. Kaltstart der Aufnahme aus Control oder Action Button bei gesperrtem Gerät (`AudioRecordingIntent` + `LiveActivityIntent`): funktioniert er auf iOS 26/27, oder braucht es den Umweg über `openAppWhenRun`?
14. M4A ohne Klartextdatei schreiben: Auf Android braucht `MediaMuxer` einen Dateideskriptor; taugt ein speichergestützter Deskriptor (`SharedMemory`) oder der Media3-`Mp4Muxer`, und welche Zwischenform (ADTS-Rahmen oder fragmentiertes MP4) sichert die Aufnahme bei App-Kill? Rückfall: AAC-ADTS als Endformat (Abschnitt 3.1).
15. Zeitstempel-Genauigkeit von Parakeet TDT (Token zu Wörtern zusammengeführt) auf deutscher Sprache; Verhalten der VAD-Segmentgrenzen mit Moonshine bei schnellem Sprechen ohne Pausen.
16. Späterer Opus-Pfad: Greift `AVAudioConverter.bitRate` bei `kAudioFormatOpus` (ein Apple-Engineer zeigt nur `bitRateStrategy`), oder braucht es libopus als xcframework? Verhalten von `MediaRecorder` OGG/OPUS auf Samsung- und Xiaomi-Geräten [85].
17. Chunk-AEAD-Primitive: XChaCha20-Poly1305 über libsodium oder AES-256-GCM über CryptoKit/`javax.crypto`; Durchsatz beider Varianten im Player auf dem 4-GB-Gerät messen (Spike S4).

## Quellen

1. https://developer.apple.com/documentation/speech/speechanalyzer
2. https://developer.apple.com/documentation/speech/assetinventory
3. https://developer.apple.com/documentation/speech/speechtranscriber/preset
4. https://developer.apple.com/documentation/speech/sfspeechrecognizer
5. https://developer.apple.com/documentation/speech/speechdetector
6. https://github.com/Beingpax/VoiceInk/blob/8f089cb4bf2c9c2f217b0cc0af909d9052ff6288/VoiceInk/Features/ModelLibrary/Models/LanguageDictionary.swift
7. https://developer.apple.com/forums/thread/797835
8. https://developer.apple.com/forums/thread/790108
9. https://developer.apple.com/forums/thread/806765
10. https://pub.dev/packages/sherpa_onnx
11. https://developer.apple.com/documentation/speech/dictationtranscriber
12. https://pub.dev/packages/speech_to_text
13. https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
14. https://pub.dev/packages/record
15. https://pub.dev/packages/sqlite3
16. https://github.com/simolus3/drift/blob/develop/docs/content/platforms/encryption.md
17. https://pub.dev/packages/sodium
18. https://pub.dev/packages/flutter_secure_storage
19. https://github.com/ionspin/kotlin-multiplatform-libsodium
20. https://github.com/whyoleg/cryptography-kotlin
21. https://developer.apple.com/documentation/cryptokit/chachapoly
22. https://github.com/serenity-kit/react-native-libsodium
23. https://github.com/argmaxinc/WhisperKit/releases
24. https://github.com/argmaxinc/WhisperKit
25. https://github.com/argmaxinc/WhisperKit/blob/main/Sources/WhisperKit/Core/Models.swift
26. https://github.com/argmaxinc/argmax-oss-swift/issues/528
27. https://developer.apple.com/documentation/coreml/mlcomputeunits
28. https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/main/core/java/android/speech/SpeechRecognizer.java
29. https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/main/core/java/android/speech/RecognitionSupport.java
30. https://github.com/k2-fsa/sherpa-onnx/releases
31. https://github.com/k2-fsa/sherpa-onnx
32. https://raw.githubusercontent.com/moonshine-ai/moonshine/main/docs/models/available-models.md
33. https://raw.githubusercontent.com/moonshine-ai/moonshine/main/LICENSE
34. https://raw.githubusercontent.com/k2-fsa/sherpa/master/docs/source/onnx/pretrained_models/offline-transducer/nemo/parakeet-tdt-0.6b-v3.rst
35. https://raw.githubusercontent.com/huggingface/open_asr_leaderboard/main/scripts/data/multilingual.csv
36. https://github.com/googlesamples/mlkit/issues/1066
37. https://developer.android.com/guide/playcore/asset-delivery
38. https://developer.android.com/google/play/requirements/target-sdk
39. https://developer.android.com/guide/practices/page-sizes
40. https://developer.android.com/about/versions/17/behavior-changes-all
41. https://developer.apple.com/documentation/xcode/configuring-background-execution-modes
42. https://developer.android.com/develop/background-work/services/fgs/service-types
43. https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start
44. https://developer.apple.com/documentation/coreaudiotypes/kaudioformatopus
45. https://developer.android.com/media/platform/supported-formats
46. https://github.com/jedisct1/libsodium-doc/blob/master/secret-key_cryptography/secretstream.md
47. https://github.com/xiph/opus/blob/main/include/opus_defines.h
48. https://github.com/sqlcipher/sqlcipher
49. https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly
50. https://developer.apple.com/documentation/localauthentication/accessing-keychain-items-with-face-id-or-touch-id
51. https://developer.android.com/privacy-and-security/keystore
52. https://developer.android.com/identity/sign-in/biometric-auth
53. https://developer.apple.com/documentation/foundation/fileprotectiontype
54. https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
55. https://developer.android.com/identity/data/autobackup
56. https://pub.dev/packages/screen_protector
57. https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-PLATFORM/MASTG-TEST-0010.md
58. https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-STORAGE/MASTG-TEST-0011.md
59. https://github.com/OWASP/owasp-masvs/blob/master/Document/11-MASVS-RESILIENCE.md
60. https://github.com/jedisct1/libsodium-doc/blob/master/password_hashing/default_phf.md
61. https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Password_Storage_Cheat_Sheet.md
62. https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel
63. https://developer.apple.com/videos/play/wwdc2025/286/
64. https://developer.apple.com/documentation/foundationmodels/managing-the-context-window
65. https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models
66. https://support.apple.com/121115 (aus der Sandbox nicht abrufbar)
67. https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output
68. https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute
69. https://developer.android.com/ai/gemini-nano
70. https://github.com/capawesome-team/capacitor-mlkit
71. https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger
72. https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive
73. https://developer.apple.com/documentation/appintents/audiorecordingintent
74. https://developer.android.com/develop/ui/views/notifications/notification-permission
75. https://developer.android.com/develop/background-work/services/alarms/schedule
76. https://github.com/urbandroid-team/dont-kill-my-app
77. https://github.com/signalapp/Signal-Android/blob/main/reproducible-builds/README.md
78. https://github.com/signalapp/Signal-iOS/issues/641
79. https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
80. https://developer.apple.com/documentation/appintents/liveactivityintent
81. https://developer.apple.com/forums/thread/815725
82. https://developer.apple.com/videos/play/wwdc2026/319/
83. https://developer.apple.com/videos/play/wwdc2019/256/
84. https://github.com/argmaxinc/argmax-oss-swift/discussions/391
85. `docs/recherche/nachrecherche-audio-container.md` (Nachrecherche Audio-Container, Aufnahme-Pipeline und Wiedergabe-Architektur, 3. September 2026; Primärquellen dort gelistet)
86. https://developer.apple.com/documentation/audiotoolbox/audiofiletypeid
87. https://developer.apple.com/forums/thread/128434
88. http://www.openradar.appspot.com/49315600 (rdar://49315600; nur als Suchauszug lesbar)
89. https://developer.android.com/media/media3/exoplayer/supported-formats
90. https://github.com/cryptomator/docs/blob/develop/docs/security/vault.mdx
91. https://github.com/androidx/media/blob/release/libraries/datasource/src/main/java/androidx/media3/datasource/AesCipherDataSource.java
92. https://github.com/signalapp/Signal-Android/blob/main/app/src/main/java/org/thoughtcrime/securesms/audio/AudioCodec.java
93. https://github.com/signalapp/Signal-Android/blob/main/core/util/src/main/java/org/signal/core/util/crypto/ModernDecryptingPartInputStream.java
94. https://developer.android.com/about/versions/17/changes/bg-audio
95. https://developer.android.com/media/media3/session/background-playback
96. https://github.com/androidx/media/blob/release/libraries/common/src/main/java/androidx/media3/common/PlaybackParameters.java
97. https://developer.apple.com/documentation/avfaudio/avaudioplayernode/schedulebuffer(_:completionhandler:)
98. https://developer.apple.com/documentation/avfaudio/avaudiounittimepitch/rate
99. https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter
100. https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter
101. https://developer.apple.com/videos/play/wwdc2025/277/
102. https://developer.apple.com/documentation/speech/speechtranscriber/resultattributeoption
103. https://github.com/k2-fsa/sherpa-onnx/blob/master/sherpa-onnx/csrc/offline-recognizer-moonshine-impl.h (sowie `c-api/c-api.h`, `offline-recognizer-transducer-impl.h`)
104. https://github.com/element-hq/element-x-android (libraries/voicerecorder: `AudioLevelCalculator`, Resampling auf 100 Werte)
105. https://developer.android.com/jetpack/androidx/releases/security
106. https://github.com/k2-fsa/sherpa-onnx/issues/2626
107. `docs/recherche/nachrecherche-nutzerstimmen-stores.md` (Nachrecherche Nutzerstimmen und Store-Kennzahlen, 3. September 2026)
108. https://github.com/napoleonmm83/Transkribor/issues/130
109. https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/allowbluetoothhfp (sowie `.../bluetoothhighqualityrecording`)
110. https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playandrecord
111. https://github.com/cryptomator/cryptolib/releases
112. https://developer.apple.com/documentation/audiotoolbox/audiofileopenwithcallbacks(_:_:_:_:_:_:)
113. https://developer.apple.com/forums/thread/826756
114. https://github.com/hanjoongcho/aaf-easydiary/issues/197
