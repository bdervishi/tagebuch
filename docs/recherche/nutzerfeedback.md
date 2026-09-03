# Nutzerfeedback und Beschwerden zu Tagebuch- und Voice-Journal-Apps

Recherche-Blickwinkel: `nutzerfeedback` · Stand: 3. September 2026

## 0. Methodischer Hinweis (bitte zuerst lesen)

Die Recherche musste unter einer starken Einschränkung stattfinden: Das Suchmaschinen-Kontingent der Sitzung war vor Beginn dieser Teilaufgabe aufgebraucht, und der Netzwerk-Proxy blockierte den Zugriff auf apps.apple.com, play.google.com, reddit.com (alt und neu), news.ycombinator.com / hn.algolia.com, trustpilot.com, producthunt.com, justuseapp.com, appagg.com, alternativeto.net, heise.de, discussions.apple.com, privacyguides.org, huggingface.co, medium.com, dev.to, wikipedia.org und alle erreichbaren Suchmaschinen (Google, Bing, DuckDuckGo, Startpage, Marginalia, SearX). **Erreichbar war ausschließlich github.com** (Seiten, Issues, Discussions, GitHub-Suche mit Rate-Limit, raw.githubusercontent.com) sowie die GitHub-API über den MCP-Server.

Konsequenz: Die hier gesammelten Belege stammen fast vollständig aus Issue-Trackern und READMEs von Open-Source-Tagebuch-, Diktier- und Spracherkennungsprojekten sowie deren Community-Diskussionen. Das ist eine **verzerrte Stichprobe** (technisch versierte, datenschutzaffine, häufig selbst hostende Nutzer). Wörtliche App-Store-Rezensionen, Reddit-Threads und deutschsprachige Forenbeiträge zu Day One, Journey, Diarium, Daylio, Apple Journal usw. konnten **nicht** abgerufen werden. Alle Aussagen über diese kommerziellen Apps sind daher indirekt (z. B. über Import-Anfragen in Konkurrenzprojekten) und müssen vor Verwendung in Konzeptdokumenten durch eine zweite Recherche mit Store-/Reddit-Zugriff verifiziert werden. Die im Auftrag genannten Quellenarten sind in Abschnitt 7 als offene Punkte aufgeführt.

Trotzdem liefert die GitHub-Stichprobe belastbare, datierte und zitierbare Hinweise zu fast allen Themen des Auftrags: Lock-in/Export, Datenverlust, Verschlüsselungswünsche, Erinnerungen, Transkriptionsqualität (Deutsch, Schweizerdeutsch, Whisper-Halluzinationen), On-Device-Performance, fehlende Android-Versionen, Watch-Integration, Bildschirm-aus-Aufnahme und Monetarisierungs-Akzeptanz.

---

## 1. Was Nutzer wirklich stört (priorisiert)

### 1.1 Lock-in und fehlender/mangelhafter Export (Priorität: sehr hoch)

- **Apple Journal**: Ein Nutzer schreibt am 5. Jan. 2026 im Journiv-Tracker: *"I have about eighty entries trapped in Apple Journal. I'd love to be able to break them free and import them—including attached photos, audio files and geolocation data—into Journiv."* (https://github.com/journiv/journiv-app/issues/253). Das Wort "trapped" ist bezeichnend.
- Apple Journal exportiert laut dem Konverter-Projekt `journal2day1` (Dez. 2025) **nur HTML** in einem Ordner `Entries/` plus `Resources/`; *"The export includes all entries from your Journal. There is no option to export a specific date range."* Begründung für das Tool: *"Apple Journal is a great app for quick daily journaling, but it lacks advanced features like search, tags, multiple journals, and cross-platform sync."* (https://github.com/kpod13/journal2day1). Umgekehrt gehen beim Import nach Apple Journal Audiodateien verloren: *"Audio files are not imported"*, *"Videos are not imported"* (https://github.com/jeffd/DayOneToJournal, Mai 2026).
- Dass allein zwischen Dez. 2025 und Aug. 2026 mindestens **zehn** unabhängige "Apple Journal → Markdown/Obsidian/Day One"-Konverter auf GitHub entstanden sind (u. a. tarikbc/apple-journal-importer, shinchu/apple-journal-to-obsidian, Derururu/JournalToMarkdown, ostojan/Journal2Markdown, joshuahidden/journal-reader), zeigt einen realen Export-Schmerz (GitHub-Suche "apple journal export", 3. Sep. 2026).
- **Day One / Journey / Daylio / Diarium / Diarly**: Im selbst gehosteten Journiv sind Import-Anfragen für alle diese Apps die häufigste Feature-Kategorie (#14 Day One, #58 Daylio, #108 Diarly, #302 Diarium, #253 Apple Journal). Der Daylio-Nutzer nennt den Grund explizit: *"Been paying for premium for a couple of years but it's a pain having it on one device only and having next to no integration with anything else."* (https://github.com/journiv/journiv-app/issues/58, 8. Nov. 2025). Zu Day One: *"I have a lot of records in DayOne !"* (#14, 3. Nov. 2025) – Grund nicht genannt. Journey exportiert Sprachnotizen nur als MP3; Day One erwartet AAC/M4A, weshalb ein Transcoder nötig ist (https://github.com/miloshimself/journey2dayone).
- Auch in Open-Source-Apps scheitert Export regelmäßig: Journiv #530 *"the progress bar stays at zero and it never finishes"* (16. Apr. 2026), #109 Export ohne Anhänge: *"It creates the export files but doesnt save the attachments"* (19. Nov. 2025), #536 PDF-Export ohne Chinesisch; Easy Diary #236 *"Export to Excel fails"*, #237 fehlende Doku zum Dateiformat des Export-Datenbank (Nov. 2024).

**Ableitung:** Export in offene Formate (Markdown + Audio + JSON-Metadaten, Datumsbereich wählbar) ist kein Nice-to-have, sondern eine Vertrauensbedingung. Ein Konzept sollte den Export-Zustand *vor* dem ersten Eintrag beweisbar machen (z. B. "Export-Vorschau" im Onboarding).

### 1.2 Datenverlust, kaputte Backups und fehlgeschlagene Wiederherstellung (Priorität: sehr hoch)

- Easy Diary (Android, F-Droid/Play) #252, 25. Aug. 2026: *"I have approximately 1,200 photos attached to my diary entries. The photos are successfully backed up to Google Drive... However, when I restore the backup... only about two photos are restored at a time."* (https://github.com/hanjoongcho/aaf-easydiary/issues/252). #109 (2020): Backup lädt 9 statt 2 Dateien, Restore stellt gelöschtes Foto nicht her. #200 (Nov. 2022, Pixel 5/Android 13): *"Insufficient permission for the request feature"* – Backup komplett blockiert nach OS-Update.
- Journiv #540, 29. Apr. 2026: *"I have had auto-updates running on Journiv for a while now, and just realized that I've lost access to the body copy of all entries made before the version 0.17 update."* (https://github.com/journiv/journiv-app/issues/540) – Datenverlust durch Migrationsfehler bei automatischem Update.
- Fossify Voice Recorder #56, 16. Jun. 2024: Nach >50 Minuten Aufnahme `java.io.FileNotFoundException`; *"I just recorded very important information and this bug completely ruined it"* (https://github.com/FossifyOrg/Voice-Recorder/issues/56). Für ein Sprachtagebuch ist die Robustheit der Aufnahme selbst (Pause/Stop, Bildschirmsperre, Anruf) kritisch.
- Nutzerwunsch dahinter: automatisches, verschlüsseltes Backup. Easy Diary #233 (Nov. 2024): *"That would make it much safer to use the app as I can be sure my data is always backed up and restorable if I lose/damage the phone."*; #230 Android-Backup-System nutzen; #234: Backup mit dem vorhandenen PIN/Passwort verschlüsseln, *"in case of Google account compromise"*.

**Ableitung:** Für eine bewusst server- und kontolose App ist Backup/Transfer das Achillesferse-Thema. Der geplante verschlüsselte QR-initiierte Transfer muss auch als *regelmäßiges lokales Backup* (z. B. Datei in Dateien-App/SAF) funktionieren, inkl. Wiederherstellungstest.

### 1.3 Cloud-Zwang, Konten und Datenschutz (Priorität: hoch)

- Motivationsaussage des iOS-Voice-Journals DailyVox (README, 2026): *"By the time I sat down to type, half the details were gone. Voice changes that."* Und: bestehende Voice-Diary-Apps verlangten Server-Uploads, was für den Autor ein Dealbreaker war; deshalb *"a voice journal where everything runs on-device, and the AI that knows you best is the one that never shares you with anyone."* Die App trägt Apples Label *"Data Not Collected"*, *"Zero network calls. Zero third-party SDKs. Zero analytics."* (https://github.com/intrepidkarthi/dailyvox).
- Verschlüsselung ist bei Diary-Apps die am stärksten nachgefragte Eigenschaft: bei billthefarmer/Diary die drei reaktionsstärksten Issues (#39 "Encrypt diary option", #59 "Encrypted Diary", #65 "password access"); bei Journiv #186 *"The data is stored in plain text in the database"* (Dez. 2025, 4 Reaktionen, Status "Planned"); Umfrage #567 (Mai 2026, 17 Stimmen): 47 % serverseitige Verschlüsselung, 35 % E2EE, 17 % keine (https://github.com/orgs/journiv/discussions/567). Beim Fossify Voice Recorder wurde "Option to encrypt recordings by default" (#62) mit *"People need to be able to at least discourage third parties from accessing recordings"* begründet – und vom Maintainer als wontfix geschlossen, was eine Lücke für andere Apps lässt.
- Community-Kritik an intransparenter Monetarisierung: Journiv-Diskussion #425 (13. Feb. 2026): *"since January a new 'Plus' tab has appeared on the website. Was there an official statement from the owner that the project is no longer completely open source?"* Der Maintainer antwortet, Journiv sei *"not a commercial product or something from which I want to make profit from"*. Zeigt: Nutzer datenschutzorientierter Apps reagieren empfindlich auf nachträgliche Paywalls.

### 1.4 Transkriptionsqualität: Deutsch, Dialekte, Schweizerdeutsch, Halluzinationen (Priorität: hoch)

- **Groß-/Kleinschreibung und Interpunktion**: faster-whisper #601 (2. Dez. 2023): *"I tried German, using the large model. But it wrote every word in small letters (in German, we have many words with capital letters), and it did not set any punctuation."* (https://github.com/SYSTRAN/faster-whisper/issues/601).
- **Halluzinationen bei Stille** (für kurze Tagebuch-Aufnahmen mit Pausen relevant): openai/whisper Discussion #928 dokumentiert deutsche Phantomtexte wie *"Untertitel der Amara.org-Community"* und *"Untertitel im Auftrag des ZDF, 2017"* sowie *"Copyright WDR"*; empfohlene Gegenmaßnahmen: VAD vorschalten, Segmente mit `no_speech_prob` > 0,9 verwerfen (https://github.com/openai/whisper/discussions/928, ab Feb. 2023). Analog Französisch: whisper.cpp #2660 *"Sous-titres réalisés par la communauté d'Amara.org"* (Dez. 2024).
- **Sprachwechsel/Übersetzen statt Transkribieren** (typisch für DACH-Nutzer mit englischen Einsprengseln): whisper.cpp #1800 (Jan. 2024): *"when the audio starts in a french and then switch to german, whisper.cpp transcribes the audio then translate it in french"*, *"the result is sometimes terrible"*. easyspeak #153 (Aug. 2026): *"Using Whisper 'base' without being able to define the desired language doesn't work properly, it keeps switching through several languages."* Transkribor #163 (Aug. 2026) meldet dasselbe für faster-whisper `multilingual=True`.
- **On-Device-Frameworks liefern schlechter als Desktop-Pipelines**: argmax-oss-swift/WhisperKit #528 (23. Aug. 2026, deutsches Audio, large-v2 via MacWhisper): *"Wrong language detection"*, *"Skipped sentences"*, *"Straight up hallucinations"*; mit whisper-diarization *"German is detected correctly and the transcription is much more complete and reliable on the same recordings"* (https://github.com/argmaxinc/argmax-oss-swift/issues/528).
- **Schweizerdeutsch**: Das deutschsprachige Transkriptionsprojekt Transkribor (Aug. 2026) plant ein optionales Schweizerdeutsch-Whisper-Modell und nennt Kandidaten: `apexAI-Switzerland/whisper-large-v3-swissgerman` (*"WER 13.31 on SPC-R"*, *"bernisch-lastig, gated"*, CC-BY-NC-4.0) und `Flurin17/whisper-large-v3-turbo-swiss-german` (*"~1.6 GB BF16"*, nicht gated, CC-BY-NC-4.0). Begründung: *"Dialekt-Interviews sind der Kern des Tools; ein feinabgestimmtes Modell könnte die Rohqualität vor der LLM-Korrektur verbessern."* Entscheidung: *"Erst messen, dann bauen."* (https://github.com/napoleonmm83/Transkribor/issues/130). In Issue #369 heißt es, dass für Schweizerdeutsch die nachgelagerte LLM-Korrektur *"zumindest auf Schweizerdeutsch"* etwa die Hälfte der Arbeit ausmacht. Hinweis: Beide Fine-Tunes sind **CC-BY-NC** – für eine kommerzielle App nicht ohne Lizenzklärung nutzbar. Weitere Repos: Till1983/cp-swiss-german-asr (Fine-tuned Whisper-medium/wav2vec2, Fehleranalyse pro Kanton, Ergebnisse nicht im README), flo7up/Swiss-german-transcription-test-bench (ETH SwissDial 1.1, 160 Clips, 8 Kantone).
- **Modellinstallation als Hürde**: easyspeak #153 scheiterte an deutschen Fine-Tunes (`D4ve-R/faster-whisper-large-v3-german`, `MR-Eder/faster-whisper-large-v3-turbo-german`) wegen 128 vs. 80 Mel-Bins.

**Ableitung:** Für DACH-Nutzer sind (a) feste Sprachwahl statt Auto-Detect, (b) VAD + Stille-Filter gegen "ZDF-Untertitel"-Halluzinationen, (c) ein realistisches Erwartungsmanagement für Schweizerdeutsch (Rohtranskript + Audio als Wahrheit) und (d) Groß-/Kleinschreibung/Interpunktion-Nachbearbeitung konzeptrelevant.

### 1.5 On-Device-Performance, Modellgröße, Akku (Priorität: mittel-hoch)

- Android/whisper.cpp: #1022 (Jun. 2023, Samsung Note10, tiny.en): 3-Sekunden-Aufnahme brauchte 31.227 ms, nach Build-Anpassung 14.762 ms; #1070 "Android Inference is too slow"; #1637 Pixel 7 zu langsam (https://github.com/ggml-org/whisper.cpp/issues). Ältere Issues, aber sie zeigen die Streuung über Geräte.
- iOS: WhisperKit #268 *"Unable to load model (or very very slow)"*, #393 CoreML-Ressourcenleck (Jan. 2026), #328 Videoanrufe ruckeln während Transkription.
- Modell-Download als Onboarding-Killer: Dictus (iOS-Diktier-App, Sep. 2026) #449: Parakeet-Modell ~445 MB, Download bricht im Hintergrund ab und startet *"from byte 0"*; Nutzer mussten die App 139 s, 172 s, zuletzt 239 s offen halten. #428: *"A model that never finishes compiling locks the user out of the whole app"* (https://github.com/getdictus/dictus-ios/issues/449, /428).
- Apple Watch: WhisperKit-Discussion #437 (9. Mär. 2026): tiny.en (73 MB) auf Apple Watch Series 11: *"19.2s load, 4.2s transcribe, +43MB"* für 5 s Audio; Autor: *"19.2s load time is not on-demand viable"*; Tokenizer muss gebündelt werden, da watchOS nicht auf HuggingFace zugreifen kann (https://github.com/argmaxinc/WhisperKit/discussions/437).

### 1.6 Erinnerungen, die nicht zuverlässig kommen (Priorität: mittel)

Belege stammen aus dem Habit-Tracker Loop (uhabits), dessen tägliche Erinnerung funktional identisch mit einer Tagebuch-Erinnerung ist:
- #2052 (Okt. 2024, Android 12/14): *"Sometime reminder trigger on exact time and sometime it triggers after few seconds"* (5–50 s Verzögerung), in einigen Szenarien *"it is not even triggering"*; vom Maintainer als "cant-reproduce" geschlossen (https://github.com/iSoron/uhabits/issues/2052).
- #2200 (Aug. 2025, Galaxy S25+, Android 15): *"Sticky notifications only stick in the first hour or two."* – bestätigter Bug.
- #852: Erinnerungen werden nach Neustart nicht nachgeholt, wenn das Gerät nicht entsperrt wurde.
- Easy Diary #15 (2018): Alarm stumm im Lautlos-Modus; #46 (2019) Reminder als Feature-Wunsch; Journiv #56/#67 (Nov. 2025) Erinnerungen als offene Wünsche, teils über selbst gehostete Push-Dienste.

**Ableitung:** Exakte Alarme (`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`), Reboot-Handling und Hinweise zu OEM-Akku-Optimierung gehören ins Android-Konzept; iOS: lokale Benachrichtigung mit Wiederholung plus Widget als zweiter Trigger.

### 1.7 Fehlende Plattform (Android) und fehlende Mobile-App (Priorität: mittel)

- DailyVox #4 (Jun. 2026): *"Any plans for Android Release?"*; README: *"Android in development"*.
- Journiv: "Mobile app implementation" ist mit 7 Upvotes die meistgewünschte Diskussion (Jan. 2026): *"I think it is a realistic expectation, or at least for Wife-Approval-Factor, to be able to journal from an app instead of going to a website."* Weitere Threads #148, #184 "Mobile Apps?" (https://github.com/orgs/journiv/discussions/348).
- Apple Journal ist iOS-only; Diarly (Setapp) Mac/iOS-only (Journiv #108).

### 1.8 Überfrachtung und Projekt-Verlässlichkeit (Priorität: mittel)

- Easy Diary #245 (Feb. 2025): *"On f-droid it's frequently get updates but not here why?"* – Sorge um Wartungsstatus; Journiv #586 (Aug. 2026): *"It's the project alive"*.
- Journiv-Maintainer: Mobile-Apps verzögern sich, bis *"$100/month in support or $1,200 total"* für eine LLC zur Store-Veröffentlichung zusammenkommen (Discussion #348). Für einen Indie-Inhaber ein realistischer Hinweis auf Fixkosten.
- Feature-Wünsche in Diary-Trackern sind lang (Grid-Ansicht, Sketchpad, Filter, PDF, Reminder in einem einzigen Issue, Easy Diary #46) – Indiz, dass "einfach" schnell verloren geht.

### 1.9 KI: Nachfrage und Skepsis (Priorität: mittel, Beleglage dünn)

- Nachfrage existiert: Journiv #420 (Feb. 2026) bittet um OpenAI-Integration, weil *"the mental energy required to face a blank page can be a significant barrier"* – aber mit Bedingung: eigener API-Key, *"privacy protection ensuring raw context isn't stored without user consent"*.
- Skepsis zeigt sich indirekt: Projekte werben mit "Privacy by architecture, not policy" (beneathatree/voice2do-local), memex verspricht *"There is no Memex server storing your journal"* und *"Zero vendor lock-in... one-click export all your records as standard Markdown files"* (https://github.com/memex-lab/memex, 713 Sterne). Dictus formuliert: *"100% offline — no cloud, no server, no data leaves the device"* und *"No bait-and-switch — free features never become paid."* (https://github.com/getdictus/dictus-ios/issues/54).
- Explizite Anti-KI-Zitate von Endnutzern konnten in der GitHub-Stichprobe **nicht** gefunden werden (Suche in Joplin/Journiv-Trackern ohne Treffer). Muss über Reddit/HN nachrecherchiert werden.

### 1.10 Barrierefreiheit (Priorität: niedrig in der Stichprobe, hoch in der Sache)

- Kaum Belege in Diary-Trackern. uhabits #665/#666 (2020) "Touch Target"/"Color Contrast is not respected", #2170 (2025) Konfetti-Animation ignoriert "Reduce Motion". Keine TalkBack/VoiceOver-Issues in den untersuchten Journal-Repos gefunden – eher ein Zeichen fehlender Aufmerksamkeit als fehlenden Bedarfs. Ein Sprachtagebuch ist per se für Menschen mit motorischen/visuellen Einschränkungen attraktiv; das sollte im Konzept als Zielgruppe benannt werden.

---

## 2. Was Nutzer sich wünschen (priorisiert, mit Belegen)

1. **Offline-Spracherkennung direkt im Recorder**: Fossify Voice Recorder #34 "Offline, privacy-respecting speech to text" (Feb. 2024) ist das reaktionsstärkste Issue des Projekts; Wunsch nach Suche über alle Transkripte: *"file191: 00:07 / file179: 12:23..."* (https://github.com/FossifyOrg/Voice-Recorder/issues/34).
2. **Freihändig / Bildschirm aus / Wake-Word**: DreamLog (Android 12+, 2026) startet per *"Hey DreamLog"*, stoppt nach 10 s Stille, *"Transcription and optional enrichment run on the phone"*, 75-MB-Modell (https://github.com/wivy1/dreamlog). Fossify #389 (Jul. 2026) Hintergrund-Wiedergabe; #54 Bluetooth-Headset-Mikrofon (GrapheneOS, Pixel 8).
3. **Smartwatch**: Fossify #291 (Jan. 2026, Galaxy Watch 7) – als wontfix geschlossen; WhisperKit-Benchmark zeigt technische Machbarkeit auf Apple Watch mit Einschränkungen (s. 1.5).
4. **Verschlüsselte, automatische Backups und verifizierbarer Restore** (Easy Diary #230/#233/#234; Fossify #62).
5. **Export in offene Formate mit Datumsbereich, inkl. Audio** (Journiv #386: PDF nach Datumsbereich; Apple-Journal-Konverter; DailyVox exportiert *"PDF, JSON, Markdown, CSV, or AES-256 encrypted backup"*).
6. **Audio-Wellenform mit Markierungen**: Journiv #88 (Nov. 2025): *"Audio notes or journals which have a waveform horizontally"* plus Lesezeichen im Audio.
7. **Kurze, niedrigschwellige Einträge**: DailyVox begrenzt bewusst auf 42-Sekunden-Aufnahmen; Journiv #86 "2/5 minute Journal"; Journiv #420 gegen die "blank page".
8. **Feste Sprachwahl inkl. Schweizerdeutsch-Option** (Transkribor #130/#132).
9. **Widgets, Siri Shortcuts, Lock-Screen-Schnellstart** (DailyVox README).
10. **Zuverlässige tägliche Erinnerung** (uhabits #2052/#2200, Easy Diary #46, Journiv #56).
11. **Ehrliche, dauerhafte Preislogik**: "free features never become paid" (Dictus #54); Ablehnung nachträglicher Paywalls (Journiv #425).

---

## 3. Vorbilder: Was Nutzer/Entwickler an einzelnen Apps loben

| App/Projekt | Was gelobt/vorbildlich ist | Quelle |
|---|---|---|
| DailyVox (iOS, kostenlos) | "Data Not Collected"-Label, keine Netzwerkaufrufe, `SFSpeechRecognizer` on-device unconditional (v1.11.0), Sprachen DE/EN/FR/ES/IT, 42-s-Einträge, Export PDF/JSON/MD/CSV/AES-256, Biometrie-Lock, Widgets, Siri Shortcuts | https://github.com/intrepidkarthi/dailyvox |
| memex (iOS/Android, GPL-3.0, 713 Sterne) | Alles lokal (SQLite + Dateisystem), Markdown als Endformat, "Zero vendor lock-in", Ein-Klick-Export | https://github.com/memex-lab/memex |
| Dictus (iOS, MIT) | Open Core mit klarer Free/Pro-Grenze, "No bait-and-switch", StoreKit 2, on-device WhisperKit/Parakeet | https://github.com/getdictus/dictus-ios/issues/54 |
| DreamLog (Android) | Wake-Word, Auto-Stop bei Stille, kleines 75-MB-Modell, Netzwerk nur für Modell-Download | https://github.com/wivy1/dreamlog |
| Transkribor (Desktop, DE) | "Deine Aufnahmen bleiben bei dir", Schweizerdeutsch-Pipeline mit Dialektglättung, Messen vor Bauen | https://github.com/napoleonmm83/Transkribor |
| Journiv (self-hosted, 1,2k Sterne) | Mood-Tracking, Prompts, Importer für Day One/Daylio; Nutzer: *"overall I'm very happy with Journiv and grateful for the project"* | https://github.com/orgs/journiv/discussions/386 |

---

## 4. Zahlen und Fakten mit Prüfbedarf (mustVerify)

- WER 13,31 (SPC-R) für `apexAI-Switzerland/whisper-large-v3-swissgerman`; `Flurin17/whisper-large-v3-turbo-swiss-german` ~1,6 GB; beide CC-BY-NC-4.0 (Transkribor #130, 12. Aug. 2026).
- Apple Watch Series 11, WhisperKit tiny.en 73 MB: 19,2 s Laden, 4,2 s Transkription, +43 MB RAM (Discussion #437, 9. Mär. 2026).
- Dictus Parakeet-Modell ~445 MB; Downloads scheiterten nach 139 s/172 s, Erfolg nach 239 s (Issue #449, 1. Sep. 2026).
- whisper.cpp tiny.en auf Samsung Note10: 31.227 ms → 14.762 ms für 3 s Audio (Issue #1022, Jun. 2023).
- Journiv-Umfrage Verschlüsselung: 17 Stimmen, 47 % serverseitig, 35 % E2EE, 17 % keine (Discussion #567, 30. Mai 2026).
- Journiv Mobile-App-Finanzierungsziel: 100 $/Monat bzw. 1.200 $ für LLC (Discussion #348, Jan. 2026).
- Sterne: journiv-app 1,2k; memex 713; dailyvox 16; Transkribor n/a (GitHub-Topic-Seiten, 3. Sep. 2026).
- Easy Diary: 1.200 Fotos, Restore nur ~2 pro Durchlauf (Issue #252, 25. Aug. 2026).

---

## 5. Konsequenzen für das Konzept (Kurzfassung)

1. **Export und Backup als Kernfunktion, nicht als Einstellung**: offene Formate (Audio + Markdown/JSON), Datumsbereich, verschlüsselte Backup-Datei, Restore-Test im Onboarding. Der QR-initiierte Transfer sollte dieselbe Datei nutzen.
2. **Robuste Aufnahme**: Absicherung gegen App-Kill, Anruf, Bildschirmsperre; Aufnahme in Chunks schreiben; Bluetooth-Mikrofone; optional Wake-Word/Bildschirm-aus-Start (Android-Vordergrunddienst, iOS Audio-Hintergrundmodus).
3. **Transkription**: feste Sprachwahl (de-DE/de-AT/de-CH/en), VAD + Stille-Filter gegen Halluzinationen, Nachbearbeitung für Groß-/Kleinschreibung/Interpunktion, Erwartungsmanagement bei Schweizerdeutsch, Modell-Download resume-fähig und klein starten (tiny/base/small), Audio bleibt immer die Wahrheit.
4. **Erinnerungen**: exakte Alarme, Reboot-Handling, Widget als zweiter Einstieg, Erklärung der OEM-Akku-Optimierungen.
5. **Monetarisierung**: klare, unveränderliche Free-Grenze, kein späteres Einziehen von Funktionen, Einmalkauf oder Lifetime als Option prüfen (Dictus: "monthly sub vs yearly vs lifetime" offen).
6. **Kommunikation**: "Data Not Collected"-Label anstreben und sichtbar machen; keine Analytics-SDKs.
7. **Android zuerst nicht vernachlässigen** – die Lücke bei Voice-Journals ist auf Android größer als auf iOS.

---

## 6. Quellenliste

- https://github.com/journiv/journiv-app/issues/253 (Apple Journal "trapped", 5. Jan. 2026)
- https://github.com/journiv/journiv-app/issues/58 (Daylio, 8. Nov. 2025)
- https://github.com/journiv/journiv-app/issues/14 (Day One, 3. Nov. 2025)
- https://github.com/journiv/journiv-app/issues/108 (Diarly/Setapp, 19. Nov. 2025)
- https://github.com/journiv/journiv-app/issues/302 (Diarium, 14. Jan. 2026)
- https://github.com/journiv/journiv-app/issues/186 (Klartext-Datenbank, 6. Dez. 2025)
- https://github.com/journiv/journiv-app/issues/540 (Datenverlust nach Auto-Update, 29. Apr. 2026)
- https://github.com/journiv/journiv-app/issues/530, /109, /536 (Export-Fehler)
- https://github.com/journiv/journiv-app/issues/88 (Wellenform), /420 (KI), /56, /67 (Erinnerungen)
- https://github.com/orgs/journiv/discussions/567, /348, /425, /386
- https://github.com/kpod13/journal2day1 ; https://github.com/jeffd/DayOneToJournal ; https://github.com/tarikbc/apple-journal-importer ; https://github.com/miloshimself/journey2dayone
- https://github.com/hanjoongcho/aaf-easydiary/issues/252, /233, /234, /230, /200, /109, /46, /15, /245, /184
- https://github.com/billthefarmer/Diary/issues (#39, #59, #65)
- https://github.com/FossifyOrg/Voice-Recorder/issues/34, /56, /62, /291, /54, /389
- https://github.com/iSoron/uhabits/issues/2052, /2200, /852, /665, /666, /2170
- https://github.com/openai/whisper/discussions/928 ; https://github.com/ggml-org/whisper.cpp/issues/2660, /1800, /1022, /1070, /1637
- https://github.com/SYSTRAN/faster-whisper/issues/601, /1322, /874
- https://github.com/argmaxinc/argmax-oss-swift/issues/528, /268, /393, /328 ; https://github.com/argmaxinc/WhisperKit/discussions/437
- https://github.com/ctsdownloads/easyspeak/issues/153
- https://github.com/napoleonmm83/Transkribor ; …/issues/130, /132, /136, /163, /369
- https://github.com/Till1983/cp-swiss-german-asr ; https://github.com/flo7up/Swiss-german-transcription-test-bench ; https://github.com/studerus/swiss_german_gemini
- https://github.com/intrepidkarthi/dailyvox ; …/issues/4
- https://github.com/memex-lab/memex ; https://github.com/wivy1/dreamlog ; https://github.com/getdictus/dictus-ios ; …/issues/54, /449, /428
- https://github.com/pluja/sasayaki ; https://raw.githubusercontent.com/pluja/awesome-privacy/main/README.md
- https://github.com/topics/voice-journal ; https://github.com/topics/journaling-app

## 7. Offene Punkte für eine Nachrecherche mit vollem Netzzugang

- Wörtliche App-Store-/Play-Store-Rezensionen (DE/AT/CH) zu Day One, Journey, Diarium, Daylio, Apple Journal, Reflectly, Voice Diary-Apps – insbesondere zu Abo-Preisen, Sync-Ausfällen, Datenverlust.
- Reddit (r/Journaling, r/privacy, r/degoogle, r/androidapps) und Hacker News zu "voice journal", "local whisper diary", KI-Ablehnung.
- Deutschsprachige Foren/Blogs (z. B. heise, Kuketz, Android-Hilfe, MacTechNews) zu Tagebuch-Apps und Datenschutz.
- Aktuelle Preise (Day One Premium, Journey, Diarium, Daylio) mit Datum.
- Apple `SpeechAnalyzer`/`SpeechTranscriber` (iOS 26): offizielle Liste unterstützter Locales (de-CH?) – developer.apple.com war nicht lesbar.
- Lizenzlage Schweizerdeutsch-Whisper-Modelle (CC-BY-NC) und kommerzielle Alternativen.
