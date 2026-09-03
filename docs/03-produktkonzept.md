# 03 · Produktkonzept

Stand: 3. September 2026 · Status: Entwurf

Dieses Dokument beschreibt, was die App aus Sicht der Nutzerin tut: das Kernerlebnis, den täglichen Ablauf, die Bildschirme, die Erinnerungslogik, die Anzeige und Korrektur des Transkripts, Suche und Rückblicke, den Funktionsumfang in drei Stufen mit einer Schnittlinie für Version 1.0, Barrierefreiheit und die bewussten Auslassungen. Es setzt `00-anforderungen.md` (M1 bis M12, A1 bis A8) und die verbindlichen Entscheidungen D1 bis D15 um. Technische Umsetzung steht in `04-technik-architektur.md`, Schutzkonzept in `05-sicherheit-und-datenschutz.md`, Gerätewechsel und Backup in `06-geraetewechsel-qr-transfer.md`, Preise ausschließlich in `07-geschaeftsmodell.md`. Der Name ist noch offen (D11); hier heißt es "die App".

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

Der Startbildschirm zeigt eine Karte "Vor einem Jahr", wenn es an diesem Datum einen Eintrag gibt (analog "vor zwei Jahren" usw.; 1.0-Reserve nach Abschnitt 8.1). Day-One-Nutzer beschreiben diese Funktion als "a constant source of joy" [36]; sie ist mit lokalen Daten trivial und braucht keine KI. Der Kalender zeigt Monate als leise Übersicht: Tage mit Eintrag sind markiert, ohne Zähler, ohne Kette, ohne "verpasst". Monatszahlen (Tage mit Eintrag, gesprochene Minuten, Wörter; D8) folgen in Version 1.1 (Abschnitt 8.1).

### 2.4 Backup, ohne daran denken zu müssen

Der Schlüssel zum Tagebuch ist an das Gerät gebunden (D5): Keychain-Eintrag `ThisDeviceOnly`, auf Android `allowBackup="false"`. Das ist gewollt, hat aber eine Kehrseite, die Nutzerinnen in Rezensionen zu Recht hart bestrafen: Ohne eigene Backup-Datei ist ein verlorenes, defektes, gestohlenes oder zurückgesetztes Gerät der Totalverlust, und ein Betriebssystem-Backup stellt nichts wieder her. Eine monatliche Erinnerung allein löst A8 ("Der Verlust des Geräts darf nicht der Verlust des Tagebuchs sein") nicht; der Wunsch aus dem Nutzerfeedback lautet wörtlich "automatisches, verschlüsseltes Backup" [59], und `02-nutzerfeedback-und-luecken.md` nennt Backup die verwundbarste Stelle einer serverlosen App. Deshalb ist das Backup im MVP automatisch und bleibt innerhalb von D6: dieselbe Containerdatei wie beim Gerätewechsel, mit Passphrase statt Empfängerschlüssel, ohne Server des Inhabers (D14).

1. **Einrichtung** nach dem dritten Eintrag, als Karte auf "Heute" (nicht im Onboarding: Vor der ersten Aufnahme gibt es nichts zu sichern, und eine Passphrase, die man vor dem ersten Nutzen setzt, vergisst man). Zwei Schritte: Ordner wählen und Passphrase setzen. Der Ordner kommt aus dem System-Dialog (Android Storage Access Framework, `ACTION_OPEN_DOCUMENT_TREE` mit dauerhafter Berechtigung [60]; iOS Ordnerauswahl über `UIDocumentPickerViewController` [61]) und darf ein iCloud-Drive-, Nextcloud- oder anderer Anbieter-Ordner, eine SD-Karte oder ein USB-Stick sein. Die App empfiehlt einen Ort außerhalb des Geräts und erklärt, dass ein Ordner im internen Speicher bei Geräteverlust nichts nützt und dass ein Cloud-Ordner die Datei zum jeweiligen Anbieter trägt, allerdings nur als Chiffrat. Die Passphrase (Argon2id-Parameter nach D6) wird zweimal eingegeben; die App sagt unmissverständlich, dass sie ohne Passphrase nicht helfen kann.
2. **Automatik.** Nach dem Speichern eines Eintrags prüft die App, ob das letzte Backup älter als sieben Tage ist oder seit dem letzten Backup fünf Einträge hinzugekommen sind (eigene Festlegung, im Beta-Test prüfen). Trifft eines zu, schreibt sie direkt im Anschluss, im Vordergrund, einen vollständigen Container in den Ordner. Das braucht keine Hintergrundplanung und verhält sich auf beiden Plattformen gleich. Vollständige statt inkrementelle Backups sind vertretbar: Bei 3 Minuten Sprache täglich und Opus 16 kbit/s wächst das Tagebuch um rund 131 MB pro Jahr (D6); die App behält die letzten drei Dateien und löscht ältere, also nach eigener Rechnung rund 0,4 GB am Ende des ersten Jahres.
3. **Backup prüfen.** Nach jedem Schreiben leitet die App den Schlüssel aus der Passphrase erneut ab, öffnet die geschriebene Datei und liest das Manifest (Wiederherstellungstest wie in `06-geraetewechsel-qr-transfer.md`, Abschnitt Backup). Erst dann gilt das Backup als erstellt. Dieselbe Prüfung lässt sich jederzeit in den Einstellungen auslösen, auch mit erneuter Passphrase-Eingabe, damit man weiß, dass man sie noch kennt.
4. **Sichtbar auf "Heute".** Eine Zeile "Letztes Backup vor 3 Tagen, geprüft" ersetzt die Erinnerung. Schlägt das Backup fehl (Ordner nicht erreichbar, Berechtigung entzogen, Stick nicht angesteckt), bleibt die Zeile ruhig, bis 14 Tage ohne Backup vergangen sind; dann wird sie zum Hinweis mit "Jetzt sichern" und "Ordner ändern". Die monatliche Erinnerung aus D6 gilt nur, solange kein automatisches Backup eingerichtet ist.
5. **Wiederherstellen** geschieht im Onboarding eines neuen Geräts ("Aus Backup wiederherstellen": Ordner oder Datei wählen, Passphrase eingeben) und ist derselbe Import wie beim Gerätewechsel (D6). Ein manuelles "Backup jetzt als Datei teilen" bleibt zusätzlich in den Einstellungen.

## 3. Bildschirmstruktur

Die App hat fünf Bildschirme; das Onboarding ist ein einmaliger Ablauf und zählt nicht dazu.

| Bildschirm | Inhalt | Warum so |
|---|---|---|
| **Heute** (Start) | Große Aufnahmetaste; darunter der heutige Eintrag (falls vorhanden) mit Play und Textanfang; Zeile "Letztes Backup vor X Tagen" (nach dem dritten Eintrag zunächst die Einrichtungskarte, Abschnitt 2.4); Karte "Vor einem Jahr" (1.0-Reserve, Abschnitt 8.1); dezenter Zugang zu Kalender und Einstellungen. Zustand statt Mahnung: "Heute noch nichts aufgenommen" ist neutral formuliert. | Ein Tipp bis zur Aufnahme; kein Zähler, keine Schuld [5][6]; der Backup-Stand ist die einzige Zustandsanzeige, die an etwas erinnert, weil dort der einzige Totalverlust droht (A8). |
| **Aufnahme** | Vollbild: Zeit, Pegel, Pause, Fertig, Abbrechen (mit Rückfrage). Optional Live-Text (Einstellung). Bei Unterbrechung durch Anruf wird pausiert und danach weitergemacht; nichts geht verloren. | Aufnahme muss robust sein; Datenverlust bei Aufnahme-Apps ist ein häufiger Beschwerdegrund [47]. |
| **Eintrag** | Datum, Dauer, Sprach-Badge (de-DE/de-AT/de-CH/en); Player; Transkript, auf iOS mit Tipp-zum-Springen; "Ergänzen" (weitere Aufnahme); Text bearbeiten; erneut transkribieren, falls die Erkennung fehlgeschlagen ist; Audio dieses Eintrags löschen; Eintrag löschen; Eintrag exportieren. Ab 1.1: Sprache ändern und neu transkribieren, Original-Transkript wiederherstellen. | Audio und Text gleichwertig (M5, A5); Korrektur in der Hand der Nutzerin. |
| **Kalender und Suche** | Monatsraster mit markierten Tagen; Liste nach Datum; Suchfeld mit Filtern (Zeitraum, Sprache, nur mit Audio). Ab 1.1: Monatszahlen (Tage, Minuten, Wörter), "Zufälliger Eintrag". | Volltextsuche ist bei Sprachnotiz-Apps der meistgewünschte Zusatz [FossifyOrg #34, siehe `01-markt-und-wettbewerb.md`]; Heatmap statt Streak [5]. |
| **Einstellungen** | Erinnerung (Uhrzeit, Zuverlässigkeit; "Pause bis Datum" und Wochentage als 1.0-Reserve); Sprache der Transkription; Genauigkeitspaket (Plus, 1.x); App-Sperre und Zeit bis zur Sperre; Audio behalten (global); Speicherverbrauch; Backup (Ordner, Passphrase, "Backup prüfen", "Jetzt als Datei teilen") und Gerätewechsel; Export; "Was verlässt dein Gerät: nichts" (Transparenzseite mit Berechtigungsliste); Barrierefreiheit; Rechtliches und Impressum; Plus. | Alles Seltene an einem Ort; die Transparenzseite macht das Kernversprechen prüfbar (D14). |

Onboarding, einmalig und in vier Schritten: (1) Gerätecode prüfen, weil der Schlüssel daran gebunden ist (D5); derselbe Bildschirm sagt in einem Satz, dass Betriebssystem-Backups das Tagebuch deshalb nicht wiederherstellen und die App das mit einem eigenen, verschlüsselten Backup löst (D6, Abschnitt 2.4); hier auch "Aus Backup wiederherstellen" für ein neues Gerät. (2) Mikrofon. (3) Sprache wählen, mit dem Hinweis, dass Hochdeutsch die zuverlässigsten Ergebnisse liefert (D12), und im selben Schritt das Modell laden: auf iOS durch das System [55], auf Android per Play Asset Delivery (D3), mit Größe und WLAN-Hinweis, weil abgebrochene Modell-Downloads Nutzer aussperren können [54]. (4) Erinnerungszeit; auf Android-Geräten betroffener Hersteller enthält derselbe Schritt "Erinnerungen zuverlässig machen" mit Herstellerhinweisen (D7). Überspringbar sind (3) und (4). Die Backup-Einrichtung (Ordner, Passphrase) gehört bewusst nicht ins Onboarding, sondern folgt nach dem dritten Eintrag (Abschnitt 2.4).

## 4. Erinnerungslogik

Die Erinnerung ist der wichtigste Hebel der App: Bei Apps rund um mentale Gesundheit liegt die mediane 30-Tage-Retention auf Android bei 3,3 % [49] (Sekundärquelle, unverifiziert); alles, was das Ritual reibungsärmer macht, zahlt darauf ein.

**Feste Zeit, änderbar.** Eine Erinnerung pro Tag zu einer Uhrzeit, die im Onboarding gesetzt und jederzeit in den Einstellungen geändert wird (M2, D7). Vorschlag im Onboarding: 21:00 Uhr. Abend-Check-ins erhielten in einer kleinen Studie mit 20 Teilnehmenden das beste Feedback-Verhältnis [8] (aus Sekundärquelle rekonstruiert, unverifiziert); wichtiger ist, dass die Nutzerin selbst wählt.

**Aktionen in der Benachrichtigung.** "Aufnehmen" startet sofort. "In 1 Stunde" verschiebt einmalig. "Heute nicht" schließt ohne Nachfrage und ohne Kommentar. Kein "Du hast gestern verpasst": Vorwurfs-Benachrichtigungen und Reset-Zähler führen nachweislich zu Abbruch statt Gewohnheit [5][6]; sogar Duolingo musste mit Streak Freeze gegen die eigene Mechanik nachrüsten [7] (Zahlen daraus unverifiziert).

**Verhalten beim Verpassen.**

1. Wird die Erinnerung ignoriert, passiert nichts weiter; am nächsten Tag kommt sie wie immer.
2. Öffnet man die App am Folgetag, bietet der Startbildschirm neben "Heute" unaufdringlich "Für gestern nachtragen" an (A3). Nachträge sind im Kalender als solche gekennzeichnet (Aufnahmedatum ungleich Eintragsdatum).
3. War das Gerät zur Erinnerungszeit ausgeschaltet, gilt: Android plant die Erinnerung nach `BOOT_COMPLETED` neu; liegt die Uhrzeit weniger als zwei Stunden zurück, wird sie einmalig nachgeliefert, sonst verfällt sie für diesen Tag (eigene Festlegung, im Nutzertest prüfen). Hintergrund: Gewohnheits-Apps, die nach Neustart nicht nachholen, ernten Beschwerden [10], zu spätes Nachholen (z. B. morgens um 3 Uhr) wäre aber schlimmer. iOS liefert wiederholende Kalender-Trigger selbst aus [13]; dort ist keine eigene Logik nötig.
4. Kein Streak, keine Kette, kein Fortschrittsbalken. Der Kalender zeigt nur, was da ist.

**Ruhezeiten.** "Pausieren bis" einem Datum (Urlaub, Krankheit) und die Beschränkung auf Wochentage sind 1.0-Reserve (Abschnitt 8.1): D7 verlangt Uhrzeit, "Heute nicht" und "In 1 Stunde"; wer länger Ruhe will, schaltet die Erinnerung in den Einstellungen aus und später wieder ein. Die App respektiert Fokus-Modi und "Nicht stören": Die Benachrichtigung ist standardmäßig normal priorisiert; Time-Sensitive (iOS) ist eine Nutzerwahl und wird erklärt [14] (D7). Auf Android nutzt die App `setAlarmClock()` und fragt `SCHEDULE_EXACT_ALARM` an; bei Ablehnung fällt sie transparent auf ein Fenster von ±10 Minuten zurück und zeigt das in den Einstellungen [11] (D7). Ein Hinweis "Erinnerungen zuverlässig machen" mit Deep-Links in die Herstellereinstellungen ist nötig, weil etwa Samsung nach drei Tagen ohne Nutzung Hintergrundstarts blockiert [12] und Erinnerungen auf Android sonst verspätet oder gar nicht kommen [9].

**Ausbaustufe 1.x: Vorschlag statt Automatik.** Weichen die tatsächlichen Aufnahmezeiten über zwei Wochen deutlich von der Erinnerungszeit ab (Median der letzten 14 Aufnahmen mehr als 45 Minuten entfernt; eigene Heuristik), schlägt die App einmalig vor, die Uhrzeit anzupassen. Sie ändert nichts von selbst. Adaptive Zeitsteuerung erhöht die Nutzung nicht automatisch [8], aber ein Vorschlag kostet nichts.

## 5. Aufnahme ohne Bildschirm (spätere Ausbaustufen)

Im MVP gibt es zwei Einstiege: die Aufnahmetaste auf "Heute" und die Aktion in der Benachrichtigung. Alles Weitere folgt, sortiert nach Nutzen und Aufwand.

| Stufe | Einstieg | Plattform | Was zu beachten ist |
|---|---|---|---|
| 1.x | Control auf Sperrbildschirm, im Kontrollzentrum und auf dem Action Button | iOS | Ein `AudioRecordingIntent` muss eine Live Activity starten, sonst stoppt iOS die Aufnahme [15][16]. Die Live Activity zeigt Timer und Stopp, auch auf der Watch im Smart Stack [17]. Controls funktionieren bei gesperrtem Gerät; der Eintrag wird verschlüsselt geschrieben, lesen kann man ihn erst nach Entsperren. |
| 1.x | Home-Screen-Widget "Aufnehmen" und Sperrbildschirm-Widget | iOS | Widgets zeigen nur Zustand ("heute noch nicht aufgenommen"), nie Text (D5) [18]. |
| 1.x | Widget, Schnelleinstellungs-Kachel, App-Shortcut | Android | Start aus Widget oder Benachrichtigung ist von der Beschränkung für Vordergrunddienste im Hintergrund ausgenommen; die Kachel öffnet eine transparente Activity, die den Mikrofon-Dienst startet [19][20]. |
| 1.x | Siri-Kurzbefehl / App-Intent "Tagebuch aufnehmen" | iOS | Nur Start und Stopp; kein Inhalt an Siri. |
| später, nur unter Bedingungen | Apple Watch als Mikrofon | watchOS | Transkription auf der Watch gibt es nicht: `SpeechTranscriber` und `DictationTranscriber` existieren dort nicht [21]; WhisperKit tiny.en braucht auf einer Series 11 rund 19 s zum Laden [26] (Einzel-Benchmark mit stillem Audio, unverifiziert). Die Watch nimmt also auf, das iPhone transkribiert. Damit das Schutzmodell hält, gilt `05-sicherheit-und-datenschutz.md`, Abschnitt 2.7: Aufnahme über `AVAudioEngine.inputNode` [56] im Speicher statt per `AVAudioRecorder` [22], das eine Klartextdatei schreiben würde; Verschlüsselung auf der Uhr an den öffentlichen Schreibschlüssel des Telefons (Sealed Box) [57]; `WCSession.transferFile` [24] überträgt nur Chiffrat, das die Uhr selbst nicht öffnen kann. Längere Aufnahmen brauchen eine Extended-Runtime-Session, die nur im Vordergrund läuft (Self Care 10 Minuten, Mindfulness 1 Stunde) [23]. |
| nicht geplant | Wear OS als Mikrofon | Android | Data-Layer-`Asset` ist zwar für Sprachaufnahmen von einem anderen Gerät gedacht [25], aber der Data Layer läuft in den Google-Play-Diensten und leitet Daten bei fehlendem Bluetooth über Google Cloud; Google selbst rät, anzunehmen, dass Data-Layer-Daten Google-Server nutzen [58]. Das ist mit D14 nicht vereinbar, auch nicht mit verschlüsselter Nutzlast. Gestrichen, bis ein Transport existiert, der das Gerätepaar nachweislich nicht verlässt (`05-sicherheit-und-datenschutz.md`, Abschnitt 2.7). |
| nicht geplant | Wake-Word ("Hey Tagebuch") | beide | Ein dauerhaft lauschendes Mikrofon widerspricht dem Vertrauensversprechen, kostet Akku und ist auf iOS für Drittanbieter nicht vorgesehen. DreamLog zeigt, dass es auf Android geht [52]; für diese App ist es der falsche Kompromiss. |

Empfehlung: Controls/Action Button und Android-Widget als erstes 1.x-Thema, weil sie das Ritual auf eine Geste verkürzen und in der Kategorie Tagebuch selten sind (Wettbewerbsbefund in `01-markt-und-wettbewerb.md`). Die Apple Watch erst nach einem Prototyp, weil die Übertragung asynchron ist, im Simulator nicht getestet werden kann [24] und die Schutzbedingungen aus `05-sicherheit-und-datenschutz.md`, Abschnitt 2.7 (kein Klartext auf der Uhr, Verschlüsselung an den Schreibschlüssel des Telefons) erst im Spike nachgewiesen werden müssen. Ohne diesen Nachweis bleibt die Funktion gestrichen.

## 6. Transkript: Anzeige und Korrektur

**Grundsatz: Das Audio ist die Wahrheit, der Text ist eine Hilfe.** Das Transkript ist Suchindex und Lesehilfe; es ersetzt die Aufnahme nicht. Deshalb wird Audio standardmäßig behalten (A5, D4).

**Anzeige.**
- Der Text steht als Fließtext in Absätzen, die aus Sprechpausen gebildet werden. Wortweise Zeitmarken (iOS) erlauben Tipp-zum-Springen [27]. Auf Android kommt Tipp-zum-Springen in 1.0 nur, wenn Spike S2 (`09-roadmap.md`) zeigt, dass die Modelle über sherpa-onnx brauchbare Zeitmarken liefern; sonst in 1.1 (offene Frage 2).
- Ein Sprach-Badge zeigt, mit welcher Locale transkribiert wurde. Die Sprache wird nicht automatisch erkannt, sondern ist eine Einstellung, änderbar pro Eintrag: Automatische Spracherkennung führt bei deutsch-englischen Mischsätzen zu Sprachwechseln oder Übersetzungen statt Transkription (whisper.cpp #1800, easyspeak #153, siehe `01-markt-und-wettbewerb.md` und Recherche Nutzerfeedback).
- Wörter mit niedriger Konfidenz werden dezent unterlegt (iOS liefert Konfidenzwerte je Ergebnis [27]; Android: offene Frage). Kein rotes Markieren, kein "Fehlerzähler".
- Solange der Text noch erstellt wird, steht "Text wird erstellt"; schlägt die Transkription fehl, bleibt die Aufnahme erhalten und lässt sich später erneut transkribieren. Verschwindende Transkripte sind eine dokumentierte Schwäche von Apple Journal (Apple Community, siehe `01-markt-und-wettbewerb.md`).

**Qualitätsmaßnahmen, die die Nutzerin nicht sieht.**
- Sprachaktivitätserkennung vor der Transkription (iOS `SpeechDetector` [34]; Android VAD-Chunking, D2/D3). Ohne sie erzeugen Whisper-artige Modelle bei Stille Phantomtexte wie "Untertitel im Auftrag des ZDF" [32].
- Nachbearbeitung für Groß-/Kleinschreibung und Interpunktion, falls das Modell sie nicht liefert; deutsche Kleinschreibung durchgehend ist ein bekanntes Ärgernis [33].
- de-CH bedeutet Schweizer Standarddeutsch (Orthografie ohne ß), nicht Mundart; Apple veröffentlicht keine feste Liste, `supportedLocales` ist die Wahrheit [28][29]. Die App sagt das im Onboarding und beim Sprach-Badge offen (D12). Mundart-Modelle existieren nur als nicht-kommerzielle Fine-Tunes [53]; siehe Abschnitt 8, "später".

**Korrektur.**
- Text bearbeiten: einfacher Editor, Änderungen werden als "bearbeitet" gekennzeichnet. Audio wird nie verändert; wer das Original braucht, hat es als Aufnahme. Das intern erhaltene Original-Transkript mit "Wiederherstellen" folgt in 1.1: nützlich, aber nicht nötig, solange das Audio die Wahrheit ist.
- Erneut transkribieren (MVP): nur nach fehlgeschlagener Erkennung, mit denselben Einstellungen. Neu transkribieren mit anderer Sprache oder, wenn vorhanden, mit dem Genauigkeitspaket (D2/D3) folgt in 1.1; dann läuft es im Hintergrund und ersetzt den Text erst nach Bestätigung, wenn er bereits bearbeitet wurde.
- Persönliches Wörterbuch (1.x): Namen und Orte, die als Kontext an die Erkennung gehen. Auf iOS ist `AnalysisContext.contextualStrings` für `DictationTranscriber` dokumentiert, die Wirkung bei `SpeechTranscriber` unklar (Recherche iOS); auf Android ist Hotword-Unterstützung modellabhängig. Deshalb 1.x mit Spike.
- Korrektur per Sprache (1.x): "Ersetze Meier durch Maier" nach der Aufnahme, lokal per Mustervergleich. Vorbild sind die Systemfunktionen Voice Control und Voice Access, deren Qualität Nutzer als begrenzt beschreiben [35]; deshalb kein MVP-Thema.

## 7. Suche und Rückblicke, nur lokal

- **Volltextsuche** über alle Transkripte mit SQLite FTS5 in der verschlüsselten Datenbank (D4, D8). Treffer zeigen Datum, Textausschnitt und springen beim Öffnen an die Stelle im Audio. Filter: Zeitraum, Sprache, nur Einträge mit Audio, nur bearbeitete Texte.
- **Kalender** als Monatsraster; Tage mit Eintrag markiert, Intensität nach Dauer, ohne Zahlen im Raster.
- **Rückblicke** (D8): "Vor einem Jahr" auf dem Startbildschirm ist 1.0-Reserve (Abschnitt 8.1); Monatszahlen (Tage, Minuten, Wörter) und "Zufälliger Eintrag" als Taste im Kalender folgen in 1.1. Alles ohne generative KI, alles auf dem Gerät. Im ersten Jahr nach dem Start hat ohnehin niemand einen Eintrag "vor einem Jahr"; die Funktion darf also ohne Schaden nachgereicht werden.
- **Version 1.x, Plus, Opt-in** (D8, D9): Tageszusammenfassung in zwei bis drei Sätzen und ein Wochenrückblick mit Apple Foundation Models, nur auf Apple-Intelligence-Geräten; Ablehnungen des Modells (Guardrails bei Trauer, Krankheit) werden still abgefangen, der Eintrag bleibt ohne Zusammenfassung [38]. Auf Android gibt es dafür vorerst keine Lösung: Gemini Nano fasst nicht auf Deutsch zusammen und läuft nur auf Flaggschiffen (D8). Die Funktion ist abschaltbar und erklärt, was sie tut. Selbst lokale KI-Funktionen lösten bei Google Journal Kritik aus [37] (Sekundärquelle); daher niemals Standard.
- **Später:** semantische Suche mit lokalen Einbettungen ("wann war ich zuletzt so wütend?") und ein gestalteter Jahresrückblick. Beides erst, wenn die Basisnutzung steht.

Was Suche und Rückblicke nicht tun: Stimmungen aus der Stimme ableiten, Trends bewerten, Warnungen geben (Abschnitt 10).

## 8. Feature-Liste in drei Stufen

Kostenlos/Plus folgt D9; Preise stehen nur in `07-geschaeftsmodell.md`. Die kostenlosen Funktionen werden nie kostenpflichtig; das steht im Store-Text (D9).

### 8.1 Version 1.0 (MVP) mit Schnittlinie

Die erste Fassung dieser Liste war für eine Person zu groß: 17 Funktionszeilen auf zwei Plattformen mit drei nativen Brücken, eigenem Containerformat und QR-Handshake. `02-nutzerfeedback-und-luecken.md`, Abschnitt 6, rechnet allein die elf MVP-Chancen auf 7 bis 19 Wochen für eine Person (L bis XL), zusätzlich zum Grundgerüst; `09-roadmap.md` stuft Phase 3 als XL mit 480 bis 640 Stunden ein. Deshalb ist der Umfang hier in zwei Tabellen geteilt: **Muss für 1.0** (nicht kürzbar, weil sonst ein Erfolgskriterium aus `00-anforderungen.md`, Abschnitt 5, oder ein Kernversprechen aus D4 bis D9 und D14 fällt) und **1.0-Reserve** (kommt in 1.0, wenn das Budget reicht, sonst in 1.1). Kontrollpunkt und Reihenfolge des Wegfalls stehen in `09-roadmap.md`, Abschnitt 2.2. Was entfällt, bleibt kostenlos; die Garantie aus D9 ist nicht berührt. Alles, was gegenüber der ersten Fassung ganz nach 1.1 gewandert ist, steht in Abschnitt 8.2 in der ersten Zeile.

Zweiter Hebel neben dem Umfang ist die Kotlin-Brücke aus D1 (b). sherpa-onnx liefert offizielle Dart/Flutter-Bindings, das Paket `sherpa_onnx` 1.13.7 liegt auf pub.dev [62][63]. Empfehlung: In den Spikes S2 und S8 (`09-roadmap.md`) zuerst prüfen, ob diese Bindings für Streaming-Erkennung mit Moonshine ausreichen; dann schrumpft die Brücke auf das Auflösen des Modellpfads aus Play Asset Delivery und den Vordergrunddienst für die Aufnahme, und der Aufwand für Phase 3 sinkt spürbar. Empfehlung, weil eine eigene JNI-Anbindung der teuerste und am wenigsten wiederverwendbare Teil des Android-Pfads wäre.

**Muss für 1.0**

| Funktion | Begründung | Kostenlos/Plus |
|---|---|---|
| Aufnahme mit einem Tipp, Pause, Fertig; robust bei Anruf und Sperre | M1, M3; Datenverlust bei Aufnahme ist der schlimmste Fehler [47] | kostenlos |
| Aufnahmen bis 5 Minuten je Eintrag | Kurze Einträge senken die Hürde; Grenze nach D9 | kostenlos |
| Lokale Transkription Deutsch (de-DE/de-AT/de-CH) und Englisch, feste Sprachwahl; iOS 26 ab iPhone 12 empfohlen, Android 12 ab 4 GB RAM (D13) | M4, M6, A1, D2, D3, D12; Apple Journal transkribiert nur Englisch [1], Day One nur bis 10 Minuten und bis iOS 26 nur online [2]; iPhone 11 und SE 2 bieten `SpeechTranscriber` nicht, dort greift der Fallback [30] | kostenlos |
| Wiedergabe und Text lesen; Tipp-zum-Springen auf iOS [27], auf Android nur bei positivem Spike S2, sonst 1.1 | M5, A5; Android-Zeitmarken sind offen (Abschnitt 11, Frage 2) | kostenlos |
| Text bearbeiten (einfacher Editor, Kennzeichnung "bearbeitet"); erneut transkribieren nach Fehlschlag | Korrektur ohne Datenverlust; das Audio bleibt die Wahrheit (Abschnitt 6) | kostenlos |
| Tägliche Erinnerung zur gewählten Uhrzeit mit "In 1 Stunde" und "Heute nicht"; Aufnahme direkt aus der Benachrichtigung; Android-Schritt "Erinnerungen zuverlässig machen" | M2, D7; kein Streak-Druck [5][6]; ein Tipp vom Signal zur Aufnahme | kostenlos |
| Mehrere Aufnahmen pro Tag, Nachträge für vergangene Tage | A3, A4 | kostenlos |
| Volltextsuche (FTS5) und Kalender | D8; Volltextsuche ist der meistgewünschte Zusatz bei Sprachnotiz-Apps (Abschnitt 3) | kostenlos |
| Verschlüsselung, App-Sperre per Biometrie/Gerätecode (Standard 30 s, einstellbar bis 5 Minuten), Privacy-Overlay | M7, D5; Verschlüsselung ist bei Tagebuch-Apps die meistgefragte Eigenschaft (Recherche Nutzerfeedback) | kostenlos |
| Audio behalten oder löschen, pro Eintrag und global; Speicheranzeige | A5, D4; Rechenbasis: 3 Minuten täglich ergeben bei Opus 16 kbit/s rund 131 MB pro Jahr (D6) | kostenlos |
| Automatisches verschlüsseltes Backup in einen selbst gewählten Ordner (Passphrase, Wiederherstellungstest, "Letztes Backup vor X Tagen"); zusätzlich manuelles Backup als Datei; Wiederherstellung im Onboarding | A8, D6; Abschnitt 2.4; automatisches Backup ist der ausdrückliche Nutzerwunsch [59], kaputte Backups sind ein Top-Beschwerdegrund (Recherche Nutzerfeedback) | kostenlos |
| Gerätewechsel per QR-Code und Datei, iOS und Android in beide Richtungen | M8, D6; kein Wettbewerber bietet das serverlos (`01-markt-und-wettbewerb.md`) | kostenlos |
| Export: Markdown, JSON, Audio als Opus, jeweils das ganze Tagebuch; vor dem ersten Eintrag ausprobierbar | Lock-in ist der Hauptvorwurf gegen Apple Journal, das nur HTML exportiert [46]; Markdown, JSON und Opus reichen als Nachweis, dass nichts eingesperrt ist | kostenlos |
| Transparenzseite "Was verlässt dein Gerät: nichts" mit Berechtigungsliste; Android ohne INTERNET-Berechtigung | D14; Nachweis im Flugmodus | kostenlos |
| Onboarding in vier Schritten (Abschnitt 3) | D3, D5, D7; Backup-Einrichtung erst nach dem dritten Eintrag | kostenlos |
| Barrierefreiheit im Grundumfang: Abschnitt 9, Punkte 1 bis 5 und 7 | Zielgruppe; Accessibility Nutrition Labels [40] | kostenlos |
| Lokalisierung Deutsch (Schweizer Orthografie für de-CH) und Englisch | D12; reine Textarbeit, kein eigenes Paket | kostenlos |

**1.0-Reserve** (Reihenfolge des Wegfalls nach `09-roadmap.md`, Abschnitt 2.2: zuerst das Kaufgerüst, dann PDF, dann "Vor einem Jahr", zuletzt die Erinnerungs-Pausen)

| Funktion | Begründung | Kostenlos/Plus |
|---|---|---|
| In-App-Kauf-Gerüst für Plus zum Start | Plus kann auch mit 1.1 kommen; Beta-Tester erhalten Codes nachträglich (`09-roadmap.md`, Abschnitt 13) | Voraussetzung für Plus |
| PDF-Export und Zeitraumfilter beim Export | Bequem, aber für "kein Lock-in" nicht nötig; PDF bleibt nach D9 kostenlos, wann immer es kommt | kostenlos |
| "Vor einem Jahr" auf dem Startbildschirm | D8; "On This Day" ist die beliebteste Rückblickfunktion des Marktführers [36], aber im ersten Jahr nach dem Start für niemanden befüllt | kostenlos |
| Erinnerung: "Pause bis Datum", Wochentagsauswahl | Über D7 hinaus; Ausschalten in den Einstellungen deckt den Fall vorerst ab | kostenlos |

### 8.2 Version 1.x

| Funktion | Begründung | Kostenlos/Plus |
|---|---|---|
| Aus dem ursprünglichen MVP-Umfang verschoben: Monatszahlen und "Zufälliger Eintrag"; Original-Transkript wiederherstellen; Sprache ändern und neu transkribieren; Tipp-zum-Springen auf Android, falls Spike S2 keine Zeitmarken liefert; Barrierefreiheit Punkte 6 und 8 aus Abschnitt 9; dazu die nicht geschaffte 1.0-Reserve aus 8.1 | Schnitt für eine Person (8.1); nichts davon trägt ein Erfolgskriterium aus `00-anforderungen.md`, Abschnitt 5; erste Themen nach dem Start | kostenlos |
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
| Apple Watch als Mikrofon, nur unter den Schutzbedingungen aus `05-sicherheit-und-datenschutz.md`, Abschnitt 2.7 | Abschnitt 5; asynchroner Transfer, Prototyp nötig; Wear OS ist gestrichen, solange der Data Layer der einzige Weg ist | kostenlos |
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

Verbindlich ab Version 1.0 sind die Punkte 1 bis 5 und 7; die Punkte 6 und 8 folgen in 1.1, weil sie eigene Testdurchläufe je Eingabemethode brauchen und Aufnahme starten und beenden schon über Punkt 1 und die Systemfunktionen erreichbar sind (Schnitt in Abschnitt 8.1):

1. Jedes Bedienelement hat ein Label für VoiceOver und TalkBack; die Aufnahmetaste meldet ihren Zustand ("Aufnahme läuft, 1 Minute 20"). Flutter bildet Semantik auf beide Screenreader ab [39].
2. Start und Stopp der Aufnahme werden haptisch und mit einem kurzen Ton bestätigt, damit man ohne Blick auf den Bildschirm weiß, was passiert. Der Ton ist abschaltbar.
3. Schriftgrößen folgen der Systemeinstellung (Dynamic Type, Android-Schriftskalierung) bis 200 % ohne abgeschnittene Texte; Kontrast mindestens 4,5:1; Touch-Ziele mindestens 48 × 48 dp, die Aufnahmetaste deutlich größer [39].
4. "Reduce Motion" schaltet Pegel-Animationen auf eine statische Anzeige um; Gewohnheits-Apps, die das ignorieren, erhalten dafür Fehlerberichte [48].
5. Farbe ist nie der einzige Informationsträger (Kalender-Markierungen zusätzlich mit Form oder Text).
6. (1.1) Vollständige Bedienbarkeit per Tastatur und Switch Control sowie per Voice Control / Voice Access über alle Bildschirme; in 1.0 wird geprüft, dass Aufnahme starten und beenden mit diesen Methoden funktioniert.
7. Das Transkript ist zugleich Untertitel für gehörlose und schwerhörige Nutzer; Vorlesen des Transkripts mit lokaler Sprachausgabe folgt in 1.x, ebenso ein Texteintrag ohne Aufnahme für Menschen, die nicht sprechen können oder wollen.
8. (1.1) Links- und Rechtshänder: Die wichtigsten Tasten liegen im unteren Drittel (das gilt ab 1.0) und lassen sich spiegeln (1.1).

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
- **Kein Versprechen für Schweizerdeutsche Mundart** (D12), keine Transkription auf der Uhr [21], kein Wear-OS-Mikrofon über den Data Layer (Abschnitt 5), kein Betrieb, der nie eine Netzverbindung braucht: Der einmalige Modell-Download durch das Betriebssystem bzw. den Play Store ist unvermeidlich und wird erklärt (D14).
- **Kein Teilen in Netzwerke, keine Sozialfunktionen.** Export geht in Dateien, die die Nutzerin selbst weitergibt.

## 11. Offene Fragen

1. **Aufnahme bei gesperrter App.** Damit Controls und Widgets ohne Entsperren aufnehmen können, müssen neue Eintragsschlüssel ohne Zugriff auf den Master-Key gewrappt werden (z. B. asymmetrisch). `05-sicherheit-und-datenschutz.md`, Abschnitt 2.7 skizziert dafür den "Schreibschlüssel" (Sealed Box an einen X25519-Schlüssel des Telefons, spätere Neuverpackung mit dem Master-Key); ob D5 das hergibt oder ob der Start eine Authentifizierung verlangt, klärt ein Spike im Technikkonzept.
2. **Zeitmarken und Konfidenz auf Android.** Liefern Moonshine Streaming und Parakeet über sherpa-onnx wort- oder nur segmentweise Zeitmarken und Konfidenzen? Davon hängt Tipp-zum-Springen und die Unterlegung unsicherer Wörter ab.
3. **5-Minuten-Grenze bei mehreren Aufnahmen pro Tag.** D9 formuliert "je Eintrag"; ob das je Aufnahme oder als Tagessumme gilt, entscheidet `07-geschaeftsmodell.md`. Empfehlung: je Aufnahme, weil Ergänzungen (A4) sonst bestraft würden.
4. **Nachholfenster für verpasste Erinnerungen** (zwei Stunden, Abschnitt 4) und **Standard-Erinnerungszeit** (21:00) sind eigene Festlegungen ohne Nutzerdaten; im Beta-Test prüfen.
5. **Live-Text auf Android.** Moonshine ist ein Streaming-Modell; ob Live-Vorschau auf einem 4-GB-Gerät flüssig läuft, zeigt der Spike aus D3.
6. **Wirkung des persönlichen Wörterbuchs** bei `SpeechTranscriber` und bei den Android-Modellen (Abschnitt 6).
7. **Play-Policy für `USE_EXACT_ALARM`** als Erinnerungs-App (auch offen in `04-technik-architektur.md`).
8. **Frage des Tages und Altersfreigabe.** Welche Formulierungen gelten als neutrale Reflexion (4+) und welche als Wellness-Empfehlung (9+) [43]; Liste vor 1.x redaktionell prüfen.
9. **Backup-Einrichtung nach dem dritten Eintrag.** D6 verlangt die Backup-Erklärung im Onboarding; sie steht dort in Schritt 1 als ein Satz. Ordner und Passphrase werden erst nach dem dritten Eintrag abgefragt (Abschnitt 2.4). Ob "drei Einträge" der richtige Moment ist und wie viele Nutzerinnen die Karte wegwischen, zeigt der Beta-Test; die Zeile "Letztes Backup: noch keins" bleibt so lange sichtbar.
10. **Dauerhafter Ordnerzugriff für das automatische Backup.** Auf Android ist die dauerhafte Berechtigung über das Storage Access Framework dokumentiert [60]; ob iOS den Zugriff auf einen gewählten Ordner über App-Neustarts hinweg zuverlässig behält (security-scoped bookmark) und wie sich Anbieter-Ordner (iCloud Drive, Nextcloud) beim Schreiben großer Dateien verhalten, ist im Spike zu prüfen (in der Recherche nicht untersucht). Ebenso offen: ob die App erkennen kann, dass der gewählte Ordner nur im internen Speicher liegt, um davor zu warnen.
11. **Kotlin-Brücke oder Dart-Bindings.** Reichen die offiziellen Dart/Flutter-Bindings von sherpa-onnx [62][63] für Streaming-Erkennung, Modellpfade aus Play Asset Delivery und den Vordergrunddienst, oder braucht es die Kotlin-Brücke aus D1 (b)? Entscheidet Spike S2/S8 in `09-roadmap.md`; davon hängt der Aufwand von Phase 3 ab (Abschnitt 8.1).
12. **Abgleich mit `09-roadmap.md`.** Die Schnittlinie dort (Abschnitt 2.2) nennt Monatszahlen noch als Teil von Paket 5 und Paket 7 ohne Automatik; nach diesem Dokument sind Monatszahlen 1.1 und Paket 7 umfasst Ordnerwahl, Automatik, Wiederherstellungstest und Backup-Stand auf "Heute". Beide Dokumente sind auf denselben Stand zu bringen.
13. **Verifikation.** Die Faktenprüfung (verifikation.json) lag bei Redaktionsschluss nicht vor; alle als unverifiziert gekennzeichneten Angaben sind vor Veröffentlichung zu prüfen (D15).

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
56. Apple, `AVAudioEngine.inputNode` (watchOS 4.0+, Aufnahme-Tap im Speicher): https://developer.apple.com/documentation/avfaudio/avaudioengine/inputnode
57. libsodium, Sealed Boxes (`crypto_box_seal`, ephemeres Schlüsselpaar): https://github.com/jedisct1/libsodium-doc/blob/master/public-key_cryptography/sealed_boxes.md
58. Android, Wear OS Data Layer, Überblick (Google Play services, Bluetooth oder Google Cloud, "may at some point use Google-owned servers"): https://developer.android.com/training/wearables/data/overview
59. Easy Diary, Issue #233 (Wunsch nach automatischem, verschlüsseltem Backup: "restorable if I lose/damage the phone"), ergänzend #230 und #234: https://github.com/hanjoongcho/aaf-easydiary/issues/233 ; https://github.com/hanjoongcho/aaf-easydiary/issues/230 ; https://github.com/hanjoongcho/aaf-easydiary/issues/234
60. Android, Storage Access Framework (`ACTION_OPEN_DOCUMENT_TREE`, `ACTION_CREATE_DOCUMENT`, dauerhafte URI-Berechtigung): https://developer.android.com/training/data-storage/shared/documents-files
61. Apple, `UIDocumentPickerViewController` (Ordner- und Dateiauswahl in der Dateien-App): https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller
62. sherpa-onnx, README (Bindings u. a. für Dart und Flutter, Plattformen Android und iOS; laut verifikation.json belegt): https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/master/README.md
63. pub.dev, Paket `sherpa_onnx` 1.13.7 (Angabe aus dem Recherchebericht Technik-Stack; pub.dev selbst war in der Verifikation nicht Gegenstand): https://pub.dev/packages/sherpa_onnx
