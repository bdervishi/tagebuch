# Technik-Recherche iOS: 100 % lokale Sprachtranskription für ein Sprach-Tagebuch (Stand 3. September 2026)

Blickwinkel: `technik-ios`. Ziel ist eine belastbare Empfehlung, wie eine vollständig lokale Transkription in Deutsch und Englisch auf iOS heute umgesetzt wird, mit Fallbacks und Gerätemindestanforderungen. Quellenlage: Apple-Developer-Dokumentation (über den JSON-Endpunkt `developer.apple.com/tutorials/data/documentation/...`, Abruf 3. 9. 2026), WWDC25-Session-Transkripte, Apple Developer Forums, GitHub-Repositories (WhisperKit/argmax-oss-swift, whisper.cpp, FluidAudio, VoiceInk). Nicht erreichbar aus der Sandbox waren apple.com, support.apple.com, huggingface.co, argmaxinc.com, machinelearning.apple.com, macstories.net, Wikipedia und Nachrichtenseiten; entsprechende Zahlen sind mit `mustVerify` markiert.

Wichtiger Zeitkontext: iOS 26 ist die aktuell ausgelieferte Version; die Apple-Dokumentation kennzeichnet bereits iOS 27-APIs als „beta" (z. B. `CaptureInputSequenceProvider`, `PrivateCloudComputeLanguageModel`, Core AI). Apple hat am 9. 9. 2025 die App-Store-Einreichung für iOS 26 geöffnet; ein analoger Termin für iOS 27 ist für Mitte September 2026 zu erwarten, war aber am 3. 9. 2026 noch nicht angekündigt.

---

## 1. Speech-Framework alt: `SFSpeechRecognizer` (iOS 10+, On-Device seit iOS 13)

- `SFSpeechRecognitionRequest.requiresOnDeviceRecognition` (iOS 13+): „Set this property to `true` to prevent an SFSpeechRecognitionRequest from sending audio over the network. However, on-device requests won't be as accurate." Die Einstellung wird nur beachtet, wenn `SFSpeechRecognizer.supportsOnDeviceRecognition == true` ist. Quelle: https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition
- Dokumentierte Limits: „Plan for a one-minute limit on audio duration ... the framework stops speech recognition tasks that last longer than one minute." Zusätzlich Tages-/Gerätelimits, weil der Dienst netzwerkbasiert konzipiert ist. Quelle: https://developer.apple.com/documentation/speech/sfspeechrecognizer
- Sprachabdeckung: „Speech recognition supports the same locales that are supported by the keyboard's dictation feature." Welche davon offline funktionieren, hängt vom Gerät und den installierten Diktat-Sprachpaketen ab. Quelle: https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportedlocales()
- Bewertung: Für ein Tagebuch mit Einträgen von 1–5 Minuten ist die Ein-Minuten-Grenze ein K.-o.-Kriterium; außerdem musste der Nutzer bisher Siri/Diktat für die Sprache aktivieren. Der Apple-Sprecher in WWDC25-Session 277 bestätigt: SFSpeechRecognizer „relied on the user to add languages". Ein Forumsbericht vom August 2026 zeigt zudem Initialisierungsfehler (`kLSRErrorDomain Code=300`) auf iOS-26.4/26.5-Simulatoren. Quelle: https://developer.apple.com/forums/thread/840302

## 2. Speech-Framework neu: `SpeechAnalyzer` + `SpeechTranscriber` (iOS 26)

### API-Architektur
- `SpeechAnalyzer` (final actor) verwaltet eine Analyse-Session; Module wie `SpeechTranscriber`, `DictationTranscriber` und `SpeechDetector` (VAD) werden angehängt. Audio kommt als `AsyncSequence<AnalyzerInput>`; Ergebnisse kommen als `AsyncSequence` von `Result` mit `AttributedString`, `audioTimeRange` (CMTimeRange) und `ConfidenceAttribute` (0–1). Quelle: https://developer.apple.com/documentation/speech/speechanalyzer
- Presets für `SpeechTranscriber`: `transcription`, `transcriptionWithAlternatives`, `timeIndexedTranscriptionWithAlternatives`, `progressiveTranscription` (volatileResults + fastResults), `timeIndexedProgressiveTranscription`. `fastResults` ist dokumentiert als „faster but also less accurate". Quelle: https://developer.apple.com/documentation/speech/speechtranscriber/preset
- Einzige Text-Option: `etiquetteReplacements` (Schimpfwort-Redaktion). Quelle: https://developer.apple.com/documentation/speech/speechtranscriber/transcriptionoption
- Kein dokumentiertes Längenlimit. Die WWDC-Session nennt als Zielanwendung „long-form and distant audio, such as lectures, meetings, and conversations". Quelle: https://developer.apple.com/videos/play/wwdc2025/277/
- iOS 27 (beta) ergänzt `CaptureInputSequenceProvider` (Mikrofon direkt) und `AssetInputSequenceProvider` (Datei) sowie `AnalyzerInputConverter` („Speech updates", Juni 2026). Quelle: https://developer.apple.com/documentation/speech/captureinputsequenceprovider

### Offline-Fähigkeit und Modellverwaltung
- Zitat WWDC25-277: „Transcription is entirely on device but the models need to be fetched." Die Modelle liegen im Systemspeicher: „The model is retained in system storage and does not increase the download or storage size of your application, nor does it increase the run-time memory size. It operates outside of your application's memory space."
- `AssetInventory`: Assets werden „downloaded from Apple's servers and managed by the system", nach Installation systemweit geteilt und automatisch aktualisiert. „The system makes a certain number of locale-specific asset reservations available to your app". `maximumReservedLocales` „may vary between devices according to storage space". Ungenutzte Assets können vom System wieder abgemeldet werden („may unsubscribe your app from assets that haven't been used in a while"). Quelle: https://developer.apple.com/documentation/speech/assetinventory
- Konsequenz für „keine Server": Der einmalige Modell-Download von Apple-Servern ist unvermeidlich (wie bei Diktat-Sprachpaketen). Audio und Text verlassen das Gerät nie. Die App muss den Erstdownload (WLAN) im Onboarding erklären und den Fall „Asset nicht mehr vorhanden" abfangen.

### Sprachen inkl. Deutsch/Schweizerdeutsch
- Apple veröffentlicht keine statische Liste; `SpeechTranscriber.supportedLocales` ist die Wahrheit („empty if the device does not support the transcriber"). Quelle: https://developer.apple.com/documentation/speech/speechtranscriber/supportedlocales
- Empirische Liste (von der Open-Source-App VoiceInk auf macOS 26.4 abgefragt, Commit 8f089cb, 2026): yue-CN, zh-CN, zh-HK, zh-TW, en-AU/CA/IN/IE/NZ/SG/ZA/GB/US, fr-BE/CA/FR/CH, **de-AT, de-DE, de-CH**, it-IT, it-CH, ja-JP, ko-KR, pt-BR, pt-PT, es-CL/MX/ES/US. Quelle: https://github.com/Beingpax/VoiceInk/blob/8f089cb4bf2c9c2f217b0cc0af909d9052ff6288/VoiceInk/Features/ModelLibrary/Models/LanguageDictionary.swift
- Interpretation: `de-CH` ist ein Standarddeutsch-Modell mit Schweizer Orthografie/Vokabular (z. B. „ss" statt „ß"), **kein Dialekt-Modell für Schweizerdeutsch/Mundart**. Für Mundart gibt es weder von Apple noch von Whisper (kein `gsw`-Training) eine belastbare Lösung; Nutzer müssen Hochdeutsch sprechen. mustVerify durch Test auf Gerät.
- Zuverlässigkeit der API: Apple bestätigte im Januar 2026, dass Arabisch fälschlich als „supported" gelistet war („SpeechTranscriber erroneously listed Arabic as 'supported'. It actually wasn't."). Entwicklerempfehlung: „a quick validation transcription per locale before shipping rather than trusting the supportedLocale API". Quelle: https://developer.apple.com/forums/thread/797835
- Locale-Format-Falle: `Locale.current` liefert `en_US` (Unterstrich), die Allocation-Tabelle nutzt `en-US`; Fehler „Cannot use modules with unallocated locales". Apple-Empfehlung: immer `SpeechTranscriber.supportedLocale(equivalentTo:)` verwenden. Quelle: https://developer.apple.com/forums/thread/790108

### Hardware-Untergrenze
- Apple: „available for all platforms but watchOS with certain hardware requirements" (WWDC25-277). Die konkrete Grenze ist nicht dokumentiert.
- Forumsbefund (Nov 2025–März 2026): `isAvailable == false` und leere `supportedLocales` auf iPhone 11, 11 Pro, 11 Pro Max, iPhone SE (2. Gen.) und im Simulator; funktioniert auf iPhone 12 bis 17. Plausible Erklärung im Thread: 8-Kern-Neural-Engine (A13) reicht nicht, 16-Kern-ANE (ab A14) erforderlich. Kein Apple-Mitarbeiter hat dies offiziell bestätigt. Quelle: https://developer.apple.com/forums/thread/806765
- Performance-Hinweis aus dem Forum (März 2026): STT-Latenz ~2,1 s pro Turn selbst mit `fastResults`, verglichen mit 0,4 s für Foundation Models; für Tagebuch-Batch-Transkription irrelevant, für Live-Anzeige relevant.

### `DictationTranscriber` als Fallback
- „similar to system dictation features and compatible with older devices". Nutzt dieselben Modelle wie das System-Diktat bzw. SFSpeechRecognizer im On-Device-Modus; unterstützt keine Sprachen, die SFSpeechRecognizer nur per Netz konnte. Presets `longDictation`/`progressiveLongDictation`/`timeIndexedLongDictation` für „more than a minute of audio" – die alte Ein-Minuten-Grenze entfällt damit auch im Fallback. Nutzer müssen keine Siri-/Diktat-Sprache mehr manuell aktivieren („you will NOT need to tell your users to go into Settings"). Nicht auf tvOS/watchOS. Quelle: https://developer.apple.com/documentation/speech/dictationtranscriber

### VAD und Kontext
- `SpeechDetector`: Voice Activity Detection, spart Energie bei Stille, nur zusammen mit einem Transcriber-Modul; `SensitivityLevel.medium` empfohlen. Quelle: https://developer.apple.com/documentation/speech/speechdetector
- `AnalysisContext.contextualStrings` (Eigennamen) und `SFSpeechLanguageModel` (Custom Vocabulary) sind für `DictationTranscriber` dokumentiert; ein Forumsthread (Apr 2026) bemängelt fehlende Dokumentation und geringen Effekt für `SpeechTranscriber`.

## 3. Whisper-basierte Alternativen

### WhisperKit (Argmax, jetzt „argmax-oss-swift")
- MIT-Lizenz, Swift Package, `platforms: iOS 16, macOS 13`; aktuelle Releases v1.0.0 (1. 5. 2026, Umbenennung in Argmax Open-Source SDK, Swift 6) und v1.1.0 (6. 8. 2026: inkrementelles Laden, „70%+ savings for 3-hour audio input"). Quelle: https://github.com/argmaxinc/WhisperKit/releases
- Empfohlenes Modell: `large-v3-v20240930_626MB` („Recommended across iOS and macOS for maximum accuracy"), d. h. ein komprimiertes Large-v3-Turbo mit 626 MB Download. Quelle: https://github.com/argmaxinc/WhisperKit (README)
- Gerätematrix aus `Models.swift` (`fallbackModelSupportConfig`, Repo-Version 0.4): A12/A13 (iPhone 11/12 Modellkennungen = iPhone XS/XR/11, Watch 7/8): default `tiny`, max `base`. A14 (iPhone 12): default `base`, max `small`. A15 (iPhone 13): default `base`, bis `large-v3-v20240930_626MB`. A16/A17 Pro/A18 (iPhone 14 Pro/15/16): default `base`, bis `large-v3_turbo_954MB`. Maintainer-Regel: „A14 and newer can run all models", „iOS can run models below 1 GB". Quelle: https://github.com/argmaxinc/WhisperKit/blob/main/Sources/WhisperKit/Core/Models.swift und https://github.com/argmaxinc/argmax-oss-swift/discussions/391
- Speicher: Apple-Watch-Benchmark (Series 11, tiny.en): 19,2 s Modell-Ladezeit, 4,2 s für 5 s Audio, +43 MB RAM. Auf iPhone sind Ladezeiten für 600-MB-Modelle im zweistelligen Sekundenbereich beim Erststart zu erwarten (ANE-Kompilierung); mustVerify. Quelle: https://github.com/argmaxinc/argmax-oss-swift/discussions/437
- Deutsch-Qualität: Issue #528 (23. 8. 2026) berichtet für large-v2 via WhisperKit „Wrong language detection, Skipped sentences, Straight up hallucinations" bei deutschen Aufnahmen im Vergleich zu PyTorch-Whisper. Empfehlung: Sprache explizit setzen statt Auto-Detect, VAD-Chunking nutzen. Quelle: https://github.com/argmaxinc/argmax-oss-swift/issues/528
- Kommerziell: „Argmax Pro SDK" (Echtzeit, Speaker, Custom Vocabulary, Android) ist separat lizenziert; Preise nicht abrufbar (argmaxinc.com blockiert), mustVerify.

### whisper.cpp
- MIT, aktuelles Release v1.9.3 (20. 8. 2026), XCFramework für iOS/visionOS/tvOS/macOS. Quelle: https://github.com/ggml-org/whisper.cpp/releases
- Speicherbedarf (README): tiny 75 MiB/~273 MB RAM, base 142 MiB/~388 MB, small 466 MiB/~852 MB, medium 1,5 GiB/~2,1 GB, large 2,9 GiB/~3,9 GB. Quantisiert: `large-v3-turbo-q5_0` 547 MiB, `large-v3-q5_0` 1,1 GiB. Quelle: https://github.com/ggml-org/whisper.cpp und https://github.com/ggml-org/whisper.cpp/blob/master/models/README.md
- Core ML: Encoder auf der ANE „more than x3 faster compared with CPU-only"; erster Lauf langsam (ANE-Kompilierung). Praxisprobleme: Speichercrash auf iPhone mit Core ML (Issue #775), wachsender Cache („Documents and Data" bis > 4 GB, Issue #2160), ANE-Fehler auf M4/macOS 26.4 (Issue #3702, März 2026). Quelle: https://github.com/ggml-org/whisper.cpp/issues/2160
- Einordnung: Auf iPhone realistisch `small` (multilingual, ~850 MB RAM) oder `large-v3-turbo-q5_0`; `medium`/`large` sind für Hintergrund-Transkription auf iPhones mit 6–8 GB RAM riskant (Jetsam). Deutsch-WER von Whisper large-v3 ist gut (Whisper-README verweist auf Common Voice 15/FLEURS-Auswertung), konkrete Zahl mustVerify. Quelle: https://github.com/openai/whisper

### FluidAudio / Parakeet (Alternative)
- Parakeet TDT v3 (0,6B, Apache/MIT-Modelle) mit 25 europäischen Sprachen inkl. Deutsch, läuft auf der ANE; Herstellerangabe „~190x RTF on M4 Pro". Auf iPhone (A16) gibt es dokumentierte INT8-Ladefehler (Issue #828), fp16 empfohlen. Quelle: https://github.com/FluidInference/FluidAudio

## 4. Foundation Models Framework (On-Device-LLM für Zusammenfassungen)

- iOS 26+, nur auf Apple-Intelligence-fähigen Geräten und in unterstützten Regionen; `SystemLanguageModel.default.availability` liefert `.deviceNotEligible`, `.appleIntelligenceNotEnabled`, `.modelNotReady`. Quelle: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel
- Modell: „3 billion parameters, each quantized to 2 bits" (WWDC25-286). Kontextfenster: „4096 tokens per session ... a token typically represents three to four characters" (Latein-Alphabet). Fehler `contextSizeExceeded`; `contextSize`-Property ab 26.4 rückportiert. Quellen: https://developer.apple.com/videos/play/wwdc2025/286/ und https://developer.apple.com/documentation/foundationmodels/managing-the-context-window
- Drei Modellversionen: 26.0–26.3, 26.4, 27.0 – Prompts müssen pro Version getestet werden. Quelle: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel
- Sprachen: „the same model understands and generates text in any language that Apple Intelligence supports"; Prüfung per `supportsLocale(_:)`; Fehler `unsupportedLanguageOrLocale`. Empfohlene Instruktion: „The person's locale is de_DE." plus „You MUST respond in German." Quelle: https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models
- Apple-Intelligence-Sprachen/Geräte: Apple verweist auf Support-Artikel 121115 (nicht abrufbar). Nach Vorwissen: Deutsch seit iOS 18.4 (April 2025); Geräte iPhone 15 Pro/Pro Max, alle iPhone 16/17, iPads/Macs mit M1+ bzw. A17 Pro. **mustVerify**. Quelle: https://support.apple.com/121115
- Guardrails: Standard blockiert „self-harm, violence, and adult materials"; `permissiveContentTransformations` erlaubt Transformation (z. B. Zusammenfassen) auch heikler Eingaben. Für ein Tagebuch (Emotionen, Gesundheit, Krisen) sind Refusals einzuplanen; das Framework wirft `guardrailViolation` oder `refusal`. Quelle: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output
- Empfohlene Nutzung: Tageszusammenfassung in 2–3 Sätzen, Stimmungs-Tags via `@Generable`, Titelvorschläge. Lange Transkripte (> ca. 12 000 Zeichen) müssen gechunkt werden (Apple-Rezept „Split large tasks across multiple sessions").
- Ausblick iOS 27: `PrivateCloudComputeLanguageModel` (32K Kontext, Tageslimit, managed Entitlement `com.apple.developer.private-cloud-compute`; kostenlos für Small-Business-Program-Teilnehmer < 2 Mio. Downloads laut developer.apple.com/apple-intelligence). Für ein „keine Server"-Versprechen ausdrücklich nicht zu nutzen. Core AI (iOS 27 beta) erlaubt eigene ~0,6B-Modelle im selben `LanguageModelSession`-API für Geräte ohne Apple Intelligence. Quellen: https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute und https://developer.apple.com/documentation/coreai

## 5. Aufnahme, Hintergrund, Systemintegration

- Mikrofon: `NSMicrophoneUsageDescription` Pflicht („the app exits" ohne String); `AVAudioApplication.requestRecordPermission()`. Ohne Erlaubnis werden Nullsamples aufgezeichnet. Quelle: https://developer.apple.com/documentation/avfaudio/avaudioapplication/requestrecordpermission(completionhandler:)
- Hintergrundaufnahme: `UIBackgroundModes = audio` plus Session-Kategorie `.record`/`.playAndRecord`; iOS zeigt den orangen Aufnahme-Indikator. Quelle: https://developer.apple.com/documentation/xcode/configuring-background-execution-modes
- Action Button / Control Center / Lock Screen: Controls (`ControlWidgetButton`) mit `AppIntent`; `authenticationPolicy` standardmäßig `alwaysAllowed` („including when the device is locked"). Für Aufnahme-Intents gilt `AudioRecordingIntent`: „you must start a Live Activity when you begin the audio recording and keep it active as long as you record audio. If you don't start a Live Activity, the audio recording stops." Live Activity aus dem Hintergrund nur via `LiveActivityIntent`. Quellen: https://developer.apple.com/documentation/appintents/audiorecordingintent , https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system , https://developer.apple.com/documentation/appintents/liveactivityintent
- Live Activities: max. 8 h aktiv, bis 12 h auf dem Lock Screen; erscheinen auf Apple Watch im Smart Stack, in CarPlay und in der Mac-Menüleiste. Quelle: https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
- Widgets: `accessoryCircular/Rectangular/Inline` für Lock Screen und Watch, `systemSmall…` für Home Screen. Quelle: https://developer.apple.com/documentation/widgetkit/widgetfamily
- Lokale Erinnerungen: `UNCalendarNotificationTrigger(dateMatching:repeats:true)` für „täglich um HH:MM". Interruption Level `timeSensitive` „breaks through system notification controls" (Fokus, Zusammenfassung), benötigt die Capability `com.apple.developer.usernotifications.time-sensitive`; der Nutzer kann Time-Sensitive pro App abschalten. Die historische Grenze von 64 anstehenden lokalen Benachrichtigungen ist in den aktuellen Docs nicht mehr genannt (mustVerify), für eine einzelne wiederholende Erinnerung irrelevant. Quellen: https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger , https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive
- Apple Watch: `AVAudioRecorder` seit watchOS 4; **keine Transkriptions-API auf watchOS** (`SpeechTranscriber`, `DictationTranscriber`, `SFSpeechRecognizer` sind nicht für watchOS deklariert). Hintergrund-Audio auf der Watch gilt nur für Wiedergabe; für längere Aufnahme im Vordergrund eignet sich eine Extended-Runtime-Session (Mindfulness: 1 h, Self Care: 10 min). Transfer per `WCSession.transferFile(_:metadata:)` läuft asynchron im Hintergrund, nicht im Simulator testbar. Quellen: https://developer.apple.com/documentation/avfaudio/avaudiorecorder , https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions , https://developer.apple.com/documentation/watchconnectivity/wcsession/transferfile(_:metadata:)
- Journaling Suggestions: iOS 17.2+, iPadOS 26+; Entitlement `com.apple.developer.journal.allow` (Capability in Xcode, keine Sonderfreigabe). Liefert nach Nutzerauswahl im System-Picker: Photo, Video, LivePhoto, Workout(-Group), Contact, Location(-Group), Song, Podcast, GenericMedia, MotionActivity, Reflection (Reflexionsfragen), StateOfMind (Health), EventPoster. „your app can't access the details for a suggestion until after a person chooses to share them". Quelle: https://developer.apple.com/documentation/journalingsuggestions
- Core ML / Neural Engine: `MLComputeUnits.all` nutzt ANE; `cpuOnly` empfohlen „if your app might run in the background". Für Hintergrund-Transkription mit Whisper ist die ANE-Verfügbarkeit im Hintergrund also nicht garantiert – ein Argument für Apples System-Transcriber, der außerhalb des App-Prozesses läuft. Quelle: https://developer.apple.com/documentation/coreml/mlcomputeunits

## 6. Empfehlung (Architektur)

1. **Primärpfad: `SpeechTranscriber` (iOS 26+)** mit Preset `.transcription` (Batch nach Aufnahme) oder `.progressiveTranscription` (Live-Vorschau), Locale via `supportedLocale(equivalentTo:)` aus de-DE/de-AT/de-CH/en-*; `SpeechDetector` aktivieren; Erstdownload der Assets im Onboarding; pro Locale ein 3-Sekunden-Validierungslauf. Vorteile: kein App-Speicher, kein RAM-Overhead, Apple-Updates, keine Ein-Minuten-Grenze, Zeitstempel/Konfidenzen.
2. **Fallback 1: `DictationTranscriber`** auf iOS-26-Geräten ohne 16-Kern-ANE (iPhone 11-Serie, SE 2) – gleicher API-Stil, Preset `.longDictation`.
3. **Fallback 2 (optional, Premium): WhisperKit `large-v3-v20240930_626MB`** für Nutzer, die maximale Deutsch-Qualität oder iOS 16–18 wollen; Sprache fest setzen, `chunkingStrategy: .vad`, nur im Vordergrund oder mit `audio`-Background-Mode, Modell-Download als opt-in.
4. **Mindestanforderung für den Store:** iOS 26, empfohlen iPhone 12 oder neuer (A14, 16-Kern-ANE); Zusammenfassungen nur auf Apple-Intelligence-Geräten (iPhone 15 Pro+, mustVerify) und mit Nutzer-Opt-in, sonst Feature ausblenden.
5. **Aufnahme-Einstiege:** Control (Lock Screen/Action Button) → `LiveActivityIntent` + `AudioRecordingIntent` → Live Activity mit Timer und Stopp-Button; tägliche Erinnerung als wiederholender Kalender-Trigger, optional Time-Sensitive nach Nutzerwahl.
6. **Nicht versprechen:** Schweizerdeutsch-Mundart, Offline-Betrieb ohne jemals eine Netzverbindung (Modell-Download), Transkription auf der Watch.

## Offene Fragen
- Offizielle Hardware-Untergrenze und Locale-Liste für `SpeechTranscriber` (Apple dokumentiert beides nicht).
- Gemessene Deutsch-WER von `SpeechTranscriber` vs. Whisper large-v3 auf identischem Tagebuch-Audio.
- Verhalten von `AssetInventory`, wenn das System Assets bei Nichtnutzung wieder entfernt (Tagebuch wird evtl. wochenlang nicht genutzt).
- Guardrail-Refusal-Quote des Foundation-Models bei typischen Tagebuchthemen (Trauer, Krankheit) in Deutsch.
- Ob iOS 27 die Locale-Liste (z. B. nl, pl, sv) erweitert; Apple: „with more to come".

## Quellenliste
1. https://developer.apple.com/documentation/speech/speechanalyzer
2. https://developer.apple.com/documentation/speech/speechtranscriber
3. https://developer.apple.com/documentation/speech/speechtranscriber/preset
4. https://developer.apple.com/documentation/speech/speechtranscriber/supportedlocales
5. https://developer.apple.com/documentation/speech/assetinventory
6. https://developer.apple.com/documentation/speech/assetinventory/maximumreservedlocales
7. https://developer.apple.com/documentation/speech/dictationtranscriber
8. https://developer.apple.com/documentation/speech/speechdetector
9. https://developer.apple.com/documentation/speech/sfspeechrecognizer
10. https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition
11. https://developer.apple.com/documentation/speech/captureinputsequenceprovider
12. https://developer.apple.com/videos/play/wwdc2025/277/
13. https://developer.apple.com/forums/thread/806765
14. https://developer.apple.com/forums/thread/797835
15. https://developer.apple.com/forums/thread/790108
16. https://developer.apple.com/forums/thread/840302
17. https://github.com/Beingpax/VoiceInk/blob/8f089cb4bf2c9c2f217b0cc0af909d9052ff6288/VoiceInk/Features/ModelLibrary/Models/LanguageDictionary.swift
18. https://github.com/argmaxinc/WhisperKit
19. https://github.com/argmaxinc/WhisperKit/releases
20. https://github.com/argmaxinc/WhisperKit/blob/main/Sources/WhisperKit/Core/Models.swift
21. https://github.com/argmaxinc/argmax-oss-swift/discussions/391
22. https://github.com/argmaxinc/argmax-oss-swift/discussions/437
23. https://github.com/argmaxinc/argmax-oss-swift/issues/528
24. https://github.com/ggml-org/whisper.cpp
25. https://github.com/ggml-org/whisper.cpp/blob/master/models/README.md
26. https://github.com/ggml-org/whisper.cpp/releases
27. https://github.com/ggml-org/whisper.cpp/issues/2160
28. https://github.com/ggml-org/whisper.cpp/issues/3702
29. https://github.com/openai/whisper
30. https://github.com/FluidInference/FluidAudio
31. https://developer.apple.com/documentation/foundationmodels
32. https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel
33. https://developer.apple.com/documentation/foundationmodels/managing-the-context-window
34. https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models
35. https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output
36. https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute
37. https://developer.apple.com/documentation/coreai
38. https://developer.apple.com/videos/play/wwdc2025/286/
39. https://developer.apple.com/apple-intelligence/
40. https://support.apple.com/121115 (nicht abrufbar, von Apple-Doku referenziert)
41. https://developer.apple.com/documentation/appintents/audiorecordingintent
42. https://developer.apple.com/documentation/appintents/liveactivityintent
43. https://developer.apple.com/documentation/appintents/intentauthenticationpolicy
44. https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system
45. https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
46. https://developer.apple.com/documentation/widgetkit/widgetfamily
47. https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger
48. https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive
49. https://developer.apple.com/documentation/xcode/configuring-background-execution-modes
50. https://developer.apple.com/documentation/avfaudio/avaudioapplication/requestrecordpermission(completionhandler:)
51. https://developer.apple.com/documentation/avfaudio/avaudiorecorder
52. https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions
53. https://developer.apple.com/documentation/watchconnectivity/wcsession/transferfile(_:metadata:)
54. https://developer.apple.com/documentation/journalingsuggestions
55. https://developer.apple.com/documentation/journalingsuggestions/presenting-the-suggestions-picker-and-processing-a-selection
56. https://developer.apple.com/documentation/coreml/mlcomputeunits
57. https://developer.apple.com/news/?id=6lxhtioi
