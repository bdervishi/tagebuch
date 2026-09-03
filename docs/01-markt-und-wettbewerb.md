# 01 · markt und wettbewerb

Stand: 3. September 2026 · Status: Entwurf

## 1. Ergebnis in Kürze

- Keine der rund 40 untersuchten Apps erfüllt die Kombination "täglich per Sprache, ausnahmslos lokal, kein Konto, iOS und Android, Deutsch als vollwertige Sprache". Die drei nächsten Kandidaten sind CortexOS (KI-Analyse-Journal mit Cloud-Vault im Premium), Offscript (Sprachmemo-Werkzeug ohne Tagebuch-Ritual) und Flint (Standardmodus schickt Text in die Cloud) [1][2][3].
- Auf iOS setzt Apple Journal den Preis auf null und die Datenschutzerwartung hoch, transkribiert laut Apple-Support aber nur Englisch und bleibt an iCloud gebunden [4][5]. Auf Android gibt es kein Pendant: Google Recorder ist Pixel-exklusiv, Samsung Transcript Assist verlangt Netz und Samsung-Konto, Google Keep transkribiert in der Cloud [6][7][8].
- Die etablierten Tagebuch-Apps (Day One, Journey, Diarium, Diarly, Daylio) behandeln Audio als Anhang. Transkription gibt es, wenn überhaupt, nur auf iOS, mit 10-Minuten-Grenze und Konto- oder iCloud-Bindung [9][10][11].
- Der serverlose Gerätewechsel per verschlüsselter Datei und QR-Code ist in keiner untersuchten App belegt. Wettbewerber nutzen iCloud, eigene Cloud-Tresore oder bieten gar keinen Transfer an [1][12][13].
- Marktbewegung: keine Übernahme oder Einstellung einer großen Tagebuch-App 2025/2026 gefunden. Die Signale sind Preiserhöhungen (Day One), separate KI-Tarife, Wagniskapital für Cloud-KI-Journale (Rosebud) und Sherlocking durch Apple (Journal auf iPad und Mac, SpeechAnalyzer als System-API) [9][14][15][16].

Positionierung in einem Satz: **Die App ist das tägliche Sprach-Tagebuch für iPhone und Android, das Aufnahme, Transkription in Deutsch und Englisch und Ablage vollständig auf dem Gerät hält, ohne Konto und ohne Server, mit verschlüsseltem Gerätewechsel per QR-Code statt Cloud-Sync.**

## 2. Methodik und Quellenlage

Die Recherche lief am 3. September 2026 über Websuche mit Snippet-Auswertung. App Store, Google Play und die meisten Herstellerseiten waren aus der Recherche-Umgebung nicht abrufbar (D15). Direkt gelesen wurden GitHub-Repositories (DailyVox, WhisperJournal, VoiceInk, Konverter-Projekte) und developer.apple.com.

Konsequenz für dieses Dokument: Eine Faktenprüfung (`verifikation.json`) lag zum Redaktionsschluss nicht vor. **Alle Preise, Sternebewertungen, Download- und Nutzerzahlen in den Tabellen stammen aus Suchsnippets und gelten als unverifiziert**, bis sie gegen die Store-Seiten geprüft sind. Im Fließtext ist dies je Zahl mit "(unverifiziert)" markiert. Preise sind US-Dollar-Angaben der Quellen; DACH-Preise in Euro weichen ab. Mehrere "Review 2026"-Seiten werden von Wettbewerbern betrieben (reflection.app, mindsera.com, dayora.ai, spokenly.app) und wurden nur herangezogen, wo keine bessere Quelle vorlag.

## 3. Drei Gruppen von Wettbewerbern

1. **Plattform-Angebote**: kostenlos, vorinstalliert oder herstellergebunden. Sie definieren, was Nutzer ohne Zusatzkosten erwarten dürfen.
2. **Etablierte Tagebuch-Apps**: textzentriert, plattformübergreifend, mit Konto und Sync. Sie definieren Funktionsstandards (Erinnerungen, Export, Suche) und das Preisniveau für Abos.
3. **Voice-first-Apps**: Sprachnotiz- und Sprachtagebuch-Apps, meist jung (2024 bis 2026), oft von Einzelentwicklern. Hier sitzt der direkte Wettbewerb.

## 4. Wettbewerbsmatrix

Legende: OD = On-Device-Transkription; Cloud = Server-Transkription; "?" = nicht belegbar. Preise und Bewertungen in allen drei Tabellen: unverifiziert (Suchsnippets).

### 4.1 Plattform-Angebote

| Angebot | Plattformen | Preis | Datenhaltung / Konto | Transkription | Sprachen (Deutsch?) | Sync / Export | Erinnerung | Schwächen aus Sicht des Zielprodukts |
|---|---|---|---|---|---|---|---|---|
| Apple Journal [4][5][17][18] | iPhone (iOS 17.2, Dez. 2023); iPad und Mac seit 15. Sept. 2025 | kostenlos | lokal + iCloud (Ende-zu-Ende-verschlüsselt), Apple-ID; Face ID/Touch ID | OD (SpeechAnalyzer) | laut Apple-Support nur Englisch; Notizen/Sprachmemos transkribieren zehn Sprachen inkl. Deutsch | iCloud-Sync; Export seit iOS 18 als ZIP mit HTML je Eintrag plus M4A/CAF; kein Import, kein JSON/Markdown | Zeitplan mit Benachrichtigungen, Streaks (iOS 18) | kein Android; Deutsch-Transkription fehlt; Lock-in (mindestens zehn "Apple Journal → Markdown"-Konverter auf GitHub seit Dez. 2025); Nutzerberichte "Couldn't Transcribe Audio" |
| Google Recorder [6][19] | nur Pixel (offiziell) | kostenlos | lokal; Backup optional über recorder.google.com (Google-Konto) | OD, offline | mehrere Sprachen inkl. Deutsch (Angaben schwanken zwischen 8 und 15); "Transcribe again" in der Cloud mit 42 Sprachen | Export M4A, TXT/SRT | keine | nur Pixel; kein Tagebuch (keine Tageseinträge, keine Erinnerung, keine Verschlüsselung über das System hinaus) |
| Samsung Voice Recorder / Transcript Assist [7][20] | Galaxy ab S24 (Jan. 2024) | kostenlos | Samsung-Konto und Netz für Transkription/Zusammenfassung; Option "nur auf Gerät" mit reduziertem Umfang | überwiegend Cloud; One UI 9 ergänzt Cloud-Transkription (Juli 2026) | 22 Sprachen inkl. Deutsch (März 2026) | Export nach Samsung Notes | keine | Konto- und Netzpflicht; kein Tagebuch-Kontext; nur Galaxy |
| Google Keep [8] | Android, iOS, Web | kostenlos | Google-Konto, Cloud | Cloud | Google-Spracherkennung | Google-Sync | Erinnerungen (allgemein) | kein Offline-Transkript, kein Tagebuch |
| Google AI Edge Eloquent [21] | iOS (April 2026) | kostenlos | lokal; Cloud-Modus mit Gemini optional | OD (Gemma-ASR) | ? | ? | keine | Diktier-App, kein Tagebuch; nur iOS |

### 4.2 Etablierte Tagebuch-Apps

| App | Plattformen | Preis | Datenhaltung / Konto | Transkription | Sprachen (Deutsch?) | Sync / Export | Erinnerung | Schwächen aus Sicht des Zielprodukts |
|---|---|---|---|---|---|---|---|---|
| Day One (Automattic) [9][10][22][23] | iOS, iPadOS, macOS, watchOS, Android, Windows, Linux, Web | Basic kostenlos; Silver 49,99 $/J; Gold 74,99 $/J mit KI (April 2026); Altkunden 24,99 $/J | Konto Pflicht für Sync; E2E (AES-GCM-256, RSA-2048) | OD nur auf iOS 26 mit Apple Intelligence, sonst Apple-Server; Android nicht dokumentiert (vermutlich Server) | Gerätesprache | eigener Sync; Export JSON-ZIP mit Medien, TXT, CSV, PDF | täglich, Streaks, "On This Day" | Transkript-Limit 10 Minuten; Internet erforderlich; Verdopplung des Neukundenpreises; Server-Skepsis in DE-Rezensionen |
| Journey (Two App Studio) [11][24] | Android, iOS, macOS, Windows, Linux, ChromeOS, Web | Membership 49,99 $/J; Lifetime 199 $ | Google Drive, Dropbox oder Journey Cloud; Konto | nur iOS, nur bis 10 Minuten, keine importierten Audios | ? | Cloud-Sync; Export DOCX/PDF/JSON/ZIP; Audio als MP3 | ja | Android-Nutzer bekommen keine Transkription; Cloud-Bindung |
| Diarium (Timo Partl, DE) [25][26][27] | Windows, Android, iOS, macOS | Pro 14,99 $ einmalig je Plattform; Windows 19,99 $ | lokal; Sync über eigene Cloud-Speicher (OneDrive, Drive, Dropbox, iCloud, WebDAV); V5: Datenbankverschlüsselung mit Passphrase | Diktat über System-Spracherkennung; keine Nachtranskription von Aufnahmen | Systemabhängig | Export PDF/DOCX/HTML/TXT/JSON; Import aus Day One, Daylio, Journey, Apple Journal | ja | Text-App mit Diktat; Android-Diktat läuft typischerweise über Google; ca. 740 000 Android-Downloads, 4,86 Sterne (AppBrain) zeigen DACH-Nachfrage nach Einmalkauf |
| Diarly [12][28] | iPhone, iPad, Mac, Apple Watch | unter 2 $/Monat bzw. unter 24 $/J; separates Abo "AI+" für Transkription | iCloud Drive des Nutzers, keine eigenen Server; optionale Passwort-Verschlüsselung | OD mit Apple-Modell ab iOS 26 (SpeechTranscriber) | ja (Apple-Locales) | iCloud; Export Markdown, PDF | ja | kein Android; iCloud-Bindung; Transkription hinter zweitem Abo |
| Daylio (Relaxio) [29][30] | iOS, Android | Premium 35,99 $/J | lokal; verschlüsselte Backups in Drive/iCloud; PIN/Biometrie | keine | entfällt | Backup-Datei; CSV-Export | ja | Sprachmemos ohne Transkript; Nutzerklage "nur auf einem Gerät" |

### 4.3 Voice-first-Apps

| App | Plattformen | Preis | Datenhaltung / Konto | Transkription | Sprachen (Deutsch?) | Sync / Export | Erinnerung / Ritual | Schwächen aus Sicht des Zielprodukts |
|---|---|---|---|---|---|---|---|---|
| CortexOS (O. Martinov, Malta) [1][31] | iOS + Android (März 2026) | Free 10 Einträge/Monat; Premium 7,99 $/M oder 49,99 $/J, Lifetime 99,99 $ (andere Quelle: 9,99/79,99/199,99 $) | AES-256-GCM, Recovery-Phrase statt Konto; Premium mit "encrypted cloud vault" | OD Whisper; On-Device-LLM Llama 3.2 (1 bis 2 GB) | 99 Sprachen inkl. Deutsch | Cloud-Vault (Premium) | KI-Reflexion, Stimmungsmuster; Erinnerung ? | Analysefokus statt Tagebuch; 10-Einträge-Limit verhindert kostenloses tägliches Nutzen; 1 bis 2 GB Modell; Server-Komponente im Premium |
| Offscript (Richfield Labs) [2] | iOS + Android | ca. 60 $ einmalig und/oder 3 bis 20 $/M; Free-Tier | lokal; AES-256-GCM, Android Keystore, Biometrie | OD Whisper | 99 Sprachen; UI in 19 Sprachen inkl. Deutsch | ? | keine Tageserinnerung belegt | Sprachmemo-Werkzeug, kein Tagebuch-Ritual; Preis unklar |
| Flint (Klu Technologies Oy) [3][32] | iOS 17+; Play-Listing mit Update 17. Juni 2026, Funktionsgleichheit unklar | 12 $ einmalig | Audio lokal; Text im Standard zur Zusammenfassung in die Cloud; voller OD-Modus optional; Pro mit eigenem API-Key | OD-Modus oder Cloud (Deepgram/OpenAI/Anthropic) | ? | ? | Notizformate inkl. "first-person entry"; keine Erinnerung belegt | Standard nicht 100 % lokal; Tagebuch nur ein Format |
| DailyVox (K. NG, MIT) [13][33] | iOS 17+; Android in Entwicklung, unveröffentlicht (Aug. 2026) | kostenlos, Open Source, keine In-App-Käufe | 100 % lokal, "Data Not Collected"; optional iCloud-Sync; AES-256-Backup | OD (Apple Speech), Live-Transkription | DE, ES, FR, IT laut README | iCloud optional; Export PDF/JSON/Markdown/CSV | 42-Sekunden-Einträge, Wochenziele, Widgets, Siri | kein Android; Preisanker 0 € auf iOS; Solo-Projekt |
| Voice Journal (com.jr44.voicejournal) [34] | Android | ? | 100 % offline, kein Konto, keine Werbung | OD | Deutsch ausdrücklich | Export JSON/Text | ? (Tags, Suche; Update Mai 2026) | Android-only; direktester DACH-Wettbewerber auf Android |
| EchoVault [35] | Android | Free 5 Einträge/Woche; Pro 4,99 $/M | offline, "voice never leaves phone" | OD Whisper | ja | ? | Streaks, Wochenreports, KI-Coach | Android-only; Streak-Druck; Limit im Free-Tier |
| Local Journal [36] | iOS + Android | Free; Premium 6,99 $ einmalig | lokal, kein Konto, kein Sync | OD Whisper | nur Englisch | keiner ("nothing synced") | ? | kein Deutsch; kein Transfer |
| Whisper Notes [37] | iOS (iPhone 12+) | 7,99 $ einmalig | lokal | OD Whisper | 100+ Sprachen | ? | keine | Notiz-App; kein Android |
| Voicenotes [38][39] | iOS, Android, Mac, Win, Web, watchOS, Wear OS | Free; Pro 9 bis 14,99 $/M oder 99,99 $/J | Cloud (AWS USA), Konto; Audio nach Transkription gelöscht | Cloud; LLM OpenAI/Anthropic | 60+ Sprachen inkl. Deutsch | Cloud-Sync | Erinnerungsfunktionen, kein Tagebuch-Ritual | cloud-only; Aufnahmen gehen bei Upload-Fehlern verloren; Play 3,92 Sterne (2 500) |
| Whisper Memos [40] | iOS + Apple Watch | ab 5 $/M, 29,99 $/J | Cloud; Audio geht laut Datenschutzerklärung an OpenAI | Cloud | 50+ inkl. Deutsch | E-Mail, Zapier | keine | nicht lokal; Beschwerden zu Abstürzen und Abo |
| AudioPen [41] | iOS, Android, Web, Mac, Chrome | Prime 99 $/J, 159 $/2 J, 33 $/3 M (ohne Auto-Renew) | Cloud, Konto | Cloud | ? | Cloud | keine | Preis ("100 $ für mehr als 10 Notizen") kritisiert; Play 3,73 bis 3,97 Sterne |
| Talknotes [42] | iOS, Android, Web, Chrome | Free; 19,97 $/M oder 197 $/J | Cloud, Konto | Cloud | 50+; Eigenangabe Deutsch-WER 7,7 %, Dialekte beworben | Cloud | keine | hohes Abo; keine Tagebuch-Funktion |
| Speakwise [43] | iOS | 59,99 $/J | OD-Modus wählbar; Notion-Sync | OD wählbar, sonst Cloud | 100+ | Notion | Meeting-Fokus | kein Android |
| Cleft Notes [44] | iPhone, iPad, Mac | Basic free (5-Min-Notizen); Plus 6,99 $/M oder 39,99 $/J | OD-Transkription, KI-Strukturierung in der Cloud | OD | ? | ? | keine | kein Android; KI in der Cloud |
| Rosebud [15][45] | iOS, Android, Web | 12,99 $/M oder 119,88 $/J; Free 3 Einträge/Woche | Cloud, Konto; verschlüsselt in transit/at rest, nicht E2E | Cloud | "20 Sprachen" | Cloud | KI-Coaching | Cloud-Zwang; 6 Mio. $ Seed (Juni 2025) zeigt Kapitalinteresse am Gegenmodell |
| DE-Nischen: VoiceFlow, TOLDAYS, FourYou [46][47][48] | iOS (DE-Store) | ? | VoiceFlow "vollständig lokal"; FourYou "Keine Daten erhoben"; TOLDAYS speichert Original-Audio nicht dauerhaft | OD (VoiceFlow) / ? | ja | ? | Tagebuch; FourYou vier Fragen pro Tag | nur iOS; keine Bewertungen auffindbar; Beleg für DACH-Nachfrage |

Weitere Android-Listings ohne belastbare Daten: Voice Diary (60-Sekunden-Einträge, "100 % offline AI"), AI Offline Voice Journal/WhisperJournal (MIT, whisper.cpp, rund 1 100 Downloads laut AppBrain, unverifiziert), TalkJournal (Face ID, Kalenderansicht) [49][50][51]. appshunter.io zählt "226+ Voice Diary Apps for iPhone" [52]; das Segment ist zahlreich, aber flach besetzt.

## 5. Die nächsten Wettbewerber im Einzelnen

**CortexOS** ist technisch am nächsten: iOS und Android, Whisper lokal, kein E-Mail-Konto, Verschlüsselung. Es ist aber ein anderes Produkt: ein KI-Analyse-Journal (20+ Emotionen, kognitive Verzerrungen) mit 1 bis 2 GB lokalem Sprachmodell, einem Free-Tier von 10 Einträgen pro Monat (unverifiziert) und einem verschlüsselten Cloud-Tresor im Premium [1][31]. Die App braucht für den Tageseintrag weder LLM noch Server; das ist leichter, günstiger im Speicher und ehrlicher im Datenschutzversprechen.

**Offscript** liefert lokal, verschlüsselt und plattformübergreifend, aber als Sprachmemo-Werkzeug ohne Tagesstruktur, Erinnerung oder Rückblick [2]. Es zeigt, dass On-Device-Whisper auf Android produktionsreif ist, und liefert einen Preisanker für Einmalkäufe im Segment (rund 60 $, unverifiziert).

**Flint** ist der Preis-Benchmark für "günstiger Einmalkauf" (12 $, unverifiziert) und wirbt mit "private voice journaling". Im Standardmodus geht der Text jedoch zur Zusammenfassung in die Cloud; der volle On-Device-Modus ist Option, nicht Voreinstellung [3]. Ob das Android-Listing funktional gleichwertig ist, ist offen [32].

**DailyVox** beweist, dass Apples On-Device-Stack für ein komplett lokales, deutschsprachiges Sprachtagebuch mit "Data Not Collected"-Label reicht, und dass Android der schwierigere Teil ist: Die Android-Version ist seit Monaten "in Entwicklung" [13][33]. Als kostenloses Open-Source-Produkt setzt DailyVox auf iOS einen Nullpreis, allerdings mit 42-Sekunden-Einträgen und Analyse-Beiwerk ("Digital Twin").

**Voice Journal (jr44)** und **VoiceFlow** belegen Nachfrage im deutschsprachigen Raum, sind aber jeweils auf eine Plattform beschränkt und ohne erkennbare Monetarisierung [34][46].

**Diarly** ist der technische Verwandte auf iOS (SpeechTranscriber ab iOS 26, keine eigenen Server), aber Apple-only und iCloud-gebunden, mit Transkription hinter einem zweiten Abo [12][28].

**Apple Journal** bleibt der Maßstab für Einfachheit und Preis. Seine drei Grenzen sind zugleich die Differenzierungsflächen der App: kein Android, keine deutsche Transkription (Stand Support-Dokumentation, am Gerät zu prüfen), kein Weg aus iCloud heraus außer einem HTML-ZIP [4][5][17][18].

## 6. Wo die Lücke liegt

Die folgende Tabelle prüft die acht Kernmerkmale des Zielprodukts (aus `00-anforderungen.md`) gegen die nächsten Kandidaten. "teilw." = nur im Sonderfall oder nur teilweise; "?" = nicht belegbar.

| Merkmal | Apple Journal | Google Recorder | Day One | Diarly | DailyVox | CortexOS | Offscript | Flint | Local Journal | Voice Journal (jr44) |
|---|---|---|---|---|---|---|---|---|---|---|
| iOS | ja | nein | ja | ja | ja | ja | ja | ja | ja | nein |
| Android | nein | nur Pixel | ja | nein | nein (unveröffentlicht) | ja | ja | ? | ja | ja |
| Transkription immer lokal | ja | ja | teilw. (nur iOS 26 + Apple Intelligence) | ja (iOS 26) | ja | ja | ja | teilw. (Option) | ja | ja |
| Deutsch transkribiert | nein | ja | ja (Server/OD) | ja | ja | ja | ja | ? | nein | ja |
| Kein Konto, keine Server | teilw. (iCloud) | teilw. (Backup optional) | nein | teilw. (iCloud) | ja | teilw. (Cloud-Vault im Premium) | ja | teilw. | ja | ja |
| Tägliches Ritual (Erinnerung zur Uhrzeit, Tageseintrag) | ja | nein | ja | ja | teilw. (Wochenziele) | ? | nein | nein | ? | ? |
| Audio und Text gleichwertig behalten | ja | ja | ja (10 Min.) | ja | teilw. (42 s) | ? | ja | ja | ? | ? |
| Gerätewechsel ohne Cloud | nein | nein | nein | nein | teilw. (AES-Export, manuell) | nein | ? | ? | nein (kein Sync) | teilw. (JSON-Export) |

Lesart: Jede Spalte hat mindestens zwei Lücken. Die Apps, die "lokal" ernst nehmen, sind Einzelplattform-Projekte oder Werkzeuge ohne Tagebuch-Ritual; die Apps mit Ritual und Reichweite verlangen Konto oder Cloud. Der QR-initiierte, verschlüsselte Transfer (D6) ist in keiner Spalte vorhanden; das nächste Analogon ist der lokale Chat-Transfer von WhatsApp [1].

Die Lücke lässt sich in vier Sätzen beschreiben:

1. **Android ist unterversorgt.** Ohne Pixel oder aktuelles Galaxy gibt es keine konto- und cloudfreie System-Transkription; selbst mit Pixel fehlt die Tagebuch-Schicht [6][7]. Die App bringt deshalb eine eigene Engine mit (D3).
2. **Deutsch ist ein prüfbares Versprechen.** Solange Apple Journal nur Englisch transkribiert und Journey, Diarium, Daylio auf Android gar nicht transkribieren, ist "Deutsch, lokal, auf iPhone und Android" konkret und nachweisbar [4][11][25].
3. **Kein Konto ist im Mainstream unbesetzt.** Alle plattformübergreifenden Tagebuch-Apps mit Transkription verlangen ein Konto; alle kontofreien Apps sind Einzelplattform [9][11][13].
4. **Transfer statt Sync ist neu.** Dateibasierte Modelle werden akzeptiert (Diarium, Daylio) [25][29]; ein Handshake per QR-Code ohne Server ist eine erkennbare Neuerung, deren Fehlen von Live-Sync ehrlich kommuniziert werden muss.

## 7. Marktbewegungen

**Übernahmen.** Day One ging im Juni 2021 an Automattic [53]. Jour (textgeführtes Journaling) wurde 2021 von Alan übernommen, laut Gründerblog für 20 Mio. $ (unverifiziert) [54]. Reflectly soll im Mai 2021 an The Happiness Project gegangen sein (Tracxn, nicht unabhängig bestätigt) [55]. Für 2025/2026 wurde keine Übernahme einer Tagebuch- oder Voice-Journal-App gefunden.

**Einstellungen.** Journify hat sein Play-Store-Listing am 13. Mai 2024 entfernt (unverifiziert) [56]. Im KI-Begleiter-Umfeld kursiert eine Abschaltung von "Kin AI" mit Migrationsleitfaden; Details waren nicht prüfbar [57]. Die großen Tagebuch-Apps (Day One, Journey, Diarium, Diarly, Daylio, Penzu, Grid Diary, Stoic, Mindsera) werden in allen Vergleichen 2026 als aktiv geführt.

**Finanzierung.** Rosebud (Cloud-KI-Journal mit Voice) hat im Juni 2025 6 Mio. $ Seed-Kapital von Bessemer u. a. erhalten [15]. Das Kapital fließt in das Gegenmodell (Server-KI, Konto, Abo); Daylio nennt sich ausdrücklich "unfunded" [30].

**Preisdruck nach oben.** Day One hat den Neukundenpreis von 24,99 $ auf 49,99 $/Jahr (Silver) verdoppelt und einen KI-Tarif Gold für 74,99 $/Jahr eingeführt (April 2026, unverifiziert; eine deutsche Quelle datiert die Erhöhung auf August 2025) [9][14]. KI-Funktionen werden marktweit als eigener Tarif verkauft (Day One Gold, Diarly AI+, Stoic Premium+AI, Mindsera Genius) [12][58]. Hohe Voice-Abos (Talknotes 197 $/J, Untold rund 364 $/J, unverifiziert) werden in Rezensionen kritisiert [42][59].

**Sherlocking.** Apple hat Journal im September 2025 auf iPad und Mac gebracht und mit iOS 26 SpeechAnalyzer/SpeechTranscriber als System-API veröffentlicht [16][17]. Damit sinkt die Eintrittshürde für Apple-only-Apps (Diarly nutzt das Modell bereits), während Android weiter eine eigene Engine braucht. Für die App bedeutet das: Der iOS-Teil ist technisch günstig (D2), die Differenzierung liegt auf Android und im plattformübergreifenden, serverlosen Gesamtpaket.

**Google auf iOS.** Mit "AI Edge Eloquent" (April 2026) hat Google eine kostenlose Offline-Diktier-App für iOS veröffentlicht [21]. Das bestätigt On-Device-Spracherkennung als Erwartungshaltung, greift aber nicht ins Tagebuch-Segment ein.

**Marktgröße.** Marktforschungs-Pressetexte beziffern "Digital Journal Apps" mit 5,69 Mrd. $ (2025) und 6,34 Mrd. $ (2026), Wachstum rund 11,4 % pro Jahr (Straits Research; eine andere Quelle nennt 6,53 Mrd. $ für 2025; Definition unklar, unverifiziert) [60]. Belastbarer sind Produktzahlen: Day One "über 15 Mio. Downloads", Daylio 19 Mio. Downloads, Diarium rund 740 000 Android-Downloads, Voicenotes "1M+ downloads" (alle unverifiziert) [22][30][27][39]. Diarium zeigt, dass ein deutscher Einzelentwickler mit Einmalkauf ein sechsstelliges Nutzervolumen erreicht.

## 8. Folgerungen für das Konzept

Empfehlung: Die App positioniert sich nicht gegen Apple Journal oder Day One, sondern neben ihnen als das Sprach-Tagebuch für Menschen, die (a) Android nutzen oder Android und iPhone mischen, (b) Deutsch sprechen und (c) kein Konto anlegen wollen. Begründung: Auf allen drei Achsen gibt es heute kein Angebot, und jede Achse ist für Nutzer prüfbar (Store-Listing, Flugmodus, Datenschutzlabel).

Aus den Schwächen der Wettbewerber ergeben sich konkrete Vorgaben, die in den Folgedokumenten umgesetzt sind:

| Beobachtete Schwäche | Bei | Konsequenz für die App |
|---|---|---|
| Aufnahmen gehen bei Upload-Fehlern verloren | Voicenotes [38] | kein Upload; Aufnahme wird chunkweise verschlüsselt lokal geschrieben (D4) |
| Transkripte verschwinden, "Couldn't Transcribe Audio" | Apple Journal [18] | Audio bleibt erhalten; Transkription ist wiederholbar (A5, D4) |
| Nur Englisch | Apple Journal, Local Journal [4][36] | Deutsch (de-DE/de-AT/de-CH) und Englisch im MVP (D12) |
| 10-Minuten-Grenze mit Internetpflicht | Day One, Journey [10][11] | Transkription lokal, Aufnahmelänge nur als Free/Plus-Schnitt (D9, Details in `07-geschaeftsmodell.md`) |
| Free-Tier verhindert tägliches Nutzen (10 Einträge/Monat, 5/Woche) | CortexOS, EchoVault [1][35] | unbegrenzte Einträge kostenlos (D9) |
| Lock-in durch HTML-ZIP ohne Import | Apple Journal [5][17] | Export Markdown/JSON/PDF kostenlos; offener Containerformat-Entwurf (D6, D9) |
| Konto- und Serverpflicht für Sync | Day One, Journey, Samsung [9][11][7] | Transfer per verschlüsselter Datei und QR-Code (D6) |
| Streak-Druck | EchoVault, Apple Journal [35][17] | Erinnerung mit "Heute nicht" und "In 1 Stunde", kein Streak-Zwang (D7) |
| 1 bis 2 GB Modell auf dem Gerät | CortexOS [1] | kleine Streaming-Modelle als Standard, große Modelle optional (D3) |
| Unklare Angaben, ob Android-Version gleichwertig ist | Flint [32] | identischer Funktionsumfang auf beiden Plattformen als Erfolgskriterium |

Preisrahmen des Segments zur Einordnung (alle unverifiziert): Einmalkäufe für lokale Voice-Apps zwischen 6,99 $ (Local Journal) und 14,99 $ (Diarium Pro), Flint 12 $; Jahresabos für Tagebuch-Apps zwischen rund 24 $ (Diarly) und 49,99 $ (Day One Silver, Journey); Lifetime-Preise beim Zwei- bis Vierfachen des Jahresabos [3][12][25][36]. Die Preisentscheidung selbst steht in `07-geschaeftsmodell.md`.

Alternativen zur empfohlenen Positionierung, kurz bewertet:

- **"Privates KI-Journal" wie CortexOS**: höherer wahrgenommener Wert, aber schwere Modelle, Flaggschiff-Geräte und ein Versprechen, das auf Android ohne Gemini Nano in Deutsch nicht einlösbar ist (D8). Nicht empfohlen für den Start.
- **Reines Sprachmemo-Werkzeug wie Offscript**: breiterer Markt, aber bereits besetzt und ohne das tägliche Ritual, das den Auftrag ausmacht (M1, M2). Nicht empfohlen.
- **iOS-only wie Diarly/DailyVox**: technisch am billigsten, verfehlt aber M9 und die größte Lücke (Android). Nicht empfohlen.

## 9. Offene Fragen

1. Store-Prüfung aller Preise, Sterne und Bewertungszahlen in Abschnitt 4 (App Store DE/CH/AT, Google Play), insbesondere CortexOS, Offscript, Flint, DailyVox, Voice Journal, EchoVault.
2. Transkribiert Apple Journal unter iOS 26.x mit deutscher Systemsprache inzwischen auch Deutsch? Am Gerät testen; die Support-Dokumentation nennt nur Englisch.
3. Ist das Play-Listing von Flint funktional identisch mit der iOS-App (On-Device-Modus, Einmalkauf)?
4. Welche Engine und Modellgröße nutzt CortexOS auf Android, und wie gut ist die Deutsch-Qualität?
5. Wann erscheint die Android-Version von DailyVox, und mit welchem Funktionsumfang?
6. Status von Jour 2026 (Relaunch als "jour: AI Journal"?), Bestätigung der Reflectly-Übernahme, Hintergrund der Journify-Delistung.
7. Euro-Preise von Day One, Journey, Diarium, Diarly, Daylio in den DACH-Stores.
8. Wörtliche Rezensionen (DE/AT/CH) zu Sync-Ausfällen, Datenverlust und Abo-Ärger bei Day One, Journey, Apple Journal; die vorliegende Stichprobe stammt überwiegend aus GitHub-Issue-Trackern und ist technisch verzerrt.

## Quellen

1. CortexOS FAQ und Vergleichsseite: https://cortexos.app/faq/ ; https://cortexos.app/library/best-private-voice-journal-2026/
2. Offscript (Richfield Labs): https://www.richfieldlabs.com/apps/offscript ; https://play.google.com/store/apps/details?id=com.offscript.app&hl=en-US
3. Flint, Klu-Blog "Private voice journaling": https://klu.so/blog/private-voice-journaling
4. Apple Support, Journal auf dem iPhone (Transkription nur Englisch): https://support.apple.com/en-kz/guide/iphone/iph492ee70a8/ios
5. Apple Support 121822, Journal-Einträge sichern, exportieren, drucken: https://support.apple.com/en-us/121822
6. Google Pixel-Hilfe, Transkriptionen im Recorder: https://support.google.com/pixelphone/answer/16267698?hl=en
7. Samsung UK, Galaxy AI Transcript Assist: https://www.samsung.com/uk/support/mobile-devices/how-to-use-galaxy-ai-transcript-assist/
8. Android Police, Google Keep Sprachnotizen: https://www.androidpolice.com/abandoned-voice-notes-hidden-google-keep-trick-transcribes-text-instantly/
9. 9to5Mac, Day One Gold (08.04.2026): https://9to5mac.com/2026/04/08/day-one-journaling-app-introduces-gold-plan-with-ai-summaries-and-daily-chat/
10. Day One, Audio Recording Guide: https://dayoneapp.com/guides/tips-and-tutorials/audio-recording/
11. spokenly.app, Voice Journaling 2026 (Journey-Transkription iOS-only, 10 Minuten): https://spokenly.app/blog/voice-journaling
12. Diarly, Preise und Transkription: https://diarly.app/pricing ; https://diarly.app/help/record-transcribe-dictate.html
13. DailyVox, Repository (README, Android-Status): https://github.com/intrepidkarthi/dailyvox
14. 5typos.net, Day One Silver/Gold (08.04.2026): https://5typos.net/2026/04/8/day-one-introduces-silver-and-gold-with-price-increases
15. Rosebud, Seed-Finanzierung 6 Mio. $: https://www.rosebud.app/blog/rosebud-raises-6m-to-expand-the-worlds-leading-ai-journal
16. Apple Developer, WWDC25 Session 277 (SpeechAnalyzer): https://developer.apple.com/videos/play/wwdc2025/277/
17. 9to5Mac, Journal auf iPad und Mac (17.06.2025): https://9to5mac.com/2025/06/17/apples-journal-app-is-coming-to-ipad-and-mac-with-big-upgrades/ ; iOS 18 Journal (19.09.2024): https://9to5mac.com/2024/09/19/ios-18-brings-much-needed-features-to-journal-app/
18. Apple Community, "Couldn't Transcribe Audio": https://discussions.apple.com/thread/255916391 ; Konverter-Projekte: https://github.com/kpod13/journal2day1 ; https://github.com/journiv/journiv-app/issues/253
19. Android Authority, Google Recorder auf Nicht-Pixel: https://www.androidauthority.com/google-recorder-app-1069849/
20. Android Headlines, Samsung Voice Recorder Cloud-Transkription One UI 9 (Juli 2026): https://www.androidheadlines.com/2026/07/samsung-voice-recorder-one-ui-9-cloud-ai-transcription.html
21. TechCrunch, Google AI Edge Eloquent (07.04.2026): https://techcrunch.com/2026/04/07/google-quietly-releases-an-offline-first-ai-dictation-app-on-ios/
22. Day One, Plans und About: https://dayoneapp.com/plans/ ; https://dayoneapp.com/about
23. Day One, E2EE FAQ und Export: https://dayoneapp.com/guides/day-one-sync/end-to-end-encryption-faq/ ; https://dayoneapp.com/guides/tips-and-tutorials/exporting-entries/
24. Journey, Membership: https://journey.cloud/membership ; https://help.journey.cloud/en/article/journeycloud-membership-k32g8e/
25. Diarium, Website und Forum "Cost of app": https://diariumapp.com/en ; https://forum.diariumapp.com/d/4901-cost-of-app-please-read-for-explanation
26. Diarium-Forum, On-Device-Verschlüsselung und Apple-Journal-Import: https://forum.diariumapp.com/d/3624-on-device-encryption ; https://forum.diariumapp.com/d/5304-apple-journal-importmigration-difficulty
27. AppBrain, Diarium: https://www.appbrain.com/app/diarium-journal-diary/partl.Diarium
28. VoiceInk, empirische SpeechTranscriber-Locale-Liste (de-DE/de-AT/de-CH): https://github.com/Beingpax/VoiceInk/blob/8f089cb4bf2c9c2f217b0cc0af909d9052ff6288/VoiceInk/Features/ModelLibrary/Models/LanguageDictionary.swift
29. ChoosingTherapy, Daylio Review 2026: https://www.choosingtherapy.com/daylio-app-review/
30. AppBrain, Daylio: https://www.appbrain.com/app/daylio-journal-mood-tracker/net.daylio ; Journiv-Issue zu Daylio: https://github.com/journiv/journiv-app/issues/58
31. CortexOS, About: https://cortexos.app/about/ ; Play: https://play.google.com/store/apps/details?id=com.cortexos.app
32. Flint, Play-Listing: https://play.google.com/store/apps/details?id=so.klu.flintapp&hl=en-US ; App Store: https://apps.apple.com/us/app/flint-voice/id6760716646
33. DailyVox, Vergleichsseite: https://getdailyvox.com/compare
34. Voice Journal (jr44), Play: https://play.google.com/store/apps/details?id=com.jr44.voicejournal&hl=en_US
35. EchoVault, Play: https://play.google.com/store/apps/details?id=com.echovault.app&hl=en_US
36. Local Journal: https://localjournal.app/
37. Whisper Notes: https://whispernotes.app/
38. yaps.ai, Voicenotes-Alternativen (Kritik cloud-only): https://www.yaps.ai/blog/voicenotes-alternative ; Voicenotes Privacy Policy: https://help.voicenotes.com/en/articles/9196879-voicenotes-privacy-policy
39. AppBrain, Voicenotes: https://www.appbrain.com/app/voicenotes/com.app.voicenotes ; Preise: https://aiproductivity.ai/pricing/voicenotes/
40. Whisper Memos, Website und Datenschutz: https://whispermemos.com/ ; https://whispermemos.com/page/privacy-policy
41. AudioPen Prime und Play-Listing: https://www.audiopen.ai/prime ; https://play.google.com/store/apps/details?id=com.audiopen.android&hl=en_US
42. Talknotes, Deutsch: https://talknotes.io/transcribe-in/german ; Preise: https://www.krowdbase.com/software/talknotes
43. Speakwise: https://speakwiseapp.com/
44. Cleft Notes, Preise: https://cleftnotes.com/pricing
45. Rosebud, App Store: https://apps.apple.com/us/app/rosebud-ai-journal-diary/id6451135127 ; Bustle-Review (Preise): https://www.bustle.com/wellness/rosebud-therapy-app-review-features-price
46. VoiceFlow: KI-Sprachtagebuch (DE-Store): https://apps.apple.com/de/app/voiceflow-ki-sprachtagebuch/id6755595633
47. TOLDAYS: https://toldays.de/
48. FourYou: Sprach Tagebuch: https://apps.apple.com/de/app/fouryou-sprach-tagebuch/id1671616134
49. Voice Diary, Play: https://play.google.com/store/apps/details?id=com.voicediary.voicediary&hl=en_US
50. WhisperJournal, Repository und AppBrain: https://github.com/kaisoapbox/WhisperJournal ; https://www.appbrain.com/app/openai-voice-journal/com.kaizoco.whisperjournal
51. TalkJournal, Play: https://play.google.com/store/apps/details?id=app.talkjournal&hl=en_US
52. appshunter.io, Voice Diary Apps für iPhone: https://appshunter.io/ios/topics/voice-diary
53. TechCrunch, Automattic übernimmt Day One (14.06.2021): https://techcrunch.com/2021/06/14/wordpress-com-owner-automattic-acquires-journaling-app-day-one/
54. Maxime Germain, "Jour is joining Alan": https://medium.com/@maximegermain/jour-is-joining-alan-e36e14020488
55. Tracxn, Reflectly: https://tracxn.com/d/companies/reflectly/__wsshogrPyXc3oWbnVxQpSUXv8csfyJ-MxqGjHRa0Djc
56. AppBrain, Journify (Listing entfernt): https://www.appbrain.com/app/journify-audio-journal-voic/co.journify.mobile
57. blog.mylifenote.ai, AI Journaling Apps Compared 2026 (Kin AI): https://blog.mylifenote.ai/ai-journaling-apps-compared/
58. personaldevelopmentapps.com, Stoic Review 2026: https://personaldevelopmentapps.com/stoic-review ; Mindsera-Review: https://blog.mylifenote.ai/mindsera-review/
59. Untold, App Store: https://apps.apple.com/us/app/untold-voice-journal/id6451427834
60. Straits Research, Digital Journal Apps Market: https://straitsresearch.com/report/digital-journal-apps-market
