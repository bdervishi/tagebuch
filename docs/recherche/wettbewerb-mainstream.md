# Wettbewerbsanalyse Mainstream: Etablierte Tagebuch-/Journaling-Apps und Plattform-Angebote

Lens: `wettbewerb-mainstream` · Stand der Recherche: 3. September 2026 · Zielprodukt: lokales Sprach-Tagebuch (iOS + Android, On-Device-Transkription, keine Konten/Server, verschlüsselter Geräte-Transfer per QR-Code)

## 0. Methodische Hinweise

- Rund 45 Web-Suchen wurden ausgeführt; der direkte Seitenabruf (WebFetch) war im Recherche-Netz für fast alle Domains gesperrt (Apple Support, Day One, Journey, Google Support, App Store, Google Play, MacRumors u. a.). Die meisten Angaben stammen deshalb aus Suchergebnis-Auszügen der jeweiligen Primärquellen und aus Sekundärquellen (Review-Seiten 2025/2026). Nur `developer.apple.com` war vollständig lesbar (WWDC25-Session 277 zu SpeechAnalyzer).
- Konsequenz: Alle Preise, Limits, Download-Zahlen und Aussagen zu API-/Plattform-Verfügbarkeit sind als **zu verifizieren** markiert. Preise sind US-Dollar-Angaben der Quellen, sofern nicht anders vermerkt; DACH-Preise in EUR weichen in der Regel ab.
- Viele „Review 2026"-Seiten sind von Wettbewerbern betrieben (reflection.app, mindsera.com, blog.mylifenote.ai, journey.cloud). Sie werden zitiert, wo keine bessere Quelle vorlag, aber entsprechend niedriger gewichtet.

## 1. Kernergebnis in Kürze

1. **Apple Journal** ist der kostenlose Default auf iPhone (seit iOS 17.2, Dezember 2023) und seit 15. September 2025 auch auf iPad und Mac (iPadOS 26 / macOS Tahoe 26). Es bietet Audioaufnahme mit Transkription, iCloud-Sync mit Ende-zu-Ende-Verschlüsselung, Sperre per Face ID/Touch ID, Erinnerungen, Streaks, seit iOS 18 einen kompletten Export (ZIP mit HTML + Medien, darunter M4A/CAF) und seit iOS 26 mehrere Journale, Kartenansicht, Zeichnungen und bessere Suche. Die harte Grenze für ein DACH-Produkt: Laut Apple-Support-Guide für iPhone ist die Audiotranskription in Journal **nur auf Englisch verfügbar** („audio transcription available in English only (excluding Singapore and India locales)"), während Notizen/Sprachmemos mit iOS 26 bereits zehn Sprachen inkl. Deutsch transkribieren. Kein Android, kein Windows, kein Web.
2. **Android hat kein Pendant.** Google Recorder (On-Device-Transkription, offline, inkl. Deutsch) ist offiziell Pixel-exklusiv; Samsung bietet Transcript Assist (22 Sprachen inkl. Deutsch, Stand März 2026), verlangt aber Netzwerk und Samsung-Account und plant mit One UI 9 zusätzlich Cloud-Transkription; Google Keep transkribiert nur in der Cloud. Ein Nicht-Pixel-/Nicht-Galaxy-Nutzer ohne Konto hat de facto keine System-Lösung für lokale Sprach-Transkription. Das ist die größte Lücke für das geplante Produkt.
3. **Day One** (Automattic) ist der Premium-Marktführer: E2E-Verschlüsselung (AES-GCM-256 mit RSA-2048), Audio + Transkription ab Tarif „Silver" (49,99 $/Jahr, seit März/April 2026; Premium-Altkunden 24,99 $/Jahr), neuer „Gold"-Tarif 74,99 $/Jahr mit KI-Funktionen. Transkription läuft nur auf iOS-26-Geräten mit Apple Intelligence on-device, sonst über Apple-Server; Transkript-Limit 10 Minuten. Audio wird laut Drittquellen in einem proprietären Format exportiert. Day One ist konto- und serverbasiert.
4. **Mittelfeld** (Journey, Diarium, Diarly, Daylio, Penzu, Grid Diary, Reflectly) deckt Audio nur rudimentär ab: Journey transkribiert nur auf iOS und nur bis 10 Minuten (Membership 49,99 $/Jahr, Lifetime 199 $), Diarium bietet Diktat und einmalige Pro-Käufe je Plattform (14,99 $), Diarly nutzt ab iOS 26 das On-Device-Modell (Apple-only, unter 2 $/Monat, separates AI+-Abo), Daylio hat Sprachmemos ohne Transkription, Penzu und Reflectly haben keine Voice-Features.
5. **KI-Journale** (Rosebud, Mindsera, Stoic, Reflection.app) haben Voice als Kernfunktion, aber nur mit Cloud-Verarbeitung, Konten und Abos zwischen 6,99 $ und 14,99 $/Monat. Rosebud (6 Mio. $ Seed, Bessemer, Juni 2025) wirbt mit Voice in 20 Sprachen; Verschlüsselung ist serverseitig, nicht E2E.
6. **Marktbewegung:** Keine aktuelle Übernahme oder Abschaltung einer der großen Tagebuch-Apps in 2025/2026 gefunden. Historische Deals: Day One → Automattic (Juni 2021), Reflectly → The Happiness Project (Mai 2021, laut Tracxn). Aktuelle Signale sind stattdessen Preiserhöhungen (Day One 2025/2026), KI-Tarife (Day One Gold, Stoic Premium+AI, Mindsera Genius), Sherlocking durch Apple (Journal auf iPad/Mac) und die Ankündigung „Kin AI shutting down" im KI-Begleiter-Segment (ohne Details prüfbar).

## 2. Apple Journal (Apple, iOS 17.2+, Stand iOS 26)

**Plattformen und Sync.** iPhone seit iOS 17.2 (Dezember 2023). iPad und Mac seit iPadOS 26 / macOS Tahoe 26, veröffentlicht 15. September 2025 (bestjournalingapps.com; 9to5Mac 17.06.2025; AppleInsider 09.06.2025). Sync über iCloud, laut Apple-Newsroom (Dezember 2023) mit Ende-zu-Ende-Verschlüsselung; Sperre per Face ID/Touch ID. Kein Android, kein Windows, kein Web-Client. Keine In-App-Käufe, keinerlei Bezahlvariante.

**Audio und Transkription.** Aufnahme direkt im Eintrag, Transkript wird unter dem Audio angezeigt. Apple-Support-Guide (iPhone, Journal, „Add formatting, photos, and more"): „audio transcription available in English only (excluding Singapore and India locales)". Der Notizen-Guide für iPad nennt dagegen zehn Sprachen für Aufnahme-Transkription (Englisch, Spanisch, Portugiesisch, Italienisch, Französisch, Deutsch, Japanisch, Koreanisch, vereinfachtes und traditionelles Chinesisch). Technisch nutzt Journal laut WWDC25 (Session 277) dieselbe SpeechAnalyzer-Engine wie Notizen und Sprachmemos („SpeechAnalyzer is already powering features across many system apps, such as Notes, Voice Memos, Journal, and more"). Ob Apple die Journal-Sprachliste in iOS 26.x nachgezogen hat, konnte nicht abschließend geprüft werden (Support-Seite nicht abrufbar) – **unbedingt am Gerät mit deutscher Systemsprache testen**. In Apple-Community-Threads (2024/2025) berichten Nutzer über „Couldn't Transcribe Audio"-Fehler, bei denen Transkripte nach Neustart der App verschwinden.

**Export.** Seit iOS 18: einzelne Einträge oder Datumsbereiche als PDF drucken/sichern; „Export All Journal Entries" in den Einstellungen erzeugt ein ZIP „AppleJournalEntries" in der Dateien-App mit Ordner „Entries" (HTML je Eintrag), Ordner „Resources" (CAF, HEIC, M4A, JPG, JSON, MOV, PNG, WEBP) und einer „Index"-HTML (Apple Support 121822; Diarium-Forum; Joplin-Forum). Es gibt keine Importfunktion für fremde Daten, keinen JSON-/Markdown-Export. Nutzerkritik (Apple Community, numericcitizen.me): „can't search, print, or export" (Stand vor iOS 18), Lock-in ins Apple-Ökosystem, Bildlimit pro Eintrag.

**Erinnerungen.** Journaling-Zeitplan mit Benachrichtigungen, Streaks und Schreib-Statistiken seit iOS 18 (Tom's Guide, 9to5Mac 19.09.2024).

**Weitere iOS-26-Neuerungen.** Mehrere Journale, Kartenansicht, Inline-Bilder, Zeichnungen/Handschrift, verbesserte Suche, Wiederherstellung gelöschter Einträge, Sidebar und Tastaturkürzel auf iPad/Mac (9to5Mac 17.06.2025 und 05.01.2026).

**Ökosystem-Haken.** Die Journaling Suggestions API (iOS 17.2, erweitert in iOS 18 um State of Mind, Reflexionsfragen, Drittanbieter-Medien) erlaubt Dritt-Apps, dieselben Vorschläge einzubinden; Day One war Early Adopter. Für ein Sprach-Tagebuch ist das ein optionaler iOS-Mehrwert ohne Datenabfluss („third-party apps do not have access to Journaling Suggestions data until users select a specific suggestion").

**Bewertung für das Vorhaben.** Apple Journal setzt den Preis auf null und die Erwartung an Datenschutz hoch. Es ist aber (a) nicht auf Android, (b) an iCloud gebunden, (c) laut Doku nur englisch transkribierend, (d) ohne Cross-Plattform-Transfer außer iCloud. Genau dort liegen die Differenzierungsflächen.

## 3. Day One (Automattic)

- **Herkunft/Größe:** Start 2011, Übernahme durch Automattic Juni 2021 (TechCrunch 14.06.2021). Über 15 Mio. Downloads, „Apple App of the Year" (dayoneapp.com/about; Google Play).
- **Plattformen:** iOS, iPadOS, macOS, watchOS, Android, Windows, Linux, Web.
- **Preise (Stand März/April 2026, 5typos.net, 9to5Mac 08.04.2026, dayoneapp.com/plans):** Basic kostenlos (unbegrenzte Texteinträge, 1 Foto/Tag, E2E-Verschlüsselung), Silver 49,99 $/Jahr (ehemals Premium; Sync, unbegrenzte Fotos/Videos, Audio mit Transkription), Gold 74,99 $/Jahr (Daily Chat, Entry Highlights, KI-Bildgenerierung, KI-Transkriptionsformatierung). Legacy-Premium-Kunden bleiben bei 24,99 $/Jahr. Deutsche Quelle (bestjournalingapps.com/de) datiert die Erhöhung auf August 2025 – Datum widersprüchlich, prüfen.
- **Audio/Transkription (dayoneapp.com Guide „Audio Recording"):** Diktat und Aufnahme auf iPhone und Android. „On devices running iOS 26 with Apple Intelligence, transcription runs entirely on-device. On older OS versions or devices without Apple Intelligence, it is processed on Apple's servers." Transkriptionslimit 10 Minuten. Apple-Intelligence-Funktionen ab Day One 2025.19 (Foundation Models Framework). Für Android ist die Verarbeitung nicht dokumentiert auffindbar – vermutlich Server.
- **Verschlüsselung:** E2E mit AES-GCM-256 und RSA-2048-Schlüsselaustausch; Schlüssel liegt beim Nutzer (E2EE-FAQ). Day One Sync ist zwingend kontobasiert (eigene Server bei Automattic/WordPress.com-Infrastruktur).
- **Export:** Day One JSON (ZIP inkl. Medienordner photos/videos/audios/pdfs), Plain Text, CSV, PDF (PDF ohne Audio/Video). Drittquelle (getdailyvox.com): Sprachaufnahmen „are stored in a proprietary format. They export as audio files, but few journal apps can import them." – zu verifizieren.
- **Erinnerungen:** Tägliche Erinnerungen, Prompt Packs (Android ab 2025.19), Streaks, „On This Day".
- **Nutzerstimmen (App Store DE):** Lob für Bild-Text-Kombination und Sync; Abo-Modell wird „hingenommen"; ein Rezensent hält Datenschutz beim Sync für „mit erheblicher Skepsis" zu betrachten und speichert keine Gesundheitsdaten.
- **Reaktion auf Apple Journal:** Gründer Paul Mayne: „The Journal app is an exciting development for us because it introduces the benefits of digital journaling to a wider audience". Day One positioniert sich als Cross-Plattform- und Power-User-Alternative.

## 4. Journey (Two App Studio, Singapur)

- Plattformen: Android, iOS, macOS, Windows, Linux, ChromeOS, Web. Oft die Standard-Empfehlung für Android (Holstee 2026).
- Preise (help.journey.cloud, Suchauszug 2026): Membership 49,99 $/Jahr, Lifetime 199 $; kostenlose Stufe mit Basis-Sync. „Journey Signature" mit 200 GB Speicher/50.000 Einträgen. Ältere Quellen nennen niedrigere Preise – prüfen.
- Speicherort wählbar: Google Drive, Dropbox oder Journey Cloud (bestjournalingapps.com/de). Verschlüsselung der Einträge auf dem Transportweg/at rest; E2E nur mit selbst gesetztem Passwort für bestimmte Modi – Details nicht verifizierbar.
- Audio: Aufnahme kostenpflichtig; bis 20 Medien pro Eintrag; WhatsApp-Eingang für Sprachnachrichten. Transkription laut spokenly.app (2026): „Built-in transcription is iOS-only, limited to transcription-mode recordings of up to 10 minutes, and does not process imported audio." Für Android-Nutzer gibt es also keine Transkription in der App.
- Export: Import von Day One JSON; eigene Exporte als DOCX/PDF/JSON/ZIP (Standardwissen, nicht neu geprüft).

## 5. Diarium (Timo Partl, Deutschland)

- Plattformen: Windows, Android, iOS, macOS. In der DACH-Region populär (bestjournalingapps.com/de: „besonders beliebt bei deutschsprachigen Nutzern").
- Preise: Windows 19,99 $; Android/iOS/macOS kostenlos mit einmaligem Pro-Kauf 14,99 $ je Plattform (Diarium-Forum „Cost of app"; Zapier 2026). Kein Abo.
- Android-Kennzahlen (AppBrain, 2026): ca. 740.000 Downloads, 4,86 Sterne bei ca. 19.000 Bewertungen.
- Datenhaltung: lokal; Sync über eigene Cloud-Speicher (OneDrive, Google Drive, Dropbox, iCloud, WebDAV). Seit Diarium V5 (2025) optionale vollständige Datenbankverschlüsselung mit Passwort/Passkey als Master-Passphrase; „v5 sync" mit E2E-Verschlüsselung per Nutzerpasswort.
- Audio: Anhänge inkl. Audio, Sprachdiktat (Speech-to-Text über System-Diktat; Engine nicht dokumentiert – auf Android typischerweise Google-Spracherkennung, ggf. online). Keine eigene Audiotranskription nach Aufnahme dokumentiert.
- Export: PDF, DOCX, HTML, TXT, JSON (nach Community-Angaben); Import aus Daylio, Day One, Journey, Apple Journal (Forum-Thread „Apple Journal Import/Migration Difficulty").
- Erinnerungen: konfigurierbare Benachrichtigungen; automatische „Feeds" (Kalender, Fitness) in Pro.

## 6. Diarly (Apple-only)

- Plattformen: iPhone, iPad, Mac, Apple Watch. Kein Android.
- Preise (diarly.app/pricing, Auszug 2026): Premium „less than $2 per month" nach 7-Tage-Test bzw. „less than $24 per year" mit Neukundenrabatt; ein Abo für alle Apple-Geräte. Separates Abo „AI+" für Audiotranskription mit besserer Genauigkeit/Spracherkennung und OCR.
- Datenhaltung: direkt in iCloud Drive des Nutzers, keine eigenen Server; optionale Verschlüsselung mit Passwort (Premium).
- Audio: Aufnahme und Transkription, Transkript unter dem Eintrag, Original-Audio bleibt erhalten. „Premium transcription now uses Apple's latest on-device model on iOS 26 and macOS 26" – also SpeechAnalyzer/SpeechTranscriber. Das ist der nächste technische Verwandte des geplanten Produkts, aber ohne Android und mit iCloud-Bindung.
- Export: Markdown, PDF, weitere Formate (Premium).

## 7. Plattform-Angebote auf Android

**Google Recorder (Pixel).** Offiziell nur auf Pixel-Telefonen (ab Pixel 4/2019 für ältere Modelle nachgereicht). On-Device-Transkription ohne Internet in mehreren Sprachen; Sekundärquellen nennen 8 Sprachen inkl. Englisch, Spanisch, Französisch, Deutsch, Italienisch, Japanisch (happyscribe 2026; Android Central). Zusammenfassungen (Gemini Nano) auf Pixel 8+ in Englisch, Chinesisch, Hindi, Italienisch, Französisch, Deutsch, Japanisch (Pixel 10). Neu: „Transcribe again" mit Cloud-Verarbeitung in 42 Sprachen. Backup optional über recorder.google.com (Google-Konto). Export: Audio (M4A), Transkript als TXT/SRT, Videoclips. Sideloading auf Nicht-Pixel-Geräten ist ein inoffizieller XDA-Workaround (Android Authority, Gizmodo).

**Samsung Voice Recorder / Samsung Notes.** Transcript Assist (Galaxy AI, ab Galaxy S24, Januar 2024) transkribiert, fasst zusammen, übersetzt und exportiert nach Samsung Notes. Stand März 2026: 22 Sprachen inkl. Deutsch. Samsung-Support: „Transcription and Summary features for Transcript Assist require a network connection and Samsung Account login"; es gibt eine Option „Process data only on device", die aber Funktionsumfang/Genauigkeit reduziert. Android Headlines (Juli 2026): One UI 9 (Galaxy S26) bringt zusätzlich Cloud-Transkription, „aiming to fix the accuracy issues that plague its current on-device processing". Kein Tagebuch-Kontext, keine Erinnerungen, kein E2E.

**Google Keep.** Sprachnotiz speichert Audio plus Transkript, Transkription erfolgt serverseitig über Google-Spracherkennung (Cloud); Android, iOS, Web identisch. Kein Offline-Transkript, Google-Konto Pflicht.

**Gboard/Android-Systemdiktat.** Offline-Sprachpakete existieren (mehrere hundert MB je Sprache), „Faster voice typing" mit dem besseren On-Device-Modell ist Pixel-exklusiv; Offline-Modus ist laut Drittquellen ungenauer bei langen Sätzen und Akzenten. Ein Diktat ist zudem kein Aufnahme-plus-Transkript-Workflow.

**Fazit Android:** Ohne Pixel oder aktuelles Galaxy gibt es keine konto- und cloudfreie System-Transkription. Selbst mit Pixel fehlt die Tagebuch-Schicht (Erinnerung zur festen Uhrzeit, Einträge pro Tag, Verschlüsselung, Transfer). Das geplante Produkt muss auf Android eine eigene Engine mitbringen (Whisper-Derivate, sherpa-onnx o. ä.; eigener Recherche-Lens).

## 8. Weitere Wettbewerber im Überblick

| App | Plattformen | Voice/Audio | Transkription | Daten/E2E | Preis (Quelle, Datum) |
|---|---|---|---|---|---|
| Daylio (Relaxio, Bratislava) | iOS, Android | Sprachmemos als Anhang (ohne Transkript) | nein | lokal; verschlüsselte Backups in Google Drive/iCloud; PIN/Biometrie; CSV-Export | Premium 4,99 $/Monat, 35,99 $/Jahr (choosingtherapy 2026); IAP 4,99–59,99 $; 19 Mio. Downloads, 4,74 Sterne/440k Bewertungen (AppBrain 2026) |
| Reflectly (Aarhus, DK) | iOS, Android | nein (nur Audio-Inspirationen zum Anhören) | nein | Cloud/Konto; GDPR-Sonderkategorie explizit; Export nur Premium | Premium ca. 19,99 $/Jahr Android vs. 59,99 $/Jahr iOS (choosingtherapy 2026) – Diskrepanz prüfen |
| Rosebud (USA) | iOS, Android, Web | Voice-Journaling, Call Mode, „20 Sprachen" | Cloud | verschlüsselt in transit/at rest, nicht E2E; Daten „nicht zum Training" | 12,99 $/Monat oder 9,99 $/Monat jährlich (119,88 $/Jahr); Free 3 Einträge/Woche; App Store 4,9 Sterne; 6 Mio. $ Seed Juni 2025 (Bessemer) |
| Stoic (Maciej Lobodzinski) | iOS, Android | Voice-Notes/Voice-Einträge | Cloud (KI-Mentoren) | Konto/Cloud | Premium 6,99 $/Monat bzw. 39,99–49,99 $/Jahr, Premium+AI 12,99 $/Monat bzw. 99,99 $/Jahr (reflection.app; personaldevelopmentapps.com Juni 2026); „über 4 Mio. Nutzer" (getstoic.com) |
| Mindsera | Web, iOS, Android | Voice Mode, Call Mode | Cloud | Konto/Cloud | Genius 14,99 $/Monat oder 129 $/Jahr, Aktion 99 $/Jahr (blog.mylifenote.ai 2026) |
| Reflection.app | iOS, Web | Echtzeit-Voice mit Live-Transkript und Coaching | Cloud | Konto/Cloud | 8 $/Monat oder 5,75 $/Monat jährlich (2026) |
| Penzu | Web, iOS, Android | nein | nein | serverbasiert; 256-Bit-AES „double password" nur in Pro/Pro+ | Pro 19,99 $/Jahr, Pro+ 49,99 $/Jahr (2026) |
| Grid Diary (Sumi Interactive) | iPhone, iPad, Mac (Android-Status unklar) | Sprachmemo pro Zelle | nein | iCloud; Export nur als HTML-Ordner | kostenlos auf Apple; Pro 2,99 $/Monat oder 22,99 $/Jahr (prowritingaid 2026) |
| Bearable | iOS, Android | nein | nein | Konto/Cloud; Health-Import | 6,99 $/Monat, 34,99 $/Jahr (choosingtherapy 2026) |

## 9. Marktbewegungen und Signale

- **Übernahmen:** Day One → Automattic (14.06.2021, TechCrunch). Reflectly → The Happiness Project (Mai 2021, laut Tracxn; Reflectly heute 9 Mitarbeitende, 4,95 Mio. $ Funding) – nicht unabhängig bestätigt. Keine Übernahme oder Einstellung von Journey, Diarium, Diarly, Daylio, Penzu, Grid Diary, Stoic, Mindsera, Bearable oder Reflection.app in 2025/2026 gefunden; alle werden in Vergleichen 2026 als aktiv geführt.
- **Abschaltungen:** Einzige gefundene Ankündigung im Umfeld: „Kin AI" (KI-Begleiter mit Journaling-Anteil) mit Migrationsleitfaden (blog.mylifenote.ai) – Details nicht prüfbar.
- **Finanzierung:** Rosebud 6 Mio. $ Seed (Juni 2025, Bessemer, 776, Initialized u. a.) – KI-Voice-Journaling gilt als investierbar. Daylio explizit „unfunded".
- **Preisdruck nach oben:** Day One verdoppelt für Neukunden von 24,99 $ auf 49,99 $ (Silver) und führt Gold (74,99 $) ein; Journey Membership bei 49,99 $/Jahr; Stoic und Mindsera mit separaten KI-Tarifen. Gleichzeitig kostenlose Plattform-Apps (Apple Journal, Google Recorder, Samsung) – das Mittelfeld ohne klare USP wird zerrieben.
- **Sherlocking:** Apple Journal auf iPad/Mac (September 2025) und SpeechAnalyzer als System-API (iOS 26) senken die Eintrittshürde für Apple-only-Apps wie Diarly und Day One erheblich; Day One antwortet mit Apple-Intelligence-Integration (Day One 2025.19) und Cross-Plattform.
- **Nutzerbedürfnis, das offen bleibt:** Datenschutz-Skepsis gegenüber Server-Sync (App-Store-Rezension Day One DE), fehlender Export/Lock-in bei Apple Journal (Apple Community), fehlende Transkription für Android bei Journey, Cloud-Zwang bei Samsung/Keep.

## 10. Implikationen für das Konzept

1. **Positionierung:** „Sprach-Tagebuch ohne Konto" ist im Mainstream unbesetzt. Alle Apps mit Transkription außer Apple Journal/Diarly/Day One-auf-iOS-26 verarbeiten Audio in der Cloud; alle Cross-Plattform-Apps verlangen ein Konto.
2. **Deutsch als Argument:** Solange Apple Journal laut Doku nur englisch transkribiert, ist „Deutsch, lokal, auf iPhone und Android" ein konkret prüfbares Versprechen. Auf iOS 26+ kann das Produkt SpeechAnalyzer/SpeechTranscriber nutzen (Modell im Systemspeicher, kein App-Größenzuwachs, Assets via `AssetInventory`); für iOS < 26 und Android ist eine eigene Engine nötig.
3. **Feature-Parität, die Nutzer erwarten:** Erinnerung zur festen Uhrzeit (alle Wettbewerber), Streaks (Apple, Day One), Audio + Text nebeneinander (Apple, Diarly), Export in offenen Formaten (Day One JSON, Apple ZIP/HTML+M4A) – der Export sollte mindestens ZIP mit M4A/Opus + Markdown/JSON liefern, um Apple Journal und Day One nicht zu unterbieten.
4. **Transfer statt Sync:** Der geplante QR-initiierte, verschlüsselte Geräte-Transfer ist ein Alleinstellungsmerkmal gegenüber iCloud-/Konto-Sync, muss aber das Fehlen von Live-Sync ehrlich kommunizieren; Diarium (eigene Cloud) und Daylio (Backup-Datei) zeigen, dass Nutzer dateibasierte Modelle akzeptieren.
5. **Monetarisierung:** Einmalkauf je Plattform (Diarium 14,99 $) oder günstiges Abo (Diarly < 24 $/Jahr) sind die Preisanker für „privacy-first"; Day One/Journey (49,99 $/Jahr) markieren die Obergrenze. KI-Zusatzfunktionen werden marktweit separat bepreist (Gold, Premium+AI, Genius, AI+).

## Quellen

- Apple Developer, WWDC25 Session 277 „Bring advanced speech-to-text to your app with SpeechAnalyzer": https://developer.apple.com/videos/play/wwdc2025/277/
- Apple Support, Journal iPhone „Add formatting, photos, and more" (Transkription nur Englisch): https://support.apple.com/en-kz/guide/iphone/iph492ee70a8/ios
- Apple Support 121822 „Back up, export, and print Journal entries on iPhone": https://support.apple.com/en-us/121822
- Apple Support, Notizen iPad Aufnahme/Transkription (10 Sprachen): https://support.apple.com/guide/ipad/record-and-transcribe-audio-ipadd0bde806/ipados
- Apple Newsroom, Journal-Launch Dezember 2023: https://www.apple.com/newsroom/2023/12/apple-launches-journal-app-a-new-app-for-reflecting-on-everyday-moments/
- 9to5Mac, Journal auf iPad/Mac (17.06.2025): https://9to5mac.com/2025/06/17/apples-journal-app-is-coming-to-ipad-and-mac-with-big-upgrades/
- 9to5Mac, iPadOS 26 Journal Erfahrungsbericht (05.01.2026): https://9to5mac.com/2026/01/05/ipados-26-adds-new-journal-app-and-ive-been-using-it-almost-every-day/
- 9to5Mac, iOS 18 Journal (19.09.2024): https://9to5mac.com/2024/09/19/ios-18-brings-much-needed-features-to-journal-app/
- AppleInsider, Journal auf iPad (09.06.2025): https://appleinsider.com/articles/25/06/09/apple-finally-brings-journal-to-ipad-for-better-writing-sketching-reflection
- Apple Community, Export-Thread: https://discussions.apple.com/thread/255354729
- Apple Community, „Couldn't Transcribe Audio" in Journal: https://discussions.apple.com/thread/255916391
- Diarium-Forum, Apple Journal Import (ZIP-Struktur): https://forum.diariumapp.com/d/5304-apple-journal-importmigration-difficulty
- Day One, Audio Recording Guide: https://dayoneapp.com/guides/tips-and-tutorials/audio-recording/
- Day One, Plans: https://dayoneapp.com/plans/
- Day One, E2EE FAQ: https://dayoneapp.com/guides/day-one-sync/end-to-end-encryption-faq/
- Day One, Exporting entries: https://dayoneapp.com/guides/tips-and-tutorials/exporting-entries/
- Day One, Apple Intelligence Blog: https://dayoneapp.com/blog/go-deeper-with-apple-intelligence/
- Day One, Android Release Notes: https://dayoneapp.com/guides/release-notes/android-release-notes/
- 9to5Mac, Day One Gold (08.04.2026): https://9to5mac.com/2026/04/08/day-one-journaling-app-introduces-gold-plan-with-ai-summaries-and-daily-chat/
- 5typos.net, Day One Silver/Gold Preiserhöhung (08.04.2026): https://5typos.net/2026/04/8/day-one-introduces-silver-and-gold-with-price-increases
- TechCrunch, Automattic übernimmt Day One (14.06.2021): https://techcrunch.com/2021/06/14/wordpress-com-owner-automattic-acquires-journaling-app-day-one/
- getdailyvox.com, Day One Export (proprietäres Audioformat): https://getdailyvox.com/blog/how-to-export-day-one
- App Store DE, Day One Rezensionen: https://apps.apple.com/de/app/day-one-t%C3%A4gliches-tagebuch/id1044867788?see-all=reviews&platform=iphone
- Journey, Membership: https://journey.cloud/membership und https://help.journey.cloud/en/article/journeycloud-membership-k32g8e/
- Journey, Google Play: https://play.google.com/store/apps/details?id=com.journey.app
- spokenly.app, Voice Journaling 2026 (Journey-Transkription iOS-only, 10 min): https://spokenly.app/blog/voice-journaling
- Diarium, Website: https://diariumapp.com/en
- Diarium-Forum, Kosten: https://forum.diariumapp.com/d/4901-cost-of-app-please-read-for-explanation
- Diarium-Forum, On-Device-Verschlüsselung: https://forum.diariumapp.com/d/3624-on-device-encryption
- AppBrain, Diarium: https://www.appbrain.com/app/diarium-journal-diary/partl.Diarium
- TinkeringProd, Diarium Review: https://tinkeringprod.com/diarium-review/
- Diarly, Pricing: https://diarly.app/pricing
- Diarly, Recording/Transcribing: https://diarly.app/help/record-transcribe-dictate.html
- Google Pixel Help, Transkriptionen: https://support.google.com/pixelphone/answer/16267698?hl=en
- Android Authority, Recorder auf Nicht-Pixel: https://www.androidauthority.com/google-recorder-app-1069849/
- HappyScribe, Audio auf Android transkribieren (2026): https://www.happyscribe.com/blog/how-to-transcribe-audio-on-android
- Samsung UK, Transcript Assist: https://www.samsung.com/uk/support/mobile-devices/how-to-use-galaxy-ai-transcript-assist/
- Samsung US, Voice Recorder mit Galaxy AI: https://www.samsung.com/us/support/answer/ANS10000942/
- Android Headlines, Samsung Voice Recorder Cloud-Transkription One UI 9 (Juli 2026): https://www.androidheadlines.com/2026/07/samsung-voice-recorder-one-ui-9-cloud-ai-transcription.html
- Android Police, Google Keep Sprachnotizen: https://www.androidpolice.com/abandoned-voice-notes-hidden-google-keep-trick-transcribes-text-instantly/
- keyboardapps.net, Gboard Offline-Sprachpakete: https://www.keyboardapps.net/gboard-voice-typing
- Daylio, Google Play: https://play.google.com/store/apps/details?id=net.daylio
- AppBrain, Daylio: https://www.appbrain.com/app/daylio-journal-mood-tracker/net.daylio
- ChoosingTherapy, Daylio Review 2026: https://www.choosingtherapy.com/daylio-app-review/
- ChoosingTherapy, Reflectly Review 2026: https://www.choosingtherapy.com/reflectly-app-review/
- Tracxn, Reflectly: https://tracxn.com/d/companies/reflectly/__wsshogrPyXc3oWbnVxQpSUXv8csfyJ-MxqGjHRa0Djc
- Rosebud, Funding-Blog (6 Mio. $): https://www.rosebud.app/blog/rosebud-raises-6m-to-expand-the-worlds-leading-ai-journal
- Rosebud, App Store: https://apps.apple.com/us/app/rosebud-ai-journal-diary/id6451135127
- Bustle, Rosebud Review (Preise): https://www.bustle.com/wellness/rosebud-therapy-app-review-features-price
- blog.mylifenote.ai, AI Journaling Apps Compared 2026: https://blog.mylifenote.ai/ai-journaling-apps-compared/
- blog.mylifenote.ai, Mindsera Review: https://blog.mylifenote.ai/mindsera-review/
- personaldevelopmentapps.com, Stoic Review 2026: https://personaldevelopmentapps.com/stoic-review
- getstoic.com, AI und Mental Health (4 Mio. Nutzer): https://www.getstoic.com/blog/ai-mental-health-stoic
- reflection.app, Stoic-Profil: https://www.reflection.app/journaling-apps/stoic
- reflection.app, Penzu-Profil: https://www.reflection.app/journaling-apps/penzu
- RytePad, Penzu-Alternativen (Pro/Pro+ Preise): https://rytepad.com/penzu-alternatives/
- ProWritingAid, 12 best journaling apps 2026 (Grid Diary Preise): https://prowritingaid.com/journaling-apps
- Zapier, best journal apps 2026 (Grid Diary, Diarium): https://zapier.com/blog/best-journaling-apps/
- ChoosingTherapy, Bearable Review 2026: https://www.choosingtherapy.com/bearable-app-review/
- Reflection.app, Startseite/Preise: https://www.reflection.app/
- Holstee, Best Journaling Apps 2026: https://www.holstee.com/blogs/mindful-matter/best-journaling-apps
- bestjournalingapps.com (DE), Day-One-Alternativen 2026: https://bestjournalingapps.com/de/blog/best-day-one-alternatives/
- Day One Blog, Reaktion auf Apple Journal: https://dayoneapp.com/blog/apples-journal-app-and-day-ones-evolution/
- Day One Blog, Journaling Suggestions: https://dayoneapp.com/blog/introducing-journaling-suggestions/
- Apple Developer, WWDC24 Journaling Suggestions: https://developer.apple.com/videos/play/wwdc2024/10209/
