# Technik-Recherche Android: 100 % lokale Sprachtranskription für ein Voice Diary

Stand: 3. September 2026. Blickwinkel: On-Device-Spracherkennung und relevante Plattform-APIs auf Android (Android 14–17, API 34–37).

Hinweis zur Quellenlage: Während der Recherche waren developers.google.com, support.google.com, play.google.com, huggingface.co, alphacephei.com, dontkillmyapp.com und k2-fsa.github.io über den Netzwerk-Proxy nicht erreichbar. Ersatzweise wurden developer.android.com, die AOSP-Quellen (GitHub-Mirror), die GitHub-Repositories der Engines (README, Docs-Quellen, Issues, Release-Seiten) sowie Drittanbieter-Wrapper-Dokumentationen (Capacitor/Flutter-Plugins) ausgewertet. Aussagen, die nur aus Sekundärquellen stammen, sind als solche markiert.

---

## 1. Kernaussage

Für ein Tagebuch mit der Anforderung "keine Cloud, keine Konten, keine Server" gibt es auf Android drei realistische Wege zur Transkription. Keiner davon ist allein ausreichend:

1. **Android-Framework `SpeechRecognizer.createOnDeviceSpeechRecognizer()`** (API 31+): kostenlos, systemintegriert, aber herstellerabhängig verfügbar und nicht kontrollierbar (Modelle, Sprachen, Session-Verhalten liegen beim OEM/Google).
2. **ML Kit GenAI Speech Recognition (`com.google.mlkit:genai-speech-recognition:1.0.0-alpha1`)**: neu, unterstützt `de-DE`, läuft über Google Play Services/AICore, Alpha-Status mit dokumentierten Problemen bei langen Streams.
3. **Eigene, in die App gebündelte Open-Source-Engine** (sherpa-onnx mit Moonshine/Whisper/Parakeet, whisper.cpp oder Vosk): einzige Variante, bei der die App die Datenschutzgarantie technisch selbst kontrolliert (die App kann komplett ohne `android.permission.INTERNET` ausgeliefert werden). Kosten: 50–650 MB Modelldaten, RAM-Bedarf, NDK-Pflege.

Empfehlung (Details in Abschnitt 9): Primärpfad = gebündelte Engine (sherpa-onnx + Moonshine Small Streaming für Deutsch und Englisch, MIT-lizenziert, je 123 M Parameter), Sekundärpfad = optional zuschaltbarer System-Recognizer für Geräte mit wenig Speicher, ML Kit GenAI Speech nur als Experiment beobachten.

---

## 2. Android-Framework: `SpeechRecognizer` on-device

### 2.1 API-Oberfläche (AOSP-Quelle `android/speech/SpeechRecognizer.java`)

- `SpeechRecognizer.createOnDeviceSpeechRecognizer(Context)` erzeugt einen Recognizer, der an die Systemkomponente aus der Ressource `config_defaultOnDeviceSpeechRecognitionService` bindet. Die Methode "throws `UnsupportedOperationException` iff `isOnDeviceRecognitionAvailable(Context)` is false". `isOnDeviceRecognitionAvailable()` gibt nur dann `true` zurück, wenn diese String-Ressource zu einem gültigen `ComponentName` auflöst. Beide Methoden sind seit API 31 vorhanden (Bestätigung über die API-Jar-Mirror `Reginer/aosp-android-jar`, Ordner `android-31`).
- `checkRecognitionSupport(Intent, Executor, RecognitionSupportCallback)` und `triggerModelDownload(Intent[, Executor, ModelDownloadListener])` existieren ab API 33 (Ordner `android-33` und höher). Der `ModelDownloadListener` liefert `onSuccess()`, `onProgress(int)`, `onScheduled()` oder `onError(int)`.
- `RecognitionSupport` enthält vier Listen: `installedOnDeviceLanguages` ("ready for use on this device"), `supportedOnDeviceLanguages` ("need to be downloaded before use. See SpeechRecognizer#triggerModelDownload"), `pendingOnDeviceLanguages` ("scheduled for download") und `onlineLanguages` ("SpeechRecognizer created via createOnDeviceSpeechRecognizer are expected to return an empty list"). Damit lässt sich zur Laufzeit prüfen, ob `de-DE`/`en-US` lokal installiert ist.
- Relevante Fehlercodes: `ERROR_LANGUAGE_NOT_SUPPORTED = 12`, `ERROR_LANGUAGE_UNAVAILABLE = 13` ("Requested language is supported, but not available currently (e.g. not downloaded yet)"), `ERROR_CANNOT_CHECK_SUPPORT = 14`, `ERROR_CANNOT_LISTEN_TO_DOWNLOAD_EVENTS = 15`, `ERROR_SERVER_DISCONNECTED = 11`.
- `RecognizerIntent`-Extras: `EXTRA_PREFER_OFFLINE` ("indicate whether to only use an offline speech recognition engine"; API 23), `EXTRA_SEGMENTED_SESSION` (liefert Ergebnisse segmentweise über `RecognitionListener#onSegmentResults(Bundle)`; API 33), `EXTRA_AUDIO_SOURCE` (`ParcelFileDescriptor` mit bereits geöffneter Audioquelle; API 33), `EXTRA_ENABLE_FORMATTING` (Interpunktion/Großschreibung; API 33), `EXTRA_LANGUAGE_MODEL` (Pflicht-Extra).

### 2.2 Datenschutz: geht wirklich nichts ins Netz?

- Die Klassenbeschreibung warnt ausdrücklich, dass die Implementierung "is likely to stream audio to remote servers to perform speech recognition" und "is not intended to be used for continuous recognition". Diese Warnung gilt für den generischen Recognizer (`createSpeechRecognizer`). Bei `createOnDeviceSpeechRecognizer` wird an einen eigenen, vom Hersteller festgelegten Dienst gebunden; das Framework selbst garantiert aber keine Netzwerk-Isolation.
- Auf Pixel-Geräten zeigt die Overlay-Konfiguration `config_defaultOnDeviceSpeechRecognitionService = com.google.android.as/com.google.android.apps.miphone.aiai.app.AiAiSpeechRecognitionService` (Android System Intelligence, Teil des Private Compute Core). Viele Custom-ROM-Overlays setzen denselben Wert; als generischer "Speech Recognizer"-Rolleninhaber ist dagegen `com.google.android.tts` (Speech Services by Google) konfiguriert, der auch online arbeiten kann.
- Für Samsung, Xiaomi & Co. konnte kein belastbarer Beleg gefunden werden, welcher Dienst hinter `createOnDeviceSpeechRecognizer` steckt oder ob `isOnDeviceRecognitionAvailable()` überhaupt `true` liefert. Das ist eine offene Prüf-Frage und muss auf echten Geräten getestet werden (Testmatrix: Samsung One UI 6/7/8, Xiaomi HyperOS, OnePlus, Pixel).
- Konsequenz: Wenn "keine Cloud" ein Produktversprechen sein soll, kann die App dieses Versprechen mit dem System-Recognizer nicht selbst garantieren. Sie kann es nur mit einer eigenen Engine und dem Verzicht auf die `INTERNET`-Permission (die dann vom OS durchgesetzt wird).

### 2.3 Längenbegrenzungen

Das Framework dokumentiert keine feste Zeitgrenze. Google-Recognizer beenden Sessions typischerweise nach Stille; `EXTRA_SEGMENTED_SESSION` (API 33) ist der vorgesehene Weg für längere Diktate. Für das Tagebuch (typisch 1–5 Minuten) ist der bessere Ansatz ohnehin: Audio selbst mit `AudioRecord` aufnehmen, speichern und dann offline transkribieren, statt live über den System-Recognizer.

---

## 3. ML Kit GenAI / Gemini Nano über AICore

### 3.1 APIs und Artefakte

Die Seite developer.android.com/ai/gemini-nano (zuletzt aktualisiert 2026-04-02) listet sechs ML-Kit-GenAI-APIs: Prompt, Summarization, Proofreading, Rewriting, Image Description und **Speech Recognition** ("Transcribe spoken audio to text"). AICore wird beschrieben mit "No persistent data storage" und "Restricted internet access – AICore has no direct internet access; all requests routed through Private Compute Services".

Maven-Artefakte (aus Beispiel-Builds, Juli/August 2026): `com.google.mlkit:genai-summarization:1.0.0-beta1`, `genai-prompt:1.0.0-beta2`, `genai-proofreading:1.0.0-beta1`, `genai-rewriting:1.0.0-beta1`, `genai-image-description:1.0.0-beta1`, `genai-speech-recognition:1.0.0-alpha1`.

### 3.2 Summarization und Prompt: Sprachen und Limits

Laut Capacitor-ML-Kit-Wrapper-Dokumentation (Sekundärquelle, spiegelt die Google-Doku): Summarization unterstützt nur **Englisch, Japanisch, Koreanisch**; Eingabe "under 4,000 tokens (or about 3,000 English words)"; Ausgabe 1–3 Bullet Points; Voraussetzung: Gerät mit Gemini Nano, gesperrter Bootloader, Android API 26+. Prompt API: "currently only validated for English and Korean", Eingabe < 4.000 Tokens, "use cases that require a long output (more than 256 tokens) should be avoided", "the output is not moderated". Deutsch wird für Zusammenfassungen also (Stand der Wrapper-Doku) nicht unterstützt; die Prompt API wäre für Deutsch ungetestet.

### 3.3 Geräteliste

Aus einem GitHub-Issue (googlesamples/mlkit #944, Mai 2025), das die offizielle Liste zitiert: Pixel 9/9 Pro/9 Pro XL/9 Pro Fold; Honor Magic 7/7 Pro; iQOO 13; Motorola Razr 60 Ultra; OnePlus 13/13s; OPPO Find N5/X8/X8 Pro; POCO F7 Ultra; realme GT 7 Pro; Samsung Galaxy S25/S25+/S25 Ultra; vivo X200/X200 Pro; Xiaomi 15/15 Ultra. Spätere Issues zeigen Pixel 10 (Gemini Nano v3, Aug 2025) und Galaxy S26 (März 2026, Exynos SLSI2600; Prompt API dort mit `Null getService`-Fehler, die anderen APIs funktionieren). Nicht unterstützt laut Issues: Pixel 8 Pro (`606-FEATURE_NOT_FOUND`, Nov 2025), OnePlus 12 mit 12 GB RAM, Galaxy S22, GrapheneOS auf Pixel 9 Pro. Ein OnePlus Pad 3 (OxygenOS 16) meldete trotz Listung `FEATURE_NOT_FOUND` (März 2026).

Fazit: Gemini Nano ist 2026 ein Flaggschiff-Feature. Für ein DACH-Publikum mit vielen Samsung-A-Serie- und Mittelklasse-Geräten ist es nur als optionales Extra (z. B. englische Wochenzusammenfassung) sinnvoll.

### 3.4 ML Kit GenAI Speech Recognition (Alpha)

Aus dem offiziellen Sample (googlesamples/mlkit, `android/speech/.../SpeechRecognitionActivity.kt`): Client über `SpeechRecognition.getClient(speechRecognizerOptions { locale = ...; preferredMode = ... })`; Modi `MODE_BASIC` und `MODE_ADVANCED`; Audioquellen `AudioSource.fromMic()` (API 31+) und `AudioSource.fromPfd(ParcelFileDescriptor)` (PCM-Stream, damit auch Datei-Transkription); `checkStatus()` liefert `AVAILABLE/DOWNLOADABLE/DOWNLOADING/UNAVAILABLE`; `download()` mit `DownloadStarted/DownloadProgress/DownloadCompleted/DownloadFailed`; `startRecognition()` als Flow mit `PartialTextResponse`, `FinalTextResponse`, `CompletedResponse`, `ErrorResponse`.

Sprachen (Capacitor-Wrapper-README, Sekundärquelle): Basic Mode (API 31+, "traditional speech model"): en-US, fr-FR, it-IT, **de-DE**, es-ES, hi-IN, ja-JP, pt-BR, tr-TR, pl-PL, cmn-Hans-CN, ko-KR, cmn-Hant-TW, ru-RU, vi-VN. Advanced Mode ("currently only available on a very limited set of devices (e.g. Pixel 10)"): 21 Locales inkl. de-DE.

Praxisbefund (Issue #1066, 28.07.2026): Bei einem langen Sprach-Stream über `AudioSource.fromPfd()` wurden "only about 48 words from a 1,234-word expected transcript" erkannt; VAD-Clips als Einzelsessions brachten 119 Wörter, die meisten Clips endeten mit `ERROR_TYPE_NO_SPEECH_DETECTED`. Die API liefert nur `text`, keine Wort-Timestamps oder Confidences. Der Wrapper warnt: "breaking changes are expected". Für ein Produkt 2026 ist das ein Beobachtungskandidat, kein Fundament.

---

## 4. Open-Source-Engines für Android

### 4.1 whisper.cpp (MIT)

- Modelltabelle (README): tiny 75 MiB Disk / ~273 MB RAM; base 142 MiB / ~388 MB; small 466 MiB / ~852 MB; medium 1,5 GiB / ~2,1 GB; large 2,9 GiB / ~3,9 GB. Parameter (OpenAI model card): tiny 39 M, base 74 M, small 244 M, medium 769 M, large 1550 M, turbo 798 M. Integer-Quantisierung (q5/q8) halbiert Disk/RAM ungefähr.
- Android-Beispiel `examples/whisper.android`: "I recommend the tiny or base models for running on an Android device". Ein 2023er Issue (#1022) misst auf einem Samsung Note10 mit tiny.en für 3 s Audio 31 s (Standard-Build) bzw. 14,8 s nach Deaktivieren von R8-Shrinking – also RTF ≈ 5–10 auf einem 2019er Flaggschiff. Neuere Releases haben die Android-Performance verbessert (Release-Notes v1.9.3: "Improved inference performance in the Android example project"; Release-Datum laut Seite 20. August, Jahr aus Seitenfußzeile 2026 – prüfen).
- Deutsch-Qualität: Für large-v3 liegt die WER laut Open-ASR-Leaderboard-Rohdaten (multilingual.csv, Stand 26.03.2026) bei 5,25 % (CoVoST de) bzw. 3,27 % (FLEURS de); large-v3-turbo 8,64 % / 3,78 %. Für tiny/base/small liegen dort keine Deutsch-Zahlen vor; erfahrungsgemäß fällt Whisper bei kleinen Modellen für Deutsch deutlich stärker ab als für Englisch (mustVerify anhand des Whisper-Papers, Tabelle FLEURS).
- Bekannte Risiken: Halluzinations-/Wiederholungsschleifen bei langen Aufnahmen (Issues #3955, #3729, 2026), daher immer mit VAD-Segmentierung (z. B. Silero VAD) und Timeout arbeiten.

### 4.2 sherpa-onnx (Apache 2.0) – empfohlene Laufzeit

- Aktuelle Version v1.13.7 (Release-Datum 1. September 2026). Plattformen: Android, iOS, HarmonyOS, Desktop; Bindings u. a. Kotlin/Java, Swift, Dart/Flutter, C#. Android-AAR aus den Releases; ein Drittprojekt dokumentiert `sherpa-onnx-1.13.3.aar` mit 57 MB (alle ABIs) bzw. 4,3 MB nach Beschneidung auf arm64-v8a/x86_64.
- Unterstützte ASR-Familien: Whisper (tiny…large-v3, turbo, distil-Varianten, int8-Exporte), Moonshine, NeMo Parakeet/Canary, SenseVoice, Paraformer, Zipformer-Transducer (Streaming), Dolphin, TeleSpeech, Wenet, Qwen3-ASR (Release-Notes 1.13.x).
- **Parakeet TDT 0.6B v3 (int8)**: 25 europäische Sprachen inkl. Deutsch; Dateien `encoder.int8.onnx` 622 MB, `decoder.int8.onnx` 12 MB, `joiner.int8.onnx` 6,1 MB (≈ 640 MB). Deutsch-WER laut Leaderboard-Rohdaten 4,13 % (CoVoST) / 4,26 % (FLEURS) – auf Augenhöhe mit Whisper large-v3 bei rund einem Fünftel der Parameter. RAM: ein iOS-Nutzer misst 1,23 GB (Issue #2626, Sept. 2025). Bekannte Fehler: fehlende Wörter in einzelnen Fällen (Issue #2605). Lizenz des Modells (CC-BY-4.0 laut NVIDIA) muss auf der Modellkarte verifiziert werden (Hugging Face war nicht erreichbar).
- Kleine Streaming-Zipformer-Modelle in der sherpa-Doku gibt es nur für zh/en, nicht für Deutsch.

### 4.3 Moonshine (MIT für alle Streaming-Modelle)

- Modelle (docs/models/available-models.md, 2026): **German Small Streaming 123 M Parameter, WER 7,5 % (FLEURS + MLS)**; **German Tiny Streaming 34 M, WER 12,0 %**; English Medium Streaming 245 M, 6,65 %; English Small Streaming 123 M, 7,84 %; English Tiny Streaming 34 M, 12,0 %. Alle Streaming-Modelle sind MIT-lizenziert; nur die "legacy non-streaming" Modelle für sieben Nicht-Englisch-Sprachen unterliegen der nicht-kommerziellen "Moonshine Community License" (Registrierung für Firmen < 1 Mio. USD Umsatz, Attribution "Powered by Moonshine AI").
- Format: ONNX, konvertiert in memory-mappbares `.ort`; Android-Artefakt `ai.moonshine:moonshine-voice:0.1.5` (Quickstart). Moonshine ist zudem in sherpa-onnx integriert. Für ein Tagebuch ist Moonshine Small Streaming aktuell das beste Verhältnis aus Größe (≈ 123 M Parameter, quantisiert grob 150–250 MB je Sprache – Dateigröße prüfen), Deutsch-Qualität und Lizenzfreiheit.

### 4.4 Vosk (Apache 2.0)

- Deutsch: `vosk-model-small-de-0.15` 45 MB, WER 13,75 (Tuda-de); `vosk-model-de-0.21` 1,9 GB, WER 9,83; `vosk-model-de-tuda-0.6-900k` 4,4 GB, WER 9,48. Englisch: `vosk-model-small-en-us-0.15` 40 MB, WER 9,85 (LibriSpeech). Android: `com.alphacephei:vosk-android:0.3.75@aar` + `net.java.dev.jna:jna:5.18.1@aar`, minSdk 21.
- Bewertung: kleinste Downloads und älteste Android-Integration, aber keine Interpunktion/Großschreibung und die schlechteste Deutsch-Genauigkeit der Kandidaten. Nur als Ultra-Low-End-Fallback (Geräte mit < 3 GB RAM) sinnvoll.

### 4.5 Kyutai STT

`kyutai/stt-1b-en_fr` (Englisch/Französisch, 0,5 s Delay) und `stt-2.6b-en` (nur Englisch, 2,5 s Delay). Kein Deutsch, keine Android-Implementierung (nur MLX/Swift auf iPhone 16 Pro getestet). Für dieses Projekt nicht relevant.

### 4.6 Vergleich Deutsch-WER (verschiedene Testsets, nur Größenordnung)

| Engine/Modell | Parameter | Deutsch-WER | Testset | Lizenz |
|---|---|---|---|---|
| Whisper large-v3 | 1550 M | 3,27 % / 5,25 % | FLEURS / CoVoST | MIT |
| Whisper large-v3-turbo | 798 M | 3,78 % / 8,64 % | FLEURS / CoVoST | MIT |
| Parakeet TDT 0.6B v3 int8 | 600 M | 4,26 % / 4,13 % | FLEURS / CoVoST | CC-BY-4.0 (prüfen) |
| Moonshine German Small Streaming | 123 M | 7,5 % | FLEURS + MLS | MIT |
| Moonshine German Tiny Streaming | 34 M | 12,0 % | FLEURS + MLS | MIT |
| Vosk small-de-0.15 | – | 13,75 % | Tuda-de | Apache 2.0 |

---

## 5. Aufnahme im Hintergrund: Foreground Service `microphone`

- Manifest: `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MICROPHONE`, `android:foregroundServiceType="microphone"`, Laufzeit-Permission `RECORD_AUDIO`. Ab Target Android 14 wirft `startForeground()` ohne Typ eine `MissingForegroundServiceTypeException`; die Typen müssen zusätzlich in der Play Console (Policy > App content) deklariert werden.
- While-in-use-Regel: "you cannot create a `microphone` foreground service while your app is in the background and you cannot launch a `microphone` foreground service from a `BOOT_COMPLETED` receiver". Ab Android 14 gibt es sofort eine `SecurityException`, wenn der Dienst aus dem Hintergrund gestartet wird. Ausnahmen, die für das Tagebuch relevant sind: "The service starts by interacting with app widgets", "The service starts by interacting with a notification". Damit funktionieren "Aufnahme starten"-Buttons in Widget und Erinnerungs-Notification.
- Kein Zeitlimit für den Typ `microphone` (das 6-Stunden-Limit aus Android 15 gilt nur für `dataSync`/`mediaProcessing`). Aufnahme bei ausgeschaltetem Bildschirm ist damit möglich, solange der Dienst aus einem sichtbaren Zustand oder einer der Ausnahmen gestartet wurde.
- Android 17 (API 37, final; Doku-Stand 2026-09-02): "Background audio hardening" schränkt Wiedergabe, Audio-Focus und Lautstärke-APIs im Hintergrund ein; **Aufnahme ist nicht betroffen**. Neu sind App-Speicherlimits abhängig vom Geräte-RAM (`ApplicationExitInfo` mit "MemoryLimiter:AnonSwap") – wichtig für große ASR-Modelle – sowie die Pflicht, per `System.load()` geladene Native-Libs read-only zu halten.
- Für die Transkription nach der Aufnahme reicht bei 1–5 Minuten Audio meist ein `WorkManager`-Job (expedited) oder der laufende Service; erst bei Batch-Verarbeitung kommt `mediaProcessing` (6 h/24 h) in Frage.

---

## 6. Tägliche Erinnerung

- `POST_NOTIFICATIONS` (Android 13+): bei Neuinstallationen mit Target 33+ sind Notifications standardmäßig aus; die App muss den Dialog im Kontext auslösen.
- Exakte Alarme: `SCHEDULE_EXACT_ALARM` ist auf Android 13+ bei Neuinstallationen nicht vorab erteilt, vom Nutzer widerrufbar und geht bei Backup-Restore verloren; `USE_EXACT_ALARM` wird automatisch erteilt, unterliegt aber der Play-Policy (Weckeruhr, Timer, Kalender/Erinnerungs-Apps). Vor jedem `setExact*` `canScheduleExactAlarms()` prüfen und auf `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` reagieren.
- Doze: `set()`/`setExact()` werden verschoben, `setExactAndAllowWhileIdle()` und `setAlarmClock()` feuern auch im Doze. Inexakte Alternativen: `setWindow()` mit mindestens 10 Minuten Fenster, `setInexactRepeating()` mindestens 15 Minuten; `WorkManager`-PeriodicWork ebenfalls mindestens 15 Minuten und ausdrücklich nicht zeitgenau.
- Empfehlung: `setAlarmClock()` (Nutzer hat die Uhrzeit selbst gewählt, Wecker-Semantik, sichtbares Alarm-Icon) mit `USE_EXACT_ALARM` nur, wenn die Play-Policy-Einordnung als Erinnerungs-App abgesichert ist; sonst `SCHEDULE_EXACT_ALARM` anfragen und bei Ablehnung transparent auf `setWindow()` (±10 Minuten) zurückfallen.
- Hersteller-Akku-Killer (dontkillmyapp, Repo-Metadaten): Rangliste Huawei (Platz 1, Award 5), Xiaomi (2, 5), OnePlus (3, 5), Samsung (4, 5), Oppo (8, 4). Samsung: "After 3 days any unused app will not be able to start from background (e.g. alarms will not work anymore)"; "even when you remove an app from the restricted list, Samsung may re-add them later after a firmware update"; Entwicklerseite: "No known solution on dev end"; ab One UI 6.0 verspricht Samsung funktionierende Foreground Services für Apps mit Target Android 14. Xiaomi: Autostart-Freigabe, Akku-Sparer auf "No restrictions", ggf. "MIUI optimizations" deaktivieren. Die App braucht also einen Onboarding-Schritt "Erinnerungen zuverlässig machen" mit herstellerspezifischen Deep-Links (dontkillmyapp API v2 liefert JSON pro Hersteller).

---

## 7. Widgets, Quick Settings, Wear OS

- Widget: Klick auf eine Widget-Schaltfläche zählt als Nutzerinteraktion und ist ausdrücklich von den While-in-use-Beschränkungen ausgenommen; ein "Jetzt aufnehmen"-Widget kann also direkt den Microphone-FGS starten.
- Quick Settings Tile: `TileService` mit `BIND_QUICK_SETTINGS_TILE`, Label max. 18 Zeichen, ab API 33 `StatusBarManager.requestAddTileService()`; Aktionen über `startActivityAndCollapse(PendingIntent)`. Der Tile sollte eine (transparente) Activity öffnen, die den Service startet – so ist der Start "aus sichtbarem Zustand".
- Wear OS: Data Layer `Asset` ist laut Doku ausdrücklich für "a voice recording from another device" gedacht, Transport über Bluetooth; Play verlangt für Wear-OS-Apps Target API 35. Eine Uhr als Aufnahmegerät ist technisch machbar, aber v2-Thema.

---

## 8. Audio-Codec und Speicher

- Android kann seit API 29 Opus kodieren (`MediaRecorder.AudioEncoder.OPUS = 7` mit `OutputFormat.OGG = 11`; alternativ `MediaCodec` in WebM/MP4). AAC-LC ist auf allen Versionen verfügbar (MPEG-4/M4A). `setPrivacySensitive(true)` verhindert gleichzeitiges Mithören durch andere Apps.
- Rechenbeispiel (eigene Kalkulation): Opus mono 24 kbit/s → 0,18 MB/Minute → 5 Minuten/Tag ≈ 0,9 MB/Tag ≈ 330 MB/Jahr. AAC-LC 64 kbit/s → 0,48 MB/Minute ≈ 880 MB/Jahr. Empfehlung: Opus 16–24 kbit/s, 16 kHz mono in OGG; zusätzlich 16-kHz-PCM nur transient für die ASR-Pipeline. Für den QR-initiierten Gerätetransfer ist Opus auch das kompaktere Format.
- Play-Rahmenbedingungen: Target API 36 seit 31.08.2026 Pflicht für neue Apps/Updates (Verlängerung bis 01.11.2026 beantragbar); ab 01.02.2027 müssen Apps mit Target 35+ 16-KB-Seiten unterstützen (NDK r28+, AGP 8.5.1+, `zipalign -P 16`). Das betrifft alle nativen ASR-Bibliotheken.
- Modellauslieferung: Play Asset Delivery bietet `install-time`, `fast-follow` und `on-demand`; `fast-follow`/`on-demand` zählen nicht zur angezeigten App-Größe. Ob die App dafür die `INTERNET`-Permission benötigt, geht aus der Doku nicht hervor (mustVerify); Play Core läuft im Play-Store-Prozess, was den Verzicht auf `INTERNET` in der eigenen App plausibel macht.

---

## 9. Empfehlung und Mindestanforderungen

**Architektur "Privacy by Construction":**
1. Aufnahme immer lokal via `AudioRecord` (16 kHz mono PCM) im Microphone-FGS; parallel Opus/OGG schreiben.
2. Transkription nach Aufnahmeende (oder streaming während der Aufnahme) mit **sherpa-onnx** als Laufzeit und **Moonshine German/English Small Streaming** als Standardmodelle (MIT, je 123 M Parameter, Deutsch-WER 7,5 %). Optionales "Hohe Genauigkeit"-Paket: **Parakeet TDT 0.6B v3 int8** (≈ 640 MB, Deutsch-WER ≈ 4 %, 25 Sprachen, ~1,2 GB RAM) für Geräte ab 6 GB RAM.
3. App ohne `android.permission.INTERNET` ausliefern; Modelle als Play-Asset-Packs (`fast-follow` für das Standardpaket, `on-demand` für Parakeet). Das ist das einzige technisch überprüfbare "es geht nichts ins Netz".
4. Fallback-Kette: (a) Moonshine Tiny Streaming (34 M) auf Geräten mit < 4 GB RAM oder wenn Small zu langsam ist; (b) optional vom Nutzer aktivierbar: `createOnDeviceSpeechRecognizer` mit `RecognitionSupport`-Prüfung auf `de-DE`/`en-US` – mit klarem Hinweis, dass hier eine Systemkomponente von Google/OEM arbeitet; (c) ML Kit GenAI Speech nur hinter einem Feature-Flag beobachten.
5. Zusammenfassungen: nicht auf Gemini Nano bauen (Deutsch nicht unterstützt, Flaggschiff-only). Für v1 reichen regelbasierte Features (Wortzahl, Stichwörter, Stimmungs-Tags per lokalem Klassifikator).

**Geräte-Mindestanforderungen (Vorschlag, im Test zu bestätigen):**
- minSdk 31 (Android 12): deckt `createOnDeviceSpeechRecognizer`, moderne FGS-Regeln und den Play-Zeitrahmen ab; API 33+ für `triggerModelDownload`/`EXTRA_SEGMENTED_SESSION` per Laufzeitprüfung.
- arm64-v8a only (32-Bit-Builds von sherpa-onnx sind fehleranfällig, Issues #3508/#3533 2026), 4 GB RAM für Moonshine Small, 6 GB für Parakeet; 1 GB freier Speicher für das Premium-Modell.
- Performance-Ziel: RTF ≤ 0,5 auf einem Snapdragon-6/7-Klasse-Gerät für Moonshine Small; eigene Benchmarks nötig, weil belastbare öffentliche Android-Zahlen fehlen (whisper.cpp-Issues zeigen 2023 RTF 5–10 für tiny auf Note10; Streaming-Encoder wie Moonshine/Zipformer sind hier klar im Vorteil).

**Offene Prüfpunkte:** Verfügbarkeit von `isOnDeviceRecognitionAvailable()` auf Samsung/Xiaomi; tatsächliche `.ort`-Dateigrößen und RAM von Moonshine Small auf Android; Play-Policy-Einordnung für `USE_EXACT_ALARM`; INTERNET-Permission bei Play Asset Delivery; Whisper-small/base-Deutsch-WER aus dem Whisper-Paper; Parakeet-Modelllizenz.

---

## Quellen

- SpeechRecognizer (AOSP-Quelle): https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/main/core/java/android/speech/SpeechRecognizer.java
- RecognizerIntent (AOSP-Quelle): https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/main/core/java/android/speech/RecognizerIntent.java
- RecognitionSupport (AOSP-Quelle): https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/main/core/java/android/speech/RecognitionSupport.java
- API-Level-Nachweis (API-Jar-Mirror, android-31/33): https://github.com/Reginer/aosp-android-jar
- Pixel-Overlay `config_defaultOnDeviceSpeechRecognitionService` (Beispiel): https://github.com/NeutronBlobs/android_vendor_google_devices (raven/overlays/product.txt)
- Gemini Nano / ML Kit GenAI Übersicht: https://developer.android.com/ai/gemini-nano
- ML Kit GenAI Speech Sample: https://github.com/googlesamples/mlkit/tree/master/android/speech
- ML Kit GenAI Device-/Fehler-Issues: https://github.com/googlesamples/mlkit/issues/944 , /issues/985 , /issues/1021 , /issues/1063 , /issues/1066
- Capacitor-Wrapper-Dokumentation (Sprachen/Limits): https://github.com/capawesome-team/capacitor-mlkit (packages/genai-speech-recognition, genai-summarization, genai-prompt)
- whisper.cpp: https://github.com/ggml-org/whisper.cpp ; Android-Beispiel: https://github.com/ggml-org/whisper.cpp/tree/master/examples/whisper.android ; Issue #1022: https://github.com/ggml-org/whisper.cpp/issues/1022 ; Releases: https://github.com/ggml-org/whisper.cpp/releases
- Whisper Model Card: https://github.com/openai/whisper/blob/main/model-card.md
- Open ASR Leaderboard Rohdaten (multilingual.csv): https://raw.githubusercontent.com/huggingface/open_asr_leaderboard/main/scripts/data/multilingual.csv
- sherpa-onnx: https://github.com/k2-fsa/sherpa-onnx ; Releases: https://github.com/k2-fsa/sherpa-onnx/releases ; Parakeet-v3-Doku: https://raw.githubusercontent.com/k2-fsa/sherpa/master/docs/source/onnx/pretrained_models/offline-transducer/nemo/parakeet-tdt-0.6b-v3.rst ; Issues #2626, #2605, #3508
- Moonshine: https://github.com/moonshine-ai/moonshine ; Modelle: https://raw.githubusercontent.com/moonshine-ai/moonshine/main/docs/models/available-models.md ; Genauigkeit: https://raw.githubusercontent.com/moonshine-ai/moonshine/main/docs/models/accuracy.md ; Lizenz: https://raw.githubusercontent.com/moonshine-ai/moonshine/main/LICENSE ; Quickstart: https://raw.githubusercontent.com/moonshine-ai/moonshine/main/docs/quickstart.md
- Vosk: https://github.com/alphacep/vosk-api ; Modellliste (Quelle der Website): https://raw.githubusercontent.com/alphacep/vosk-space/master/models.md ; Android-Demo build.gradle: https://raw.githubusercontent.com/alphacep/vosk-android-demo/master/app/build.gradle
- Kyutai STT: https://github.com/kyutai-labs/delayed-streams-modeling
- FGS-Typen: https://developer.android.com/develop/background-work/services/fgs/service-types ; Hintergrundstart/While-in-use: https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start ; Android 14 Typpflicht: https://developer.android.com/about/versions/14/changes/fgs-types-required ; Android 15: https://developer.android.com/about/versions/15/behavior-changes-15
- Android 16: https://developer.android.com/about/versions/16/behavior-changes-all ; Android 17: https://developer.android.com/about/versions/17/behavior-changes-all , https://developer.android.com/about/versions/17/behavior-changes-17 , https://developer.android.com/about/versions/17/changes/bg-audio
- Alarme: https://developer.android.com/develop/background-work/services/alarms/schedule ; WorkManager: https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work ; Notification-Permission: https://developer.android.com/develop/ui/views/notifications/notification-permission
- dontkillmyapp (Repo): https://github.com/urbandroid-team/dont-kill-my-app (_vendors/*.md, _vendors-content/samsung/*.md, _vendors-content/xiaomi/user.md)
- Quick Settings: https://developer.android.com/develop/ui/views/quicksettings-tiles ; Wear OS Data Layer: https://developer.android.com/training/wearables/data/data-layer
- Codecs: https://developer.android.com/media/platform/supported-formats ; MediaRecorder-Quelle: https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/main/media/java/android/media/MediaRecorder.java
- Play Target-API: https://developer.android.com/google/play/requirements/target-sdk ; 16 KB: https://developer.android.com/guide/practices/page-sizes ; Play Asset Delivery: https://developer.android.com/guide/playcore/asset-delivery
