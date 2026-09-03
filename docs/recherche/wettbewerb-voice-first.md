# Wettbewerbsanalyse: Voice-first-Tagebuch-Apps und Sprachnotiz-Apps mit Tagebuch-Charakter

Stand der Recherche: 3. September 2026. Lens: `wettbewerb-voice-first`.

## 0. Methodischer Hinweis (wichtig für Autoren)

Die Recherche lief über Web-Suche mit Snippet-Auswertung. Direkte Abrufe von `apps.apple.com`, `play.google.com`, `cortexos.app`, `cleftnotes.com`, `whispermemos.com`, `getdailyvox.com`, `klu.so`, `journalinghabit.com`, `dayora.ai`, `appbrain.com` u. a. wurden vom Netzwerk-Proxy blockiert (HTTP 403 auf CONNECT, "organization policy"). Erfolgreich direkt gelesen wurden nur `github.com` (DailyVox-Repo, WhisperJournal-Repo) und `developer.apple.com` (WWDC25-Session 277, Developer-Forum-Thread 806765). Alle Sterne-Bewertungen, Bewertungsanzahlen, Preise und Plattformaussagen sind daher aus Suchsnippets rekonstruiert und müssen vor Verwendung in Konzeptdokumenten gegen die Store-Seiten geprüft werden (in der Strukturausgabe: `mustVerify=true`).

## 1. Kernfrage: Erfüllt bereits eine App "täglich per Sprache, 100 % lokal, iOS UND Android"?

Kurzantwort: **Nein, nicht vollständig.** Es gibt (a) reine iOS-Apps, die 100 % lokal arbeiten (DailyVox, VoiceFlow, Whisper Notes, MindDrop, Flint im On-Device-Modus), (b) Android-Apps, die 100 % lokal arbeiten (Voice Diary, Voice Journal von jr44, AI Offline Voice Journal/WhisperJournal, EchoVault), und (c) plattformübergreifende Apps, die entweder eine Cloud-Komponente haben (Voicenotes, Talknotes, AudioPen, Audionotes, AudioDiary, Journify, Rosebud) oder deren Kernfokus nicht das tägliche Tagebuch ist (Offscript, Spokenly, Local Journal, TalkJournal).

Die drei Kandidaten, die der Zielbeschreibung am nächsten kommen:

1. **CortexOS** (iOS + Android, seit März 2026, Solo-Gründer Orlin Martinov, Malta): On-Device-Whisper mit "99 Sprachen", On-Device-LLM (Llama 3.2, ~1 GB "Standard" / ~2 GB "Enhanced"), AES-256-GCM, kein E-Mail-Konto, sondern eine Sechs-Wort-Recovery-Phrase. Abweichungen vom Zielbild: Der Fokus ist ein KI-Analyse-Journal (20+ Emotionen, kognitive Verzerrungen), nicht ein schlichtes Audio-Tagebuch; der Free-Tier ist auf 10 Einträge/Monat begrenzt; Premium enthält einen "encrypted cloud vault", also existiert eine (verschlüsselte) Server-Komponente. Preisangaben schwanken je Quelle: 7,99 $/Monat bzw. 49,99 $/Jahr, Lifetime 99,99 $; eine App-Store-Quelle nennt "Cortex Deep" 9,99 $/Monat, 79,99 $/Jahr und "Cortex Ultra Lifetime" 199,99 $.
2. **Offscript: Private Voice Memos** (Richfield Labs, iOS + Android): On-Device-Whisper, 99 Transkriptionssprachen, UI in 19 Sprachen inkl. Deutsch, AES-256-GCM, Android Keystore, biometrische Sperre, semantische lokale Suche. Abweichung: Voice-Memo-Werkzeug, kein Tagebuch-Ritual (keine belegte Tageserinnerung, kein Kalender/Streak). Preis laut Snippets: Einmalkauf ca. 60 $ und/oder Abos 3–20 $/Monat, plus Free-Tier (prüfen).
3. **Flint (Klu Technologies Oy)**: Einmalkauf 12 $, iOS (iOS 17+), Google-Play-Listing `so.klu.flintapp` mit Update vom 17. Juni 2026. Optionaler vollständiger On-Device-Modus; im Standardmodus bleibt Audio lokal, aber Text geht zur Zusammenfassung in die Cloud (Pro: eigener API-Key für Deepgram/OpenAI/Anthropic). Abweichung: Standard ist nicht 100 % lokal, Tagebuch-Charakter ("first-person entry") ist nur ein Format unter mehreren.

Fazit für die Positionierung: Die Kombination **"täglich, kurz, zur selbstgewählten Uhrzeit" + "ausnahmslos lokal, kein Konto, kein Server" + "iOS und Android" + "Deutsch als erstklassige Sprache" + "Audio und Text gleichwertig wiedergeben" + "verschlüsselter Gerätewechsel per Datei/QR"** ist derzeit nicht besetzt. Der QR-basierte, serverlose Gerätetransfer ist in keiner der untersuchten Apps belegt (nur WhatsApp nutzt lokalen Chat-Transfer per QR).

## 2. Wettbewerbsmatrix

Legende: OD = On-Device-Transkription; Cloud = Server-Transkription; "?" = nicht belegbar.

| App | Plattformen | Preis | Datenhaltung / Konto | Transkription | Deutsch | Erinnerung / Tagebuch-Ritual | Bewertung (Quelle) |
|---|---|---|---|---|---|---|---|
| Flint (Klu) | iOS 17+, Android (Play-Listing Jun 2026) | 12 $ einmalig | Audio lokal; Text zur KI-Zusammenfassung in Cloud; voller OD-Modus optional | OD-Modus oder Cloud (Deepgram/OpenAI/Anthropic via BYOK) | ? | Notizformate inkl. "first-person entry"; keine Erinnerung belegt | keine Sterne auffindbar; Review Jul 2026 positiv |
| DailyVox | iOS 17+ (Android in Entwicklung, Kotlin/Compose, API 33, unveröffentlicht, Stand Aug 2026) | kostenlos, MIT-Open-Source, keine IAP | 100 % lokal; "Data Not Collected"; optional iCloud-Sync; AES-256-Export | OD (Apple Speech), v1.11.0 Aug 2026: Live-Transkription, "unconditional on-device" | ja (DE, ES, FR, IT laut README) | 42-Sekunden-Einträge, Wochenziele, Widgets, Siri Shortcuts | "4+" Altersfreigabe; Sterne nicht auffindbar |
| CortexOS | iOS + Android (März 2026) | Free (10 Einträge/Monat); Premium 7,99 $/M oder 49,99 $/J; Lifetime 99,99 $ (andere Quelle: 9,99 $/79,99 $/199,99 $) | Zero-Knowledge, AES-256-GCM, Recovery-Phrase statt Konto; Premium mit verschlüsseltem Cloud-Vault | OD Whisper, 99 Sprachen; On-Device-LLM Llama 3.2 | ja (Whisper) | KI-Reflexion, Stimmungsmuster; Erinnerungen ? | keine Sterne auffindbar |
| Speakwise | iOS only | 59,99 $/Jahr (+ Wochenabo) | OD-Modus wählbar; Notion-Sync | OD wählbar, sonst Cloud; 100+ Sprachen; Diarisierung | ja (100+) | Meeting-Fokus, Journaling nur als Anwendungsfall | 4,9 (App Store, laut Speakwise-Blog) |
| Talknotes | iOS, Android, Web, Chrome | Free; 19,97 $/M oder 197 $/J | Cloud, Konto | Cloud; 50+ Sprachen; Deutsch-WER 7,7 % (Eigenangabe), Dialekte beworben | ja | keine Tagebuch-Funktion; 100+ Templates | Sterne nicht auffindbar; "10.000+ Professionals" |
| AudioPen | iOS, Android, Web, Mac, Chrome | Free (limitiert); Prime 33 $/3 M, 99 $/J, 159 $/2 J, kein Auto-Renew; Lifetime ~100 $ (unklar) | Cloud, Konto; Option "notes locally" laut Play-Rezension | Cloud | ? | keine Tagebuch-Funktion | Play: 3,97/5 (210) bzw. 3,73/5 (160); iOS 4,9 (136+) |
| Vomo AI | iOS (Android: laut tl;dv nur Web) | ab 19,99 $/M; Free ~30 Min/Monat | Cloud, Konto | Cloud, 50–90+ Sprachen | ja | Meeting-Fokus | iOS 4,4–4,45/5 (350) |
| Whisper Memos | iOS + Apple Watch | ab 5 $/M, 29,99 $/J | Cloud; Audio geht laut Privacy Policy an OpenAI; E-Mail-Zustellung, Zapier | Cloud (Whisper/ElevenLabs Scribe); 50+ Sprachen inkl. DE | ja | keine Tagebuch-Funktion; Watch offline aufnehmen, später sync | Sterne nicht auffindbar; Beschwerden zu Crashes/Abo |
| Spokenly | iOS, Mac, Win, Linux | lokale Modelle kostenlos ohne Limit; Pro 9,99 $/M | lokal möglich; Verlauf in App; BYOK | OD Whisper Large-v3 / Parakeet; 100+ Sprachen | ja | Diktat-Tool, Tagebuch nur als Workflow | 4,4/5 (43 Bewertungen, Apr 2026); iOS-Version als weniger stabil beschrieben |
| Voicenotes | iOS, Android, Mac, Win, Web, watchOS, Wear OS | Free; Pro 9–14,99 $/M, 99,99 $/J; Team 49 $/M | Cloud (AWS USA), Konto; Audio nach Transkription gelöscht | Cloud; 60+ Sprachen; LLM OpenAI/Anthropic | ja | Erinnerungs-/Coach-Funktionen, kein Tagebuch-Ritual | iOS 4,7 (1 Mio.+ Downloads, Aug 2026); Play 3,92/5 (2.500); Trustpilot 4,2 |
| Cleft Notes | iPhone, iPad, Mac (kein Android) | Basic free (5-Min-Notizen); Plus 6,99 $/M oder 39,99 $/J | OD-Transkription, KI-Strukturierung in Cloud | OD | ? | Markdown-Notizen, kein Tagebuch | Sterne nicht auffindbar; "beste App für ADHS" (Nutzerzitat) |
| Jour (Jour Inc.) | iOS | Premium 59,99 $/J bzw. 4,99 $/M | Cloud | Text-geführtes Journaling; 2021 von Alan übernommen | ? | Daily Jour | nicht voice-first; Stand 2026 unklar |
| AudioDiary ("a smarter journal") | iOS + Android | Free + Premium (Preis ?) | Cloud (AWS + DigitalOcean), Konto, OpenAI-DPA | Cloud | ? | Tagebuch mit KI-Feedback, SMART-Ziele | iOS 4,9 (500+), Play 4,8 (1.500+) (Eigenangabe) |
| Voice Diary (com.voicediary.voicediary) | Android | ? | 100 % lokal, kein Tracking | OD "100 % offline AI" | ? | 60-Sekunden-Einträge, Favoriten, Datumsfilter | Sterne nicht auffindbar |
| Voice Journal (com.jr44.voicejournal) | Android | ? | 100 % offline, kein Konto, keine Werbung; Export JSON/Text | OD; Deutsch ausdrücklich | ja | Tags, Suche; Update Mai 2026 | Sterne nicht auffindbar |
| EchoVault | Android | Free (5 Einträge/Woche); Pro 4,99 $/M | offline, "voice never leaves phone" | OD Whisper "95 %" | ja (Whisper) | Streaks, Wochenreports, KI-Coach | "10.000+ Nutzer"; Sterne nicht auffindbar |
| AI Offline Voice Journal (WhisperJournal) | Android (iOS laut Repo, Store-Verfügbarkeit unklar) | kostenlos, MIT | lokal; einzige Netzwerkaufrufe = Modell-Download | OD whisper.cpp via whisper.rn (React Native), Autodetect | ja | kein Ritual | ~1.100 Downloads (AppBrain) |
| Offscript | iOS + Android | ~60 $ einmalig und/oder 3–20 $/M; Free-Tier | lokal, AES-256-GCM, Keystore, Biometrie | OD Whisper, 99 Sprachen; UI 19 Sprachen inkl. DE | ja | Voice-Memos, kein Tagebuch | Sterne nicht auffindbar |
| Local Journal | iOS + Android | Free; Premium 6,99 $ einmalig | lokal, kein Konto, kein Sync | OD Whisper, **nur Englisch** | nein | Text-Tagebuch mit Voice-Option | Sterne nicht auffindbar |
| TalkJournal | iOS + Android | Free (1 Eintrag); Pro (Preis ?) | lokal; Face ID | OD, native Spracherkennung | ? | Kalenderansicht | Sterne nicht auffindbar |
| Untold | iOS 15.1+ | 6,99 $/Woche (~364 $/J) | Cloud | Cloud | ? | 30-Sekunden-Einträge, psychologische Analyse | "Feels like you're talking to a person" (Nutzer) |
| Journify | iOS (Play-Listing am 13.05.2024 entfernt) | 3,99 $/M, 29,99 $/J; Free 5 Einträge/Monat | Cloud | Cloud | ? | Stimmung, Fotos | iOS 3,52 (44), Android 3,24 (131) |
| Sound Off | iOS | Free + Premium-Abo | lokal auf iPhone/Apple ID | keine Transkription belegt | ? | tägliche Audio-Starter | positive Reviews, Design gelobt |
| VoiceFlow: KI-Sprachtagebuch | iOS (DE-Store) | ? | vollständig lokal ("Flugmodus an, alles läuft") | OD | ja | Tagebuch | keine Sterne |
| TOLDAYS | iOS (DE) | Abo/Einmalkauf (Beträge ?) | Original-Audio wird nicht dauerhaft gespeichert; Server ? | ? | ja | Tagebuch aus Sprache | keine Sterne |
| FourYou: Sprach Tagebuch | iOS (DE) | ? | "Keine Daten erhoben" | ? | ja | vier Fragen pro Tag, Export | keine Sterne |
| Diarly | iOS/macOS | Premium 27 €/J | lokal/iCloud | Premium-Transkription mit Apple-On-Device-Modell (iOS 26) | ja | Text-Tagebuch | -- |
| Day One | iOS, Android, Mac, Web | Basic free; Silver 49,99 $/J; Gold 74,99 $/J (Apr 2026) | E2E-Cloud-Sync | Transkription nur iOS, max. 10 Min, Internet erforderlich | Geräte-Sprache | Erinnerungen | -- |
| Apple Journal | iOS 18+/26 | kostenlos | lokal/iCloud | OD, **Transkription nur Englisch** | nein | Erinnerungen, Vorschläge | Nutzerberichte über verschwindende Transkripte |

## 3. Einzelbefunde mit Details

### 3.1 Flint (Klu Technologies Oy)
- Positionierung laut Klu-Blog: "keeps your audio on-device, offers an on-device mode where nothing leaves the phone, turns your spoken entries into clean first-person notes, and charges a one-time $12 instead of a recurring fee".
- Datenfluss im Standardmodus: "Flint keeps audio on your device and only sends text to the cloud for summarisation. Full on-device mode is available for users who want zero cloud involvement." Pro-Plan mit eigenem API-Key (Deepgram, OpenAI, Anthropic).
- Plattform: App Store `id6760716646` (iOS 17+); Klu-Texte sagen "iOS-only for now, with Android coming", gleichzeitig existiert das Play-Listing `so.klu.flintapp` ("Flint: Voice Note with AI") mit Update 17. Juni 2026. Ob das Android-Listing funktional gleichwertig ist (On-Device-Modus), ist nicht belegt.
- Nutzerreview Juli 2026: "worth the $12, saving more time and costing less than other voice-to-text tools".
- Relevanz: Direktester Preis-Benchmark für Einmalkauf (12 $) im Segment.

### 3.2 DailyVox (Karthikeyan NG)
- Kostenlos, Open Source (MIT), iOS 17+, "Data Not Collected". Apple Speech framework + NaturalLanguage; keine Server.
- Funktionen laut README: 42-Sekunden-Einträge mit Live-Transkription, Stimmungsanalyse, "Digital Twin", Export PDF/JSON/Markdown/CSV, AES-256-verschlüsselte Backups, Biometrie-Sperre, optionaler iCloud-Sync, Widgets, Siri Shortcuts, Sprachen Spanisch/Französisch/Deutsch/Italienisch.
- Android: "In Development, not yet released" (Kotlin, Jetpack Compose, Room, "On-device recognition only (no network fallback)", API 33). Letzte Version v1.11.0 im August 2026.
- Relevanz: Beleg, dass Apples On-Device-Stack für ein 100 % lokales Sprachtagebuch reicht; gleichzeitig Beleg, dass Android der schwierigere Teil ist (noch nicht geliefert). Als kostenloses Open-Source-Produkt setzt DailyVox einen Preisanker "0 €" auf iOS.

### 3.3 CortexOS (Orlin Martinov, Malta)
- App Store `id6759070325`, Play `com.cortexos.app`; Launch März 2026; Solo-Gründer, Entwicklung ab Ende 2025.
- Technik: On-Device-Whisper ("99 languages, no cloud speech recognition"), Llama 3.2 lokal (Standard ~1 GB, Enhanced ~2 GB, automatischer Fallback bei wenig RAM), TFLite (Android) / Neural Engine (iOS), 13 Hintergrund-Worker, AES-256-GCM, Recovery-Phrase.
- Free: 10 verschlüsselte Einträge/Monat, Voice Journaling, Top-3-Emotionen. Premium: 20+ Emotionen, Deep Analysis, Mustererkennung, "encrypted cloud vault", 7 Tage Trial.
- Schwächen aus Sicht des Zielprodukts: hoher Speicher-/Rechenbedarf (1–2 GB Modell), Analyse-Fokus statt Tagebuch-Ritual, 10-Einträge-Limit verhindert tägliches kostenloses Nutzen, Cloud-Vault im Premium.

### 3.4 Speakwise
- iOS-nativ, 4,9 Sterne (Eigenangabe), 59,99 $/Jahr, Wochenabo ("yearly saves 81 %"). "Processes everything locally on your iPhone when you choose." Diarisierung, Notion-Sync, 100+ Sprachen. Kein Android.

### 3.5 Talknotes
- iOS/Android/Web. Free; 19,97 $/Monat oder 197 $/Jahr (unbegrenzte Notizen, 2 h pro Notiz). Cloud-Transkription. Eigenangabe Deutsch-WER 7,7 % (Englisch 6,4 %), Hochdeutsch, österreichisches und Schweizer Deutsch beworben. Kein Tagebuch-Ritual. Sterne nicht auffindbar.

### 3.6 AudioPen
- iOS/Android/Web/Mac/Chrome; Prime 99 $/Jahr, 159 $/2 Jahre, 33 $/3 Monate, kein Auto-Renew ("When it expires, you'll have the option to purchase it again"). Play-Store-Bewertung 3,97/5 (210) bzw. 3,73/5 (160) je nach Snippet-Datum; iOS 4,9 (136+). Nutzerkritik: "$100 insane to be able to do more than just 10 notes". Cloud, Konto.

### 3.7 Vomo AI
- iOS 4,4/5 (ca. 350 Bewertungen). Ab 19,99 $/Monat; Free ca. 30 Min/Monat. Cloud. tl;dv-Review: "free plan is incredibly weak", "limited platform support" (kein nativer Android-Client laut tl;dv, Play-Listing dennoch referenziert; prüfen).

### 3.8 Whisper Memos
- iPhone + Apple Watch, ab 5 $/Monat, 29,99 $/Jahr. Privacy Policy: "transcription entails sending the audio file to OpenAI". E-Mail-Zustellung der Transkripte, Zapier. Watch offline aufnehmen, Upload später. Nutzerbeschwerden: Crashes, Aufnahmezuverlässigkeit, Abo-Verwaltung. Nicht lokal.

### 3.9 Spokenly
- iOS/Mac/Windows/Linux; lokale Modelle (Whisper Large-v3, Parakeet) kostenlos ohne Wort-/Zeitlimit; Pro 9,99 $/Monat für Cloud. App Store 4,4/5 bei 43 Bewertungen (April 2026). Nutzer: "works great on macOS, for iPhone ... hard time working properly". Journaling-Workflow (Diktat in Day One/Obsidian/Apple Journal), kein eigenes Tagebuch.

### 3.10 Voicenotes
- Das größte Cloud-Produkt: iOS 4,7 und "1M+ downloads" (Aug 2026), Play 3,92/5 (2.500 Bewertungen), 150.000+ aktive Nutzer, Product Hunt "Bootstrapped Product of the Year". Free; Pro 9–14,99 $/Monat bzw. 99,99 $/Jahr; Team 49 $/Monat. Daten auf AWS in den USA; Audio wird nach Transkription gelöscht; LLM-Anbieter OpenAI/Anthropic. Kritik: "cloud-only, can lose recordings when an upload fails, and does nothing offline". 60+ Sprachen inkl. Deutsch.

### 3.11 Cleft Notes
- Apple-only (iPhone/iPad/Mac). Basic free mit 5-Min-Aufnahmen und On-Device-Transkription; Plus 6,99 $/Monat oder 39,99 $/Jahr (30-Min-Notizen, Custom AI, Family Sharing). KI-Strukturierung läuft in der Cloud. Nutzerzitat: "one of the BEST apps for ADHD people".

### 3.12 Jour
- Jour Inc. (Maxime Germain, True-Ventures-Seed 1,8 Mio. $ 2019, Übernahme durch Alan für 20 Mio. $ 2021). Premium 59,99 $/Jahr bzw. 4,99 $/Monat (jährlich). Text-geführtes Journaling, nicht voice-first. Ein separates Listing "jour : AI Journal App" (`id6762167232`) und mehrere ähnlich benannte Apps (Journ, Journi, Joice, Journee) existieren; Zuordnung unklar.

### 3.13 Play-Store-Segment "Voice Diary" (Android)
- **Voice Diary** (`com.voicediary.voicediary`): 60-Sekunden-Aufnahmen, "100 % offline AI speech recognition", KI-Tagebuchtext, Favoriten. Keine Sterne auffindbar.
- **Voice Journal** (`com.jr44.voicejournal`): automatische Transkription auf Deutsch, 100 % offline, kein Konto, keine Werbung, Tags, Export JSON/Text, Update Mai 2026. Das ist der direkteste Android-Wettbewerber für DACH, aber Android-only.
- **EchoVault** (`com.echovault.app`): Whisper offline, Free 5 Einträge/Woche, Pro 4,99 $/Monat, KI-Coaches, Streaks, "10.000+ users".
- **AI Offline Voice Journal / WhisperJournal** (`com.kaizoco.whisperjournal`): React Native + whisper.rn, MIT, ~1.100 Downloads, 5-Sterne-Zitat: "really good especially when some of the Google voice typing features on my Pixel 6 aren't working".
- Weitere: My Voice Diary (hitbytes), Voice Diary with Photos & Videos, VoiceJournal: AI Audio Diary, My Diary: AI Voice Journaling, Voice Diary with Lock 2024, TalkJournal, Private Dictation: Offline AI, Offline Voice Input, Voice Note Pro: Offline AI.

### 3.14 App-Store-Segment "Audio Journal" (iOS)
- Sound Off (tägliche Audio-Starter, Premium-Abo), Voice Journal - Audio Diary (`id6760410000`), Voice Journal: Diary Lock (Face ID, Wochen-/3-Monats-Abo, verschlüsseltes Cloud-Backup), Untold (6,99 $/Woche), AudioDiary (4,9/500+), Journee, Joice, Journi, Echo Journal, LocalOne VoiceVault, VoiceScriber, Whisper Notes (7,99 $ einmalig, 100+ Sprachen, iPhone 12+), Aiko, Offline Privacy Transcription. appshunter.io listet "226+ Voice Diary Apps for iPhone (2026)".
- Deutschsprachige iOS-Nischenapps: VoiceFlow: KI-Sprachtagebuch (vollständig lokal), TOLDAYS (toldays.de), FourYou: Sprach Tagebuch (vier Fragen/Tag, "Keine Daten erhoben"), Vozly.

### 3.15 Plattform-Baselines
- **Apple Journal**: Audio-Transkription nur Englisch; Nutzer berichten "Couldn't Transcribe Audio" und verschwindende Transkripte. Kein Android.
- **Day One**: Silver 49,99 $/Jahr, Gold 74,99 $/Jahr (April 2026, "Premium" im März 2026 in "Silver" umbenannt). Audio-Transkription nur iOS, max. 10 Minuten, "an internet connection is required".
- **Google Recorder**: Pixel-exklusiv, On-Device, Echtzeit in 15 Sprachen inkl. Deutsch, Nach-Transkription 40+.
- **Google AI Edge Eloquent** (April 2026, iOS): kostenlose Offline-Diktat-App mit Gemma-ASR-Modellen, Füllwortfilter; Cloud-Modus optional mit Gemini.

## 4. Technische Randbedingungen für "100 % lokal" mit Deutsch

- **iOS 26 SpeechAnalyzer/SpeechTranscriber** (WWDC25 Session 277): läuft vollständig on-device, Modelle werden systemseitig per `AssetInventory` nachgeladen, nicht app-gebündelt; nicht auf watchOS. `SpeechTranscriber.supportedLocales` enthält laut Forum-Snippet u. a. `de_DE`, `de_AT`, `de_CH`. Harte Hardwaregrenze: iPhone 11/11 Pro/SE 2 (8-Core Neural Engine) liefern ein leeres Locale-Array; ab iPhone 12 (16-Core NE) unterstützt; Simulator nicht unterstützt (Thread Nov 2025–März 2026). Fallback: `DictationTranscriber` / `SFSpeechRecognizer`.
- **Android**: `SpeechRecognizer.createOnDeviceSpeechRecognizer()` ab API 31/33 erzwingt lokale Erkennung, scheitert ohne lokale Engine; Verfügbarkeit von Sprachpaketen herstellerabhängig; Gboard-Offline-Modell gilt als "small, dated model". Robuste Alternative: whisper.cpp (GGML tiny 75 MB bis large 2,9 GB; RAM 273 MB bis 3,9 GB), von WhisperJournal, EchoVault, Offscript und CortexOS produktiv genutzt. Whisper-Deutsch: Hochdeutsch hoch genau, Schweizerdeutsch/Bairisch deutlich schwächer (voicescriber.com).
- Zwischenfazit: iOS lässt sich mit Apple-Bordmitteln lokal und deutschsprachig lösen; Android braucht ein mitgeliefertes/nachladbares Modell (whisper.cpp-Klasse), um Gleichwertigkeit und Herstellerunabhängigkeit zu garantieren.

## 5. Preis- und Marktbenchmarks

- Einmalkäufe im Segment: Flint 12 $, Local Journal 6,99 $, Whisper Notes 7,99 $, Offscript ~60 $, CortexOS Lifetime 99,99 $ (oder 199,99 $).
- Abos: EchoVault 4,99 $/M; Cleft 39,99 $/J; Day One 49,99 $/J; Speakwise 59,99 $/J; Jour 59,99 $/J; AudioPen 99 $/J; Voicenotes 99,99 $/J; Rosebud 107,99 $/J; Talknotes 197 $/J; Untold ~364 $/J.
- Kostenlos: DailyVox (iOS), WhisperJournal (Android), Spokenly lokal, Dayora (Web, OpenAI-Training erlaubt).
- Markt: "Digital Journal Apps" 5,69 Mrd. $ (2025) auf 6,34 Mrd. $ (2026), CAGR ~11,4–11,5 % (Straits Research/The Business Research Company; andere Quelle 6,53 Mrd. $ 2025). RevenueCat 2026: Top-25 % der Abo-Apps wachsen MRR um 80 %+, unteres Viertel schrumpft um 33 %+; Indie-Median unter 1.000 $/Monat; Empfehlung: Jahresabo 20–40 $, Lifetime als 3–4x-Anker.

## 6. Lücken und Chancen für das geplante Produkt

1. Kein Wettbewerber verbindet iOS + Android + 100 % lokal + Deutsch + tägliches Ritual. CortexOS ist am nächsten, aber schwer (LLM), limitiert (10/Monat) und analysefokussiert.
2. Der serverlose Gerätewechsel (verschlüsselte Datei + QR-Handshake) ist ein Alleinstellungsmerkmal; Wettbewerber nutzen iCloud (DailyVox), Cloud-Vault (CortexOS, VoiceJournal) oder gar nichts (Local Journal: "nothing synced").
3. Deutsch als First-Class-Sprache: Voice Journal (jr44) und VoiceFlow beweisen Nachfrage in DACH, sind aber Single-Platform ohne Monetarisierung.
4. Preislogik: Einmalkauf 10–15 € (Flint-Niveau) oder niedriges Jahresabo (20–40 €) mit Lifetime-Anker ist marktkonform; hohe Abos (Talknotes, Untold) werden in Rezensionen kritisiert.
5. Bekannte Schwächen der Konkurrenz, die man vermeiden kann: Upload-Verluste (Voicenotes), Transkripte verschwinden (Apple Journal), Crash/Abo-Ärger (Whisper Memos), Englisch-only (Local Journal, Apple Journal), 10-Min-/60-Sek-Grenzen.

## 7. Offene Fragen

- Exakte Sterne/Bewertungsanzahl für Flint, DailyVox, CortexOS, Speakwise, Talknotes, Whisper Memos, Voice Diary, EchoVault, Offscript (Store-Seiten blockiert).
- Ist das Android-Listing von Flint funktional identisch (On-Device-Modus, 12 $ Einmalkauf)?
- Welche Transkriptions-Engine nutzt CortexOS auf Android konkret (whisper.cpp? Modellgröße?), und wie ist die Deutsch-Qualität?
- Aktueller Status von "Jour" 2026 (Relaunch als "jour: AI Journal"?).
- Preise von TalkJournal Pro, Offscript (Einmalkauf vs. Abo), TOLDAYS, VoiceFlow, FourYou.
- Ob `SpeechTranscriber` für `de_CH`/`de_AT` dieselbe Qualität wie `de_DE` liefert.

## 8. Quellen

- https://klu.so/blog/private-voice-journaling
- https://apps.apple.com/us/app/flint-voice/id6760716646
- https://play.google.com/store/apps/details?id=so.klu.flintapp&hl=en-US
- https://www.danrecommends.com/reviews/flint
- https://github.com/intrepidkarthi/dailyvox
- https://apps.apple.com/in/app/dailyvox-voice-journal-diary/id6760454642
- https://getdailyvox.com/compare
- https://cortexos.app/faq/
- https://cortexos.app/about/
- https://cortexos.app/library/best-private-voice-journal-2026/
- https://play.google.com/store/apps/details?id=com.cortexos.app
- https://apps.apple.com/us/app/cortexos/id6759070325
- https://speakwiseapp.com/
- https://apps.apple.com/us/app/speakwise-ai-note-taker/id6751740223
- https://www.dayora.ai/blog/best-voice-journaling-apps-2026
- https://www.krowdbase.com/software/talknotes
- https://talknotes.io/transcribe-in/german
- https://aichief.com/ai-text-tools/audiopen/
- https://www.audiopen.ai/prime
- https://play.google.com/store/apps/details?id=com.audiopen.android&hl=en_US
- https://tldv.io/blog/vomo-ai/
- https://apps.apple.com/us/app/vomo-transcribe-audio-to-text/id6449889336
- https://whispermemos.com/
- https://whispermemos.com/page/privacy-policy
- https://spokenly.app/pricing
- https://spokenly.app/blog/voice-journaling
- https://www.getvoibe.com/resources/spokenly-review/
- https://aiproductivity.ai/pricing/voicenotes/
- https://help.voicenotes.com/en/articles/9196879-voicenotes-privacy-policy
- https://www.appbrain.com/app/voicenotes/com.app.voicenotes
- https://www.yaps.ai/blog/voicenotes-alternative
- https://cleftnotes.com/pricing
- https://medium.com/jour/meet-jour-premium-a57ec7c06caf
- https://medium.com/@maximegermain/jour-is-joining-alan-e36e14020488
- https://play.google.com/store/apps/details?id=com.voicediary.voicediary&hl=en_US
- https://play.google.com/store/apps/details?id=com.jr44.voicejournal&hl=en_US
- https://play.google.com/store/apps/details?id=com.echovault.app&hl=en_US
- https://github.com/kaisoapbox/WhisperJournal
- https://www.appbrain.com/app/openai-voice-journal/com.kaizoco.whisperjournal
- https://www.richfieldlabs.com/apps/offscript
- https://play.google.com/store/apps/details?id=com.offscript.app&hl=en-US
- https://localjournal.app/
- https://play.google.com/store/apps/details?id=app.talkjournal&hl=en_US
- https://audiodiary.ai/
- https://apps.apple.com/us/app/untold-voice-journal/id6451427834
- https://mindsera.com/articles/voice-journaling-benefits-and-the-5-best-apps-2026
- https://www.appbrain.com/app/journify-audio-journal-voic/co.journify.mobile
- https://apps.apple.com/us/app/sound-off-voice-memo-journal/id1522671266
- https://apps.apple.com/de/app/voiceflow-ki-sprachtagebuch/id6755595633
- https://toldays.de/
- https://apps.apple.com/de/app/fouryou-sprach-tagebuch/id1671616134
- https://apps.apple.com/de/app/diarly-mein-tagebuch-journal/id1387167765
- https://whispernotes.app/
- https://voicescriber.com/offline-transcription/german
- https://dayoneapp.com/guides/tips-and-tutorials/audio-recording/
- https://9to5mac.com/2026/04/08/day-one-journaling-app-introduces-gold-plan-with-ai-summaries-and-daily-chat/
- https://discussions.apple.com/thread/255916391
- https://support.google.com/pixelphone/answer/16267698?hl=en
- https://techcrunch.com/2026/04/07/google-quietly-releases-an-offline-first-ai-dictation-app-on-ios/
- https://developer.apple.com/videos/play/wwdc2025/277/
- https://developer.apple.com/forums/thread/806765
- https://developer.apple.com/documentation/speech/speechtranscriber/supportedlocales
- https://picovoice.ai/blog/android-speech-recognition/
- https://openwhispr.com/blog/whisper-model-sizes-explained
- https://straitsresearch.com/report/digital-journal-apps-market
- https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026
- https://appopportunity.com/blog/indie-app-revenue-models-2026
- https://journalinghabit.com/best-voice-journal-apps-2026/
- https://appshunter.io/ios/topics/voice-diary
