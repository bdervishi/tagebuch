# Nachrecherche Lücke 1: Echte Nutzerstimmen und verifizierte Store-Kennzahlen aus DE/AT/CH

Blickwinkel: `luecke:Echte Nutzerstimmen und verifizierte Store-Kennzahlen aus DE/AT/CH` · Stand: 3. September 2026

## 0. Ergebnis vorab und methodische Grenzen (zuerst lesen)

**Das Ziel (mind. 60 datierte Store-/Reddit-/Forenzitate, davon 30 auf Deutsch, plus verifizierte Sterne/Preise pro Storefront) konnte in dieser Sitzung nicht erreicht werden.** Grund ist nicht fehlende Quellenlage, sondern die Netzwerkpolitik der Sitzung:

1. Der Egress-Proxy blockierte (HTTP 403 „organization policy", Prüfung am 3.9.2026) sämtliche relevanten Hosts: `apps.apple.com`, `itunes.apple.com` (Lookup-API und RSS-Rezensionsfeed), `play.google.com`, `communities.apple.com`, `discussions.apple.com`, `reddit.com`/`old.reddit.com`, `news.ycombinator.com`, `hn.algolia.com`, `kuketz-blog.de`, `heise.de`, `golem.de`, `maclife.de`, `mactechnews.de`, `iphone-ticker.de`, `ifun.de`, `appgefahren.de`, `android-hilfe.de`, `justuseapp.com`, `appfollow.io`, `appagg.com`, `appbrain.com`, `apkcombo.com`, `apkpure.com`, `alternativeto.net`, `trustpilot.com`, `producthunt.com`, `g2.com`, `medium.com`, `dev.to`, `stackoverflow.com`, `wikipedia.org`, `substack.com`, `besteerfahrungen.de`, `mind-verse.de`, `otto.de`, `bernardzitzer.com`, `bjoern-eickhoff.de`, `s3nnet.de`, `toldays.de`, `arminschoepf.com`, `getdailyvox.com`, `cortexos.app`, `voiceflowjournal.com`, `speakwiseapp.com`, `spokenly.app`, `voicescriber.com`, `journalinghabit.com`, `danrecommends.com`, `nubiapage.com`, `yaps.ai`, `audionotes.app`, `reflection.app`, `mwm.ai`.
2. Erreichbar waren ausschließlich `github.com` (Repos, Issues, Topic-Seiten; die GitHub-Suchseite lief nach wenigen Abfragen in ein 429-Rate-Limit) und `developer.apple.com` (Developer Forums). Der GitHub-MCP-Server ist auf das Repo `bdervishi/tagebuch` beschränkt und lieferte für alle Fremd-Repos leere bzw. verweigerte Ergebnisse.
3. Das Websuche-Kontingent der Sitzung (200 Abfragen, sitzungsweit) war nach 14 eigenen Suchen erschöpft. Die 14 Suchen lieferten aber Snippets mit einigen wörtlichen Rezensionsfragmenten aus dem deutschen App Store (Day One, Diarium) sowie Preise/Sterne aus Store-Listings (VoiceFlow, FourYou, EchoVault, AudioPen).

Konsequenz für die Autoren: **Alle Zahlen in diesem Bericht bleiben `mustVerify`.** Wörtliche Store-Zitate sind Snippet-Fragmente ohne Nutzername, Version und exaktes Datum; sie sind als Hinweis auf Tonalität brauchbar, nicht als Beleg. Abschnitt 6 beschreibt exakt, wie die Lücke in einer Sitzung ohne Proxy-Sperre in unter zwei Stunden geschlossen werden kann (URL-Muster, Tools, App-IDs).

Was dieser Bericht dennoch neu beiträgt (gegenüber `nutzerfeedback.md`, das nur GitHub-Issues auswertete):
- Erstmals **Snippet-Fragmente echter deutschsprachiger App-Store-Rezensionen** (Day One, Diarium) mit Kategorisierung.
- **Verbatim-Play-Store-Rezensionen**, die ein Entwickler (Easy Diary, 557 Sterne, Play + F-Droid, DE-Lokalisierung) selbst als Issues archiviert hat – inklusive eines deutschsprachigen Nutzers („Heinrich IV.").
- **Deutsch-/Dialektspezifische Transkriptionsprobleme** aus Apple Developer Forums (Mai 2026, Nov 2025) und einem Schweizer Transkriptions-Projekt (Aug 2026, mit WER-Zahlen für Schweizerdeutsch-Whisper-Modelle).
- Titel und IDs deutschsprachiger Apple-Community-Threads zu Apple Journal (Export, Day-One-Import), Kuketz-Artikel und MacLife-Artikel zum Day-One-Abozwang als **konkrete Abrufziele**.

---

## 1. Wörtliche Nutzerstimmen, kategorisiert

Legende Kategorien: **[ABO]** Abo-/Preiskritik · **[DE-STT]** Transkriptionsqualität Deutsch/Dialekt · **[ERINNERUNG]** Erinnerungen unzuverlässig/fehlend · **[VERLUST]** Datenverlust/Sync-/Backup-Ausfall · **[EXPORT]** Export/Lock-in · **[UX]** Bedienung/Überfrachtung · **[KI]** KI-Ablehnung oder -Wunsch · **[PRIVACY]** Datenschutzbedenken · **[PLATTFORM]** Plattform-/API-Einschränkung.

Herkunftskennzeichen: (S) = Suchmaschinen-Snippet einer Store-Seite, Nutzername/Version/Datum nicht sichtbar; (G) = GitHub-Issue, vollständig gelesen; (A) = Apple Developer Forums, vollständig gelesen.

### 1.1 Deutschsprachige Stimmen (App Store DE, GitHub, Apple-Foren)

| # | App | Zitat (Original) | Kat. | Datum / Quelle |
|---|-----|------------------|------|----------------|
| 1 | Day One (iOS, DE-Store) | Day One sei eine App, „die wirklich ihr Geld für ein Abo wert ist" | [ABO] positiv | (S) undatiert, https://apps.apple.com/de/app/day-one-t%C3%A4gliches-tagebuch/id1044867788?see-all=reviews&platform=iphone |
| 2 | Day One (iOS, DE) | Nutzer musste sich „an das omnipräsente Abo-Modell" gewöhnen, verstehe aber „als Kaufleute und IT-Interessierte die Hintergründe und Vorzüge des Prinzips" | [ABO] ambivalent | (S) undatiert, ebd. |
| 3 | Day One (iOS, DE) | Nutzer schätzen, dass Day One „auf eigenen Servern gespeichert und Ende-zu-Ende verschlüsselt ist", und bevorzugen das Abo „gegenüber Werbefinanzierung bei persönlichen Daten" | [PRIVACY] [ABO] | (S) undatiert, ebd. |
| 4 | Day One (Mac App Store DE) | eigene Rezensionsseite existiert: id1055511498 | – | https://apps.apple.com/de/app/day-one/id1055511498?mt=12&see-all=reviews&platform=mac |
| 5 | Day One (MacLife) | „In den App Stores reagieren viele Nutzer von Day One mit schlechten Bewertungen und kündigen an, auf eine andere App umzusteigen." (Redaktionstext zur Abo-Umstellung) | [ABO] | (S) Artikel „Nach Photoshop, 1Password und TextExpander: Digitales Tagebuch Day One mit Abozwang", https://www.maclife.de/news/nach-photoshop-1password-textexpander-digitales-tagebuch-day-one-abozwang-10093275.html (Erstveröffentlichung 2017, Datum prüfen) |
| 6 | Diarium (iOS/Mac, DE) | „Die gesamte App ist gut aufgebaut und ehrlich beschrieben, eine tolle Oberfläche, in Deutsch, einfach zu bedienen, sehr umfangreich" | [UX] positiv | (S) undatiert, https://apps.apple.com/de/app/diarium-privates-tagebuch/id1502834782?mt=12&see-all=reviews&platform=mac |
| 7 | Diarium (DE) | „Es ist kein Abo! Eine Einmalzahlung von knapp 10 Euro und man kann für immer Tagebuch schreiben" | [ABO] positiv (Einmalkauf) | (S) undatiert, ebd. / https://apps.apple.com/ch/app/1436044299?see-all=reviews&platform=iphone |
| 8 | Diarium (DE) | „Das Synchronisation zwischen MacBook und iPad ist perfekt" | [VERLUST] Gegenbeispiel (Sync lobend) | (S) undatiert, ebd. |
| 9 | Diarium (DE) | „Viele Fragen an den Support wurden alles klar beantwortet" | [UX] Support | (S) undatiert, ebd. |
| 10 | Apple Journal (Apple Community DE) | Thread-Titel: „Keine Export Funktionen in Journal App" | [EXPORT] | https://communities.apple.com/de/thread/255508808 (blockiert; Thread-Text nicht lesbar) |
| 11 | Apple Journal (Apple Community DE) | Thread-Titel: „DayOne-Einträge ins Journal importieren" | [EXPORT] Migration | https://communities.apple.com/de/thread/256153585 (blockiert) |
| 12 | Apple Journal (DE-Blogs) | Export nur über Einstellungen → Apps → Journal → „Alle Journal-Einträge exportieren"; Nutzer bemängeln laut Snippet „fehlende Exportoptionen und die Unmöglichkeit, Einträge außerhalb von iCloud zu sichern" | [EXPORT] [PRIVACY] | (S) https://www.appgefahren.de/journal-app-so-exportiert-sichert-und-druckt-ihr-eure-eintraege-368533.html ; https://www.iphone-ticker.de/journal-die-einstellungen-von-apples-tagebuch-app-anpassen-226666/ |
| 13 | Easy Diary (Android, Play/F-Droid) – Nutzer „Heinrich IV." | „export mit txt oder pdf zur weiteren bearbeitung am pc" | [EXPORT] | (G) 7. Aug. 2020, https://github.com/hanjoongcho/aaf-easydiary/issues/128 |
| 14 | Easy Diary – „Heinrich IV." | „die befehlszeile optional vom oberen an den unteren bildrand plazieren" (Einhandbedienung) | [UX] | (G) ebd. |
| 15 | Easy Diary – „Heinrich IV." | „in der kalenderübersicht einen direkten zugriff auf die tage ohne eintrag" | [UX] | (G) ebd. |
| 16 | Easy Diary – F-Droid-Nutzer (lieferte deutsche Übersetzung) | „the app still shuts down, when i try to open the faq" / „i would love to be able to export to txt and maybe chose which entries should be included" | [VERLUST] Stabilität, [EXPORT] | (G) 4. Sep. 2020, https://github.com/hanjoongcho/aaf-easydiary/issues/132 |
| 17 | Diary (billthefarmer, Android/F-Droid) – deutschsprachiger Nutzer | „Ho to restore an Backup? There is noch menu or button" | [VERLUST] [UX] | (G) 7. Nov. 2024, https://github.com/billthefarmer/diary/issues/236 |
| 18 | Transkribor (Schweizer Transkriptions-Tool, whisper large-v3) | „Dialekt-Interviews sind der Kern des Tools; ein feinabgestimmtes Modell könnte die Rohqualität vor der LLM-Korrektur verbessern." – Kandidaten: „apexAI-Switzerland (large-v3, WER 13.31) — gated, CC-BY-NC-4.0" und „Flurin17 (large-v3-turbo, ~1,6 GB)"; Einschätzung: „Das aktuelle large-v3-Modell meistert Schweizerdeutsch bereits gut." Entscheidung: „Erst messen, dann bauen" | [DE-STT] Dialekt | (G) 11. Aug. 2026, https://github.com/napoleonmm83/Transkribor/issues/130 |
| 19 | Transkribor | Prompts „für Schweizerdeutsch→Standarddeutsch entwickelt", Varianten für andere Sprachen „plausibel, aber ungemessen" | [DE-STT] | (G) 12. Aug. 2026, https://github.com/napoleonmm83/Transkribor/issues/136 |
| 20 | Transkribor README | Tool „glättet" Schweizerdeutsch zu „lesbarem Standarddeutsch"; Transkription „vollständig lokal", KI-Korrektur optional online oder lokal (Ollama) | [DE-STT] [PRIVACY] | (G) https://github.com/napoleonmm83/Transkribor |
| 21 | Apple Diktat Deutsch (Dev Forum, Nutzer robu29) | „Dictation in German has a couple of persistent bugs." – „Saying ‚Anführungszeichen' inserts punctuation AND writes out the word" – „Compound words incorrectly split into separate words: Compound words are either cohesive or hyphenated, the english spelling with two separate words is simply wrong!" – „German dictation adds spaces before and after hyphens." | [DE-STT] | (A) Mai 2026, https://developer.apple.com/forums/thread/826756 |
| 22 | Siri/App Intents Deutsch (Dev Forum) | „when user said ‚Prüfung der Bluetooth Funktion' … in my app, it only can get ‚Bluetooth Funktion'. This behaviour only happened in German version." | [DE-STT] | (A) Nov. 2025, https://developer.apple.com/forums/thread/806911 |
| 23 | Kuketz-Blog | Artikel-Titel: „Android: Miserabler Datenschutz bei Tagebuch-Apps" (Inhalt nicht abrufbar) | [PRIVACY] | https://www.kuketz-blog.de/android-miserabler-datenschutz-bei-tagebuch-apps/ |
| 24 | Voice Journal (com.jr44.voicejournal, Play DE) | Listing: „automatische Transkription in Deutsch, 100 % offline … keine Cloud, keine Konten, keine Werbung … Export als JSON oder Text" (Anbietertext, keine Rezension) | [PRIVACY] [EXPORT] | (S) https://play.google.com/store/apps/details?id=com.jr44.voicejournal&hl=de |
| 25 | TOLDAYS (toldays.de) | „Original-Audioaufnahmen werden dabei nicht dauerhaft gespeichert." / „Ein sanfter Anstupser am Abend hält die Gewohnheit am Leben." (Anbietertext) | [PRIVACY] [ERINNERUNG] | (S) https://toldays.de/ |
| 26 | Murmeln: Sprachtagebuch (DE-Store, id1510564828) | weiterer deutschsprachiger Voice-Diary-Wettbewerber, bisher in keinem Bericht erfasst | – | (S) https://apps.apple.com/de/app/murmeln-sprachtagebuch/id1510564828 |

### 1.2 Englischsprachige Stimmen zu Voice-First-Apps (Store-Snippets)

| # | App | Zitat / Aussage | Kat. | Quelle |
|---|-----|-----------------|------|--------|
| 27 | EchoVault (Android) | Rezensenten berichten, die App starte Aufnahmen „frequently not" und erfordere „multiple force closes before capturing audio"; „Data loss has also been reported, with some users losing all entries." | [VERLUST] | (S) https://play.google.com/store/apps/details?id=com.echovault.app&hl=en |
| 28 | EchoVault | Free: „5 voice journal entries per week"; Pro „$4.99/month"; „Whisper-powered transcription with 95% accuracy, works offline" | [ABO] | (S) ebd. |
| 29 | AudioPen | „Slow processing is a repeated complaint in reviews, and authentication issues have blocked some users from even accessing the app." Free „10 notes with a 3-minute cap", Paid „around $99 a year" | [UX] [ABO] | (S) https://www.yaps.ai/blog/voicenotes-alternative |
| 30 | Voicenotes | „Billing and cancellation complaints show up regularly in reviews for Voicenotes." | [ABO] | (S) https://www.audionotes.app/compare/audionotes-vs-voicenotes |
| 31 | Whisper Memos (iOS) | „some users reported occasional issues with app crashes, recording reliability, and subscription management"; „surpasses them in accuracy"; Sprachen inkl. Deutsch | [ABO] [VERLUST] [DE-STT] positiv | (S) https://apps.apple.com/us/app/whisper-memos-speech-to-text/id6443658039?see-all=reviews&platform=iphone |
| 32 | FourYou (iOS) | „4.8 average rating"; „free version of limited functionality, a one-time purchase option up to $75, and subscription options ranging from $4 to $30 per month"; „has not received enough ratings or reviews on some App Store regions" | [ABO] | (S) https://alternativeto.net/software/fouryou--guided-audio-journal/about ; https://arminschoepf.com/fouryou/ |
| 33 | VoiceFlow: KI-Sprachtagebuch (iOS DE, Carl Brindle) | „Premium is now available for $2.99/month or $9.99/year (saving 72%)"; „recording, transcription, and analysis happen completely on your device" | [ABO] [PRIVACY] | (S) https://apps.apple.com/de/app/voiceflow-ki-sprachtagebuch/id6755595633 |
| 34 | DailyVox (iOS) | README: „Free forever" · v1.10.0 (Aug 2026) „Spanish, French, German, and Italian language support added" · v1.11.0 (Aug 2026): on-device „always" – „if no on-device model exists, the app stops rather than routing audio to cloud servers" | [PRIVACY] [DE-STT] | (G) https://github.com/intrepidkarthi/dailyvox |
| 35 | DailyVox – Nutzer Vikranttiw | Issue „[Feature] Any plans for Android Release?" | [PLATTFORM] Android-Wunsch | (G) 3. Aug. 2026, https://github.com/intrepidkarthi/dailyvox/issues/4 |
| 36 | Flint Voice (Klu Technologies Oy) | „one-time purchase with no subscription"; „storing data privately on your phone" | [ABO] | (S) https://apps.apple.com/us/app/flint-voice/id6760716646 |
| 37 | CortexOS | Suchergebnisse „primarily contained information from CortexOS's own website and app store listing rather than independent user reviews" – keine unabhängige Nutzerstimme auffindbar | – | (S) https://play.google.com/store/apps/details?id=com.cortexos.app |

### 1.3 Verbatim-Play-Store-Rezensionen, vom Entwickler archiviert (Easy Diary, Android)

Der Entwickler von Easy Diary (Kotlin, Play + F-Droid, 557 GitHub-Sterne, Sprachen u. a. Deutsch, Backup via Google Drive) legt Play-Store-Rezensionen als Issues ab. Das sind echte Store-Stimmen mit Datum:

| # | Zitat | Kat. | Datum / URL |
|---|-------|------|-------------|
| 38 | „backup to device can't be seen where it is saved on interbal device" (wichtig bei Gerätewechsel/Reparatur) · „add notification reminders for urgent upcoming tasks" | [VERLUST] [ERINNERUNG] | 28. Dez. 2021, https://github.com/hanjoongcho/aaf-easydiary/issues/184 |
| 39 | „I would really like to use this app for journaling, but the one thing that holds me back is the fact that, if you exit the app or navigate to another app via the Recents button, the screen content that you were just writing is still visible in the Recents menu snapshot view." | [PRIVACY] | 2. Jan. 2022, https://github.com/hanjoongcho/aaf-easydiary/issues/186 |
| 40 | „It would be very useful to be able to attach any kind of file(s) to the each diary item. For example, a previously recorded audio file…" | [UX] Audio-Wunsch | 2. Jan. 2022, https://github.com/hanjoongcho/aaf-easydiary/issues/187 |
| 41 | „Belle application. Dommage n'a pas de dossiers.(FOLDERS ) ni étiquettes (TAG) pour organiser les notes." | [UX] | 28. Dez. 2021, https://github.com/hanjoongcho/aaf-easydiary/issues/185 |
| 42 | (JP) Wunsch nach HTML-Export „alle Einträge / monatsweise / nur ausgewählte" | [EXPORT] | 18. Nov. 2021, https://github.com/hanjoongcho/aaf-easydiary/issues/175 |
| 43 | „If I change week start day, it change in the calender in the home screen, but it doesn't change in the window where I want to write a new diary." | [UX] | 6. Jun. 2023, https://github.com/hanjoongcho/aaf-easydiary/issues/216 |
| 44 | „Insufficient permission for the request feature" – Backup (Drive und Gerät) komplett blockiert auf Pixel 5/Android 13, App fragte nie nach Berechtigung; Nutzer will App erst nutzen, „once the backup functionality is restored" | [VERLUST] | 11. Nov. 2022, https://github.com/hanjoongcho/aaf-easydiary/issues/200 |
| 45 | „Recently I foolishly added another fingerprint to my device lock and all apps that relied on fingerprint unlock had to have their locks reset." – App verlangt 4-stellige PIN, die der Nutzer nie gesetzt hat; Aussperrung aus dem eigenen Tagebuch | [VERLUST] Zugang | 16. Aug. 2022, https://github.com/hanjoongcho/aaf-easydiary/issues/197 |
| 46 | „I have a backup file from 5th Jan 2020. But there is no option to choose backup file manually." | [VERLUST] | 22. Mär. 2020, https://github.com/hanjoongcho/aaf-easydiary/issues/111 |

### 1.4 Weitere GitHub-Stimmen zu kommerziellen Apps (Lock-in, Migration)

| # | Zitat | Kat. | Datum / URL |
|---|-------|------|-------------|
| 47 | Apple Journal: „I have about eighty entries trapped in Apple Journal. I'd love to be able to break them free and import them—including attached photos, audio files and geolocation data" | [EXPORT] | 5. Jan. 2026, https://github.com/journiv/journiv-app/issues/253 |
| 48 | Diarly: „it's the Day One equivalent that's included as part of the SetApp bundle, so I assume there's some degree of an install base there. I'd love to be able to bring my Diarly archive over to Journiv." | [EXPORT] | 19. Nov. 2025, https://github.com/journiv/journiv-app/issues/108 |
| 49 | Diarium: „quite a popular cross-platform diary app"; Diarium exportiert JSON „including media and attachments", „options to get a single or separate files per day" | [EXPORT] positiv für Diarium | 14. Jan. 2026, https://github.com/journiv/journiv-app/issues/302 |
| 50 | Day One: „I was able to successfully import my Day One journals into journiv" | [EXPORT] | 13. Jan. 2026, https://github.com/journiv/journiv-app/issues/299 |
| 51 | Day One: „I've been juggling between Day One and Obsidian (because I love using plain text as much as I can)" | [EXPORT] | https://github.com/MarcDonald/obsidian-day-one-importer/issues/15 |
| 52 | Day One: „Currently, I am journaling with Day One (a popular journaling app). One feature I like is On that Day." | [UX] Feature-Anker | https://github.com/liamcain/obsidian-calendar-plugin/issues/217 |
| 53 | Apple Journal (apple-journal-cli): „Back up your journal first. journal-cli writes directly to Apple Journal's private, undocumented data store." – Datenbank `group.com.apple.moments/Library/moments.sqlite`, Eintragstext als RTF „without encryption at the local level" | [EXPORT] [PRIVACY] | https://github.com/omarshahine/apple-journal-cli (16 Sterne, aktiv Sep 2026) |
| 54 | StoryPad (Play/App Store, „over 100k downloads"): Nach Neuinstallation „only 2025 records restored successfully; 2026 records failed despite being synced to Google Drive (~400 MB)"; gekaufte Add-ons „inaccessible post-reinstall" | [VERLUST] [ABO] | 11. Mär. 2026, https://github.com/theachoem/storypad/issues/611 |
| 55 | StoryPad: Nutzer schlägt „Serverless Zero-Knowledge Journal Encryption using Passkeys" vor | [PRIVACY] | 11. Jan. 2026, https://github.com/theachoem/storypad/issues/568 |
| 56 | Diary (billthefarmer): „Is there any way to have the app remind me of an event?" | [ERINNERUNG] | 4. Feb. 2023, https://github.com/billthefarmer/diary/issues/209 |
| 57 | June (Android, Play): Issues „Individual Journal Export" (#66) und „Markdown file import" (#67) | [EXPORT] | 21. Aug. 2026, https://github.com/DenserMeerkat/June/issues |
| 58 | One Second Diary: „How to prevent Google Photos backup" | [PRIVACY] | 31. Aug. 2023, https://github.com/KyleKun/one_second_diary/issues/97 |

### 1.5 Transkriptions-Engine: Deutsch-Halluzinationen und Plattform-Limits

| # | Zitat | Kat. | Datum / URL |
|---|-------|------|-------------|
| 59 | faster-whisper: Halluzination „Untertitel im Auftrag des ZDF, 2020" bei Stille/Fremdaudio | [DE-STT] | 4. Aug. 2024, https://github.com/SYSTRAN/faster-whisper/issues/949 |
| 60 | whisperX, 90-min-deutsche Datei: „Untertitel der Amara.org-Community", „Untertitel im Auftrag des ZDF für funk, 2017" → Alignment-Fehler | [DE-STT] | 8. Mai 2023, https://github.com/m-bain/whisperX/issues/230 |
| 61 | whisper.cpp: Nutzer FlavianDiethelmEPS will „whisper-large-v3-turbo-swiss-german" nach GGML konvertieren; scheitert („header too large"), Issue „stale" | [DE-STT] Dialekt | 26. Sep. 2025, https://github.com/ggml-org/whisper.cpp/issues/3431 |
| 62 | SFSpeechRecognizer offline: „I was under the impression, with offline speech to text, that there was no limit … Yet when I process: speechRecognizer.recognitionTask it quits after one minute." | [PLATTFORM] | Dez. 2021, https://developer.apple.com/forums/thread/697188 |
| 63 | Apple-Antwort (Zitat der Doku): „Plan for a one-minute limit on audio duration. … the framework stops speech recognition tasks that last longer than one minute." | [PLATTFORM] | Sep. 2021, https://developer.apple.com/forums/thread/105405?answerId=686599022 |
| 64 | SpeechTranscriber (iOS 26): `isAvailable == false` auf iPhone 11/11 Pro/11 Pro Max/SE 2; Hypothese „16-core Neural Engine" nötig; „Apple should clearly state this requirement in their documentation." Simulator nicht unterstützt. | [PLATTFORM] | Nov. 2025 – Mär. 2026, https://developer.apple.com/forums/thread/806765 |
| 65 | HeikoTranslate (dt. Entwickler): `requiresOnDeviceRecognition = true` als „hard requirement"; sonst „audio goes to Apple and three published documents become untrue at once"; Einschränkung: „Segment confidence is frequently reported as 0.0 for partial results" | [PRIVACY] [PLATTFORM] | 17. Aug. 2026, https://github.com/Georg-Klock/HeikoTranslate/issues/135 |
| 66 | Apple-Mitarbeiter zu SpeechTranscriber-Locales: „SpeechTranscriber erroneously listed Arabic as ‚supported'. It actually wasn't." | [PLATTFORM] | Jan. 2026, https://developer.apple.com/forums/thread/797835 |

**Zählung:** 66 datierte bzw. quellenzugeordnete Belege, davon 26 mit deutschem Bezug (Nr. 1–26), aber nur **9 echte deutschsprachige Store-Rezensionsfragmente** (Nr. 1–3, 6–9, 13–15). Das Ziel von 30 deutschen Originalzitaten ist damit **nicht** erreicht; die Lücke bleibt offen.

---

## 2. Verifizierte vs. unverifizierte Store-Kennzahlen (Stand 3.9.2026)

Keine einzige Store-Seite war direkt abrufbar. „Quelle" nennt daher den Snippet-Ursprung. Alle Werte `mustVerify`.

| App | Store-ID / Paket | Sterne | Anzahl | Preis (Währung/Storefront) | Quelle / Status |
|-----|------------------|--------|--------|----------------------------|-----------------|
| Day One | iOS id1044867788; Mac id1055511498 | – | „200.000 5-Sterne-Bewertungen weltweit" (Marketing) | Silver 49,99 $/J, Gold 74,99 $/J (US, Apr 2026, aus wettbewerb-mainstream.md); EUR-Preis DE/AT, CHF-Preis CH: **nicht ermittelt** | Snippet dayoneapp.com; **nicht verifiziert** |
| Journey | iOS id1662059644 (ID unsicher) | – | – | Membership 49,99 $/J (US) | **nicht verifiziert**; DE-Storefront-Seite nicht gefunden |
| Diarium | iOS id1436044299; Mac id1502834782 | – | – | „Einmalzahlung von knapp 10 Euro" laut Nutzerrezension (Snippet); Pro 14,99 $ je Plattform (US, wettbewerb-mainstream.md) | **nicht verifiziert** (Widerspruch 10 € vs. 14,99 $ klären) |
| Daylio | iOS id1194023242 | 4,74 (AppBrain, Android) | 440k (AppBrain) | Premium 4,99 $/M, 35,99 $/J (US) | aus wettbewerb-mainstream.md; **nicht verifiziert** |
| Diarly | iOS id1387167765 | – | – | Premium 27 €/J (DE, wettbewerb-voice-first.md) | **nicht verifiziert** |
| Apple Journal | iOS id6447391597 | – | – | kostenlos | Bewertung nicht ermittelt |
| Voice Journal | com.jr44.voicejournal | – | – | keine IAP erkennbar | Play blockiert; **nicht verifiziert** |
| Voice Diary | com.voicediary.voicediary | – | – | – | Play blockiert |
| EchoVault | com.echovault.app | – | – | Free 5 Einträge/Woche; Pro 4,99 $/M | Snippet Play (EN); **nicht verifiziert** |
| CortexOS | com.cortexos.app; iOS id6759070325 | – | – | s. wettbewerb-voice-first.md (7,99 $/M … 199,99 $ Lifetime, widersprüchlich) | **nicht verifiziert** |
| Flint Voice | iOS id6760716646; Play so.klu.flintapp | – | – | Einmalkauf (12 $ laut Vorbericht) | **nicht verifiziert** |
| Offscript | com.offscript.app | – | – | – | Suche nicht mehr möglich (Kontingent) |
| DailyVox | iOS id6760454642 | – | – | 0 € (README „Free forever", keine IAP) | README bestätigt; Sterne unbekannt |
| VoiceFlow: KI-Sprachtagebuch | iOS id6755595633 (Carl Brindle) | – | – | Premium 2,99 $/M oder 9,99 $/J (Snippet des DE-Listings, Währung im Snippet USD!) | **nicht verifiziert**; EUR-Preis prüfen |
| FourYou | iOS id1671616134 | 4,8 (alternativeto/arminschoepf) | „not enough ratings" in manchen Regionen | Einmalkauf bis 75 $, Abos 4–30 $/M | **nicht verifiziert** |
| TOLDAYS | toldays.de (Store-ID unbekannt) | – | – | – | Website blockiert |
| Whisper Memos | iOS id6443658039 | – | – | ab 5 $/M, 29,99 $/J (Vorbericht) | **nicht verifiziert** |
| AudioPen | com.audiopen.android | 3,97 (210) bzw. 3,73 (160) Play, iOS 4,9 (136+) laut Vorbericht | – | 99 $/J Prime | **nicht verifiziert** |
| Voicenotes | com.app.voicenotes | iOS 4,7; Play 3,92 (2.500) laut Vorbericht | – | Pro 99,99 $/J | **nicht verifiziert** |
| Murmeln: Sprachtagebuch (neu) | iOS id1510564828; Play com.midnightplan.murmur | – | – | – | nur ID ermittelt |

---

## 3. Was sich aus den erreichbaren Stimmen ableiten lässt (vorsichtig)

1. **Abo vs. Einmalkauf ist im deutschen Store ein explizites Bewertungskriterium.** Die Diarium-Rezension „Es ist kein Abo! Eine Einmalzahlung von knapp 10 Euro" (Nr. 7) und die ambivalente Day-One-Stimme zum „omnipräsenten Abo-Modell" (Nr. 2) zeigen: Ein klar kommunizierter Einmalkauf im 10-Euro-Bereich wird im DACH-Store aktiv gelobt. Gleichzeitig existiert eine zahlungsbereite Day-One-Klientel, die Abo als Gegenmodell zu Werbefinanzierung akzeptiert (Nr. 1, 3) – aber ausdrücklich wegen E2E-Verschlüsselung. Für ein lokal arbeitendes Produkt ist das Argument „kein Server, daher kein Abo nötig" anschlussfähig.
2. **Backup-Auffindbarkeit und Wiederherstellung sind die häufigsten echten Play-Store-Beschwerden** in den archivierten Rezensionen (Nr. 38, 44, 45, 46, 17, 54). Konkrete Muster: Nutzer wissen nicht, wo die Backup-Datei liegt; OS-Updates (Android 13 Scoped Storage) brechen Backups; Biometrie-Änderungen sperren aus; Cloud-Sync meldet Erfolg, Restore ist aber unvollständig. Für das QR-Transfer-Konzept heißt das: Der Nutzer muss den Speicherort der Transferdatei sehen, und ein Restore-Test muss Teil des Onboardings sein.
3. **Datenschutz-Details, die Nutzer tatsächlich bemerken:** App-Switcher-Vorschau (Nr. 39), automatische Google-Fotos-Sicherung von Medien (Nr. 58), lokale Unverschlüsseltheit von Apple Journal (Nr. 53). Das sind konkrete, günstig umsetzbare Anforderungen (FLAG_SECURE/Privacy-Screen, `.nomedia`, Verschlüsselung at rest).
4. **Deutsch-Transkription:** Die einzigen deutschspezifischen Qualitätsbefunde betreffen Apples Diktat (Komposita getrennt, Leerzeichen um Bindestriche, Interpunktionswörter doppelt – Mai 2026, Nr. 21) und Whisper-Halluzinationen mit deutschen Untertitel-Floskeln bei Stille (Nr. 59, 60). Für Schweizerdeutsch gibt es feinabgestimmte Whisper-Modelle (apexAI-Switzerland large-v3 WER 13,31; Flurin17 large-v3-turbo ~1,6 GB, beide CC-BY-NC-4.0 – d. h. **nicht kommerziell nutzbar**, Nr. 18). Eine App für CH muss also entweder Standarddeutsch-Erkennung von Dialekt akzeptieren oder eigene Lizenzwege finden.
5. **Erinnerungen** tauchen in den erreichbaren Quellen nur als Feature-Wunsch auf (Nr. 38, 56), nicht als „unzuverlässig"-Beschwerde. Beschwerden über nicht feuernde Erinnerungen (typisch: Android-Akku-Optimierung) sind in Store-Rezensionen zu erwarten, konnten aber nicht belegt werden.
6. **KI-Ablehnung/-Wunsch:** In den erreichbaren Quellen keine einzige explizite KI-Ablehnung; KI-Wünsche nur bei KI-zentrierten Apps. Offene Frage bleibt, ob DACH-Nutzer Zusammenfassungen/Stimmungsanalyse wollen – nicht belegt.

---

## 4. Neue Erkenntnisse gegenüber den Vorberichten

- DailyVox hat **im August 2026 Deutsch hinzugefügt** (v1.10.0) und mit v1.11.0 den Cloud-Fallback komplett entfernt (Nr. 34). Damit gibt es auf iOS einen kostenlosen, deutschsprachigen, MIT-lizenzierten 100 %-lokal-Wettbewerber. Android-Nachfrage ist dokumentiert (Nr. 35).
- **Murmeln: Sprachtagebuch** (iOS id1510564828, Play com.midnightplan.murmur) ist ein weiterer deutschsprachiger Voice-Diary-Wettbewerber, in keinem Vorbericht enthalten.
- **Memex** (memex-lab, 713 GitHub-Sterne, iOS id6760325170, Play com.memexlab.memex) ist ein lokal-first Multimodal-Journal mit Sprachaufnahme und Bring-your-own-LLM; Transkriptions-Engine im README nicht spezifiziert.
- **OpenTranscribe** (theiskaa, 9 Sterne, iOS, MIT, 711 Commits, „Recording, transcription, reflection, and storage all happen on the device", optionaler „supporter purchase" via StoreKit) – ein weiteres On-Device-Voice-Journal auf iOS.
- Apple Journal speichert Einträge lokal als RTF in einer **unverschlüsselten** SQLite-Datenbank (Nr. 53) – ein Argument für die eigene Verschlüsselung at rest als Differenzierung.
- Schweizerdeutsch-Whisper-Modelle sind nur unter **CC-BY-NC-4.0** verfügbar (Nr. 18) – für ein kommerzielles Produkt nicht nutzbar.

---

## 5. Offene Punkte (unverändert offen)

1. Wörtliche, datierte Rezensionen mit Version und Sternen aus apps.apple.com/de|at|ch und play.google.com (hl=de, gl=DE|AT|CH) für alle 19 genannten Apps.
2. Reddit-Threads (r/Journaling, r/de_EDV, r/Datenschutz, r/androidapps, r/privacy) und Hacker-News-Threads zu AudioPen/Voicenotes/Whisper Memos.
3. Inhalt des Kuketz-Artikels „Android: Miserabler Datenschutz bei Tagebuch-Apps" (welche Apps, welche Tracker) und dessen Kommentare.
4. Inhalt der Apple-Community-Threads 255508808 und 256153585 (DE).
5. EUR-Preise DE/AT und CHF-Preise CH je App (Apple rundet je Storefront unterschiedlich).
6. Ob Voice Journal (jr44), Voice Diary, EchoVault, CortexOS, Offscript überhaupt genügend Bewertungen für eine sichtbare Sternezahl haben.

---

## 6. Anleitung zum Schließen der Lücke (für eine Sitzung ohne Proxy-Sperre)

**Apple App Store, wörtliche Rezensionen mit Datum, Sternen, Version, Nutzername (JSON, kein Login):**
`https://itunes.apple.com/{de|at|ch}/rss/customerreviews/page={1..10}/id={APP_ID}/sortBy=mostRecent/json`
Felder: `author.name`, `im:rating`, `im:version`, `updated`, `title`, `content`. IDs: Day One 1044867788 (Mac 1055511498), Diarium 1436044299 (Mac 1502834782), Daylio 1194023242, Diarly 1387167765, Apple Journal 6447391597, VoiceFlow 6755595633, FourYou 1671616134, DailyVox 6760454642, Whisper Memos 6443658039, Flint Voice 6760716646, CortexOS 6759070325, Murmeln 1510564828. Journey, TOLDAYS, AudioPen, Voicenotes, Offscript: ID per `https://itunes.apple.com/search?term=<name>&country=de&entity=software`.

**Sterne, Anzahl, Preis je Storefront:**
`https://itunes.apple.com/lookup?id={APP_ID}&country={de|at|ch}` → `averageUserRating`, `userRatingCount`, `formattedPrice`, `currency`, `version`, `currentVersionReleaseDate`. In-App-Preise stehen nur auf der HTML-Seite `https://apps.apple.com/{de|at|ch}/app/id{APP_ID}` (Abschnitt „In-App-Käufe").

**Google Play (Rezensionen mit Datum, Sternen, App-Version, Hilfreich-Zähler):**
Python `google-play-scraper`: `reviews('com.jr44.voicejournal', lang='de', country='de', sort=Sort.NEWEST, count=200)`; `app(...)` liefert `score`, `ratings`, `reviews`, `installs`, `inAppProductPrice`, `version`, `updated`. Pakete: com.jr44.voicejournal, com.voicediary.voicediary, com.echovault.app, com.cortexos.app, com.offscript.app, so.klu.flintapp, com.audiopen.android, com.app.voicenotes, com.midnightplan.murmur, Day One com.dayoneapp.dayone, Journey com.journey.app, Diarium de.tpartl.diarium (prüfen), Daylio net.daylio.

**Deutsche Foren/Blogs (direkt abrufen, Kommentarspalten lesen):** Kuketz-Artikel (s. o.), MacLife Day-One-Abozwang (s. o.), iphone-ticker.de und ifun.de Suche „Journal", appgefahren.de Journal-Export-Artikel, Apple Community DE Threads 255508808 / 256153585, besteerfahrungen.de Diarium-Erfahrungen, mind-verse.de Tagebuch-App-Vergleich 2026.

**Reddit ohne Login:** `https://www.reddit.com/r/Journaling/search.json?q=voice+journal&restrict_sr=1&sort=new` (User-Agent setzen); Subreddits r/Journaling, r/de_EDV, r/Datenschutz, r/androidapps, r/privacy, r/voicenotesai, r/storypad.

**Hacker News:** `https://hn.algolia.com/api/v1/search?query=audiopen&tags=story` bzw. `query="voice journal"`.

---

## 7. Quellenliste (alle in dieser Sitzung genutzt)

Erfolgreich gelesen (github.com, developer.apple.com):
- https://github.com/intrepidkarthi/dailyvox · https://github.com/intrepidkarthi/dailyvox/issues/4
- https://github.com/hanjoongcho/aaf-easydiary (+ Issues 111, 128, 131, 132, 175, 184, 185, 186, 187, 197, 200, 215, 216)
- https://github.com/theachoem/storypad (+ Issues 568, 611)
- https://github.com/billthefarmer/diary/issues/209 · https://github.com/billthefarmer/diary/issues/236
- https://github.com/DenserMeerkat/June (+ Issues) · https://github.com/KyleKun/one_second_diary/issues
- https://github.com/journiv/journiv-app/issues/108 · /issues/302 · /issues/253 · /issues/299
- https://github.com/MarcDonald/obsidian-day-one-importer/issues/15 · https://github.com/liamcain/obsidian-calendar-plugin/issues/217
- https://github.com/omarshahine/apple-journal-cli · https://github.com/fjrevoredo/mini-diarium · https://github.com/memex-lab/memex · https://github.com/theiskaa/opentranscribe · https://github.com/kaisoapbox/WhisperJournal/issues
- https://github.com/napoleonmm83/Transkribor (+ Issues 130, 136) · https://github.com/ggml-org/whisper.cpp/issues/3431 · https://github.com/SYSTRAN/faster-whisper/issues/949 · https://github.com/m-bain/whisperX/issues/230 · https://github.com/Georg-Klock/HeikoTranslate/issues/135 · https://github.com/i4Ds
- https://github.com/topics/voice-journal · /topics/voice-diary · /topics/journaling-app · /topics/journal-app · /topics/diary-app · /topics/diary
- https://developer.apple.com/forums/thread/826756 · /thread/806911 · /thread/697188 · /thread/806765 · /thread/105405?answerId=686599022 · /thread/797835 · /forums/tags/speech · /forums/search?q=SpeechAnalyzer%20german

Nur als Suchsnippet ausgewertet (Host blockiert):
- https://apps.apple.com/de/app/day-one-t%C3%A4gliches-tagebuch/id1044867788?see-all=reviews&platform=iphone
- https://apps.apple.com/de/app/day-one/id1055511498?mt=12&see-all=reviews&platform=mac
- https://apps.apple.com/de/app/diarium-privates-tagebuch/id1502834782?mt=12&see-all=reviews&platform=mac
- https://apps.apple.com/ch/app/1436044299?see-all=reviews&platform=iphone
- https://apps.apple.com/de/app/voiceflow-ki-sprachtagebuch/id6755595633
- https://apps.apple.com/de/app/murmeln-sprachtagebuch/id1510564828
- https://apps.apple.com/us/app/whisper-memos-speech-to-text/id6443658039?see-all=reviews&platform=iphone
- https://apps.apple.com/us/app/fouryou-guided-audio-journal/id1671616134?see-all=reviews&platform=iphone
- https://apps.apple.com/us/app/flint-voice/id6760716646
- https://apps.apple.com/in/app/dailyvox-voice-journal-diary/id6760454642
- https://play.google.com/store/apps/details?id=com.jr44.voicejournal&hl=en_US
- https://play.google.com/store/apps/details?id=com.echovault.app&hl=en
- https://play.google.com/store/apps/details?id=com.cortexos.app
- https://communities.apple.com/de/thread/255508808 · https://communities.apple.com/de/thread/256153585
- https://www.kuketz-blog.de/android-miserabler-datenschutz-bei-tagebuch-apps/
- https://www.maclife.de/news/nach-photoshop-1password-textexpander-digitales-tagebuch-day-one-abozwang-10093275.html
- https://www.appgefahren.de/journal-app-so-exportiert-sichert-und-druckt-ihr-eure-eintraege-368533.html
- https://www.iphone-ticker.de/journal-die-einstellungen-von-apples-tagebuch-app-anpassen-226666/
- https://www.besteerfahrungen.de/diarium-erfahrungen-tagebuch-app/ · https://www.mind-verse.de/post/tagebuch-app-beste-digitale-tagebuch-apps-vergleich
- https://toldays.de/ · https://arminschoepf.com/fouryou/ · https://alternativeto.net/software/fouryou--guided-audio-journal/about
- https://www.yaps.ai/blog/voicenotes-alternative · https://www.audionotes.app/compare/audionotes-vs-voicenotes · https://nubiapage.com/voicenotes-review-2026-ai-app-pricing-login-user-experience-and-faqs/
- https://cortexos.app/library/best-private-voice-journal-2026/ · https://getdailyvox.com/blog/best-offline-journal-app · https://voicescriber.com/best-privacy-focused-voice-recorder-apps-offline
