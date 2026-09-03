# 09 · Roadmap

Stand: 3. September 2026 · Status: Entwurf

Dieses Dokument ordnet die Arbeit vom ersten technischen Versuch bis zum Store-Start. Es nennt Reihenfolge, Ziele, Ergebnisse und Prüfkriterien je Phase, Aufwandsklassen mit Stundenschätzung, eine Kapazitätsannahme mit daraus abgeleitetem Zielmonat für Version 1.0 und eine Schnittlinie für Phase 3 (Abschnitt 2). Feste Kalenderdaten gibt es erst nach Phase 1, wenn die Spikes die Rückfallfragen beantwortet haben. Es setzt `00-anforderungen.md` und die verbindlichen Entscheidungen D1 bis D15 um; die Feature-Stufen stammen aus `03-produktkonzept.md` (Abschnitt 8), die Teststrategie aus `04-technik-architektur.md` (Abschnitt 11), die Rechtspflichten aus `05-sicherheit-und-datenschutz.md`, der Transfer aus `06-geraetewechsel-qr-transfer.md`, der Marktstart aus `07-geschaeftsmodell.md` (Abschnitt 7). Preise stehen nur dort. Der Name ist offen (D11); hier heißt es "die App".

## 1. Leitgedanken der Reihenfolge

1. **Unsicherheit zuerst abbauen.** Die drei Kernversprechen (lokale Transkription auf beiden Plattformen, Verschlüsselung ohne Klartext auf der Platte, Gerätewechsel ohne Cloud) hängen an Annahmen, die keine Recherche ersetzen kann: Apple dokumentiert weder die Hardware-Untergrenze noch eine statische Sprachliste von `SpeechTranscriber` [2][3]; die Faktenprüfung bestätigt die Forumsberichte zu iPhone 11 und SE 2 und fand de-DE, de-AT und de-CH in einer zur Laufzeit abgefragten `supportedLocales`-Liste, deren Inhalt sich über die iOS-26.x-Versionen änderte (Einträge 2 und 3) [67], für Moonshine Small fehlen belastbare Android-Laufzeitzahlen [7], und ob Play Asset Delivery ohne `INTERNET`-Berechtigung funktioniert, weiß niemand [10]. Deshalb kommen die Spikes vor jeder Oberfläche.
2. **Jede Phase endet mit einem Nachweis, nicht mit einem Gefühl.** Der Flugmodus-Test aus `04-technik-architektur.md` läuft ab dem ersten durchgehenden Prototyp bei jedem Phasenabschluss.
3. **Rückfalloptionen sind Teil des Plans.** D1 nennt zweimal nativ als zweite Wahl, D2 den `DictationTranscriber`, D3 den System-Recognizer. Die Roadmap definiert, an welcher Stelle und anhand welcher Zahl umgeschaltet wird.
4. **Ein Entwickler, kein Team.** Aufwandsklassen sind eigene Schätzungen für eine Person mit Flutter- und etwas Swift/Kotlin-Erfahrung: **S** = wenige Tage, **M** = ein bis drei Wochen, **L** = ein bis zwei Monate, **XL** = mehr als zwei Monate. Umrechnung in Stunden als Setzung, identisch mit `07-geschaeftsmodell.md` 4.6: ein Personenmonat = 160 Stunden; S = 40, M = 40 bis 120, L = 160 bis 320, XL = 480 bis 640 Stunden. Die Klassen sind Reihenfolge- und Größenhinweise, keine Zusagen; die Stundensumme in Abschnitt 2 ist eine eigene Rechnung ohne externe Quelle.

## 2. Phasen im Überblick

| Phase | Ziel | Ergebnis | Aufwand | Stunden (Schätzung) |
|---|---|---|---|---|
| 0 Vorbereitung | Entscheidungen des Inhabers, Konten, Geräte, Repository | Beschlossene Punkte aus Abschnitt 13; Testgerätepool; öffentliches Repository mit Konzeptdokumenten | S | 40 |
| 1 Technische Spikes | Kernannahmen auf echten Geräten prüfen | Messprotokolle, Go/No-go je Spike, ggf. Umschalten auf Rückfalloptionen | L | 160 bis 320 |
| 2 Durchstich | Ein Eintrag von Aufnahme bis Wiedergabe, verschlüsselt, auf beiden Plattformen | Lauffähiger Prototyp ohne Feinschliff; erster bestandener Flugmodus-Test | M | 40 bis 120 |
| 3 MVP-Aufbau | Funktionsumfang nach `03-produktkonzept.md` 8.1 | Feature-vollständige App in Deutsch und Englisch | XL | 480 bis 640 |
| 4 Härtung und interne Alpha | Teststrategie vollständig, Sicherheits-Selbstprüfung, CI mit reproduzierbarem Android-Build | Alpha-Build; Threat-Model und Netzwerk-Null-Nachweis veröffentlicht | L | 160 bis 320 |
| 5 Beta | TestFlight und Play Closed Testing mit der Privacy-Community | Behobene Blocker, bestätigte Erinnerungs- und Transfer-Zuverlässigkeit, erste Rezensenten | M bis L | 40 bis 320 |
| 6 Store-Vorbereitung | Listings, Labels, Rechtstexte, Barrierefreiheit, Exportkontrolle | Eingereichte Builds, Launch-Checkliste abgehakt | M | 40 bis 120 |
| 7 Start und erste Wochen | Gestaffelte Freigabe, Reaktion ohne Telemetrie | Version 1.0 in beiden Stores; F-Droid eingereicht | S bis M | 40 bis 120 |
| 8 Nach dem Start | Version 1.x nach `03-produktkonzept.md` 8.2 | Eine Geste zum Aufnehmen, Plus-Funktionen, lokale Rückblicke | fortlaufend | nicht enthalten |
| **Summe bis Version 1.0** | | | | **1.000 bis 2.000 Stunden (6,25 bis 12,5 Personenmonate)** |

Die Summe ist eine eigene Rechnung aus den Klassen oben (Minimal- und Maximalwerte addiert); `07-geschaeftsmodell.md` 4.6 rundet dieselbe Rechnung auf 6 bis 13 Personenmonate. Pflege nach dem Start (jährliche Betriebssystem-Versionen, Modellwechsel, 1.x) ist nicht enthalten. Wartezeiten, die keine Arbeitszeit kosten (DSA-Verifizierung, Beta-App-Review, Store-Review, Angebote für den Krypto-Review), verlängern den Kalender zusätzlich; deshalb beginnt die Checkliste aus Abschnitt 9 schon in Phase 4.

### 2.1 Kapazitätsannahme und Zielmonat

Die Roadmap rechnet mit **einer Person in Vollzeit, 160 Stunden pro Monat** (Setzung, dieselbe wie in `07-geschaeftsmodell.md` 4.6). Daraus folgt:

| Kapazität | Stunden pro Monat | Dauer bis 1.0 bei 1.000 bis 2.000 Stunden | Planungswert (eigene Setzung) |
|---|---|---|---|
| Vollzeit | 160 | 6,25 bis 12,5 Monate | **12 Monate**: Mitte der Spanne (rund 1.500 Stunden, 9,5 Monate) plus Reserve für einen ausgelösten Rückfall in Phase 1 und eine zweite Beta-Runde |
| Teilzeit stark, 30 Stunden/Woche | 130 | 7,7 bis 15,4 Monate | 15 Monate |
| Teilzeit schwach, 15 Stunden/Woche | 65 | 15,4 bis 30,8 Monate | über zwei Jahre |

**Zielmonat:** Version 1.0 in beiden Stores **zwölf Monate nach Beginn von Phase 0**; bei Beginn im Oktober 2026 (Setzung) also Herbst 2027. Bei 15 Stunden pro Woche verschiebt sich 1.0 auf 2028 oder später und das Zeitfenster aus `01-markt-und-wettbewerb.md` Abschnitt 8 (Android-Lücke bei lokaler Deutsch-Transkription, mögliche Google-Journal-App) ist mit hoher Wahrscheinlichkeit zu. Auf iOS ist es bereits enger geworden: DailyVox (kostenlos, MIT) hat im August 2026 Deutsch hinzugefügt und den Cloud-Fallback entfernt, ist also dort ein kostenloser, deutschsprachiger, vollständig lokaler Wettbewerber; eine Android-Version gibt es nicht, die Nachfrage danach ist dokumentiert (Issue #4 vom 3. August 2026) [66][71]. Das offene Fenster ist damit vor allem Android; auf iOS zählen Verschlüsselung, Backup und QR-Gerätewechsel, Erinnerungslogik und Produktreife (Abschnitt 12). Empfehlung: Vollzeit oder mindestens 30 Stunden pro Woche zusagen, sonst den Zielmonat in Abschnitt 13 (Punkt 10) bewusst neu setzen und den Funktionsumfang nach Abschnitt 2.2 von Anfang an kürzen. Der Zielmonat wird am Ende von Phase 1 einmal überprüft und danach nur noch über die Schnittlinie gehalten, nicht über längere Arbeitstage.

### 2.2 Schnittlinie für Phase 3

Phase 3 hat ein Budget von 480 bis 640 Stunden (drei bis vier Vollzeitmonate) für 14 Arbeitspakete plus ein bedingtes (Abschnitt 6). **Kontrollpunkt nach drei Monaten (480 Stunden):** Sind bis dahin die Pakete 1 bis 8 (Aufnahme, Erinnerung, Sperre, Transkript, Suche, Audio-Verwaltung, Backup, Gerätewechsel) nicht fertig und getestet, entfallen für Version 1.0 in dieser Reihenfolge, bis das Restbudget reicht:

1. Paket 14, Kaufgerüst: Plus kommt mit 1.1 (Alternative aus Abschnitt 13, Punkt 4; Beta-Tester erhalten ihre Codes nachträglich).
2. PDF-Export aus Paket 9: Markdown und JSON bleiben, weil sie die Lock-in-Freiheit sichern; PDF folgt in 1.1.
3. "Vor einem Jahr" und Monatszahlen aus Paket 5: Volltextsuche und Kalender bleiben.
4. "Pause bis Datum" und Wochentagsauswahl aus Paket 2: die tägliche Erinnerung mit "In 1 Stunde" und "Heute nicht" bleibt (D7).

Nicht kürzbar sind die Pakete 1 bis 4, 6 bis 8 und 10 bis 13, weil sie die Erfolgskriterien aus `00-anforderungen.md` Abschnitt 5, die Kernversprechen aus D9, D14 und die Barrierefreiheit tragen. Alles Gestrichene bleibt kostenlos und rückt an den Anfang von Phase 8; die Garantie aus D9 ist davon nicht berührt. **Harte Grenze:** Sind nach vier Monaten (640 Stunden) die Pakete 1 bis 8 immer noch nicht fertig, ist das kein Planungs-, sondern ein Architekturproblem (Brücken, Engine, Krypto-Durchsatz); dann entscheidet der Inhaber über Verlängerung mit neuem Zielmonat oder über die Rückfalloption aus D1, nicht die Roadmap. `03-produktkonzept.md` 8.1 sollte die vier kürzbaren Funktionen als "1.0-Reserve" kennzeichnen.

## 3. Phase 0: Vorbereitung

**Ziel:** Alles, was nicht Code ist und den Code blockiert.

1. Entscheidungen aus Abschnitt 13 treffen (mindestens Name, Lizenz, Rechtsform, Plus-Zeitpunkt).
2. Entwicklerkonten anlegen: Apple Developer Program (99 $/Jahr) und Google Play (einmalig 25 $) [41]; Apple Small Business Program beantragen (15 % Abgabe bis 1 Mio. $ Vorjahreserlös) [41]. Bei Google Play Konto früh anlegen, weil neue persönliche Konten vor der Produktionsfreigabe einen geschlossenen Test mit einer Mindestzahl von Testern über einen Mindestzeitraum nachweisen müssen (Play-Console-Hilfe, in der Sandbox nicht erreichbar; Bedingung und Zahlen unverifiziert) [50].
3. Testgerätepool beschaffen. Empfehlung: ein iPhone 12 oder neuer (16-Kern-Neural-Engine, `SpeechTranscriber`-Pfad) und ein iPhone 11 oder SE 2 (Fallback `DictationTranscriber`; Forumsbefunde, durch die Faktenprüfung bestätigt, von Apple weiterhin nicht dokumentiert, Eintrag 3) [2][6][67]; auf Android ein Pixel (Referenz), ein Samsung-Mittelklassegerät mit 4 GB RAM (Richtwert D13, Akku-Killer-Rangliste Platz 4) und ein Xiaomi (Platz 2) [15]. Ohne diese Geräte sind Spike 1, 2 und 7 nicht aussagekräftig.
4. Repository `tagebuch` öffentlich, Konzeptdokumente 00 bis 09, Lizenzdatei nach D10, Issue-Vorlagen, `SECURITY.md` mit Meldeweg.

**Prüfkriterium:** Alle Punkte aus Abschnitt 13 haben eine Antwort oder ein bewusstes "später mit Datum".

## 4. Phase 1: Technische Spikes

Jeder Spike ist ein kleines, wegwerfbares Projekt mit einer Messfrage, einem Zielwert und einer Rückfallregel. Ergebnisse landen als Tabelle in `docs/recherche/spikes/` mit Gerät, OS-Version, Build-Hash und Datum. Die Reihenfolge folgt dem Risiko: Was das Produktversprechen kippen könnte, kommt zuerst.

| Nr. | Spike | Messfrage | Zielwert | Rückfall, wenn verfehlt | Aufwand |
|---|---|---|---|---|---|
| S1 | iOS-Transkription (D2) | Liefert `SpeechTranscriber` auf iOS 26 für de-DE, de-AT, de-CH und en-* nutzbaren Text? Ist `supportedLocales` verlässlich? Wie verhält sich `AssetInventory` beim Erstdownload und nach Wochen Nichtnutzung? | Je Locale ein Validierungslauf mit 3 Minuten Tagebuch-Audio, wie von Apple selbst empfohlen, statt der API zu vertrauen (Apple listete Arabisch fälschlich als unterstützt; die Liste war über iOS-26.x-Versionen nicht stabil, Faktenprüfung Eintrag 2) [3][67]; kein Locale-Format-Fehler dank `supportedLocale(equivalentTo:)` [4]; Assets nach Entzug automatisch neu anforderbar; Modelle liegen im Systemspeicher, nicht in der App [5][46]; im selben Lauf prüfen: Komposita und Bindestriche (Apples Diktat trennt deutsche Komposita und setzt Leerzeichen um Bindestriche, Mai 2026) [66][72] sowie `audioTimeRange`-Wortzeitstempel für den mitlaufenden Text (D4) [65] | `DictationTranscriber` mit `.longDictation` als Primärpfad auf betroffenen Locales [6]; falls auch der versagt: WhisperKit large-v3-v20240930 (626 MB, laut Gerätematrix erst ab A15/iPhone 13, Faktenprüfung Eintrag 5) [67] als Standard statt Zusatzpaket (D2) | M |
| S2 | Android-Transkription (D3) | Läuft sherpa-onnx mit Moonshine German/English Small Streaming auf dem 4-GB-Samsung? Tatsächliche `.ort`-Dateigrößen, Spitzen-RAM, Echtzeitfaktor (RTF). Zusätzlich die Qualität bei **spontaner Sprache**: Die 7,5 % WER von Moonshine German Small sind auf FLEURS + MLS gemessen [7][64], also auf vorgelesener, sauberer Sprache (eigene Einordnung der Testsets); für Abendsprache im Wohnzimmer mit Füllwörtern, Nebengeräuschen und österreichischer oder schweizerischer Färbung gibt es keine veröffentlichte Zahl, und ob Moonshine Interpunktion und Groß-/Kleinschreibung liefert, ist unbekannt; Wort-Zeitstempel liefert Moonshine nicht (Codebefund sherpa-onnx), weshalb der mitlaufende Text auf Android im MVP aus VAD-Segmentgrenzen kommt (D3, D4) [65]. Deshalb Messung an einem **Mini-Korpus**: 10 Sprecher × 3 Minuten spontane Tagebuchsprache (kein Ablesen), darunter mindestens je zwei aus AT und CH in Hochdeutsch, Handy-Mikrofon, Zimmerakustik, mit schriftlicher Einwilligung; Referenz manuell transkribiert. Der Korpus wird in Phase 4 zum Regressionskorpus ausgebaut | RTF ≤ 0,5 auf einem Snapdragon-6/7-Gerät (Zielwert aus dem Android-Bericht, keine öffentlichen Messungen vorhanden) [7][9]; kein Absturz durch die neuen RAM-Limits von Android 17 [60]; **WER ≤ 12 % auf dem Mini-Korpus** (Setzung: die Marke, bei der die Moonshine-Dokumentation selbst nur noch das Tiny-Modell ansiedelt [7]) und **Interpunktion sowie Groß-/Kleinschreibung** im Ergebnis vorhanden oder mit Paket 15 aus Abschnitt 6 erreichbar; VAD-Segmentgrenzen als Zeitstempel für den mitlaufenden Text brauchbar (Abweichung zum Audio unter einer Sekunde, Setzung) | Entscheidungsbaum, Ergebnis vor Phase 3: (a) alle Schwellen bestanden: Moonshine Small bleibt Standard (D3). (b) nur RTF verfehlt: Moonshine German Tiny Streaming (34 M, 12,0 % auf FLEURS + MLS) [7] auf schwachen Geräten, sofern Tiny die WER-Schwelle auf dem Korpus ebenfalls hält, sonst (c). (c) WER verfehlt: Entscheidung des Inhabers (Abschnitt 13, Punkt 9) zwischen Parakeet TDT 0.6B v3 int8 als Standard (≈ 640 MB [8]; eine einzelne, unbestätigte Nutzermessung nennt 1,23 GB RAM beim Laden auf iOS [62]) mit Anhebung des Android-Richtwerts aus D13 von 4 auf 6 GB und Verzicht auf die Erzählung "kleines Modell", oder System-Recognizer als Opt-in mit Hinweis (D3) bei 4 GB. (d) keine Interpunktion oder Kasus: Paket 15 in Phase 3 wird aktiv. In jedem Fall gilt: Store-Formulierungen zur Deutsch-Qualität erst nach dieser Messung (Abschnitt 9) | M; der Korpus mit Referenztranskripten kostet etwa eine zusätzliche Woche (Setzung) |
| S3 | Modellauslieferung und Bezahlung ohne `INTERNET` (D3, D14) | Funktionieren Play Asset Delivery (`fast-follow`, `on-demand`) und die Play Billing Library, wenn die App keine `INTERNET`-Berechtigung deklariert? | Modelle kommen an, Kauf lässt sich abschließen; `dumpsys package` zeigt keine `INTERNET`-Berechtigung [10] | Modelle im APK/AAB bündeln (Größe prüfen) oder Berechtigung bewusst aufnehmen und auf der Transparenzseite erklären; Entscheidung an Inhaber | S |
| S4 | Verschlüsselung und Schlüsselverwahrung (D4, D5) | Durchsatz der chunkweisen AEAD nach Cryptomator-Muster (32-KiB-Chunks, je Chunk Nonce und Auth-Tag, AAD = Chunk-Nummer + Kopf-Nonce, Dateischlüssel im Kopf mit dem Master-Key gewrappt; XChaCha20-Poly1305 über libsodium oder AES-256-GCM) aus Dart bzw. den Brücken während der Aufnahme [65][68]; **Seek-Test:** wahlfreier Zugriff auf Chunk n = Position/32768 ohne Entschlüsselung der Vorgänger, vertauschte oder abgeschnittene Chunks werden erkannt; Argon2id 64 MiB/t=3 auf dem 4-GB-Gerät; nutzt `flutter_secure_storage` 11 StrongBox oder nur TEE; überlebt der iOS-Keychain-Eintrag eine Deinstallation; SQLCipher via `sqlite3` mit `source: sqlcipher` und Raw-Key. `secretstream` wird hier nicht mehr gemessen, es bleibt dem Transfer-Container vorbehalten (S5, D6) | Verschlüsselung hält mit der Aufnahme mit, kein Klartext-Audio im Sandbox-Verzeichnis (Scan nach M4A-`ftyp`- und WAV-Magic-Bytes); Sprung an eine beliebige Position in einer 30-Minuten-Aufnahme unter 200 ms (Setzung); Argon2id unter einer Sekunde (libsodium nennt eine Sekunde als akzeptables Maximum) [16][17][18][19][20]; Keystore-Schutzstufe protokolliert [21] | Bei fehlender StrongBox-Anbindung eigene Kotlin-Brücke (D1 c); bei zu langsamer Ableitung Parameter im Rahmen der OWASP-Äquivalente senken (dokumentieren) [17]; ist die Dart-AEAD zu langsam, Chunk-Verschlüsselung in die Brücken verlagern (CryptoKit bzw. `javax.crypto` mit Keystore-Schlüssel) [65] | M |
| S5 | Transfer und Container (D6) | Round-Trip Export/Import iOS→Android und Android→iOS mit Testdaten von rund 263 MB (ein Jahr AAC-LC 32 kbit/s bei 3 Minuten täglich, Rechenbasis D4/D6) und zusätzlich 131 MB (späterer Opus-Pfad); Durchsatz von `crypto_secretstream_xchacha20poly1305` in 64-KiB-Chunks aus Dart beim Packen und Entpacken; QR unter 200 Byte lesbar (ein QR fasst höchstens 2953 Byte) [45]; HKDF im Dart-Paket `sodium` vorhanden; Übergabe per Dateien-App, AirDrop, Quick Share, USB-Stick | Gesamtzeit unter fünf Minuten je Weg (Erfolgskriterium `00-anforderungen.md`); Abschneiden und Umsortieren werden erkannt [16] | Fehlt HKDF: `crypto_kx` mit BLAKE2b (siehe `06-geraetewechsel-qr-transfer.md`); dauert die Übergabe zu lang: Container in Teile splitten | M |
| S6 | Audio-Pipeline und Wiedergabe (D4) | PCM-Stream aus `record` 7.x (bzw. AVAudioEngine/AudioRecord) parallel in STT-Puffer und AAC-LC-Encoder (M4A, mono, 24 kHz); **Hörtest** 24, 32 und 48 kbit/s mit Tagebuchsprache, dazu Vergleich der erneuten Transkription aus der gespeicherten Datei; Wellenform (100 Pegelwerte) bei der Aufnahme berechnen; Verhalten bei Anruf, Sperre, App-Kill, 30 Minuten Dauer, insbesondere ob die M4A-Datei nach App-Kill lesbar bleibt; **Wiedergabe aus verschlüsselten Chunks:** Android Media3/ExoPlayer mit eigener `DataSource` in einem `MediaSessionService` (Android-17-Hintergrundaudio-Regeln, Test mit `adb shell cmd audio set-enable-hardening throw`), iOS AVAudioEngine/AVAudioPlayerNode mit Dekodierung über `AudioFileOpenWithCallbacks`/`AVAudioConverter`; Sperrbildschirm-Steuerung, Geschwindigkeit 0,8 bis 2,0 [65][69][75] | Keine verlorene Aufnahme in allen Abbruchfällen (Vorbild negativ: `FileNotFoundException` nach langer Aufnahme im Fossify Voice Recorder) [44]; Bitrate im Bereich 24 bis 48 kbit/s entschieden (Vorgabe 32 kbit/s wie Signal-Sprachnachrichten [76]); Wiedergabe startet und springt ohne Klartext-Tempdatei, auch bei ausgeschaltetem Bildschirm | Bei Problemen mit `record` native Aufnahme in den Brücken; Ogg/Opus ist kein Rückfall, sondern die spätere Speicher-Optimierung (Phase 8), weil iOS Opus nur in CAF schreibt, Ogg nicht abspielt und die Bitrate nicht steuern lässt [65][70] | M (Aufnahme S, Wiedergabepfad S) |
| S7 | Erinnerungen Android (D7) | `setAlarmClock()` mit und ohne `SCHEDULE_EXACT_ALARM`, `setWindow()`-Fallback, Neustart, Doze (`force-idle`), Samsung- und Xiaomi-Akkuoptimierung | Erinnerung kommt an allen drei Android-Geräten an drei aufeinanderfolgenden Tagen ohne manuellen Eingriff nach dem Onboarding-Schritt [14][15] | Onboarding-Hinweise verschärfen; `USE_EXACT_ALARM` nur nach Klärung der Play-Policy | S |
| S8 | Größe der nativen Brücken (D1) | Wie viel Swift und Kotlin braucht es tatsächlich für S1, S2 und S4? | Brücken bleiben dünne Adapter ohne eigene Geschäftslogik | Übersteigen sie das Maß eines Plugins, greift die Rückfalloption zweimal nativ (D1); Entscheidung vor Phase 3 | wird aus S1, S2, S4 abgeleitet |

Parallel zu den Spikes: Lizenzprüfung der Modelle (Parakeet TDT 0.6B v3: CC-BY-4.0 laut NVIDIA, Modellkarte in der Sandbox nicht erreichbar; Moonshine Streaming: MIT) [7][8] und die Exportkontroll-Einordnung, weil libsodium und SQLCipher keine Betriebssystem-Kryptografie sind (Apples Tabelle: Industriestandard, nicht vom OS bereitgestellt, erfordert die französische Deklaration bei Vertrieb in Frankreich; Jahresbericht an das BIS möglich, Frist unverifiziert) [29][30].

**Prüfkriterium Phase 1:** Für S1 bis S7 liegt ein Protokoll mit Messwert und Entscheidung vor. Kein Spike endet mit "funktioniert wahrscheinlich".

## 5. Phase 2: Durchstich

**Ziel:** Ein einziger Ablauf, der die gesamte Architektur berührt: Aufnahme starten, PCM in AAC-LC/M4A und chunkweise AEAD (D4), Transkription, Speichern in SQLCipher, Liste, Wiedergabe aus den verschlüsselten Chunks mit Sprung an eine beliebige Stelle, Text lesen. Keine Einstellungen, keine Erinnerung, keine Suche, rohe Oberfläche.

**Ergebnis:** Ein Build je Plattform, der den Flugmodus-Test aus `04-technik-architektur.md` (Schritte 1 bis 4, ohne Export) besteht, plus ein Lauf hinter mitmproxy mit null Verbindungen aus dem App-Prozess.

**Prüfkriterien:**
- Kein Klartext-Audio und keine unverschlüsselte Datenbank im Sandbox-Verzeichnis (Dateisystem-Scan).
- App-Kill während der Aufnahme verliert höchstens den letzten Chunk, nie den Eintrag.
- Öffnen mit falschem Schlüssel schlägt fehl.
- Wiedergabe springt an eine beliebige Position, ohne die Datei von vorn zu entschlüsseln (Ergebnis S4 im Produktcode bestätigt).

Empfehlung: Den Durchstich auf Flutter stable 3.47.x (D1) [1] und nicht wegwerfen, sondern als Rumpf der Paketstruktur aus `04-technik-architektur.md` bauen (Krypto- und Containerkern als separate Dart-Bibliothek nach D10), weil genau dieser Kern später auditierbar sein muss.

## 6. Phase 3: MVP-Aufbau

**Ziel:** Der Funktionsumfang aus `03-produktkonzept.md` 8.1, in dieser Reihenfolge (jede Zeile ist ein abschließbares Arbeitspaket mit eigenem Test):

1. Aufnahmebildschirm "Heute", Pause, Fertig, mehrere Aufnahmen pro Tag, Nachträge (M1, M3, A4); Testfall aus `07-geschaeftsmodell.md` 4.3: Hinweis bei 4:30, weicher Stopp bei 5:00 mit "Ergänzen", kein Audio wird verworfen.
2. Tägliche Erinnerung mit "In 1 Stunde", "Heute nicht", Pause bis Datum, Aufnahme aus der Benachrichtigung (D7).
3. App-Sperre, Privacy-Overlay, `FLAG_SECURE`, Benachrichtigungen ohne Inhalt (D5); Testfall: ein neu hinzugefügter Fingerabdruck oder ein geändertes Face ID darf nicht aussperren, der Gerätecode-Pfad muss den Master-Key weiterhin freigeben (Aussperrung nach Biometrie-Änderung ist eine belegte Store-Beschwerde) [66][73].
4. Transkriptanzeige, Bearbeiten mit Original, neu transkribieren, feste Sprachwahl (D12); Wiedergabe mit mitlaufendem Text (iOS wortgenau über `audioTimeRange`, Android segmentweise aus VAD-Grenzen, D3/D4), Wellenform, Geschwindigkeit 0,8 bis 2,0, Sperrbildschirm-Steuerung [65].
5. Volltextsuche (FTS5), Kalender, "Vor einem Jahr", Monatszahlen (D8).
6. Audio behalten oder löschen pro Eintrag und global, Speicheranzeige, Crypto-Shredding (D4, D5).
7. Backup-Container mit Passphrase, monatliche Erinnerung, Wiederherstellung im Onboarding (D6, A8); der Speicherort der Backup-Datei wird angezeigt und die Wiederherstellung einmal probeweise durchlaufen, weil unauffindbare Backup-Dateien und durch OS-Updates gebrochene Backups die häufigsten echten Play-Store-Beschwerden bei Tagebuch-Apps sind [66][73].
8. Gerätewechsel per QR und Datei in beide Richtungen, "Einträge hier löschen" danach (D6, M8).
9. Export Markdown, JSON, PDF, Audio als M4A mit Zeitraum; Exportvorschau vor dem ersten Eintrag.
10. Onboarding: Gerätecode-Prüfung, Modell-Download mit Wiederaufnahme (Negativbeispiel: Download startet nach Abbruch "from byte 0", Nutzer mussten die App minutenlang offen halten) [42], Erinnerungs-Zuverlässigkeit je Hersteller, Backup-Hinweis.
11. Transparenzseite "Was verlässt dein Gerät: nichts" mit Berechtigungsliste (D14).
12. Barrierefreiheit über den gesamten Fluss: VoiceOver/TalkBack, Schriftskalierung, Kontrast, Reduce Motion.
13. Lokalisierung Deutsch (mit Schweizer Orthografie für de-CH) und Englisch.
14. In-App-Kauf-Gerüst (StoreKit 2, Play Billing) für Plus, sofern der Inhaber Plus zum Start freigibt (Abschnitt 13, Punkt 4).
15. **Bedingt, Ergebnis S2:** Nachbearbeitung für Interpunktion und Groß-/Kleinschreibung auf Android, falls Moonshine sie nicht liefert. `03-produktkonzept.md` Abschnitt 6 kündigt diese Nachbearbeitung an, ohne sie als Komponente zu benennen; hier ist sie ein eigenes Paket: on-device, Deutsch und Englisch, nach der Erkennung und vor dem Speichern. Ob sherpa-onnx ein für Deutsch taugliches Interpunktionsmodell mitbringt, wurde in der Recherche nicht untersucht (Prüfpunkt in S2); ohne Modell bleibt ein regelbasierter Ansatz (Satzgrenzen aus Sprechpausen, Großschreibung am Satzanfang und über ein Substantivwörterbuch), der sichtbar schwächer ist. Aufwand M (Setzung). Zeigt S2, dass das Modell Interpunktion liefert, entfällt das Paket, und der Satz in `03-produktkonzept.md` ist zu streichen. Ob `SpeechTranscriber` auf iOS Interpunktion und Groß-/Kleinschreibung liefert, prüft S1 im selben Validierungslauf mit; nach heutigem Stand betrifft das Paket nur den Android-Pfad.

**Prüfkriterium:** Jedes Paket hat Unit- oder Integrationstests nach `04-technik-architektur.md` 11; die Erfolgskriterien aus `00-anforderungen.md` 5 sind im Flugmodus-Test nachweisbar (ein Tipp bis Aufnahme; Deutsch und Englisch offline; Eintrag nach Sperre nur mit Code/Biometrie; Gerätewechsel unter fünf Minuten).

Empfehlung: Migrationstests ab der ersten Datenbankversion, weil Datenverlust durch fehlgeschlagene Migration ein belegter Totalschaden bei Tagebuch-Apps ist ("lost access to the body copy of all entries made before the version 0.17 update") [43]. Jede Schemaänderung bekommt einen Vorwärts-Migrationstest mit einer echten Alt-Datenbank.

## 7. Phase 4: Härtung und interne Alpha

**Ziel:** Die App verhält sich unter widrigen Bedingungen wie versprochen, und das Versprechen ist öffentlich nachvollziehbar.

1. **Teststrategie vollständig** nach `04-technik-architektur.md` 11: STT-Regressionskorpus (de-DE, de-AT, de-CH, en; Freiwillige mit Einwilligung plus TTS-Sätze) mit WER, RTF und Spitzen-RAM je Engine und Gerät; Erinnerungstests mit Zeitzonenwechsel und Neustart; Sicherheitsfälle nach OWASP MASTG (App-Switcher-Snapshot leer, Screenshot geblockt, `adb backup` liefert nichts) [22][47][49]; Zugangsfälle: Biometrie-Änderung, Gerätecode-Änderung, Wiederherstellung aus dem Backup nach Neuinstallation [66][73]; Wiedergabe- und Seek-Tests über verschlüsselte Chunks auf allen Geräten, auf Android mit aktivem Hintergrundaudio-Hardening [69].
2. **Halluzinations-Schutz** prüfen: Stille-Abschnitte im Korpus dürfen keine Phantomsätze erzeugen (bekanntes Whisper-Muster "Untertitel im Auftrag des ZDF") [48][56]; Sprache ist fest gesetzt, weil Auto-Erkennung bei deutschem Audio zu Sprachwechseln und Auslassungen führt [55], VAD aktiv (D2, D3).
3. **CI ohne Datenabfluss** nach `04-technik-architektur.md` 10: Format, Analyse, Tests auf jedem Pull Request; reproduzierbarer Android-Build im Docker-Image mit `apkdiff` nach dem Signal-Muster [37]; iOS-Reproduzierbarkeit ist praktisch nicht erreichbar und wird nicht versprochen [38].
4. **Sicherheitsdokumente veröffentlichen:** Threat-Model (aus `05-sicherheit-und-datenschutz.md`), Datenflussdiagramm, Liste ausgehender Verbindungen (Ziel: null außer OS- und Store-Downloads), Flugmodus-Protokolle.
5. **Fehlermeldung ohne Crash-Reporter:** Die App schreibt Fehler nur lokal; "Problem melden" erzeugt eine Diagnosedatei ohne Tagebuchinhalt, die der Nutzer selbst per Mail sendet. Kein automatischer Upload (D14).
6. **Interne Alpha** auf dem Testgerätepool mit täglicher eigener Nutzung über mindestens zwei Wochen (eigene Festlegung), damit Erinnerung, Sperre und Speicherwachstum im Alltag auffallen.

**Prüfkriterium:** Flugmodus-Test auf iPhone, Pixel und Samsung bestanden und in `docs/` abgelegt; keine offenen Blocker der Kategorien Datenverlust, Klartext, Absturz bei Aufnahme.

Empfehlung: Vor der Beta einen bezahlten Kurz-Review des Krypto- und Containerkerns einholen (Schlüsselhierarchie, Chunk-AEAD-Dateiformat nach Cryptomator-Muster, secretstream-Nutzung im Transfer-Container, HKDF-Ableitung, Argon2id-Parameter), weil der Kern klein und separat ist und weil das Argument "wir können deine Einträge nicht lesen" später gegen Kritik bestehen muss. Umfang und Budget entscheidet der Inhaber (Abschnitt 13).

## 8. Phase 5: Beta

**Ziel:** Bestätigung durch Fremde auf Geräten, die der Entwickler nicht besitzt, ohne Telemetrie.

### 8.1 Kanäle

| Plattform | Stufe | Zweck |
|---|---|---|
| iOS | TestFlight intern (Team) [51] | Build-Pipeline, Signatur, Exportkontroll-Frage einmal durchspielen |
| iOS | TestFlight extern mit Beta-App-Review | 50 bis 100 Personen aus der Privacy-Community (Plan aus `07-geschaeftsmodell.md` 7.1) |
| Android | Play Internal Testing | Play-Asset-Delivery-Pfad und Billing unter Store-Bedingungen (S3 bestätigen) |
| Android | Play Closed Testing | Dieselbe Gruppe; erfüllt zugleich die Testpflicht neuer Konten (unverifiziert) [50] |
| Android | Direktes APK aus dem CI-Build | Für GrapheneOS- und Custom-ROM-Tester ohne Play-Dienste; prüft den Hinweis "Keystore nicht hardwaregestützt" (D5) |

Tester erhalten nach dem Start Lifetime per Offer Code (Offer Codes gelten seit 29. Oktober 2025 für alle Kauftypen) [40]; das setzt ein vorhandenes Plus-Produkt voraus (Abschnitt 13, Punkt 4).

### 8.2 Was die Beta beantworten muss

1. Kommt die Erinnerung auf fremden Samsung-, Xiaomi-, OnePlus- und Huawei-Geräten an? Abfrage per kurzem Formular nach einer Woche; Ziel: kein Hersteller, auf dem sie ohne Hinweis dauerhaft ausbleibt.
2. Gelingt der Gerätewechsel iOS↔Android bei Testern ohne Anleitung durch den Entwickler? Ziel: unter fünf Minuten, Fehlerfälle dokumentiert.
3. Ist die Transkription für Schweizer Tester mit Hochdeutsch brauchbar, und ist der Hinweis zur Mundart verständlich (D12)?
4. Werden Modell-Download und Backup-Hinweis im Onboarding verstanden, und finden Tester ihre Backup-Datei ohne Hilfe wieder? Beobachtung: Bricht jemand vor dem ersten Eintrag ab?
5. Barrierefreiheit: mindestens zwei Tester, die VoiceOver oder TalkBack dauerhaft nutzen, durchlaufen Aufnahme, Wiedergabe, Suche und Export.
6. Speicherwachstum und Akku über zwei Wochen täglicher Nutzung: Rückmeldung per Speicheranzeige der App (Erwartung bei 3 Minuten täglich: rund 0,72 MB pro Tag, D4).
7. Reicht der segmentweise mitlaufende Text auf Android, oder erwarten Tester Wortgenauigkeit wie auf iOS (D3)?

Weil die App keine Nutzungsdaten sendet, sind alle Antworten freiwillig und kommen per Formular, Mail oder Issue. Das ist langsamer als Telemetrie und gehört so kommuniziert.

### 8.3 Ausstiegskriterien

- Kein Datenverlust-Bericht in den letzten zwei Beta-Wochen.
- Flugmodus-Test auf mindestens drei fremden Gerätemodellen von Testern bestätigt (Screenshot der Transparenzseite plus Aussage genügt).
- Alle Fehler der Klasse "Aufnahme verloren", "Eintrag nicht lesbar", "Transfer schlägt reproduzierbar fehl" geschlossen.
- Onboarding-Abbruchgründe bekannt und behoben oder bewusst akzeptiert.

Aufwand: M bis L, je nachdem, wie viele Runden nötig sind. Empfehlung: zwei Runden einplanen, die zweite kürzer.

## 9. Phase 6: Store-Vorbereitung und Launch-Checkliste

Die Checkliste fasst `05-sicherheit-und-datenschutz.md` (Rechtspflichten) und die Store-Anforderungen zusammen. Einträge mit "unverifiziert" beruhen auf Quellen, die in der Recherche-Sandbox nicht erreichbar waren (D15); die Faktenprüfung (`docs/recherche/verifikation.json`, 30 Aussagen, 18 bestätigt, 12 präzisiert) deckt technische Aussagen ab, keine Rechts- und Store-Richtlinien, deshalb bleibt die Kennzeichnung dort bestehen [67].

**Store-Labels und Datenschutz**
- [ ] Apple App Privacy: "Es werden keine Daten erfasst". Apples Definition zählt nur Daten als erfasst, die das Gerät verlassen und für den Entwickler oder Partner zugänglich sind; rein lokal verarbeitete Daten müssen nicht angegeben werden [23]. Vorher prüfen, dass kein SDK etwas sendet (Flugmodus-Protokoll).
- [ ] Google Play Data Safety: "Keine Daten erhoben"; Datentyp "Sprach- oder Tonaufnahmen" bewusst als nicht erhoben begründen [32][33] (Play-Definition unverifiziert).
- [ ] Datenschutzerklärung als URL im Store und in der App erreichbar (Apple 5.1.1 verlangt sie für alle Apps, inklusive Aufbewahrung und Löschung) [24]; Kerntext aus `05-sicherheit-und-datenschutz.md`.
- [ ] `PrivacyInfo.xcprivacy` mit Required-Reason-Codes für Dateizeitstempel, UserDefaults, Speicherplatz und Systemzeit, je nach Nutzung [25].
- [ ] `NSMicrophoneUsageDescription` in Deutsch und Englisch nach der Formulierungshilfe; `NSSpeechRecognitionUsageDescription` nur, wenn `SFSpeechRecognizer` im Fallback wirklich genutzt wird [26]. Sichtbare Aufnahmeanzeige (Apple 2.5.14) [24].
- [ ] Android: `RECORD_AUDIO` im Kontext anfragen; Vordergrunddienst-Typ `microphone` in der Play Console deklarieren [13]; keine `INTERNET`-Berechtigung (Ergebnis S3).
- [ ] Health-App-Deklaration bei Google prüfen; Empfehlung: keine Health-Connect-Integration in Version 1, keine Gesundheitsaussagen (unverifiziert) [34].

**Rechtliches**
- [ ] Impressum in der App (Einstellungen > Rechtliches) nach § 5 DDG bzw. § 5 ECG; aktuelle Fassung unverifiziert [36].
- [ ] DSA-Händlerstatus bei Apple und Google mit verifizierter Adresse, Telefon und E-Mail; Apple veröffentlicht sie in allen EU-Storefronts [31]. Vor dem ersten Kauf zwingend; Empfehlung: schon zum Start, damit Offer Codes funktionieren.
- [ ] Exportkontrolle: Frage in App Store Connect beantworten; `ITSAppUsesNonExemptEncryption` korrekt setzen; bei gebündeltem libsodium/SQLCipher französische Deklaration bereitlegen; Jahresbericht an das BIS prüfen (Frist unverifiziert) [29][30].
- [ ] Altersfreigabe: Apple-Fragebogen (Stufen 4+, 9+, 13+, 16+, 18+; seit September 2026 mit Fragen zu Social-Media-Funktionen) und IARC bei Google; reines Tagebuch ohne Empfehlungen bleibt 4+ [27][35]. Zielgruppe nicht "Kinder".
- [ ] Open-Source-Lizenzhinweise in der App: MIT (Moonshine, whisper-Komponenten, falls genutzt), Apache-2.0 mit NOTICE (sherpa-onnx), CC-BY (Parakeet, falls Zusatzpaket) [8]; keine Schweizerdeutsch-Fine-Tunes, weil die verfügbaren Whisper-Modelle nur unter CC-BY-NC-4.0 stehen und kommerziell nicht nutzbar sind [66][74].
- [ ] Abgrenzungssatz "kein Medizinprodukt" in Store-Text und Nutzungsbedingungen; keine der vermiedenen Formulierungen ("erkennt Stress", "militärische Verschlüsselung").
- [ ] Freischaltung nur über In-App-Kauf; der Transfer-QR schaltet nichts frei (Apple 3.1.1) [24].

**Listing und Material**
- [ ] Store-Seiten Deutsch (DE, AT, CH) und Englisch; Keyword-Hypothesen aus `07-geschaeftsmodell.md` 7.2.
- [ ] Screenshots je Gerätetyp: Aufnahme mit einem Tipp, Transkript, Kalender, Transparenzseite "Was verlässt dein Gerät: nichts", Gerätewechsel per QR. Keine Screenshots mit echten Tagebuchtexten; Demo-Daten kennzeichnen.
- [ ] Garantie im Store-Text: kostenlose Funktionen werden nie kostenpflichtig (D9).
- [ ] Positionierung gegenüber DailyVox auf iOS: "kostenlos, deutsch, lokal" allein ist dort seit August 2026 kein Alleinstellungsmerkmal mehr; der iOS-Store-Text stellt Verschlüsselung, Backup und QR-Gerätewechsel, Erinnerungslogik und Produktreife heraus, der Android-Text die Plattform selbst [66][71].
- [ ] Aussagen zur Deutsch-Qualität ("Deutsch erstklassig" oder Ähnliches) nur, wenn S2 und der Regressionskorpus aus Phase 4 die WER-Schwelle auf spontaner Sprache belegen; sonst neutral formulieren. Wortwahl für das Zusatzpaket nach `07-geschaeftsmodell.md` 4.3 ("größeres Modell für schwierige Aufnahmen", nicht "besseres Deutsch").
- [ ] Website statisch, ohne Tracking, mit Datenschutzerklärung, Impressum, Pressemappe, Link zum Repository.
- [ ] Accessibility Nutrition Labels (iOS 26+) ausfüllen; derzeit freiwillig, von Apple als künftige Pflicht angekündigt [28].
- [ ] Barrierefreiheits-Abnahme: VoiceOver/TalkBack-Durchlauf, Schriftskalierung, Kontrast, Reduce Motion, protokolliert.
- [ ] Support-Postfach, Antwortvorlagen, Issue-Vorlagen im Repository.

**Technisch vor Einreichung**
- [ ] Ziel-API auf Android mindestens 36 (seit 31. August 2026 Pflicht für neue Apps und Updates; Verlängerung bis 1. November 2026 beantragbar) [11]; 16-KB-Seiten für alle nativen Bibliotheken (ab 1. Februar 2027 Pflicht für Ziel-API 35+) [12].
- [ ] iOS-Mindestversion 26 (D13); Verhalten unter dem zum Startzeitpunkt aktuellen iOS 27 geprüft (Apple öffnete 2025 die Einreichung für iOS 26 am 9. September; ein analoger Termin für iOS 27 war am 3. September 2026 nicht angekündigt) [59].
- [ ] Reproduzierbarer Android-Build stimmt mit dem Store-AAB überein (`apkdiff`) [37]; F-Droid-Metadaten vorbereitet [58].
- [ ] Letzter Flugmodus-Test mit dem Release-Kandidaten, Protokoll mit Build-Hash in `docs/`.

Aufwand: M. Empfehlung: Die Checkliste bereits in Phase 4 anlegen und füllen, weil DSA-Verifizierung, Exportkontrolle und Rechtstexte Wartezeiten haben, die sich nicht durch Programmieren verkürzen lassen.

## 10. Phase 7: Start und erste Wochen

1. **Gestaffelt freigeben:** Play Staged Rollout mit kleinem Anteil, iOS Phased Release (beide Store-Funktionen; Details der Konsolen in der Sandbox nicht geprüft) [52][53]. Ein Datenverlust-Fehler am ersten Tag träfe sonst alle.
2. **Ohne Telemetrie reagieren:** Rezensionen beider Stores täglich lesen, Support-Postfach, Repository-Issues. Ein dokumentierter Hotfix-Pfad (Branch, CI, Einreichung) liegt vor dem Start bereit.
3. **Sichtbarkeit nach `07-geschaeftsmodell.md` 7.1:** Pressemappe, awesome-privacy, AlternativeTo, Mastodon, Reddit mit Fokus auf Architektur; in den Wochen danach F-Droid-Einreichung, Privacy-Guides-Forum, Kuketz-Blog, Fachpresse; Product Page Optimization mit bis zu drei Varianten [54]. Privacy Guides nimmt nur Apps mit offenem Client auf [39], daher hängt dieser Schritt an D10.
4. **Erste Messgröße ohne Nutzerdaten:** Downloads und Bewertungen aus den Store-Konsolen (Apple und Google sind dafür eigene Verantwortliche) und die Zahl der Support-Anfragen je Kategorie. Mehr gibt es nicht, und das ist so gewollt.

**Prüfkriterium:** Version 1.0 auf 100 % ausgerollt, kein offener Blocker, F-Droid-Einreichung abgeschickt.

## 11. Phase 8: Nach dem Start (Version 1.x)

Reihenfolge aus `03-produktkonzept.md` 8.2, sortiert nach Nutzen für das tägliche Ritual und nach Abhängigkeiten:

1. **Eine Geste zum Aufnehmen:** iOS Controls, Action Button, Widgets mit Live Activity (Pflicht für `AudioRecordingIntent`); Android Widget, Schnelleinstellungs-Kachel, App-Shortcut. Aufwand M.
2. **Plus-Funktionen** (falls nicht schon zum Start): 30-Minuten-Aufnahmen, Zusatzpaket "Hohe Genauigkeit" (WhisperKit large-v3-v20240930, 626 MB, ab iPhone 13, Faktenprüfung Eintrag 5 [67]; Parakeet TDT 0.6B v3 int8 rund 640 MB, ab 6 GB RAM, bringt auf Android zugleich wortgenaue Zeitstempel für den mitlaufenden Text (D3); Lizenz aus Phase 1) [8]. Aufwand M.
3. **Persönliches Wörterbuch und Korrektur per Sprache** mit vorgeschaltetem Spike, weil die Wirkung von `contextualStrings` bei `SpeechTranscriber` unklar ist. Aufwand M.
4. **Lokale Zusammenfassungen** mit Apple Foundation Models, Opt-in, Ablehnungen abgefangen (D8); Android später. Aufwand M (iOS).
5. **Direkte WLAN-Übertragung** nach dem LocalSend-Muster, dann bewusst mit `INTERNET`-Berechtigung und neuem Flugmodus-Protokoll; Store-Labels vorher erneut prüfen (offene Frage aus `05-sicherheit-und-datenschutz.md`). Aufwand L.
6. **Opus-Pfad als Speicher-Optimierung:** Ogg/Opus mit 16 bis 24 kbit/s, auf iOS libopus als xcframework mit eigenem Decoder in den AVAudioEngine-Graphen, auf Android `MediaRecorder` OGG/OPUS ab API 29 oder Media3 `OggMuxer`; senkt den Jahresbedarf von rund 263 auf 131 bis 197 MB (D4) und verkürzt den Transfer-Container entsprechend [65]. Aufwand M. Erst, wenn Beta oder Support zeigen, dass Speicher oder Übergabezeit ein Problem sind; Altdateien bleiben M4A, der Container muss beide Formate tragen.
7. **Jährlich wiederkehrend:** iOS- und Android-Hauptversionen (neue Verhaltensänderungen wie die RAM-Limits von Android 17) [60], Modellwechsel mit STT-Regressionskorpus, Ziel-API-Anhebung, Flugmodus-Protokoll je Release.

## 12. Größte Risiken und wie die Roadmap sie früh entschärft

| Risiko | Folge | Entschärfung in der Roadmap |
|---|---|---|
| `SpeechTranscriber` liefert für de-CH oder auf bestimmten Geräten nichts Brauchbares; Hardware-Untergrenze ist nicht offiziell (Faktenprüfung Eintrag 3 bestätigt die Berichte zu iPhone 11 und SE 2, Apple schweigt) [2][3][67] | iOS-Kernversprechen wackelt | S1 vor allem anderen; Validierungslauf je Locale; `DictationTranscriber`-Fallback bereits im Durchstich verdrahtet |
| Moonshine Small ist auf 4-GB-Android zu langsam, zu groß oder bei spontaner Sprache deutlich schlechter als die 7,5 % auf vorgelesenem Material [7][64]; Interpunktion und Groß-/Kleinschreibung ungeklärt | Android-Nutzer warten, die App stürzt ab, oder das kostenlose Deutsch-Versprechen trägt nicht; der Rückfall Parakeet (≈ 640 MB [8], unbestätigte Messung 1,23 GB RAM [62]) kippt den 4-GB-Richtwert aus D13 | S2 mit RTF-Zielwert, Mini-Korpus spontaner Sprache (AT, CH, Zimmerakustik) und WER-Schwelle; Entscheidungsbaum mit Inhaberentscheid vor Phase 3 (Abschnitt 13, Punkt 9); bedingtes Paket 15 für Interpunktion; Mindestanforderung und Store-Text erst nach Messung festlegen |
| Play Asset Delivery oder Billing braucht `INTERNET` [10] | Stärkster Netz-Nachweis auf Android entfällt | S3 in Phase 1; Entscheidung des Inhabers mit beiden Optionen vor Phase 3 |
| Native Brücken wachsen über ein Plugin hinaus | Flutter-Vorteil schmilzt, Wartung verdoppelt sich | S8 als expliziter Prüfpunkt; Rückfall zweimal nativ vor Phase 3, nicht danach |
| Datenverlust durch Migration, Aufnahmeabbruch oder Backup, das nicht wiederherstellt; Backup-Datei nicht auffindbar, OS-Update bricht das Backup, Aussperrung nach Biometrie-Änderung (häufigste echte Store-Beschwerden) [43][44][66][73] | Vertrauensbruch, der für ein Tagebuch nicht heilbar ist | Migrationstests ab Version 1 des Schemas; Abbruchfälle in S6; sichtbarer Speicherort und Wiederherstellungstest im Onboarding (Paket 7); Gerätecode-Pfad bei Biometrie-Änderung (Paket 3); Beta-Fragen 4 und Ausstiegskriterium "kein Datenverlust" |
| AAC-LC statt Opus erhöht den Speicherbedarf um ein Drittel bis auf das Doppelte (rund 263 statt 131 bis 197 MB/Jahr, D4), und das Chunk-AEAD-Dateiformat ist eine eigene, seekbare Struktur [65] | Größerer Transfer-Container und längere Übergabe; ein Fehler im Dateiformat macht alle Einträge unlesbar | S5 mit 263-MB-Testdaten gegen die Fünf-Minuten-Grenze; S4 mit Seek-Test und Formatversion im Dateikopf; Cryptomator-Muster statt Eigenentwurf [68]; Krypto-Review vor der Beta; Opus-Pfad erst in Phase 8, wenn Speicher oder Übergabezeit nachweislich drücken |
| DailyVox ist auf iOS seit August 2026 kostenlos, deutschsprachig und vollständig lokal; eine Android-Version fehlt, wird aber nachgefragt [66][71] | "Kostenlos, deutsch, lokal" ist auf iOS kein Alleinstellungsmerkmal mehr; ein iOS-lastiger Start hätte keinen Vorsprung, und eine DailyVox-Android-Version würde auch das Android-Fenster verengen | Beide Plattformen im selben Release, Play-Beta früh und sichtbar (Abschnitt 8); auf iOS Unterschied über Verschlüsselung, Backup und QR-Gerätewechsel, Erinnerungslogik und Produktreife (Store-Text, Abschnitt 9); Zielmonat halten (Abschnitt 2.1); Entscheidung zur Plattform-Reihenfolge in Abschnitt 13, Punkt 11 |
| Erinnerungen bleiben auf Hersteller-Android aus [15] | Ritual bricht, Retention der Kategorie ist ohnehin niedrig (30-Tage-Retention von Mental-Health-Apps auf Android im niedrigen einstelligen Prozentbereich; Sekundärquelle, unverifiziert) [57] | S7 auf drei Geräten; Onboarding-Schritt; Beta-Frage 1 auf fremden Geräten |
| Store-Ablehnung oder falsche Labels (Datenschutz, Exportkontrolle, Altersfreigabe, 3.1.1) | Startverzögerung, im schlimmsten Fall falsche öffentliche Aussage | Checkliste ab Phase 4; Flugmodus-Protokoll als Beleg; QR ohne Freischaltfunktion; Exportkontroll-Einordnung schon in Phase 1 |
| Rechtsquellen waren in der Recherche nicht erreichbar (D15) | Pflichten könnten anders lauten als beschrieben | Alle als unverifiziert markierten Punkte vor Phase 6 gegen Primärquellen prüfen; Rechtsbausteine budgetieren |
| Ein Entwickler, Plattformwechsel jedes Jahr | Wartungsschulden, Modelle veralten; bei Teilzeit verpasst 1.0 das Zeitfenster (Abschnitt 2.1) | Kleiner Funktionsumfang im MVP; Kapazitätsannahme und Zielmonat explizit, Schnittlinie in Phase 3 (Abschnitt 2.2); STT-Regressionskorpus, CI, jährlicher Pflegeblock in Phase 8 eingeplant |
| Privacy-Publikum reagiert auf nachträgliche Bezahlschranken empfindlich | Rezensionen, Verlust der Kernzielgruppe | Garantie "kostenlose Funktionen bleiben kostenlos" ab Store-Text 1.0 (D9); Plus nur mit neuen Funktionen |

## 13. Was der Inhaber jetzt entscheiden muss

1. **Name (D11):** Arbeitstitel und Alternativen siehe `08-namensfindung.md`, Abschnitt 7; Prüfpflichten dort Abschnitt 8. Die interne Nachprüfung fand für keinen Favoriten eine App oder Marke gleichen Namens, konnte aber weder App Store, Play Store noch DPMA/EUIPO/Swissreg direkt abfragen [61]. Vor Phase 3 nötig: Store-Suche, Markenrecherche, Domains (.app, .de, .ch).
2. **Lizenz (D10):** GPLv3 mit Store-Builds und Marke beim Inhaber, oder Open Core. Entscheidet über F-Droid, Privacy-Guides-Listung und den Aufbau des Krypto-Kerns als separate Bibliothek; muss vor dem ersten öffentlichen Commit feststehen.
3. **Rechtsform und veröffentlichte Adresse:** Einzelunternehmen genügt; der DSA-Händlerstatus veröffentlicht Adresse, Telefon und E-Mail in allen EU-Storefronts [31]. Wer die Privatadresse nicht zeigen will, braucht eine c/o-Lösung oder eine Gesellschaft (Kosten siehe `07-geschaeftsmodell.md`).
4. **Plus zum Start oder in 1.1:** `07-geschaeftsmodell.md` plant Lifetime-Codes für Beta-Tester, `03-produktkonzept.md` legt alle Plus-Funktionen in 1.x. Empfehlung: Kaufgerüst und ein kleines Plus (30-Minuten-Aufnahmen) bereits in 1.0, weil DSA-Status, In-App-Kauf-Review, Billing-ohne-`INTERNET`-Test (S3) und Tester-Codes dann nur einmal durchlaufen werden und die Garantie "kostenlos bleibt kostenlos" von Anfang an sichtbar ist. Alternative: 1.0 vollständig kostenlos, Plus mit 1.1.
5. **Modellauslieferung, falls S3 scheitert:** Modelle bündeln (größerer Download, saubere Aussage "keine INTERNET-Berechtigung") oder Berechtigung aufnehmen und erklären.
6. **Budget für externe Prüfung:** Kurz-Review des Krypto-Kerns vor der Beta (5.000 bis 15.000 €) und Rechtsprüfung der unverifizierten Punkte (Impressum, Exportkontrolle, Play-Richtlinien, MDR-Abgrenzung, GPL und Store) vor Phase 6 (1.000 bis 3.000 €); Beträge sind Setzungen aus der Budgettabelle in Abschnitt 13.1, vor Beauftragung Angebote einholen.
7. **Testgeräte:** Freigabe für den Pool aus Phase 0 (ein neueres und ein älteres iPhone, Pixel, Samsung-Mittelklasse, Xiaomi), 2.000 bis 3.000 € (Setzung, Abschnitt 13.1).
8. **Beta-Rekrutierung:** Wer spricht die 50 bis 100 Tester aus der Privacy-Community an, und unter welchem Namen, falls der Produktname noch nicht feststeht?
9. **Rückfall Android-Qualität, falls S2 die WER-Schwelle verfehlt:** Parakeet TDT 0.6B v3 int8 als Standardmodell mit Anhebung des Android-Richtwerts aus D13 auf 6 GB RAM und größerem Erstdownload (≈ 640 MB [8]), oder System-Recognizer als Opt-in mit Hinweis bei 4 GB (D3). Die Entscheidung ändert D13 und den Store-Text und muss vor Phase 3 fallen.
10. **Kapazität und Zielmonat:** Bestätigung der Annahme "Vollzeit, 160 Stunden pro Monat" aus Abschnitt 2.1 oder Festlegung einer anderen Kapazität mit neu gerechnetem Zielmonat; bei weniger als 30 Stunden pro Woche zugleich Entscheidung, welche Pakete aus Abschnitt 2.2 von vornherein in 1.1 rücken.
11. **Plattform-Reihenfolge nach dem DailyVox-Befund:** Diese Roadmap plant beide Plattformen im selben Release. Weil DailyVox auf iOS bereits kostenlos, deutsch und vollständig lokal ist und Android-Nachfrage dokumentiert ist [66][71], wäre die Alternative, die Android-Beta bewusst vorzuziehen und iOS mit der vollen Differenzierung (Verschlüsselung, Backup, QR-Gerätewechsel) nachzuschieben. Die Entscheidung ändert die Beta-Reihenfolge in Abschnitt 8 und die Store-Texte in Abschnitt 9, nicht den Zielmonat.

### 13.1 Budget für externe Ausgaben

Die Beträge sind Setzungen ohne externe Quelle und stehen wortgleich in `07-geschaeftsmodell.md` 4.6; Änderungen erfolgen nur in beiden Dokumenten gleichzeitig. Arbeitszeit ist nicht enthalten (Abschnitt 2); laufende Kosten (Apple Developer Program 99 $/Jahr, Domain, mit UG oder GmbH zusätzlich ab rund 1.000 €/Jahr) stehen dort.

| Posten | Herkunft der Empfehlung | Betrag |
|---|---|---|
| Bezahlter Kurz-Review des Krypto- und Containerkerns | Abschnitt 7 dieses Dokuments; `05-sicherheit-und-datenschutz.md` Abschnitt 4.2 | 5.000 bis 15.000 € (Setzung) |
| Rechtsprüfung der unverifizierten Punkte (Impressum, Exportkontrolle, Play-Richtlinien, MDR-Abgrenzung, GPL und Store) | Abschnitt 13, Punkt 6; `07-geschaeftsmodell.md` Abschnitt 6 | 1.000 bis 3.000 € (Setzung) |
| Testgerätepool, fünf Geräte (zwei iPhones, Pixel, Samsung-Mittelklasse, Xiaomi) | Phase 0 | 2.000 bis 3.000 € (Setzung) |
| Entwicklerkonten und Rechtsbausteine | [41][63] | Apple 99 $/Jahr, Google 25 $ einmalig, Rechtsbausteine rund 300 € |
| **Summe einmalig, ohne Arbeitszeit** | | **rund 8.000 bis 21.000 €** |

Am Krypto-Review und an der Rechtsprüfung wird nicht gespart, weil beide das Kernversprechen tragen; sparen lässt sich am Gerätepool (gebrauchte Geräte, Leihgeräte aus der Community), nicht an seiner Zusammensetzung.

## 14. Offene Fragen

1. Reihenfolge iOS 27: Erscheint es vor dem Store-Start, und ändert es `SpeechTranscriber`-Locales oder -Hardwareanforderungen ("with more to come")? Betrifft S1 und die Mindestversion.
2. Testpflicht neuer Play-Konten (Anzahl Tester, Dauer) und Auswirkung auf die Beta-Dauer (unverifiziert) [50].
3. Ob TestFlight-Builds mit gebündelten Modellen und ohne Netz in der Beta-App-Review Rückfragen auslösen; Einreichungsnotizen mit Flugmodus-Hinweis vorbereiten.
4. Zeitpunkt der F-Droid-Einreichung relativ zum Store-Start und Modellauslieferung ohne Play Asset Delivery (offene Frage aus `04-technik-architektur.md`).
5. Ob eine zweite Beta-Runde speziell für Schweizer Nutzer (de-CH, Hochdeutsch-Hinweis) sinnvoll ist oder die erste Runde reicht.
6. Umfang des externen Krypto-Reviews: nur Containerformat und Schlüsselhierarchie oder auch die nativen Brücken.
7. Wie Erfolg ohne Telemetrie nach dem Start definiert wird (Downloads, Bewertungen, Support-Volumen) und ab welchem Wert Phase 8 priorisiert wird.
8. Ob Moonshine German Small Streaming Interpunktion und Groß-/Kleinschreibung ausgibt und ob sherpa-onnx ein deutsches Interpunktionsmodell mitbringt; davon hängt Paket 15 in Phase 3 ab (S2).
9. Ob die WER-Schwelle von 12 % auf spontaner Sprache (Setzung in S2) die richtige Marke ist; ein Vergleichswert wäre der iOS-Pfad auf demselben Mini-Korpus, den S1 deshalb mitmessen sollte.
10. Kapazität des Entwicklers (Abschnitt 2.1): Vollzeit ist angenommen, nicht bestätigt; bei Teilzeit sind Zielmonat und Schnittlinie neu zu setzen.
11. Ob AAC-LC mit 32 kbit/s im Hörtest (S6) reicht oder 48 kbit/s nötig sind; bei 48 kbit/s steigt die Rechenbasis aus D4 von rund 263 auf rund 394 MB pro Jahr, und S5 muss mit dieser Größe wiederholt werden.
12. Ob die Chunk-AEAD in Dart (package:sodium) den Aufnahme- und Wiedergabedurchsatz hält oder in die nativen Brücken wandern muss (S4); das beeinflusst S8 und die Auditierbarkeit des Krypto-Kerns (D10).
13. Ob DailyVox eine Android-Version ankündigt (Issue #4 vom 3. August 2026 ist offen) [71]; dann schrumpft auch das Android-Fenster aus Abschnitt 2.1, und Punkt 11 in Abschnitt 13 ist neu zu bewerten.

## Quellen

1. Flutter-Releases (3.47.2 vom 27. 8. 2026): https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
2. Apple Developer Forum, `SpeechTranscriber` nicht verfügbar auf iPhone 11/SE 2 (nicht offiziell bestätigt): https://developer.apple.com/forums/thread/806765
3. Apple Developer Forum, Arabisch fälschlich als unterstützt gelistet, Empfehlung Validierungslauf je Locale: https://developer.apple.com/forums/thread/797835
4. Apple Developer Forum, Locale-Format und `supportedLocale(equivalentTo:)`: https://developer.apple.com/forums/thread/790108
5. Apple, `AssetInventory`: https://developer.apple.com/documentation/speech/assetinventory
6. Apple, `DictationTranscriber`: https://developer.apple.com/documentation/speech/dictationtranscriber
7. Moonshine, verfügbare Modelle (German Small Streaming 123 M, WER 7,5 %; Tiny 34 M, WER 12,0 %): https://raw.githubusercontent.com/moonshine-ai/moonshine/main/docs/models/available-models.md
8. sherpa-onnx, Parakeet TDT 0.6B v3 (≈ 640 MB, Lizenzhinweis): https://raw.githubusercontent.com/k2-fsa/sherpa/master/docs/source/onnx/pretrained_models/offline-transducer/nemo/parakeet-tdt-0.6b-v3.rst
9. sherpa-onnx Releases (v1.13.7): https://github.com/k2-fsa/sherpa-onnx/releases
10. Android, Play Asset Delivery: https://developer.android.com/guide/playcore/asset-delivery
11. Android, Ziel-API-Anforderungen von Google Play: https://developer.android.com/google/play/requirements/target-sdk
12. Android, 16-KB-Seitengröße: https://developer.android.com/guide/practices/page-sizes
13. Android, Vordergrunddienst-Typen: https://developer.android.com/develop/background-work/services/fgs/service-types
14. Android, Alarme planen: https://developer.android.com/develop/background-work/services/alarms/schedule
15. dontkillmyapp (Hersteller-Rangliste, Samsung-/Xiaomi-Hinweise): https://github.com/urbandroid-team/dont-kill-my-app
16. libsodium, secretstream: https://github.com/jedisct1/libsodium-doc/blob/master/secret-key_cryptography/secretstream.md
17. libsodium, Passwort-Hashing (Argon2id, eine Sekunde als akzeptables Maximum): https://github.com/jedisct1/libsodium-doc/blob/master/password_hashing/default_phf.md
18. Dart-Paket `sodium` 4.1.0+1: https://pub.dev/packages/sodium
19. `flutter_secure_storage` 11.0.0: https://pub.dev/packages/flutter_secure_storage
20. drift, Verschlüsselung mit SQLCipher: https://github.com/simolus3/drift/blob/develop/docs/content/platforms/encryption.md
21. Android Keystore: https://developer.android.com/privacy-and-security/keystore
22. Android Auto Backup: https://developer.android.com/identity/data/autobackup
23. Apple, App Privacy Details ("processed only on device is not collected"): https://developer.apple.com/app-store/app-privacy-details/
24. Apple, App Review Guidelines (2.5.14, 3.1.1, 5.1.1): https://developer.apple.com/app-store/review/guidelines/
25. Apple, Required Reason API: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
26. Apple, `NSMicrophoneUsageDescription`: https://developer.apple.com/documentation/bundleresources/information-property-list/nsmicrophoneusagedescription
27. Apple, Altersfreigabe-Werte und -Definitionen: https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions
28. Apple, Accessibility Nutrition Labels: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels
29. Apple, Exportkontrolle für Verschlüsselung: https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
30. Apple, Dokumentationstabelle Exportkontrolle: https://developer.apple.com/help/app-store-connect/reference/export-compliance-documentation-for-encryption
31. Apple, DSA-Händleranforderungen: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements
32. Android, Datentypen für Data Safety: https://developer.android.com/guide/topics/data/collect-share
33. Google Play Data Safety (in der Sandbox nicht erreichbar, unverifiziert): https://support.google.com/googleplay/android-developer/answer/10787469
34. Google Play Health-Apps-Richtlinie (unverifiziert): https://support.google.com/googleplay/android-developer/answer/12261419
35. Google Play Altersfreigabe IARC (unverifiziert): https://support.google.com/googleplay/android-developer/answer/9859655
36. § 5 DDG (aktuelle Fassung unverifiziert): https://www.gesetze-im-internet.de/ddg/__5.html
37. Signal Android, Reproducible Builds: https://github.com/signalapp/Signal-Android/blob/main/reproducible-builds/README.md
38. Signal iOS, Reproducible Builds offen seit 2015: https://github.com/signalapp/Signal-iOS/issues/641
39. Privacy Guides, Aufnahmekriterien: https://raw.githubusercontent.com/privacyguides/privacyguides.org/main/docs/about/criteria.md
40. Apple News, Offer Codes für alle In-App-Kauftypen (29. 10. 2025): https://developer.apple.com/news/?id=r1s3hw2b
41. Apple Small Business Program: https://developer.apple.com/app-store/small-business-program/
42. Dictus iOS, Modell-Download bricht ab und startet von vorn (Issue #449): https://github.com/getdictus/dictus-ios/issues/449
43. Journiv, Datenverlust nach Update-Migration (Issue #540): https://github.com/journiv/journiv-app/issues/540
44. Fossify Voice Recorder, Aufnahme nach langer Dauer verloren (Issue #56): https://github.com/FossifyOrg/Voice-Recorder/issues/56
45. node-qrcode, QR-Kapazitätstabelle (2953 Byte bei V40-L): https://github.com/soldair/node-qrcode
46. Apple WWDC25 Session 277 (SpeechAnalyzer, Modelle im Systemspeicher): https://developer.apple.com/videos/play/wwdc2025/277/
47. OWASP MASTG, App-Switcher-Snapshot (MASTG-TEST-0010): https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-PLATFORM/MASTG-TEST-0010.md
48. openai/whisper, Halluzinationen bei Stille (Discussion #928): https://github.com/openai/whisper/discussions/928
49. OWASP MASTG, Speicherhygiene (MASTG-TEST-0011): https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-STORAGE/MASTG-TEST-0011.md
50. Google Play, Testanforderungen für neue persönliche Entwicklerkonten (in der Sandbox nicht geprüft, unverifiziert): https://support.google.com/googleplay/android-developer/answer/14151465
51. Apple TestFlight: https://developer.apple.com/testflight/
52. Apple, Phased Release (in der Sandbox nicht geprüft): https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/release-a-version-update-in-phases
53. Google Play, Staged Rollout (in der Sandbox nicht geprüft, unverifiziert): https://support.google.com/googleplay/android-developer/answer/6346149
54. Apple, Product Page Optimization: https://developer.apple.com/app-store/product-page-optimization/
55. WhisperKit, Deutsch-Probleme bei Auto-Erkennung (Issue #528): https://github.com/argmaxinc/argmax-oss-swift/issues/528
56. openai/whisper Discussion #928 und whisper.cpp Issue #2660 (Phantom-Untertitel): https://github.com/ggml-org/whisper.cpp/issues/2660
57. 30-Tage-Retention von Mental-Health-Apps auf Android (Sekundärquelle, unverifiziert): https://www.researchgate.net/figure/App-30-day-retention-by-mental-health-focus-The-percentages-reflect-the-number-of-users_fig2_334562120
58. F-Droid, Inclusion Policy (in der Sandbox nicht geprüft): https://f-droid.org/docs/Inclusion_Policy/
59. Apple News, Einreichung für iOS 26 geöffnet (9. 9. 2025): https://developer.apple.com/news/?id=6lxhtioi
60. Android 17, Verhaltensänderungen (App-Speicherlimits, Native-Libs read-only): https://developer.android.com/about/versions/17/behavior-changes-all
61. Interne Nachprüfung der Namensfavoriten (3. 9. 2026): `docs/recherche/namensfindung/nachpruefung.md`
62. sherpa-onnx Issue #2626, einzelne Nutzermessung 1,23 GB RAM beim Laden von parakeet-tdt-0.6b-v3-int8 auf iOS (geschlossen, ohne sichtbare Bestätigung der Maintainer): https://github.com/k2-fsa/sherpa-onnx/issues/2626
63. Recherchebericht Geschäftsmodell (Rechenannahmen, Fixkosten, Rechtsbausteine): `docs/recherche/geschaeftsmodell.md`
64. Moonshine, Genauigkeitstabelle (German Small Streaming 7,5 % und Tiny 12,0 % auf FLEURS + MLS, quantisiert ausgeliefert): https://raw.githubusercontent.com/moonshine-ai/moonshine/main/docs/models/accuracy.md
65. Nachrecherche Audio-Container, Aufnahme-Pipeline und Wiedergabe-Architektur (Stand 3. 9. 2026; AAC-LC/M4A im MVP, Chunk-AEAD nach Cryptomator-Muster, Moonshine ohne Zeitstempel, Wellenform bei der Aufnahme, Android-17-Hintergrundaudio; Primärquellen dort gelistet): `docs/recherche/nachrecherche-audio-container.md`
66. Nachrecherche Nutzerstimmen und Store-Kennzahlen DE/AT/CH (Stand 3. 9. 2026; Abschnitt 3 Store-Beschwerden zu Backups und Aussperrung, Deutsch-Diktat-Fehler, Schweizerdeutsch-Fine-Tunes; Abschnitt 4 DailyVox): `docs/recherche/nachrecherche-nutzerstimmen-stores.md`
67. Faktenprüfung von 30 priorisierten Aussagen (18 bestätigt, 12 präzisiert; Stand 3. 9. 2026; hier zitiert: Eintrag 2 SpeechTranscriber-Locales, Eintrag 3 Hardware-Untergrenze, Eintrag 5 WhisperKit-Gerätematrix): `docs/recherche/verifikation.json`
68. Cryptomator, Vault-Format (Dateikopf mit gewrapptem Inhaltsschlüssel, 32-KiB-Chunks mit Nonce und Tag, AAD aus Chunk-Nummer und Kopf-Nonce): https://github.com/cryptomator/docs/blob/develop/docs/security/vault.mdx
69. Android 17, Background Audio Hardening (Wiedergabe ohne sichtbare Activity oder Foreground Service wird stumm unterdrückt; Empfehlung `MediaSessionService`): https://developer.android.com/about/versions/17/changes/bg-audio
70. Apple Developer Forum, Ogg/Opus in `AVAudioPlayer` "This media format is not supported" (Thread 128434): https://developer.apple.com/forums/thread/128434
71. DailyVox, Repository mit README und Release-Notizen (v1.10.0 Deutsch, v1.11.0 ohne Cloud-Fallback, August 2026) und Issue #4 "Any plans for Android Release?" (3. 8. 2026): https://github.com/intrepidkarthi/dailyvox und https://github.com/intrepidkarthi/dailyvox/issues/4
72. Apple Developer Forum, deutsche Diktat-Fehler (Komposita getrennt, Leerzeichen um Bindestriche, Interpunktionswörter doppelt; Mai 2026): https://developer.apple.com/forums/thread/826756
73. Easy Diary, vom Entwickler archivierte Play-Store-Rezensionen (Backup-Speicherort unauffindbar #184; Aussperrung nach neuem Fingerabdruck #197; Backup nach OS-Update blockiert #200): https://github.com/hanjoongcho/aaf-easydiary/issues/184, https://github.com/hanjoongcho/aaf-easydiary/issues/197, https://github.com/hanjoongcho/aaf-easydiary/issues/200
74. Transkribor, Issue #130 (Schweizerdeutsch-Whisper-Fine-Tunes nur unter CC-BY-NC-4.0; 11. 8. 2026): https://github.com/napoleonmm83/Transkribor/issues/130
75. androidx media, `AesCipherDataSource` (Muster für eine seekbare, entschlüsselnde Media3-`DataSource`): https://github.com/androidx/media/blob/release/libraries/datasource/src/main/java/androidx/media3/datasource/AesCipherDataSource.java
76. Signal Android, `AudioCodec` (Sprachnachrichten als AAC-LC, 32 kbit/s, mono): https://github.com/signalapp/Signal-Android/blob/main/app/src/main/java/org/thoughtcrime/securesms/audio/AudioCodec.java
