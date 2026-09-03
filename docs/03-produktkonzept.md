# 03 · Produktkonzept

Stand: 3. September 2026 · Status: Entwurf

Dieses Dokument beschreibt, was die App aus Sicht der Nutzerin tut: das Kernerlebnis, den täglichen Ablauf, die Bildschirme, die Erinnerungslogik, die Anzeige und Korrektur des Transkripts, Suche und Rückblicke, den Funktionsumfang in drei Stufen, Barrierefreiheit und die bewussten Auslassungen. Es setzt `00-anforderungen.md` (M1 bis M12, A1 bis A8) und die verbindlichen Entscheidungen D1 bis D15 um. Technische Umsetzung steht in `04-technik-architektur.md`, Schutzkonzept in `05-sicherheit-und-datenschutz.md`, Gerätewechsel und Backup in `06-geraetewechsel-qr-transfer.md`, Preise ausschließlich in `07-geschaeftsmodell.md`. Der Name ist noch offen (D11); hier heißt es "die App".

## 1. Kernerlebnis

Am Abend meldet sich die App zu der Uhrzeit, die man selbst gewählt hat. Ein Tipp, und man spricht drei Minuten über den Tag; ein zweiter Tipp beendet die Aufnahme. Wenige Sekunden später steht der Text unter der Aufnahme, erzeugt auf dem Gerät, ohne dass ein Wort das Telefon verlassen hat. Wochen oder Jahre später hört man die eigene Stimme von damals und liest mit. Es gibt kein Konto, keinen Server, keine Zähler, die einen mahnen, und nichts, was man richtig oder falsch machen kann. Das Tagebuch gehört der Person, die es spricht: verschlüsselt auf ihrem Gerät, jederzeit als offene Datei exportierbar, und auf ein neues Gerät nur dann übertragen, wenn sie es ausdrücklich anstößt.

## 2. Der tägliche Ablauf

### 2.1 Erinnerung, ein Tipp, sprechen, fertig

1. Um die gewählte Uhrzeit erscheint eine Benachrichtigung ohne Inhalt: "Zeit für deinen Eintrag" mit den Aktionen "Aufnehmen", "In 1 Stunde", "Heute nicht" (D7). Benachrichtigungen enthalten nie Tagebuchtext (D5).
2. "Aufnehmen" öffnet die App direkt im Aufnahmebildschirm; die Aufnahme läuft sofort. Wer die App stattdessen selbst öffnet, sieht auf dem Startbildschirm eine große Aufnahmetaste: ein Tipp, und es läuft (Erfolgskriterium aus `00-anforderungen.md`, Abschnitt 5).
3. Während der Aufnahme zeigt der Bildschirm nur Zeit, Pegel und eine Stopptaste. Eine Live-Vorschau des Texts ist möglich (iOS-Preset `.progressiveTranscription`, D2), aber standardmäßig aus: Sie lenkt vom Sprechen ab und verleitet zum Korrigieren statt Erzählen.
4. Ein Tipp auf "Fertig". Die App verschlüsselt das Audio bereits während der Aufnahme (D4), startet die Transkription und kehrt zum Startbildschirm zurück. Der Eintrag erscheint dort mit dem Hinweis "Text wird erstellt", typischerweise nach wenigen Sekunden mit dem fertigen Transkript. Man muss nicht warten.
5. Wer später am Tag noch etwas ergänzen will, tippt erneut auf Aufnehmen; die Ergänzung gehört zum selben Tageseintrag (A4). Nachträge für vergangene Tage sind erlaubt (A3, D7).

Bewusst weggelassen: Titel, Stimmung, Tags, Fotos oder Fragen vor der Aufnahme. Die leere Seite ist die größte Hürde beim Tagebuchschreiben [4]; die App ersetzt sie durch eine einzige Taste. Wettbewerber, die Einträge kurz halten, tun das aus demselben Grund: DailyVox begrenzt bewusst auf 42 Sekunden [3].

### 2.2 Wiedergabe

Ein Eintrag zeigt Datum, Wochentag, Dauer und Sprache. Darunter der Player mit Fortschrittsbalken, darunter der Text. Tippt man auf ein Wort, springt die Wiedergabe an diese Stelle; läuft die Wiedergabe, wird der gesprochene Abschnitt im Text mitgeführt. Auf iOS liefert `SpeechTranscriber` dafür Zeitbereiche je Ergebnis [27]; auf Android hängt die Granularität vom Modell ab (siehe offene Fragen). Wiedergabe funktioniert mit Bildschirm aus und über Kopfhörer; die Bedienung über Sperrbildschirm zeigt nur "Tagebuch, 3. September", keinen Text.

### 2.3 Rückblick

Der Startbildschirm zeigt eine Karte "Vor einem Jahr", wenn es an diesem Datum einen Eintrag gibt (analog "vor zwei Jahren" usw.). Day-One-Nutzer beschreiben diese Funktion als "a constant source of joy" [36]; sie ist mit lokalen Daten trivial und braucht keine KI. Der Kalender zeigt Monate als leise Übersicht: Tage mit Eintrag sind markiert, ohne Zähler, ohne Kette, ohne "verpasst". Monatsweise gibt es drei Zahlen: Tage mit Eintrag, gesprochene Minuten, Wörter (D8).

## 3. Bildschirmstruktur

Die App hat fünf Bildschirme; das Onboarding ist ein einmaliger Ablauf und zählt nicht dazu.

| Bildschirm | Inhalt | Warum so |
|---|---|---|
| **Heute** (Start) | Große Aufnahmetaste; darunter der heutige Eintrag (falls vorhanden) mit Play und Textanfang; Karte "Vor einem Jahr"; dezenter Zugang zu Kalender und Einstellungen. Zustand statt Mahnung: "Heute noch nichts aufgenommen" ist neutral formuliert. | Ein Tipp bis zur Aufnahme; kein Zähler, keine Schuld [5][6]. |
| **Aufnahme** | Vollbild: Zeit, Pegel, Pause, Fertig, Abbrechen (mit Rückfrage). Optional Live-Text (Einstellung). Bei Unterbrechung durch Anruf wird pausiert und danach weitergemacht; nichts geht verloren. | Aufnahme muss robust sein; Datenverlust bei Aufnahme-Apps ist ein häufiger Beschwerdegrund [47]. |
| **Eintrag** | Datum, Dauer, Sprach-Badge (de-DE/de-AT/de-CH/en); Player; Transkript mit Tipp-zum-Springen; "Ergänzen" (weitere Aufnahme); Text bearbeiten; Sprache ändern und neu transkribieren; Audio dieses Eintrags löschen; Eintrag löschen; Eintrag exportieren. | Audio und Text gleichwertig (M5, A5); Korrektur in der Hand der Nutzerin. |
| **Kalender und Suche** | Monatsraster mit markierten Tagen; Liste nach Datum; Suchfeld mit Filtern (Zeitraum, Sprache, nur mit Audio). Monatszahlen: Tage, Minuten, Wörter. | Volltextsuche ist bei Sprachnotiz-Apps der meistgewünschte Zusatz [FossifyOrg #34, siehe `01-markt-und-wettbewerb.md`]; Heatmap statt Streak [5]. |
| **Einstellungen** | Erinnerung (Uhrzeit, Pause bis Datum, Zuverlässigkeit); Sprache der Transkription; Genauigkeitspaket (Plus); App-Sperre und Zeit bis zur Sperre; Audio behalten (global); Speicherverbrauch; Backup und Gerätewechsel; Export; "Was verlässt dein Gerät: nichts" (Transparenzseite mit Berechtigungsliste); Barrierefreiheit; Rechtliches und Impressum; Plus. | Alles Seltene an einem Ort; die Transparenzseite macht das Kernversprechen prüfbar (D14). |

Onboarding, einmalig und in dieser Reihenfolge: (1) Gerätecode prüfen, weil der Schlüssel daran gebunden ist (D5); (2) Mikrofon; (3) Sprache wählen, Hinweis, dass Hochdeutsch die zuverlässigsten Ergebnisse liefert (D12); (4) Modell laden, auf iOS durch das System [55], auf Android per Play Asset Delivery (D3), mit Größe und WLAN-Hinweis, weil abgebrochene Modell-Downloads Nutzer aussperren können [54]; (5) Erinnerungszeit; (6) auf Android "Erinnerungen zuverlässig machen" mit Herstellerhinweisen (D7); (7) Backup-Erklärung: Betriebssystem-Backups stellen das Tagebuch nicht wieder her, die App erinnert monatlich an eine Backup-Datei (D6). Jeder Schritt ist überspringbar, außer (1) und (2).

## 4. Erinnerungslogik

Die Erinnerung ist der wichtigste Hebel der App: Bei Apps rund um mentale Gesundheit liegt die mediane 30-Tage-Retention auf Android bei 3,3 % [49] (Sekundärquelle, unverifiziert); alles, was das Ritual reibungsärmer macht, zahlt darauf ein.

**Feste Zeit, änderbar.** Eine Erinnerung pro Tag zu einer Uhrzeit, die im Onboarding gesetzt und jederzeit in den Einstellungen geändert wird (M2, D7). Vorschlag im Onboarding: 21:00 Uhr. Abend-Check-ins erhielten in einer kleinen Studie mit 20 Teilnehmenden das beste Feedback-Verhältnis [8] (aus Sekundärquelle rekonstruiert, unverifiziert); wichtiger ist, dass die Nutzerin selbst wählt.

**Aktionen in der Benachrichtigung.** "Aufnehmen" startet sofort. "In 1 Stunde" verschiebt einmalig. "Heute nicht" schließt ohne Nachfrage und ohne Kommentar. Kein "Du hast gestern verpasst": Vorwurfs-Benachrichtigungen und Reset-Zähler führen nachweislich zu Abbruch statt Gewohnheit [5][6]; sogar Duolingo musste mit Streak Freeze gegen die eigene Mechanik nachrüsten [7] (Zahlen daraus unverifiziert).

**Verhalten beim Verpassen.**

1. Wird die Erinnerung ignoriert, passiert nichts weiter; am nächsten Tag kommt sie wie immer.
2. Öffnet man die App am Folgetag, bietet der Startbildschirm neben "Heute" unaufdringlich "Für gestern nachtragen" an (A3). Nachträge sind im Kalender als solche gekennzeichnet (Aufnahmedatum ungleich Eintragsdatum).
3. War das Gerät zur Erinnerungszeit ausgeschaltet, gilt: Android plant die Erinnerung nach `BOOT_COMPLETED` neu; liegt die Uhrzeit weniger als zwei Stunden zurück, wird sie einmalig nachgeliefert, sonst verfällt sie für diesen Tag (eigene Festlegung, im Nutzertest prüfen). Hintergrund: Gewohnheits-Apps, die nach Neustart nicht nachholen, ernten Beschwerden [10], zu spätes Nachholen (z. B. morgens um 3 Uhr) wäre aber schlimmer. iOS liefert wiederholende Kalender-Trigger selbst aus [13]; dort ist keine eigene Logik nötig.
4. Kein Streak, keine Kette, kein Fortschrittsbalken. Der Kalender zeigt nur, was da ist.

**Ruhezeiten.** In den Einstellungen lässt sich die Erinnerung "pausieren bis" einem Datum (Urlaub, Krankheit) oder auf bestimmte Wochentage beschränken. Die App respektiert Fokus-Modi und "Nicht stören": Die Benachrichtigung ist standardmäßig normal priorisiert; Time-Sensitive (iOS) ist eine Nutzerwahl und wird erklärt [14] (D7). Auf Android nutzt die App `setAlarmClock()` und fragt `SCHEDULE_EXACT_ALARM` an; bei Ablehnung fällt sie transparent auf ein Fenster von ±10 Minuten zurück und zeigt das in den Einstellungen [11] (D7). Ein Hinweis "Erinnerungen zuverlässig machen" mit Deep-Links in die Herstellereinstellungen ist nötig, weil etwa Samsung nach drei Tagen ohne Nutzung Hintergrundstarts blockiert [12] und Erinnerungen auf Android sonst verspätet oder gar nicht kommen [9].

**Ausbaustufe 1.x: Vorschlag statt Automatik.** Weichen die tatsächlichen Aufnahmezeiten über zwei Wochen deutlich von der Erinnerungszeit ab (Median der letzten 14 Aufnahmen mehr als 45 Minuten entfernt; eigene Heuristik), schlägt die App einmalig vor, die Uhrzeit anzupassen. Sie ändert nichts von selbst. Adaptive Zeitsteuerung erhöht die Nutzung nicht automatisch [8], aber ein Vorschlag kostet nichts.

## 5. Aufnahme ohne Bildschirm (spätere Ausbaustufen)

Im MVP gibt es zwei Einstiege: die Aufnahmetaste auf "Heute" und die Aktion in der Benachrichtigung. Alles Weitere folgt, sortiert nach Nutzen und Aufwand.

| Stufe | Einstieg | Plattform | Was zu beachten ist |
|---|---|---|---|
| 1.x | Control auf Sperrbildschirm, im Kontrollzentrum und auf dem Action Button | iOS | Ein `AudioRecordingIntent` muss eine Live Activity starten, sonst stoppt iOS die Aufnahme [15][16]. Die Live Activity zeigt Timer und Stopp, auch auf der Watch im Smart Stack [17]. Controls funktionieren bei gesperrtem Gerät; der Eintrag wird verschlüsselt geschrieben, lesen kann man ihn erst nach Entsperren. |
| 1.x | Home-Screen-Widget "Aufnehmen" und Sperrbildschirm-Widget | iOS | Widgets zeigen nur Zustand ("heute noch nicht aufgenommen"), nie Text (D5) [18]. |
| 1.x | Widget, Schnelleinstellungs-Kachel, App-Shortcut | Android | Start aus Widget oder Benachrichtigung ist von der Beschränkung für Vordergrunddienste im Hintergrund ausgenommen; die Kachel öffnet eine transparente Activity, die den Mikrofon-Dienst startet [19][20]. |
| 1.x | Siri-Kurzbefehl / App-Intent "Tagebuch aufnehmen" | iOS | Nur Start und Stopp; kein Inhalt an Siri. |
| später | Apple Watch als Mikrofon | watchOS | Aufnahme per `AVAudioRecorder` ist möglich [22], Transkription auf der Watch nicht: `SpeechTranscriber` und `DictationTranscriber` existieren dort nicht [21]; WhisperKit tiny.en braucht auf einer Series 11 rund 19 s zum Laden [26] (Community-Benchmark, unverifiziert). Die Watch nimmt also auf, überträgt die Datei per `WCSession.transferFile` [24], das iPhone transkribiert. Längere Aufnahmen brauchen eine Extended-Runtime-Session [23]. |
| später | Wear OS als Mikrofon | Android | Data-Layer-`Asset` ist ausdrücklich für Sprachaufnahmen von einem anderen Gerät gedacht [25]; gleiche Arbeitsteilung wie bei der Watch. |
| nicht geplant | Wake-Word ("Hey Tagebuch") | beide | Ein dauerhaft lauschendes Mikrofon widerspricht dem Vertrauensversprechen, kostet Akku und ist auf iOS für Drittanbieter nicht vorgesehen. DreamLog zeigt, dass es auf Android geht [52]; für diese App ist es der falsche Kompromiss. |

Empfehlung: Controls/Action Button und Android-Widget als erstes 1.x-Thema, weil sie das Ritual auf eine Geste verkürzen und in der Kategorie Tagebuch selten sind (Wettbewerbsbefund in `01-markt-und-wettbewerb.md`). Uhren erst nach einem Prototyp, weil die Übertragung asynchron ist und im Simulator nicht getestet werden kann [24].

## 6. Transkript: Anzeige und Korrektur

**Grundsatz: Das Audio ist die Wahrheit, der Text ist eine Hilfe.** Das Transkript ist Suchindex und Lesehilfe; es ersetzt die Aufnahme nicht. Deshalb wird Audio standardmäßig behalten (A5, D4).

**Anzeige.**
- Der Text steht als Fließtext in Absätzen, die aus Sprechpausen gebildet werden. Wortweise Zeitmarken (iOS) erlauben Tipp-zum-Springen [27].
- Ein Sprach-Badge zeigt, mit welcher Locale transkribiert wurde. Die Sprache wird nicht automatisch erkannt, sondern ist eine Einstellung, änderbar pro Eintrag: Automatische Spracherkennung führt bei deutsch-englischen Mischsätzen zu Sprachwechseln oder Übersetzungen statt Transkription (whisper.cpp #1800, easyspeak #153, siehe `01-markt-und-wettbewerb.md` und Recherche Nutzerfeedback).
- Wörter mit niedriger Konfidenz werden dezent unterlegt (iOS liefert Konfidenzwerte je Ergebnis [27]; Android: offene Frage). Kein rotes Markieren, kein "Fehlerzähler".
- Solange der Text noch erstellt wird, steht "Text wird erstellt"; schlägt die Transkription fehl, bleibt die Aufnahme erhalten und lässt sich später erneut transkribieren. Verschwindende Transkripte sind eine dokumentierte Schwäche von Apple Journal (Apple Community, siehe `01-markt-und-wettbewerb.md`).

**Qualitätsmaßnahmen, die die Nutzerin nicht sieht.**
- Sprachaktivitätserkennung vor der Transkription (iOS `SpeechDetector` [34]; Android VAD-Chunking, D2/D3). Ohne sie erzeugen Whisper-artige Modelle bei Stille Phantomtexte wie "Untertitel im Auftrag des ZDF" [32].
- Nachbearbeitung für Groß-/Kleinschreibung und Interpunktion, falls das Modell sie nicht liefert; deutsche Kleinschreibung durchgehend ist ein bekanntes Ärgernis [33].
- de-CH bedeutet Schweizer Standarddeutsch (Orthografie ohne ß), nicht Mundart; Apple veröffentlicht keine feste Liste, `supportedLocales` ist die Wahrheit [28][29]. Die App sagt das im Onboarding und beim Sprach-Badge offen (D12). Mundart-Modelle existieren nur als nicht-kommerzielle Fine-Tunes [53]; siehe Abschnitt 8, "später".

**Korrektur.**
- Text bearbeiten: einfacher Editor, Änderungen werden als "bearbeitet" gekennzeichnet; das Original-Transkript bleibt intern erhalten und lässt sich wiederherstellen. Audio wird nie verändert.
- Neu transkribieren: mit anderer Sprache oder, wenn vorhanden, mit dem Genauigkeitspaket (D2/D3). Läuft im Hintergrund, ersetzt den Text erst nach Bestätigung, wenn er bereits bearbeitet wurde.
- Persönliches Wörterbuch (1.x): Namen und Orte, die als Kontext an die Erkennung gehen. Auf iOS ist `AnalysisContext.contextualStrings` für `DictationTranscriber` dokumentiert, die Wirkung bei `SpeechTranscriber` unklar (Recherche iOS); auf Android ist Hotword-Unterstützung modellabhängig. Deshalb 1.x mit Spike.
- Korrektur per Sprache (1.x): "Ersetze Meier durch Maier" nach der Aufnahme, lokal per Mustervergleich. Vorbild sind die Systemfunktionen Voice Control und Voice Access, deren Qualität Nutzer als begrenzt beschreiben [35]; deshalb kein MVP-Thema.

## 7. Suche und Rückblicke, nur lokal

- **Volltextsuche** über alle Transkripte mit SQLite FTS5 in der verschlüsselten Datenbank (D4, D8). Treffer zeigen Datum, Textausschnitt und springen beim Öffnen an die Stelle im Audio. Filter: Zeitraum, Sprache, nur Einträge mit Audio, nur bearbeitete Texte.
- **Kalender** als Monatsraster; Tage mit Eintrag markiert, Intensität nach Dauer, ohne Zahlen im Raster.
- **Rückblicke im MVP** (D8): "Vor einem Jahr" auf dem Startbildschirm; Monatszahlen (Tage, Minuten, Wörter); "Zufälliger Eintrag" als Taste im Kalender. Alles ohne generative KI, alles auf dem Gerät.
- **Version 1.x, Plus, Opt-in** (D8, D9): Tageszusammenfassung in zwei bis drei Sätzen und ein Wochenrückblick mit Apple Foundation Models, nur auf Apple-Intelligence-Geräten; Ablehnungen des Modells (Guardrails bei Trauer, Krankheit) werden still abgefangen, der Eintrag bleibt ohne Zusammenfassung [38]. Auf Android gibt es dafür vorerst keine Lösung: Gemini Nano fasst nicht auf Deutsch zusammen und läuft nur auf Flaggschiffen (D8). Die Funktion ist abschaltbar und erklärt, was sie tut. Selbst lokale KI-Funktionen lösten bei Google Journal Kritik aus [37] (Sekundärquelle); daher niemals Standard.
- **Später:** semantische Suche mit lokalen Einbettungen ("wann war ich zuletzt so wütend?") und ein gestalteter Jahresrückblick. Beides erst, wenn die Basisnutzung steht.

Was Suche und Rückblicke nicht tun: Stimmungen aus der Stimme ableiten, Trends bewerten, Warnungen geben (Abschnitt 10).

## 8. Feature-Liste in drei Stufen

Kostenlos/Plus folgt D9; Preise stehen nur in `07-geschaeftsmodell.md`. Die kostenlosen Funktionen werden nie kostenpflichtig; das steht im Store-Text (D9).

### 8.1 MVP

| Funktion | Begründung | Kostenlos/Plus |
|---|---|---|
| Aufnahme mit einem Tipp, Pause, Fertig; robust bei Anruf und Sperre | M1, M3; Datenverlust bei Aufnahme ist der schlimmste Fehler [47] | kostenlos |
| Aufnahmen bis 5 Minuten je Eintrag | Kurze Einträge senken die Hürde; Grenze nach D9 | kostenlos |
| Lokale Transkription Deutsch (de-DE/de-AT/de-CH) und Englisch, feste Sprachwahl; iOS 26 ab iPhone 12 empfohlen, Android 12 ab 4 GB RAM (D13) | M4, M6, A1, D2, D3, D12; Apple Journal transkribiert nur Englisch [1], Day One nur bis 10 Minuten und bis iOS 26 nur online [2]; iPhone 11 und SE 2 bieten `SpeechTranscriber` nicht, dort greift der Fallback [30] | kostenlos |
| Wiedergabe mit Tipp-zum-Springen, Text lesen | M5, A5 | kostenlos |
| Text bearbeiten, Original wiederherstellbar; neu transkribieren | Korrektur ohne Datenverlust | kostenlos |
| Tägliche Erinnerung mit "In 1 Stunde", "Heute nicht", Pause bis Datum, Wochentage | M2, D7; kein Streak-Druck [5][6] | kostenlos |
| Aufnahme direkt aus der Benachrichtigung | Ein Tipp vom Signal zur Aufnahme (D7) | kostenlos |
| Mehrere Aufnahmen pro Tag, Nachträge für vergangene Tage | A3, A4 | kostenlos |
| Volltextsuche, Kalender, "Vor einem Jahr", Monatszahlen | D8; "On This Day" ist die beliebteste Rückblickfunktion des Marktführers [36] | kostenlos |
| Verschlüsselung, App-Sperre per Biometrie/Gerätecode (Standard 30 s, einstellbar bis 5 Minuten), Privacy-Overlay | M7, D5; Verschlüsselung ist bei Tagebuch-Apps die meistgefragte Eigenschaft (Recherche Nutzerfeedback) | kostenlos |
| Audio behalten oder löschen, pro Eintrag und global; Speicheranzeige | A5, D4; Rechenbasis: 3 Minuten täglich ergeben bei Opus 16 kbit/s rund 131 MB pro Jahr (D6) | kostenlos |
| Verschlüsseltes Backup als Datei mit Passphrase, monatliche Erinnerung | A8, D6; kaputte Backups sind ein Top-Beschwerdegrund (Recherche Nutzerfeedback) | kostenlos |
| Gerätewechsel per QR-Code und Datei, iOS und Android in beide Richtungen | M8, D6; kein Wettbewerber bietet das serverlos (`01-markt-und-wettbewerb.md`) | kostenlos |
| Export: Markdown, JSON, PDF, Audio als Opus; Zeitraum wählbar | Lock-in ist der Hauptvorwurf gegen Apple Journal, das nur HTML exportiert [46]; Export vor dem ersten Eintrag beweisbar | kostenlos |
| Transparenzseite "Was verlässt dein Gerät: nichts" mit Berechtigungsliste; Android ohne INTERNET-Berechtigung | D14; Nachweis im Flugmodus | kostenlos |
| Onboarding mit Gerätecode-Prüfung, Modell-Download, Erinnerungs-Zuverlässigkeit | D3, D5, D7 | kostenlos |
| Barrierefreiheit: VoiceOver/TalkBack, Schriftskalierung, Kontrast, Reduce Motion | Abschnitt 9 | kostenlos |

### 8.2 Version 1.x

| Funktion | Begründung | Kostenlos/Plus |
|---|---|---|
| Controls, Action Button, Widgets (iOS); Widget, Schnelleinstellungs-Kachel, App-Shortcut (Android); Siri-Kurzbefehl | Abschnitt 5; Ritual auf eine Geste verkürzen | Aufnahmestart kostenlos; gestaltete Widgets Plus (D9) |
| Aufnahmen bis 30 Minuten | Für ausführliche Tage; Free/Plus-Schnitt nach D9 | Plus |
| Genauigkeitspaket "Hohe Genauigkeit" (iOS WhisperKit large-v3-turbo 626 MB; Android Parakeet TDT 0.6B v3 int8 ≈ 640 MB, ab 6 GB RAM) | D2, D3, D13; Deutsch-WER ≈ 4 % statt 7,5 % beim Standardmodell [31] (Leaderboard-Zahlen, unverifiziert) | Plus |
| Tageszusammenfassung und Wochenrückblick (Apple Foundation Models, Opt-in) | D8, D9; Android später | Plus |
| Mehrere Tagebücher (z. B. "Arbeit", "Briefe an mein Kind") | D9; rein lokal entfällt die Server-Problematik bei Kinderdaten (Recherche Innovationslücken) | Plus |
| Persönliches Wörterbuch für die Erkennung | Abschnitt 6 | kostenlos |
| Korrektur per Sprache | Abschnitt 6 | kostenlos |
| Erinnerungs-Vorschlag aus tatsächlichen Aufnahmezeiten | Abschnitt 4 | kostenlos |
| Frage des Tages: kuratierte, neutrale Reflexionsfragen, lokal vorgelesen, abschaltbar | Hilft gegen die leere Seite [4]; neutrale Fragen halten Altersfreigabe 4+, Wellness-Tipps würden 9+ auslösen [43] | kostenlos |
| Export für Behandelnde: Zeitraum, nur Text, PDF | Bewusste Übergabe durch die Nutzerin, kein Medizinprodukt-Anspruch | kostenlos (Export bleibt frei) |
| Live-Text während der Aufnahme als Option | D2; standardmäßig aus | kostenlos |
| Direkte Übertragung im selben WLAN (LocalSend-Muster) | D6; dann bewusst mit INTERNET-Berechtigung | kostenlos |
| Texteintrag ohne Aufnahme (Barrierefreiheit, laute Umgebung) | Abschnitt 9 | kostenlos |
| Journaling Suggestions (iOS): Fotos, Orte, Trainings als Aufhänger, nur nach Nutzerwahl im System-Picker | Die App erhält Daten erst nach ausdrücklicher Auswahl [51] | kostenlos |

### 8.3 Später

| Funktion | Begründung | Kostenlos/Plus |
|---|---|---|
| Apple Watch und Wear OS als Mikrofon | Abschnitt 5; asynchroner Transfer, Prototyp nötig | kostenlos |
| Mundart-Paket Schweizerdeutsch, Ausgabe Hochdeutsch, klar als Beta | Stärkste Differenzierung für die Schweiz; Lizenz der Fine-Tunes (CC-BY-NC) und Größe ungeklärt [53] | Plus (D9: weitere Sprachen) |
| Weitere Sprachen (fr, it, es, …) | Folgen der Verfügbarkeit lokaler Modelle (A7) | Plus |
| Gestaltetes Jahrbuch-PDF | D9; Druck durch Dritte nur außerhalb der App | Plus |
| Semantische Suche mit lokalen Einbettungen | Abschnitt 7 | Plus |
| Zusammenfassungen auf Android mit kleinem eigenem Modell | D8 | Plus |
| Zeitkapsel: Eintrag mit Öffnungsdatum | Kleines, beliebtes Format; lokal trivial | kostenlos |
| Offline-Nachlass: Notfallblatt mit geteiltem Schlüssel für eine Vertrauensperson | Echte Lücke ohne Server; braucht sorgfältige Krypto-UX | kostenlos |
| Themes, App-Icons | Geringe Zahlungsbereitschaft, gute Beigabe (D9) | Plus |
| Zweiter App-Code unabhängig vom Gerätecode | Offene Frage aus `05-sicherheit-und-datenschutz.md` | kostenlos |

## 9. Barrierefreiheit

Ein Sprach-Tagebuch ist für Menschen mit Legasthenie, motorischen Einschränkungen oder Sehbehinderung von sich aus attraktiv: Sprechen umgeht Rechtschreibung und Tastatur, und es geht schneller als Tippen [42] (Sekundärquelle, Zahlen unverifiziert). Dieser Vorteil verfällt, wenn die Oberfläche drumherum nicht bedienbar ist. Rechtlich ist ein Kleinstunternehmen vom BFSG ausgenommen [41] (aktuelle Fassung unverifiziert); die App hält die Anforderungen trotzdem ein, weil Apple die Accessibility Nutrition Labels schrittweise zur Pflicht macht [40] und weil es zur Zielgruppe gehört.

Verbindlich ab MVP:

1. Jedes Bedienelement hat ein Label für VoiceOver und TalkBack; die Aufnahmetaste meldet ihren Zustand ("Aufnahme läuft, 1 Minute 20"). Flutter bildet Semantik auf beide Screenreader ab [39].
2. Start und Stopp der Aufnahme werden haptisch und mit einem kurzen Ton bestätigt, damit man ohne Blick auf den Bildschirm weiß, was passiert. Der Ton ist abschaltbar.
3. Schriftgrößen folgen der Systemeinstellung (Dynamic Type, Android-Schriftskalierung) bis 200 % ohne abgeschnittene Texte; Kontrast mindestens 4,5:1; Touch-Ziele mindestens 48 × 48 dp, die Aufnahmetaste deutlich größer [39].
4. "Reduce Motion" schaltet Pegel-Animationen auf eine statische Anzeige um; Gewohnheits-Apps, die das ignorieren, erhalten dafür Fehlerberichte [48].
5. Farbe ist nie der einzige Informationsträger (Kalender-Markierungen zusätzlich mit Form oder Text).
6. Vollständige Bedienbarkeit per Tastatur und Switch Control sowie per Voice Control / Voice Access, insbesondere Aufnahme starten und beenden.
7. Das Transkript ist zugleich Untertitel für gehörlose und schwerhörige Nutzer; Vorlesen des Transkripts mit lokaler Sprachausgabe folgt in 1.x, ebenso ein Texteintrag ohne Aufnahme für Menschen, die nicht sprechen können oder wollen.
8. Links- und Rechtshänder: Die wichtigsten Tasten liegen im unteren Drittel und lassen sich spiegeln.

Barrierefreiheit wird im Testplan (`04-technik-architektur.md`, Abschnitt 11) mit Screenreader-Durchläufen auf beiden Plattformen geprüft.

## 10. Was die App bewusst nicht tut

- **Kein Cloud-Sync, kein Konto, keine Server**, auch nicht optional (Nicht-Ziele in `00-anforderungen.md`). Der Gerätewechsel ist ein bewusster, einmaliger Akt, kein Live-Abgleich; die App sagt das offen.
- **Keine Stimmungserkennung aus der Stimme und keine Bewertung von Trends.** Die Evidenz ist unreif, die Regulierung heikel (AI Act, Emotionserkennungssysteme mit Transparenzpflicht [45], unverifiziert) und eine bewertende App wäre ein Medizinprodukt-Kandidat, während reine Speicherung, Archivierung und einfache Suche es nicht sind [44] (unverifiziert). Erlaubt bleibt eine freiwillige Selbsteinschätzung durch die Nutzerin; das ist frühestens ein 1.x-Thema.
- **Keine medizinischen Aussagen.** Abgrenzungssatz aus `05-sicherheit-und-datenschutz.md`: Die App ist ein persönliches Tagebuch und kein Medizinprodukt.
- **Keine Streaks, keine Abzeichen, keine Vorwurfs-Benachrichtigungen** [5][6].
- **Keine KI als Standard.** Zusammenfassungen sind Opt-in, erklärt, abschaltbar und nur lokal (D8).
- **Keine Werbung, keine Analytik, keine Crash-Reporter mit Upload, kein Drittanbieter-SDK mit Netzwerkzugriff** (A6, D14). Auf Android fordert die App keine INTERNET-Berechtigung an (D3).
- **Kein Wake-Word, kein dauerhaft aktives Mikrofon** (Abschnitt 5).
- **Keine Fotos, Videos, Zeichnungen, Tags oder Stimmungs-Emojis im MVP.** Jede zusätzliche Eingabe vor oder nach der Aufnahme verlängert das Ritual; überfrachtete Tagebuch-Apps werden aufgegeben, einfache benutzt [50] (Sekundärquelle). Fotos sind ein Kandidat für später, nicht für jetzt.
- **Kein Tagebuchinhalt in Benachrichtigungen, Widgets oder auf der Sperrbildschirm-Wiedergabe** (D5).
- **Kein Versprechen für Schweizerdeutsche Mundart** (D12), keine Transkription auf der Uhr [21], kein Betrieb, der nie eine Netzverbindung braucht: Der einmalige Modell-Download durch das Betriebssystem bzw. den Play Store ist unvermeidlich und wird erklärt (D14).
- **Kein Teilen in Netzwerke, keine Sozialfunktionen.** Export geht in Dateien, die die Nutzerin selbst weitergibt.

## 11. Offene Fragen

1. **Aufnahme bei gesperrter App.** Damit Controls und Widgets ohne Entsperren aufnehmen können, müssen neue Eintragsschlüssel ohne Zugriff auf den Master-Key gewrappt werden (z. B. asymmetrisch). Ob D5 das hergibt oder ob der Start eine Authentifizierung verlangt, klärt ein Spike im Technikkonzept.
2. **Zeitmarken und Konfidenz auf Android.** Liefern Moonshine Streaming und Parakeet über sherpa-onnx wort- oder nur segmentweise Zeitmarken und Konfidenzen? Davon hängt Tipp-zum-Springen und die Unterlegung unsicherer Wörter ab.
3. **5-Minuten-Grenze bei mehreren Aufnahmen pro Tag.** D9 formuliert "je Eintrag"; ob das je Aufnahme oder als Tagessumme gilt, entscheidet `07-geschaeftsmodell.md`. Empfehlung: je Aufnahme, weil Ergänzungen (A4) sonst bestraft würden.
4. **Nachholfenster für verpasste Erinnerungen** (zwei Stunden, Abschnitt 4) und **Standard-Erinnerungszeit** (21:00) sind eigene Festlegungen ohne Nutzerdaten; im Beta-Test prüfen.
5. **Live-Text auf Android.** Moonshine ist ein Streaming-Modell; ob Live-Vorschau auf einem 4-GB-Gerät flüssig läuft, zeigt der Spike aus D3.
6. **Wirkung des persönlichen Wörterbuchs** bei `SpeechTranscriber` und bei den Android-Modellen (Abschnitt 6).
7. **Play-Policy für `USE_EXACT_ALARM`** als Erinnerungs-App (auch offen in `04-technik-architektur.md`).
8. **Frage des Tages und Altersfreigabe.** Welche Formulierungen gelten als neutrale Reflexion (4+) und welche als Wellness-Empfehlung (9+) [43]; Liste vor 1.x redaktionell prüfen.
9. **Onboarding-Länge.** Sieben Schritte sind viele; welche lassen sich in den ersten Aufnahmeablauf verlagern, ohne dass Gerätecode-Bindung und Modell-Download überraschen?
10. **Verifikation.** Die Faktenprüfung (verifikation.json) lag bei Redaktionsschluss nicht vor; alle als unverifiziert gekennzeichneten Angaben sind vor Veröffentlichung zu prüfen (D15).

## Quellen

1. Apple Support, Journal auf dem iPhone, Transkription nur Englisch: https://support.apple.com/en-kz/guide/iphone/iph492ee70a8/ios
2. Day One, Audio Recording Guide (10-Minuten-Grenze, On-Device nur mit iOS 26/Apple Intelligence): https://dayoneapp.com/guides/tips-and-tutorials/audio-recording/
3. DailyVox, README (42-Sekunden-Einträge, "Data Not Collected"): https://github.com/intrepidkarthi/dailyvox
4. Journiv Issue #420 (leere Seite als Hürde): https://github.com/journiv/journiv-app/issues/420
5. Daylogue, "Why Do Journaling Apps Make Me Feel Guilty?": https://daylogue.com/learn/journaling-app-guilt
6. LogRocket, Streaks und Retention: https://blog.logrocket.com/product-management/streaks-user-retention/
7. Deconstructor of Fun, Duolingo Streaks: https://duolingo.deconstructoroffun.com/mechanics/streaks
8. MindScape-Studie (Abend-Check-ins), PMC: https://pmc.ncbi.nlm.nih.gov/articles/PMC11275533/
9. uhabits Issue #2052 (verzögerte Erinnerungen): https://github.com/iSoron/uhabits/issues/2052
10. uhabits Issue #852 (Erinnerungen nach Neustart): https://github.com/iSoron/uhabits/issues/852
11. Android, Alarme planen (`setAlarmClock`, `setWindow`, `SCHEDULE_EXACT_ALARM`): https://developer.android.com/develop/background-work/services/alarms/schedule
12. dontkillmyapp, Herstellerhinweise (Samsung, Xiaomi u. a.): https://github.com/urbandroid-team/dont-kill-my-app
13. Apple, `UNCalendarNotificationTrigger`: https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger
14. Apple, Interruption Level `timeSensitive`: https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive
15. Apple, `AudioRecordingIntent` (Live Activity Pflicht): https://developer.apple.com/documentation/appintents/audiorecordingintent
16. Apple, Controls für Sperrbildschirm, Kontrollzentrum, Action Button: https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system
17. Apple, Live Activities (Dauer, Anzeige auf Watch): https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
18. Apple, `WidgetFamily`: https://developer.apple.com/documentation/widgetkit/widgetfamily
19. Android, Vordergrunddienste aus dem Hintergrund (Ausnahmen Widget/Benachrichtigung): https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start
20. Android, Schnelleinstellungs-Kacheln: https://developer.android.com/develop/ui/views/quicksettings-tiles
21. Apple, `DictationTranscriber` (nicht auf watchOS): https://developer.apple.com/documentation/speech/dictationtranscriber
22. Apple, `AVAudioRecorder`: https://developer.apple.com/documentation/avfaudio/avaudiorecorder
23. Apple, Extended Runtime Sessions (watchOS): https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions
24. Apple, `WCSession.transferFile(_:metadata:)`: https://developer.apple.com/documentation/watchconnectivity/wcsession/transferfile(_:metadata:)
25. Android, Wear OS Data Layer (`Asset` für Sprachaufnahmen): https://developer.android.com/training/wearables/data/data-layer
26. WhisperKit Discussion #437 (tiny.en auf Apple Watch Series 11): https://github.com/argmaxinc/argmax-oss-swift/discussions/437
27. Apple, `SpeechAnalyzer` (Ergebnisse mit `audioTimeRange` und Konfidenz): https://developer.apple.com/documentation/speech/speechanalyzer
28. Apple, `SpeechTranscriber.supportedLocales`: https://developer.apple.com/documentation/speech/speechtranscriber/supportedlocales
29. VoiceInk, empirische Locale-Liste (de-DE, de-AT, de-CH): https://github.com/Beingpax/VoiceInk/blob/8f089cb4bf2c9c2f217b0cc0af909d9052ff6288/VoiceInk/Features/ModelLibrary/Models/LanguageDictionary.swift
30. Apple Developer Forums, Thread 806765 (iPhone 11/SE 2 ohne `SpeechTranscriber`): https://developer.apple.com/forums/thread/806765
31. Moonshine, verfügbare Modelle (German Small Streaming, WER 7,5 %): https://raw.githubusercontent.com/moonshine-ai/moonshine/main/docs/models/available-models.md
32. OpenAI Whisper Discussion #928 (Halluzinationen bei Stille, deutsch): https://github.com/openai/whisper/discussions/928
33. faster-whisper Issue #601 (deutsche Kleinschreibung, fehlende Interpunktion): https://github.com/SYSTRAN/faster-whisper/issues/601
34. Apple, `SpeechDetector`: https://developer.apple.com/documentation/speech/speechdetector
35. AppleVis, Diktat und Voice Control: https://www.applevis.com/forum/ios-ipados/dictation-needs-massive-improvements
36. Day One, "On This Day": https://dayoneapp.com/features/on-this-day/
37. TechBuzz, Kritik an KI-Funktionen in Google Journal: https://www.techbuzz.ai/articles/google-journal-ai-features-spark-privacy-backlash
38. Apple, Foundation Models, Sicherheit der Ausgabe (Guardrails, Refusals): https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output
39. Flutter, Accessibility (Screenreader, Kontrast 4,5:1, Touch-Ziele 48 × 48): https://github.com/flutter/website/blob/main/sites/docs/src/content/ui/accessibility/index.md
40. Apple, Accessibility Nutrition Labels: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels
41. BFSG § 3 (Spiegel des Gesetzestexts, Stand 2021; aktuelle Fassung prüfen): https://github.com/bundestag/gesetze/blob/master/b/bfsg/index.md
42. Weesper Neonflow, Diktat und Barrierefreiheit (Legasthenie): https://weesperneonflow.ai/en/blog/2025-10-19-voice-dictation-accessibility-dyslexia-disabilities-guide/
43. Apple, Altersfreigaben, Werte und Definitionen: https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions
44. MDCG 2019-11, Qualifikation von Software als Medizinprodukt: https://health.ec.europa.eu/system/files/2020-09/md_mdcg_2019_11_guidance_qualification_classification_software_en_0.pdf
45. EU AI Act, Verordnung (EU) 2024/1689: https://eur-lex.europa.eu/eli/reg/2024/1689/oj
46. journal2day1 (Apple Journal exportiert nur HTML): https://github.com/kpod13/journal2day1
47. Fossify Voice Recorder Issue #56 (Aufnahmeverlust): https://github.com/FossifyOrg/Voice-Recorder/issues/56
48. uhabits Issue #2170 (Reduce Motion ignoriert): https://github.com/iSoron/uhabits/issues/2170
49. Retention von Mental-Health-Apps (30-Tage-Median): https://www.researchgate.net/figure/App-30-day-retention-by-mental-health-focus-The-percentages-reflect-the-number-of-users_fig2_334562120
50. Lite Journal, Vergleich (einfache Apps werden benutzt): https://litejournal.co/compare/best-journaling-app
51. Apple, Journaling Suggestions: https://developer.apple.com/documentation/journalingsuggestions
52. DreamLog (Wake-Word-Tagebuch, Android): https://github.com/wivy1/dreamlog
53. Transkribor Issue #130 (Schweizerdeutsch-Modelle, CC-BY-NC): https://github.com/napoleonmm83/Transkribor/issues/130
54. Dictus Issue #449 (abgebrochene Modell-Downloads): https://github.com/getdictus/dictus-ios/issues/449
55. Apple, `AssetInventory` (Modelle werden vom System geladen): https://developer.apple.com/documentation/speech/assetinventory
