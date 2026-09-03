# 02 · Nutzerfeedback und Lücken

Stand: 3. September 2026 · Status: Entwurf

## 1. Ergebnis in Kürze

- Die vier lautesten Beschwerden über bestehende Tagebuch- und Sprachnotiz-Apps sind, in dieser Reihenfolge: **Lock-in ohne brauchbaren Export**, **Datenverlust durch kaputte Backups oder fehlgeschlagene Uploads**, **Cloud- und Kontozwang** und **schlechte deutsche Transkription** (Kleinschreibung, Phantomtexte bei Stille, ungewollter Sprachwechsel, Schweizerdeutsch). Alle vier treffen genau die Punkte, an denen der Auftrag ohnehin keine Kompromisse zulässt (M6, M7, M8, A1).
- Was Nutzer sich wünschen, ist überschaubar und größtenteils günstig: Aufnahme ohne Umweg (Widget, Taste, Benachrichtigung), zuverlässige Erinnerung ohne Schuldgefühl, offene Exporte mit Audio, verschlüsseltes Backup mit Wiederherstellungstest, feste Sprachwahl, Android-Version. Teure Wünsche (Smartwatch, Mundart-Modell, lokale Zusammenfassungen) sind Wachstumsfeatures, keine Startbedingung.
- Die App ist gut positioniert, weil die meisten Beschwerden aus Architekturentscheidungen der Wettbewerber folgen (Server, Konto, Cloud-Transkription, Abo-Gating), nicht aus Detailfehlern. Wer ohne Server baut, erbt diese Probleme nicht, muss dafür aber Backup, Transfer und Aufnahme-Robustheit über jeden Zweifel erhaben machen.
- Empfehlung für den MVP: zehn Differenzierungen mit Aufwand S oder M (Abschnitt 6, Chancen 1 bis 6 und 8 bis 11), die alle bereits durch die Entscheidungen D4 bis D9 und D14 gedeckt sind. Der Ein-Geste-Start über Widget, Kurzbefehl und Kachel (Chance 7) folgt in Version 1.x; im MVP gibt es nur die Aufnahmetaste und die Aktion in der Benachrichtigung (`03-produktkonzept.md`, Abschnitt 5). Dazu ein knappes Set von Anti-Patterns als Prüfliste für jede Produktentscheidung (Abschnitt 7).

## 2. Methodik und Quellenlage

Die Nutzerfeedback-Recherche lief am 3. September 2026 unter einer starken Einschränkung: App Store, Google Play, Reddit, Hacker News, Trustpilot, heise, Kuketz-Blog und die Apple-Community waren aus der Recherche-Umgebung nicht erreichbar (D15). Direkt lesbar war GitHub (Issue-Tracker, Discussions, READMEs); ergänzend liegen Suchsnippets aus den Wettbewerbs- und Innovationsrecherchen vor.

Das hat drei Folgen für dieses Dokument:

1. **Die Stichprobe ist verzerrt.** Wörtliche Zitate stammen überwiegend aus Open-Source-Projekten (Journiv, Easy Diary, Fossify Voice Recorder, uhabits, whisper.cpp, WhisperKit, Transkribor, DailyVox, Dictus). Diese Nutzer sind technisch versiert und datenschutzaffin. Sie sind ein guter Frühindikator für Kritik, aber kein Abbild der Store-Rezensionen von Day One oder Apple Journal.
2. **Aussagen über kommerzielle Apps sind indirekt.** Was über Apple Journal, Day One, Daylio, Diarium, Voicenotes oder Whisper Memos gesagt wird, kommt aus Import-Anfragen in Konkurrenzprojekten, aus Herstellerdokumentation, aus Konverter-Repositories und aus Sekundärquellen.
3. **Die Faktenprüfung deckt nur technische Aussagen ab.** `docs/recherche/verifikation.json` (Stand 3. September 2026) prüft 30 Aussagen aus den Technikberichten zu iOS und Android; 18 wurden bestätigt, 12 korrigiert oder präzisiert [69]. Markt-, Preis-, Benchmark- und Nutzerzahlen waren nicht Gegenstand der Prüfung. Für dieses Dokument sind vier Ergebnisse relevant und eingearbeitet: die whisper.cpp-Messung auf dem Samsung Note10 (Abschnitt 3.5, bestätigt und präzisiert), der Apple-Watch-Benchmark (Abschnitt 3.5, bestätigt), der Speicherbedarf des Parakeet-Modells (Abschnitt 3.5) und die Versionsabhängigkeit der von `SpeechTranscriber` gemeldeten Sprachen (Abschnitt 3.4). Alle übrigen Zahlen, die im Recherchebericht als `mustVerify` markiert oder aus Suchsnippets rekonstruiert sind, tragen weiterhin den Zusatz "(unverifiziert)". Direkt auf GitHub gelesene Zitate sind mit Datum und URL belegt.

Eine Nachrecherche mit Store- und Reddit-Zugriff steht in Abschnitt 8 als offene Aufgabe.

## 3. Was Nutzer stört

Die folgende Priorisierung gewichtet drei Dinge: Häufigkeit in der Stichprobe, Schwere für den Nutzer (Datenverlust wiegt schwerer als ein fehlendes Widget) und Relevanz für ein Sprach-Tagebuch.

### 3.1 Lock-in und mangelhafter Export (Priorität: sehr hoch)

Der häufigste Beschwerdetyp in der Stichprobe. Das Vokabular ist bezeichnend: Ein Nutzer von Apple Journal schreibt am 5. Januar 2026: *"I have about eighty entries trapped in Apple Journal. I'd love to be able to break them free and import them, including attached photos, audio files and geolocation data."* [1]

Apple Journal exportiert seit iOS 18 einen ZIP-Ordner mit HTML je Eintrag; ein Datumsbereich ist nicht wählbar (*"There is no option to export a specific date range."*), und es gibt keinen Import [2]. Beim Import in die Gegenrichtung gehen Audiodateien verloren: *"Audio files are not imported"* [3]. Allein zwischen Dezember 2025 und August 2026 sind auf GitHub mindestens zehn unabhängige "Apple Journal → Markdown/Obsidian/Day One"-Konverter entstanden (GitHub-Suche vom 3. September 2026) [2].

Bei Daylio nennt ein Nutzer als Wechselgrund die Bindung an ein Gerät und fehlende Anbindung nach außen: *"Been paying for premium for a couple of years but it's a pain having it on one device only and having next to no integration with anything else."* [4] Dieses Zitat ist kein Beleg gegen Lock-in, sondern ein Warnhinweis in eigener Sache: Die App ist per Design ein Ein-Geräte-Produkt ohne Sync (`00-anforderungen.md`, Nicht-Ziele). Diese bewusste Einschränkung wird nur dann akzeptiert, wenn der Transfer per Datei (D6) so schmerzfrei wie möglich ist und der Export offen bleibt; sonst trifft die Daylio-Kritik auch diese App. Im selbst gehosteten Journiv sind Import-Anfragen für Day One, Daylio, Diarly, Diarium und Apple Journal die häufigste Feature-Kategorie [1][4].

Auch wo Export existiert, scheitert er oft: *"the progress bar stays at zero and it never finishes"*, *"It creates the export files but doesnt save the attachments"* [5].

**Konsequenz:** Export ist eine Vertrauensbedingung, kein Komfortmerkmal. Die App liefert Markdown, JSON und PDF kostenlos (D9), Audio als Opus-Dateien mit, und der Export sollte vor dem ersten Eintrag sichtbar sein (Onboarding-Hinweis "So bekommst du alles wieder heraus").

### 3.2 Datenverlust, kaputte Backups, fehlgeschlagene Wiederherstellung (Priorität: sehr hoch)

- Easy Diary, 25. August 2026: *"I have approximately 1,200 photos attached to my diary entries. The photos are successfully backed up to Google Drive... However, when I restore the backup... only about two photos are restored at a time."* [6]
- Journiv, 29. April 2026: *"I have had auto-updates running on Journiv for a while now, and just realized that I've lost access to the body copy of all entries made before the version 0.17 update."* [7] Datenverlust durch eine Migration im automatischen Update.
- Fossify Voice Recorder, 16. Juni 2024: Nach über 50 Minuten Aufnahme eine `FileNotFoundException`; *"I just recorded very important information and this bug completely ruined it"* [8].
- Voicenotes (Cloud): *"can lose recordings when an upload fails, and does nothing offline"* [17].
- Apple Journal: Nutzerberichte über "Couldn't Transcribe Audio" mit verschwindenden Transkripten [60].

Der Wunsch dahinter ist konkret: *"That would make it much safer to use the app as I can be sure my data is always backed up and restorable if I lose/damage the phone."* und: Backup mit dem vorhandenen PIN verschlüsseln, *"in case of Google account compromise"* [9].

**Konsequenz:** Für eine App ohne Server ist das Thema Backup und Transfer die verwundbarste Stelle. D6 legt fest: dieselbe Containerdatei für Gerätewechsel und Backup, mit Passphrase, monatlicher Erinnerung und Erklärung, dass Betriebssystem-Backups die Daten nicht wiederherstellen. Ergänzend empfohlen: ein Wiederherstellungstest ("Backup prüfen") direkt nach dem Erstellen, Aufnahme chunkweise auf Disk (D4), Schema-Migrationen mit Vorab-Sicherung.

### 3.3 Cloud-Zwang, Konten, Tracker (Priorität: hoch)

Der Autor von DailyVox begründet sein Projekt damit, dass bestehende Voice-Diary-Apps Server-Uploads verlangten; sein Ziel: *"a voice journal where everything runs on-device"*, mit *"Zero network calls. Zero third-party SDKs. Zero analytics."* [10]. Whisper Memos schreibt in seiner Datenschutzerklärung, dass *"transcription entails sending the audio file to OpenAI"* [16]. In einer deutschen Day-One-Rezension wird der Datenschutz beim Sync *"mit erheblicher Skepsis"* betrachtet; der Rezensent speichert dort keine Gesundheitsdaten [18].

Verschlüsselung ist bei Tagebuch-Projekten die am stärksten nachgefragte Eigenschaft: bei billthefarmer/Diary sind "Encrypt diary option", "Encrypted Diary" und "password access" die reaktionsstärksten Issues [13]; bei Journiv steht *"The data is stored in plain text in the database"* auf "Planned" [11]. Beim Fossify Voice Recorder wurde die Bitte um Verschlüsselung (*"People need to be able to at least discourage third parties from accessing recordings"*) als wontfix geschlossen [12], was eine Lücke offen lässt.

Der Kuketz-Blog fand 2020/21 bei Journey (Crashlytics, Google-Komponenten) und Diaro (Amazon-Werbenetzwerk) "miserablen Datenschutz"; heise titelte 2021 "Digitale Logbücher mit Sicherheitslücken" (beide aus Suchsnippets, unverifiziert) [14][15].

**Konsequenz:** D5 und D14 decken das ab (Envelope-Verschlüsselung, keine SDKs mit Netzzugriff, keine INTERNET-Permission auf Android). Wichtig ist, dass dieser Zustand für Nutzer prüfbar wird: Flugmodus-Test im Onboarding, Datenschutzlabel "Keine Daten erfasst", offener Quellcode (D10).

### 3.4 Transkriptionsqualität für Deutsch und Schweizerdeutsch (Priorität: hoch)

Vier wiederkehrende Fehlerbilder, alle mit deutschsprachigem Bezug:

| Fehlerbild | Zitat | Quelle |
|---|---|---|
| Kleinschreibung, keine Interpunktion | *"I tried German, using the large model. But it wrote every word in small letters (in German, we have many words with capital letters), and it did not set any punctuation."* | faster-whisper #601 [19] |
| Phantomtexte bei Stille | Whisper erfindet bei Pausen *"Untertitel der Amara.org-Community"*, *"Untertitel im Auftrag des ZDF, 2017"*, *"Copyright WDR"*; im Englischen dominieren "Thank you for watching"-Varianten | whisper #928, arXiv 2501.11378 [20][26] |
| Ungewollter Sprachwechsel oder Übersetzung | *"when the audio starts in a french and then switch to german, whisper.cpp transcribes the audio then translate it in french"*; *"it keeps switching through several languages"* | whisper.cpp #1800, easyspeak #153 [21] |
| On-Device-Framework schlechter als Desktop-Pipeline | Deutsches Audio, August 2026: *"Wrong language detection"*, *"Skipped sentences"*, *"Straight up hallucinations"* | WhisperKit #528 [22] |

Schweizerdeutsch ist ein eigenes Kapitel. Das Transkriptionsprojekt Transkribor hält fest, dass für Mundart-Aufnahmen die nachgelagerte Korrektur etwa die Hälfte der Arbeit ausmacht, und plant ein optionales Schweizerdeutsch-Modell mit dem Grundsatz *"Erst messen, dann bauen."* [23]. Die Forschungslage: Whisper ohne Anpassung erreicht auf Schweizerdeutsch 23 bis 33 % Wortfehlerrate, feinabgestimmte Modelle 12,1 % bzw. 25,6 % je nach Testdaten (alle unverifiziert, aus Sekundärzusammenfassungen) [24]. Eine Schweizer App-Store-Rezension bemängelt ausdrücklich, dass Schweizerdeutsch nicht erkannt wird [25]. Die öffentlich verfügbaren Fine-Tunes stehen teils unter CC-BY-NC und sind für eine kommerzielle App nicht ohne Lizenzklärung nutzbar [23].

**Konsequenz:** D2, D3 und D12 sind darauf ausgelegt: feste Sprachwahl statt Auto-Erkennung, `SpeechDetector` bzw. VAD gegen Stille-Halluzinationen, Streaming-Modelle mit Interpunktion, ehrliche Erwartung "Hochdeutsch liefert die zuverlässigsten Ergebnisse". Eine Präzisierung aus der Faktenprüfung: Apple veröffentlicht keine feste Sprachliste für `SpeechTranscriber`; `supportedLocales` muss zur Laufzeit abgefragt werden, die Ausgabe war über die iOS-26.x-Versionen nicht stabil, und Apple bestätigte im Januar 2026, dass Arabisch fälschlich als unterstützt gelistet war [69][70]. de-DE, de-AT und de-CH stehen in einer auf macOS 26.4 abgefragten Liste, jede Ziel-Locale ist aber auf Zielgerät und Ziel-OS mit eigenem Audio zu prüfen, bevor die App sie anbietet. Und: Das Audio bleibt immer erhalten (A5), das Transkript ist nur die zweite Wahrheit.

### 3.5 Modellgröße, Performance, Onboarding-Hürden (Priorität: mittel-hoch)

Der Modell-Download ist ein Abbruchrisiko: Bei der Diktier-App Dictus brach der Download eines rund 445 MB großen Modells im Hintergrund ab und begann *"from byte 0"*; Nutzer mussten die App minutenlang offen halten. *"A model that never finishes compiling locks the user out of the whole app"* (unverifiziert, Issue vom 1. September 2026) [27]. Ältere whisper.cpp-Issues zeigen die Streuung über Android-Geräte: Eine 3-Sekunden-Aufnahme mit `tiny.en` brauchte auf einem Samsung Note10 31,2 s, nach Abschalten des R8-Code-Shrinkings noch 14,8 s, also das 5- bis 10-fache der Echtzeit (Faktenprüfung: bestätigt; Messung von 2023 mit Exynos 9825 und Debug-Build, nicht auf aktuelle Geräte übertragbar) [28][69]. Auf der Apple Watch Series 11 braucht selbst das kleinste Whisper-Modell 19,2 s zum Laden und ist damit *"not on-demand viable"* (Faktenprüfung: bestätigt; Einzelmessung eines Entwicklers) [29][69].

**Konsequenz:** D3 setzt auf kleine Streaming-Modelle als Standard (Moonshine Small, je 123 M Parameter) und macht große Modelle zum optionalen Zusatzpaket. Dass dieses Paket erst ab 6 GB RAM angeboten wird (D13), hat einen konkreten Grund: Für Parakeet TDT 0.6B v3 int8 (rund 640 MB auf der Platte) meldet ein Nutzer 1,23 GB RAM beim Laden; das ist eine einzelne, unbestätigte Messung, aber ein deutlicher Hinweis, dass der Arbeitsspeicherbedarf die Dateigröße klar übersteigt [69][71]. Der Download des Zusatzpakets muss fortsetzbar sein, und die App muss ohne das Paket vollständig funktionieren. Apple Watch ist kein MVP-Thema.

### 3.6 Erinnerungen, die nicht kommen (Priorität: mittel)

Belege aus dem Habit-Tracker Loop, dessen tägliche Erinnerung funktional einer Tagebuch-Erinnerung entspricht: *"Sometime reminder trigger on exact time and sometime it triggers after few seconds"*, in einigen Fällen *"it is not even triggering"* (Android 12/14, vom Maintainer als nicht reproduzierbar geschlossen); *"Sticky notifications only stick in the first hour or two."* (Galaxy S25+, Android 15, bestätigt); Erinnerungen werden nach Neustart nicht nachgeholt, wenn das Gerät nicht entsperrt wurde [30]. Easy Diary: Alarm stumm im Lautlos-Modus [31].

**Konsequenz:** D7 verwendet `setAlarmClock()` mit `SCHEDULE_EXACT_ALARM`, einen Onboarding-Schritt "Erinnerungen zuverlässig machen" mit Herstellerhinweisen (Samsung, Xiaomi, Huawei, OnePlus; Quelle dontkillmyapp [67]) und erlaubt den Aufnahmestart direkt aus der Benachrichtigung.

### 3.7 Fehlende Android-Version (Priorität: mittel)

*"Any plans for Android Release?"* ist die Kernfrage an DailyVox [32]; die Android-Version ist seit Monaten "in Entwicklung". Bei Journiv ist "Mobile app implementation" die meistgewünschte Diskussion, mit dem Argument *"for Wife-Approval-Factor, to be able to journal from an app instead of going to a website"* [33]. Apple Journal, Diarly und Cleft sind Apple-only; Journey transkribiert auf Android gar nicht (siehe `01-markt-und-wettbewerb.md`).

**Konsequenz:** Android ist die größere Lücke und darf nicht der nachgelagerte Port sein (M9, D1, D3).

### 3.8 Streak-Druck und Schuldgefühl (Priorität: mittel)

Daylogue beschreibt, wie "You missed your check-in yesterday"-Benachrichtigungen als Urteil wirken, Reset-Zähler Krankheit und Reisen bestrafen und der "what-the-hell effect" zum Abbruch führt; das Team entfernte nach einem Ethik-Audit alle Gamification-Elemente [34]. LogRocket ordnet Streaks der Verlustaversion zu: Wenn ein Tag alles löscht, entsteht "fragile engagement" [35]. Finch wird in Rezensionen gerade dafür gelobt, dass es keine Strafen gibt (*"your bird never dies"*) [36]. Duolingos Streak Freeze senkte laut Sekundärquelle die Abwanderung gefährdeter Nutzer um 21 % (unverifiziert) [37]; Vergebung schlägt Bestrafung also auch dort, wo Streaks das Kernprodukt sind. Die Kategorie hat ohnehin ein Bindungsproblem: Mediane 30-Tage-Retention von Mental-Health-Apps auf Android liegt bei 3,3 % (Analyse von 93 Apps, unverifiziert) [38].

**Konsequenz:** D7: "Heute nicht" und "In 1 Stunde" ohne Nachfrage, kein Streak-Zwang. Rückblicke (D8) zeigen Kontinuität als Kalender, nicht als Kette.

### 3.9 Preislogik: hohe Abos, nachträgliche Paywalls (Priorität: mittel)

Zu AudioPen: *"$100 insane to be able to do more than just 10 notes"* (unverifiziert) [41]. Zu Day One: *"$25-50 a year for a single purpose app is prohibitively expensive"* (unverifiziert) [42]. In der Journiv-Community löste ein neu aufgetauchter "Plus"-Tab sofort die Frage aus, ob das Projekt *"no longer completely open source"* sei [39]. Dictus formuliert als Grundsatz: *"No bait-and-switch — free features never become paid."* [40]. Free-Tiers mit 10 Einträgen pro Monat (CortexOS) oder 5 pro Woche (EchoVault) verhindern das tägliche Nutzen, das ein Tagebuch ausmacht (unverifiziert) [62][63].

**Konsequenz:** D9: unbegrenzt viele Einträge, Transkription, Verschlüsselung, Backup, Transfer und Export dauerhaft kostenlos; Garantie im Store-Text. Preise stehen nur in `07-geschaeftsmodell.md`.

### 3.10 Überfrachtung und Projektverlässlichkeit (Priorität: niedrig bis mittel)

Feature-Wunschlisten in Tagebuch-Trackern sind lang (Grid-Ansicht, Sketchpad, Filter, PDF und Reminder in einem einzigen Issue) [44]; *"Elaborate journaling apps tend to get abandoned while simple apps get used"* (unverifiziert) [43]. Gleichzeitig fragen Nutzer nervös nach dem Wartungsstand (*"It's the project alive"*) [33]. Beides spricht für ein kleines, sichtbar gepflegtes Produkt.

## 4. Was Nutzer sich wünschen

Priorisiert nach Beleglage und Passung zum Auftrag. "Gedeckt durch" verweist auf die verbindliche Entscheidung.

| Rang | Wunsch | Beleg | Gedeckt durch |
|---|---|---|---|
| 1 | Offline-Spracherkennung direkt im Recorder, Suche über alle Transkripte | reaktionsstärkstes Issue des Fossify Voice Recorder [45] | D2, D3, D4 (FTS5) |
| 2 | Verschlüsseltes Backup, das nachweislich wiederherstellbar ist | Easy Diary #230/#233/#234 [9] | D6 |
| 3 | Export in offene Formate mit Audio und Datumsbereich | Apple-Journal-Konverter, Journiv #386 [1][2] | D9 (Markdown/JSON/PDF); Datumsbereich zu ergänzen |
| 4 | Zuverlässige tägliche Erinnerung | uhabits #2052/#2200 [30] | D7 |
| 5 | Kurze, niedrigschwellige Einträge gegen die "blank page" | DailyVox 42-s-Format, Journiv #86/#420 [10][49] | M3, A4 (mehrere kurze Aufnahmen pro Tag) |
| 6 | Feste Sprachwahl, Option Schweizerdeutsch | Transkribor #130 [23] | D12 (Sprachwahl); Mundart später |
| 7 | Aufnahme ohne Bildschirmkontakt: Widget, Taste, Watch, Bluetooth-Mikrofon, Wake-Word | DreamLog, Fossify #54/#291, Just Press Record [46][47][51] | D7 (Start aus Benachrichtigung) im MVP; Widget, Kurzbefehl, Kachel in 1.x (Abschnitt 6, Chance 7; `03-produktkonzept.md`, Abschnitt 5) |
| 8 | Android-Version mit gleichem Funktionsumfang | DailyVox #4, Journiv #348 [32][33] | M9, D1 |
| 9 | Audio-Wellenform mit Markierungen | Journiv #88 [48] | offen |
| 10 | Ehrliche, dauerhafte Preislogik, Einmalkauf-Option | Dictus #54, Journiv #425 [39][40] | D9 (Lifetime, Free-Garantie) |
| 11 | Rückblick "vor einem Jahr" | Day One "On This Day" als *"a constant source of joy"* (Sekundärquelle) [54] | D8 |
| 12 | Barrierefreie Bedienung (VoiceOver/TalkBack, Reduce Motion, Kontrast) | uhabits #665/#666/#2170; Berichte zu Legasthenie und Sehbehinderung [58][59] | offen, Pflicht im MVP |

Explizite Anti-KI-Zitate von Endnutzern wurden in der Stichprobe nicht gefunden; die Skepsis zeigt sich indirekt darin, dass Projekte mit "Privacy by architecture, not policy" und *"There is no Memex server storing your journal"* werben [50], und im Widerstand gegen Googles KI-Funktionen in Journal, die trotz lokaler Verarbeitung als *"defeats journaling's core purpose"* kritisiert wurden (unverifiziert) [55]. Nachfrage nach KI existiert daneben, aber mit Bedingung: eigener Schlüssel, *"privacy protection ensuring raw context isn't stored without user consent"* [49].

## 5. Was gelobt wird

| Projekt | Was Nutzer oder Entwickler hervorheben | Übertragbar auf die App |
|---|---|---|
| DailyVox (iOS) | "Data Not Collected"-Label, keine Netzwerkaufrufe, Sprachen inkl. Deutsch, Export in vier Formaten plus AES-Backup, Widgets, Siri Shortcuts [10] | ja, alles außer iCloud-Option |
| memex (iOS/Android, GPL) | *"Zero vendor lock-in... one-click export all your records as standard Markdown files"* [50] | ja |
| Dictus (iOS, MIT) | Klare Free/Pro-Grenze, "No bait-and-switch" [40] | ja (D9) |
| DreamLog (Android) | Wake-Word, Auto-Stopp nach 10 s Stille, 75-MB-Modell, Netz nur für Modell-Download [46] | Auto-Stopp bei Stille: ja; Wake-Word: später |
| Transkribor (Desktop, DE) | *"Deine Aufnahmen bleiben bei dir"*, Messen vor Bauen bei Mundart [23] | ja, als Vorgehen |
| Finch | *"no penalties for missing days"* [36] | ja (D7) |
| Just Press Record (iOS) | Start per Action Button, Shortcut, Widget, Watch-Complication [51] | teilweise (Abschnitt 6) |

## 6. Lücken und Differenzierungschancen

Aufwand: S = wenige Tage, M = ein bis drei Wochen, L = mehr als einen Monat oder mit ungeklärter Abhängigkeit (Lizenz, Plattform-API). "MVP" heißt: Bestandteil der ersten Store-Version. Die Reihenfolge ist die empfohlene Priorität.

| # | Chance | Beleg (Kurz) | Aufwand | Empfehlung |
|---|---|---|---|---|
| 1 | **Nachweisbar offline**: keine INTERNET-Permission auf Android, Flugmodus-Test im Onboarding, Transparenzseite "Was verlässt dein Gerät: nichts", Datenschutzlabel "Keine Daten erfasst" | DailyVox-Vorbild, Kuketz/heise-Kritik [10][14][15] | S | MVP (D14) |
| 2 | **Backup, das man prüfen kann**: eine Containerdatei für Backup und Transfer, "Backup prüfen"-Funktion, monatliche Erinnerung, Erklärung der OS-Backup-Grenzen | Easy Diary #252/#233, Journiv #540 [6][7][9] | M | MVP (D6) |
| 3 | **Export vor dem ersten Eintrag sichtbar**: Markdown + JSON + Opus, Datumsbereich wählbar, PDF; Hinweis im Onboarding | Apple Journal "trapped", zehn Konverter [1][2] | S | MVP (D9; Datumsbereich ergänzen) |
| 4 | **Deutsch als erstklassige Sprache**: feste Sprachwahl (de-DE/de-AT/de-CH/en), Interpunktion und Groß-/Kleinschreibung aus dem Modell, Stille-Filter gegen Phantomtexte, Hinweis zu Hochdeutsch | faster-whisper #601, whisper #928, Transkribor [19][20][23] | M | MVP (D2, D3, D12) |
| 5 | **Aufnahme, die nicht kaputtgeht**: chunkweise verschlüsselt schreiben, Anruf/Bildschirmsperre/App-Kill abfangen, Bluetooth-Mikrofon, Auto-Stopp bei langer Stille (abschaltbar) | Fossify #56/#54, Voicenotes-Upload-Verluste, DreamLog [8][17][46][47] | M | MVP (D4) |
| 6 | **Erinnerung ohne Schuldgefühl, aber zuverlässig**: exakte Alarme, Herstellerhinweise, "Heute nicht", "In 1 Stunde", Start aus der Benachrichtigung, keine "Du hast gestern verpasst"-Meldungen | uhabits #2052/#2200, Daylogue, Finch [30][34][36] | S | MVP (D7) |
| 7 | **Ein-Geste-Start**: Home-Screen-Widget, App Shortcut, Siri-/Assistant-Kurzbefehl; Android Quick-Settings-Kachel; iOS Controls und Action Button | Just Press Record, Google-Recorder-Kachel [51][52] | S bis M | 1.x, als erstes 1.x-Thema (`03-produktkonzept.md`, Abschnitt 5; `09-roadmap.md`). Im MVP nur Aufnahmetaste und Benachrichtigung |
| 8 | **Kein Free-Limit auf Einträge**: unbegrenzt viele Einträge, Aufnahmelänge als einziger Free/Plus-Schnitt | CortexOS 10/Monat, EchoVault 5/Woche [62][63] | S | MVP (D9) |
| 9 | **Barrierefreiheit als Kernversprechen**: vollständige VoiceOver-/TalkBack-Bedienung, große Touch-Ziele, Reduce Motion, Vorlesen des Transkripts | uhabits #665/#2170, Legasthenie-Berichte [58][59] | M | MVP für VoiceOver/TalkBack; Vorlesen 1.x |
| 10 | **Rückblick "an diesem Tag" mit Audio-Wiedergabe**, Kalender ohne Zähler | Day One "On This Day" [54] | S | MVP (D8) |
| 11 | **Gerätewechsel iOS↔Android ohne Konto** per QR und verschlüsselter Datei | in keiner untersuchten App (siehe 01) | M | MVP (D6) |
| 12 | Erinnerungszeit-Vorschlag: App schlägt nach zwei Wochen den Median der tatsächlichen Aufnahmezeiten als neue Uhrzeit vor (nur Vorschlag, lokal berechnet) | MindScape: Abend-Check-ins am besten bewertet (unverifiziert) [53] | S | 1.x; Uhrzeit bleibt manuell (D7) |
| 13 | Wellenform mit Lesezeichen im Audio | Journiv #88 [48] | S bis M | Wellenform 1.x, Lesezeichen später |
| 14 | Persönliches Wörterbuch (Namen, Orte) als Kontext für die Transkription | gängige Whisper-`initial_prompt`-Praxis; Engine-Abhängigkeit prüfen | S bis M | 1.x nach Spike (Unterstützung in SpeechTranscriber und sherpa-onnx unklar) |
| 15 | Korrektur per Sprache ("ersetze Meier durch Maier") | Voice Control/Voice Access als Vorbild [66] | M | 1.x |
| 16 | Gesprochene Impulsfragen (kuratierte Liste, lokal vorgelesen, abschaltbar) | Journiv #420 "blank page" [49] | S | 1.x; im MVP bewusst weglassen (Einfachheit) |
| 17 | Zeitkapsel: Eintrag mit Öffnungsdatum | FutureMe seit 2025 kostenpflichtig (unverifiziert) [65] | S | 1.x |
| 18 | Therapie-Export: Zeitraum, nur Text, PDF; bewusste Übergabe ohne Medizinprodukt-Anspruch | EMA-Studien zeigen Machbarkeit von Symptomtagebüchern [68] | S | 1.x |
| 19 | Lokale Tages-/Wochenzusammenfassung (Apple Foundation Models, Opt-in) | Backlash gegen Googles Journal-KI mahnt zu Opt-in [55] | M (iOS) / L (Android) | 1.x nur iOS (D8); Android später |
| 20 | Offline-Nachlass: Archiv plus druckbares Notfallblatt für eine Vertrauensperson | Verbraucherzentrale-Empfehlung; Dead-Man's-Switch-Dienste brauchen Server [57] | M | 1.2, nach Krypto-UX-Prüfung |
| 21 | "Briefe an mein Kind" als zweites Tagebuch ohne Server | Kiddays; COPPA zählt Stimmdaten zu Kinderdaten [64] | M | später (mehrere Tagebücher sind Plus, D9) |
| 22 | Semantische Suche lokal (Embeddings) | Offscript bietet sie bereits | M | später; FTS5 zuerst (D8) |
| 23 | Mundart-Paket Schweizerdeutsch (nachladbar, Ausgabe Hochdeutsch, Beta-Kennzeichnung) | WER-Studien, CH-Rezensionen, CC-BY-NC-Lizenzen [23][24][25] | L | Wachstumsfeature CH, erst nach Messung und Lizenzklärung (D12) |
| 24 | Smartwatch-Aufnahme (Apple Watch, Wear OS) | Fossify #291 wontfix; Watch-Benchmark ernüchternd [29][47] | L | nicht vor 2.0 |
| 25 | Wake-Word-Start | DreamLog [46] | L | nicht geplant (Dauerlauschen widerspricht dem Vertrauensversprechen) |

**MVP-Empfehlung:** Chancen 1 bis 6 und 8 bis 11. Sie sind sämtlich durch D4 bis D9 und D14 gedeckt und beantworten die vier lautesten Beschwerden direkt. Einzeln sind sie klein (fünfmal S, fünfmal M), in Summe nicht: Nach eigener Rechnung mit S = 2 bis 4 Arbeitstage und M = 1 bis 3 Wochen ergeben sich rund 7 bis 19 Wochen für eine Person, in der Skala von `09-roadmap.md` also L bis XL, zusätzlich zum Grundgerüst aus Aufnahme, Transkription und Verschlüsselung. Die Roadmap verteilt diese Arbeit auf ihre Phasen. Chance 7 (Ein-Geste-Start) ist bewusst 1.x, weil sie das Ritual verkürzt, aber nicht verlässlicher macht. Bewusst nicht im MVP: alles, was das Produkt breiter statt verlässlicher macht (Impulsfragen, Zeitkapsel, Zusammenfassungen, Mundart, Watch). Begründung: Die Stichprobe zeigt, dass Vertrauen (Export, Backup, Offline-Nachweis) und Verlässlichkeit (Aufnahme, Erinnerung) über Bleiben oder Gehen entscheiden, nicht Funktionsvielfalt (Abschnitt 3.10).

Alternative Schnitte, kurz bewertet:

- **"Analyse zuerst"** (Stimmungen, Muster, KI-Reflexion wie CortexOS): höherer wahrgenommener Wert, aber regulatorisch heikel (Abschnitt 7), auf Android in Deutsch nicht lokal einlösbar (D8) und im Widerspruch zur beobachteten KI-Skepsis. Nicht empfohlen.
- **"Freihändig zuerst"** (Watch, Wake-Word, Kopfhörertaste): starker Wunsch, aber teuer, plattformabhängig und für die tägliche Zwei-Minuten-Aufnahme kein Muss. Als 1.x/2.0 empfohlen.

## 7. Anti-Patterns, die die App vermeidet

Diese Liste ist als Prüffrage für jede spätere Produktentscheidung gedacht: Verstößt das Feature gegen einen dieser Punkte, braucht es eine ausdrückliche Begründung.

| Anti-Pattern | Beobachtet bei | Beleg | Die App stattdessen |
|---|---|---|---|
| Export nur in ein proprietäres oder unvollständiges Format, kein Datumsbereich, kein Import | Apple Journal (HTML-ZIP), Journey (Audio nur als MP3) | [1][2][3] | Markdown, JSON, PDF, Opus; Datumsbereich; Import des eigenen Containers (D6, D9) |
| Cloud-Transkription als Voreinstellung, lokal nur als versteckte Option | Whisper Memos, Flint (Standardmodus), Samsung | [16], siehe 01 | ausschließlich lokal, keine Option für Cloud (A1, D14) |
| Konto als Voraussetzung für Kernfunktionen | Day One, Journey, Voicenotes, Samsung | siehe 01 | kein Konto, keine Server (A6) |
| Aufnahme geht bei Upload- oder Dateifehler verloren | Voicenotes, Fossify #56 | [8][17] | chunkweise verschlüsseltes Schreiben, kein Upload (D4) |
| Transkript verschwindet, Audio nicht wiederherstellbar | Apple Journal | [60] | Audio bleibt, Transkription wiederholbar (A5, D4) |
| Free-Tier, der tägliches Nutzen verhindert | CortexOS (10/Monat), EchoVault (5/Woche) | [62][63] | unbegrenzte Einträge kostenlos (D9) |
| Nachträgliches Einziehen kostenloser Funktionen | Journiv-"Plus"-Debatte als Warnsignal | [39] | Garantie "Free wird nie kostenpflichtig" im Store-Text (D9) |
| Strafende Streaks, Vorwurfs-Benachrichtigungen, Reset-Zähler | Daylogue-Analyse, EchoVault-Streaks | [34][35][63] | "Heute nicht" ohne Nachfrage, Kalender statt Kette (D7) |
| Tagebuchinhalt oder Stimmung in Benachrichtigungen | allgemeines Risiko | D5 | Benachrichtigungen enthalten nie Inhalt (D5) |
| Tracker-, Werbe- und Crash-SDKs in einer Tagebuch-App | Journey, Diaro (Kuketz), heise-Test | [14][15] | keine SDKs mit Netzzugriff, keine INTERNET-Permission (D14) |
| Automatische Stimmungserkennung aus der Stimme | KI-Journale allgemein | Emotionserkennung über Stimme fällt unter den AI Act (Transparenzpflicht Art. 50 seit 2. August 2026, Hochrisiko-Einstufung nach Annex III; unverifiziert) und DSGVO Art. 9 [56] | keine Inferenz; höchstens freiwillige Selbsteinschätzung (D8) |
| KI-Funktionen als Zwang oder Voreinstellung | Google Journal (Backlash trotz lokaler Verarbeitung) | [55] | Zusammenfassungen nur Opt-in, nur lokal, abschaltbar (D8) |
| Gesundheits- oder Therapieversprechen | Marketing vieler Journaling-Apps | Evidenz für Journaling ist real, aber klein (siehe Recherche Innovationslücken) | keine medizinischen Aussagen (Nicht-Ziel in 00) |
| Riesige Modelle als Pflicht, Download blockiert die App | CortexOS (1 bis 2 GB), Dictus-Download-Issues | [27], siehe 01 | kleine Modelle als Standard, große optional und fortsetzbar (D3) |
| Automatisches Update migriert Daten ohne Sicherung | Journiv 0.17 | [7] | Migration nur mit Vorab-Backup und Rollback-Pfad |
| Englisch-only bei "Deutsch" im Marketing, Auto-Spracherkennung ohne Wahl | Apple Journal, Local Journal, Whisper-Auto-Detect | [21][61] | feste Sprachwahl, Deutsch im MVP (D12) |
| Android als nachgereichter, schwächerer Port | Flint (Funktionsgleichheit unklar), DailyVox (unveröffentlicht) | [32], siehe 01 | gleicher Funktionsumfang auf beiden Plattformen als Erfolgskriterium (D1) |
| Funktionsüberladung | lange Wunschlisten in Trackern; "elaborate apps get abandoned" | [43][44] | MVP auf Chancen 1 bis 6 und 8 bis 11 begrenzt |

## 8. Offene Fragen

1. **Nachrecherche mit vollem Netzzugang**: wörtliche Rezensionen (DE/AT/CH) zu Day One, Journey, Diarium, Daylio, Apple Journal, Voice-Diary-Apps in App Store und Google Play; Reddit (r/Journaling, r/privacy, r/de_EDV) und Hacker News zu "voice journal", "local whisper diary" und KI-Ablehnung; deutschsprachige Foren (heise, Kuketz, Android-Hilfe). Ziel: die GitHub-Verzerrung ausgleichen und die Priorisierung in Abschnitt 3 bestätigen oder korrigieren.
2. **Zahlen prüfen**: alle weiterhin als "(unverifiziert)" markierten Werte, insbesondere die Schweizerdeutsch-Wortfehlerraten, die Duolingo-Streak-Zahlen, die 30-Tage-Retention, das Dictus-Modell-Download-Verhalten und die Free-Tier-Limits von CortexOS und EchoVault. Die vorliegende Faktenprüfung [69] umfasst nur technische Aussagen; eine zweite Runde für Markt-, Preis- und Nutzerzahlen steht aus.
3. **Schweizerdeutsch**: Wie transkribiert `SpeechTranscriber` mit `de_CH` tatsächlich Mundart-Audio (eigener Test)? Lizenzlage der Fine-Tunes und Trainingsdaten für kommerzielle Nutzung?
4. **Persönliches Wörterbuch**: Unterstützen SpeechTranscriber und die sherpa-onnx-Modelle Kontext-Begriffe (Hotwords)? Sonst nur als Nachkorrektur umsetzbar.
5. **Hardware-Start**: Lässt sich der iOS-Action-Button ohne Umweg über Shortcuts an die Aufnahme binden? Empfängt eine Android-App Kopfhörertasten zuverlässig, bevor die Aufnahme läuft?
6. **Barrierefreiheit**: Gibt es belastbare Nutzerberichte zu VoiceOver/TalkBack bei Tagebuch-Apps? Die Stichprobe enthielt keine, was eher fehlende Aufmerksamkeit als fehlenden Bedarf anzeigt. Eine Testgruppe mit Screenreader-Nutzern sollte vor dem Release eingeplant werden.
7. **Auto-Stopp bei Stille**: Welche Pausendauer ist für Tagebuchsprecher passend, ohne Nachdenkpausen abzuschneiden? Empfehlung: im Spike mit 5 bis 10 Sekunden testen, Standard eher lang, abschaltbar.

## Quellen

1. Journiv, Issue #253 "Import from Apple Journal" (5. Januar 2026): https://github.com/journiv/journiv-app/issues/253
2. kpod13/journal2day1 (Apple-Journal-Exportstruktur, Dezember 2025): https://github.com/kpod13/journal2day1 ; GitHub-Suche "apple journal export" (3. September 2026): https://github.com/search?q=apple+journal+export&type=repositories
3. jeffd/DayOneToJournal (Audio nicht importiert, Mai 2026): https://github.com/jeffd/DayOneToJournal
4. Journiv, Issue #58 "Import from Daylio" (8. November 2025): https://github.com/journiv/journiv-app/issues/58
5. Journiv, Export-Fehler: https://github.com/journiv/journiv-app/issues/530 ; https://github.com/journiv/journiv-app/issues/109
6. Easy Diary, Issue #252 (25. August 2026): https://github.com/hanjoongcho/aaf-easydiary/issues/252
7. Journiv, Issue #540 Datenverlust nach Update (29. April 2026): https://github.com/journiv/journiv-app/issues/540
8. Fossify Voice Recorder, Issue #56 (16. Juni 2024): https://github.com/FossifyOrg/Voice-Recorder/issues/56
9. Easy Diary, Backup-Wünsche: https://github.com/hanjoongcho/aaf-easydiary/issues/233 ; https://github.com/hanjoongcho/aaf-easydiary/issues/234 ; https://github.com/hanjoongcho/aaf-easydiary/issues/230
10. DailyVox, README: https://github.com/intrepidkarthi/dailyvox
11. Journiv, Issue #186 Klartext-Datenbank: https://github.com/journiv/journiv-app/issues/186 ; Umfrage zur Verschlüsselung: https://github.com/orgs/journiv/discussions/567
12. Fossify Voice Recorder, Issue #62 (Verschlüsselung, wontfix): https://github.com/FossifyOrg/Voice-Recorder/issues/62
13. billthefarmer/Diary, Issues #39, #59, #65: https://github.com/billthefarmer/Diary/issues
14. Kuketz-Blog, "Miserabler Datenschutz bei Tagebuch-Apps": https://www.kuketz-blog.de/android-miserabler-datenschutz-bei-tagebuch-apps/
15. heise, "Sechs Tagebuch-Apps im Test: Digitale Logbücher mit Sicherheitslücken": https://www.heise.de/tests/Sechs-Tagebuch-Apps-im-Test-Digitale-Logbuecher-mit-Sicherheitsluecken-4981737.html
16. Whisper Memos, Datenschutzerklärung: https://whispermemos.com/page/privacy-policy
17. yaps.ai, Voicenotes-Alternativen (Upload-Verluste): https://www.yaps.ai/blog/voicenotes-alternative
18. App Store DE, Day One Rezensionen: https://apps.apple.com/de/app/day-one-t%C3%A4gliches-tagebuch/id1044867788?see-all=reviews&platform=iphone
19. faster-whisper, Issue #601 (2. Dezember 2023): https://github.com/SYSTRAN/faster-whisper/issues/601
20. openai/whisper, Discussion #928 (Halluzinationen Deutsch): https://github.com/openai/whisper/discussions/928
21. whisper.cpp, Issue #1800 (Sprachwechsel): https://github.com/ggml-org/whisper.cpp/issues/1800 ; easyspeak, Issue #153: https://github.com/ctsdownloads/easyspeak/issues/153
22. argmax-oss-swift (WhisperKit), Issue #528 (23. August 2026): https://github.com/argmaxinc/argmax-oss-swift/issues/528
23. Transkribor, Issue #130 Schweizerdeutsch-Modell (12. August 2026): https://github.com/napoleonmm83/Transkribor/issues/130 ; Issue #369: https://github.com/napoleonmm83/Transkribor/issues/369
24. Dolev et al., VarDial 2024: https://aclanthology.org/2024.vardial-1.3/ ; Timmel et al. (FHNW): https://www.alphaxiv.org/abs/2412.15726 ; Flix-AI (Juni 2026): https://arxiv.org/html/2606.07608v1
25. App Store CH, Rezension zu Schweizerdeutsch: https://apps.apple.com/ch/app/sprachmemos-transkription/id6451387537
26. arXiv 2501.11378 (Whisper-Halluzinationen): https://arxiv.org/pdf/2501.11378 ; openai/whisper Discussion #1606: https://github.com/openai/whisper/discussions/1606
27. Dictus, Issues #449 und #428 (Modell-Download): https://github.com/getdictus/dictus-ios/issues/449 ; https://github.com/getdictus/dictus-ios/issues/428
28. whisper.cpp, Issue #1022 (Android-Performance): https://github.com/ggml-org/whisper.cpp/issues/1022
29. WhisperKit, Discussion #437 (Apple Watch, 9. März 2026): https://github.com/argmaxinc/WhisperKit/discussions/437
30. uhabits (Loop Habit Tracker), Issues #2052, #2200, #852: https://github.com/iSoron/uhabits/issues/2052 ; https://github.com/iSoron/uhabits/issues/2200 ; https://github.com/iSoron/uhabits/issues/852
31. Easy Diary, Issue #15 (Alarm im Lautlos-Modus): https://github.com/hanjoongcho/aaf-easydiary/issues/15
32. DailyVox, Issue #4 "Any plans for Android Release?": https://github.com/intrepidkarthi/dailyvox/issues/4
33. Journiv, Discussion #348 Mobile App: https://github.com/orgs/journiv/discussions/348 ; Issue #586: https://github.com/journiv/journiv-app/issues/586
34. Daylogue, "Why Do Journaling Apps Make Me Feel Guilty?": https://daylogue.com/learn/journaling-app-guilt
35. LogRocket, Streaks und Retention: https://blog.logrocket.com/product-management/streaks-user-retention/
36. Finch-Rezension: https://calmevo.com/finch-app-review/
37. Duolingo Streak Freeze (Sekundärquelle): https://duolingo.deconstructoroffun.com/mechanics/streaks
38. 30-Tage-Retention von Mental-Health-Apps (93 Apps): https://www.researchgate.net/figure/App-30-day-retention-by-mental-health-focus-The-percentages-reflect-the-number-of-users_fig2_334562120
39. Journiv, Discussion #425 "Plus"-Tab: https://github.com/orgs/journiv/discussions/425
40. Dictus, Issue #54 Open-Core-Grundsatz: https://github.com/getdictus/dictus-ios/issues/54
41. AudioPen, Nutzerkritik (aichief): https://aichief.com/ai-text-tools/audiopen/
42. ChoosingTherapy, Day One Review (Preiskritik): https://www.choosingtherapy.com/dayone-app-review/
43. Lite Journal, Vergleich: https://litejournal.co/compare/best-journaling-app
44. Easy Diary, Issue #46 (Sammel-Wunschliste): https://github.com/hanjoongcho/aaf-easydiary/issues/46
45. Fossify Voice Recorder, Issue #34 Offline-Spracherkennung: https://github.com/FossifyOrg/Voice-Recorder/issues/34
46. DreamLog (Wake-Word, Auto-Stopp): https://github.com/wivy1/dreamlog
47. Fossify Voice Recorder, Issue #291 Smartwatch, Issue #54 Bluetooth-Mikrofon: https://github.com/FossifyOrg/Voice-Recorder/issues/291 ; https://github.com/FossifyOrg/Voice-Recorder/issues/54
48. Journiv, Issue #88 Wellenform: https://github.com/journiv/journiv-app/issues/88
49. Journiv, Issue #86 kurze Einträge, Issue #420 KI mit Bedingungen: https://github.com/journiv/journiv-app/issues/86 ; https://github.com/journiv/journiv-app/issues/420
50. memex (GPL-3.0): https://github.com/memex-lab/memex
51. Just Press Record, App Store: https://apps.apple.com/us/app/just-press-record/id1033342465
52. Android Central, Google-Recorder-Schnelleinstellungskachel: https://www.androidcentral.com/apps-software/google-recorder-android-quick-settings
53. MindScape-Studie (CMU): https://pmc.ncbi.nlm.nih.gov/articles/PMC11275533/
54. Day One, "On This Day": https://dayoneapp.com/features/on-this-day/
55. techbuzz.ai, Google Journal KI-Backlash: https://www.techbuzz.ai/articles/google-journal-ai-features-spark-privacy-backlash
56. EU AI Act, Art. 50: https://artificialintelligenceact.eu/article/50/ ; FPF zu Art. 5(1)(f): https://fpf.org/blog/red-lines-under-eu-ai-act-unpacking-the-prohibition-of-emotion-recognition-in-the-workplace-and-education-institutions/
57. Verbraucherzentrale, Digitaler Nachlass: https://www.verbraucherzentrale.de/wissen/digitale-welt/datenschutz/digitale-vorsorge-digitaler-nachlass-was-passiert-mit-meinen-daten-12002
58. Sprachdiktat und Legasthenie/Barrierefreiheit: https://weesperneonflow.ai/en/blog/2025-10-19-voice-dictation-accessibility-dyslexia-disabilities-guide/
59. uhabits, Barrierefreiheits-Issues #665, #666, #2170: https://github.com/iSoron/uhabits/issues/665 ; https://github.com/iSoron/uhabits/issues/2170
60. Apple Community, "Couldn't Transcribe Audio" in Journal: https://discussions.apple.com/thread/255916391
61. Apple Support, Journal auf dem iPhone (Transkription nur Englisch): https://support.apple.com/en-kz/guide/iphone/iph492ee70a8/ios
62. CortexOS, FAQ (Free-Tier): https://cortexos.app/faq/
63. EchoVault, Google Play: https://play.google.com/store/apps/details?id=com.echovault.app&hl=en_US
64. Kiddays: https://kiddays.app/ ; Fenwick zu COPPA und Kinderstimmen: https://www.fenwick.com/insights/publications/ftcs-new-coppa-guidance-on-recording-childrens-voices-five-tips-for-app-developers-and-toymakers-to-comply
65. FutureMe kostenpflichtig: https://www.openwhenitstime.com/blog/is-futureme-free
66. AppleVis, Diktat und Voice Control: https://www.applevis.com/forum/ios-ipados/dictation-needs-massive-improvements
67. dontkillmyapp (Herstellerhinweise Akku-Optimierung): https://github.com/urbandroid-team/dont-kill-my-app
68. JMIR Formative Research 2025, EMA-Compliance: https://formative.jmir.org/2025/1/e66187
69. Faktenprüfung der Rechercheberichte (30 technische Aussagen, Stand 3. September 2026): `docs/recherche/verifikation.json` in diesem Repository
70. Apple Developer Forums, Thread 797835 (Apple bestätigt fälschliche Listung von Arabisch in `SpeechTranscriber.supportedLocales`, Januar 2026): https://developer.apple.com/forums/thread/797835
71. sherpa-onnx, Issue #2626 "Parakeet 0.6B Int8 model consuming 1.2GB RAM" (24. September 2025): https://github.com/k2-fsa/sherpa-onnx/issues/2626
