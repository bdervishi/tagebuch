# Innovationslücken: Was heutigen Tagebuch- und Voice-Journal-Apps fehlt

Recherche-Stand: 3. September 2026. Blickwinkel: Differenzierungschancen für ein rein lokales Sprach-Tagebuch (iOS/Android, keine Cloud, keine Konten) für den DACH-Raum.

Hinweis zur Quellenlage: Viele Primärseiten (arxiv.org, huggingface.co, dayoneapp.com, apple.com, heise.de, kuketz-blog.de, pmc.ncbi.nlm.nih.gov u. a.) waren aus der Recherche-Umgebung per Proxy gesperrt. Die Angaben zu diesen Quellen stammen aus Suchmaschinen-Snippets und sekundären Zusammenfassungen und sind entsprechend als "zu verifizieren" markiert. Direkt gelesen werden konnten u. a. GitHub (WhisperKit-README, Whisper-Diskussion #1606, OpenWhispr-Issue #462, Hugging-Face-Blog zu EmbeddingGemma) und das Apple-Developer-Forum (SpeechTranscriber-Gerätevoraussetzungen).

---

## 1. Kernaussagen

1. **Die technische Basis für "alles lokal" ist 2026 erstmals wirklich da**: Apples `SpeechTranscriber` (iOS 26) läuft on-device und listet `de_DE`, `de_AT`, `de_CH` als unterstützte Locales; das Apple Foundation Models Framework liefert ein 3B-Modell on-device (4096-Token-Kontext, iPhone 15 Pro+); Google bietet Gemini Nano über ML Kit GenAI APIs (Summarization aber nur EN/JA/KO) und EmbeddingGemma (308M Parameter, <200 MB RAM quantisiert, 100+ Sprachen) für lokale semantische Suche. Whisper-Varianten (WhisperKit large-v3-turbo komprimiert 626 MB; whisper.cpp plattformübergreifend) schließen die Lücke auf Android.
2. **Schweizerdeutsch ist eine echte, belegbare Lücke**: Zero-Shot-Whisper erreicht 23–33 % WER (Dolev et al., VarDial 2024); feinabgestimmte Modelle 12,1 % WER (Timmel et al./FHNW, ~1.033 h Training) bzw. 25,6 % WER / 13,8 % cWER auf sauber getrennten Testdaten (Flix-AI, arXiv 2606.07608, Juni 2026). Öffentlich verfügbare Fine-Tunes existieren (Flix-AI/flix-swissgerman-full; Flurin17/whisper-large-v3-turbo-swiss-german, März 2026). App-Store-Rezensionen bemängeln explizit, dass Standard-Transkriptions-Apps Schweizerdeutsch nicht erkennen.
3. **Marktführer haben klare Schwächen**: Day One transkribiert nur bis 10 Minuten, brauchte bis iOS 26 Internet, transkribiert nur in der iOS-Systemsprache und kostet 34,99 USD/Jahr; Apple Journal hatte 2025 wiederholt "Couldn't transcribe audio"-Fehler und exportiert nur PDF; Whisper Memos und AudioPen schicken Audio an OpenAI bzw. eigene Server; Kuketz fand 2020/21 bei Journey (Crashlytics, Google-Komponenten) und Diaro (Amazon-Werbenetzwerk) "miserablen Datenschutz".
4. **Ritual-Design ohne Schuldgefühl ist ein belegtes Nutzerbedürfnis**: Finch ("your bird never dies"), Daylogue (bewusst ohne Streaks/Badges) und Duolingos Streak Freeze (Churn −21 % bei gefährdeten Nutzern, +10 % Langzeitbindung) zeigen: Vergebende Mechaniken schlagen strafende.
5. **Stimmungserkennung aus der Stimme ist wissenschaftlich unreif und regulatorisch heikel**: Systematische Reviews (2025) sehen "promising" Klassifikationsgenauigkeit, aber Heterogenität, Gender-Bias und fehlende Generalisierbarkeit. Der EU AI Act verbietet Emotionserkennung am Arbeitsplatz/in Bildung (Art. 5(1)(f), seit Feb. 2025); für Consumer-Apps gilt seit 2. August 2026 die Transparenzpflicht nach Art. 50 (Betroffene informieren); Annex-III-Hochrisiko-Pflichten wurden per Digital Omnibus auf 2. Dez. 2027 verschoben. Für ein MVP: nicht bauen; wenn später, dann als opt-in Selbsteinschätzung, nicht als Inferenz.
6. **Evidenz für Journaling ist real, aber klein**: Frattaroli (2006, 146 RCTs) r ≈ 0,075 (d ≈ 0,15); Reinhold et al. (2018) fanden keine signifikanten Langzeiteffekte auf Depression; Pennebaker & Seagal (1999) berichten vergleichbare Effekte für Schreiben und Sprechen ("talking into a tape recorder"). Gratitude-Meta-Analyse (PNAS 2025, 145 Studien, 28 Länder): kleine Effekte. Fazit: Sprechen ist als Modalität gleichwertig belegt; Marketing sollte keine Therapieversprechen machen.
7. **Retention ist das eigentliche Problem der Kategorie**: Mental-Health-Apps auf Android: mediane 15-Tage-Retention 3,9 %, 30-Tage 3,3 % (Analyse von 93 Apps). Alles, was das Ritual reibungsfrei macht (Hands-free-Start, adaptive Erinnerung, "nicht heute"), zahlt direkt auf Retention ein.

---

## 2. Befunde im Detail

### 2.1 Aufnahme ohne Bildschirmkontakt

- **iOS**: Just Press Record startet/stoppt per Action Button, Shortcuts, Siri, Widget und Watch-Complication ("single tap on the Complication"). Whisper Memos wirbt mit "Record hands free by tapping a complication or action button". Diese Apps sind aber Notiz-Tools, keine Tagebücher, und Whisper Memos sendet Audio laut Datenschutzerklärung an OpenAI.
- **Android**: Google Recorder ist über eine Quick-Settings-Kachel startbar; Pixel "Quick Tap" (Doppeltipp auf Rückseite, Pixel 4a 5G+) kann App-Shortcuts auslösen; Wear OS unterstützt Tiles/Complications; Pixel Watch hat eine Recorder-App. Eine Tagebuch-App, die App-Shortcuts, Quick-Settings-Tile und Wear-OS-Tile anbietet, ist im Play Store selten.
- **Kopfhörertaste**: Auf iOS gibt es kein öffentliches API, um die AirPods-Taste einer Drittanbieter-App für "Aufnahme starten" zuzuweisen; Umwege laufen über Siri/Shortcuts. Auf Android können Apps `MediaSession`-Tasten-Events empfangen (Play/Pause), was für "Aufnahme starten, wenn App Vordergrund-Service hat" nutzbar ist. mustVerify.
- **Chance**: Ein "Ein-Geste-Ritual" (Action Button → Aufnahme läuft → Doppelklick beendet) plus Watch-Complication ist bei Tagebuch-Apps (Day One, Journey, Apple Journal) nicht der Normalfall. Apple Journal hat bis iOS 26 keine Watch-App; die Suchergebnisse zu watchOS 26 nennen keine Journal-Funktion.

### 2.2 Tägliches Ritual, Streaks, Erinnerungslogik

- Daylogue-Blog ("Why Do Journaling Apps Make Me Feel Guilty?"): Missed-day-Benachrichtigungen ("You missed your check-in yesterday") wirken wie Urteil; Reset-Zähler bestrafen Krankheit/Reise; "what-the-hell effect" führt zum Abbruch. Daylogue entfernte nach einem Ethik-Audit alle Gamification-Elemente.
- Finch: "no penalties for missing days", "your bird never dies" — in Reviews wiederholt als hilfreich für Nutzer mit Angst, ADHS, Burnout genannt.
- Duolingo (Gegenbeispiel mit Zahlen): Streak Freeze senkte Churn bei gefährdeten Nutzern um 21 %, hob Langzeit-Retention um 10 %; zwei Freezes für neue Nutzer waren einer der größten Gewinne. Gleichzeitig Kritik: "the streak can become the goal instead of the learning".
- LogRocket: Streaks nutzen Verlustaversion; wenn ein Tag alles löscht, entsteht Stress und "fragile engagement".
- Erinnerungslogik: JITAI-Forschung (Nahum-Shani et al.) definiert "receptivity" als zeitlich schwankende Bereitschaft; unpassende Benachrichtigungen erzeugen Irritation. Eine PLOS-One-Studie fand, dass adaptive Zeitsteuerung nicht automatisch Nutzung steigert. MindScape (CMU, 20 Studierende, 8 Wochen): Abend-Check-ins hatten das beste Feedback-Verhältnis (4,8 Daumen hoch pro Daumen runter), Nutzer schrieben im Schnitt 33 Einträge; kontextuelle Prompts schlugen generische.
- **Chance**: "Sanfte Kontinuität" statt Streak: Kalender-Heatmap ohne Zähler, "nicht heute"-Button ohne Nachfrage, automatische Verschiebung der Erinnerung um 30/60 Minuten, Lernen der tatsächlichen Aufnahmezeit (lokal, einfache Heuristik: Median der letzten 14 Aufnahmezeiten), Stille-Zeiten (Urlaub) einstellbar.

### 2.3 Transkription: Plattform-APIs, Whisper, Dialekte

**Apple (iOS 26, SpeechAnalyzer/SpeechTranscriber)**
- Läuft on-device, Modelle werden als Assets nachgeladen. `supportedLocales` enthält u. a. `de_AT, de_CH, de_DE, fr_CH, it_CH` (Liste aus Sekundärquelle; mustVerify).
- Geräteanforderung laut Developer-Forum: 16-Kern-Neural-Engine (iPhone 12+); auf iPhone 11/SE 2 liefert `supportedLocales` ein leeres Array; im Simulator nicht verfügbar. Fallback: `SFSpeechRecognizer`.
- Day One nutzt seit iOS 26 diese On-Device-Transkription; auf älteren Geräten läuft sie auf Apple-Servern.
- Grenzen: `de_CH` bedeutet Schweizer Hochdeutsch (Orthografie/Wortschatz), nicht Dialekt. Kein Code-Switching innerhalb einer Session ohne Neustart mit anderem Locale (mustVerify).

**Android**
- Google Recorder transkribiert on-device live in EN/FR/DE/HI/IT/ES/ZH-TW; Samsung Transcript Assist unterstützt 20+ Sprachen inkl. Deutsch. Es gibt aber kein öffentliches, herstellerübergreifendes On-Device-Transkriptions-API vergleichbar mit SpeechTranscriber; `SpeechRecognizer` mit `EXTRA_PREFER_OFFLINE` ist herstellerabhängig. mustVerify.
- Praktikabel: whisper.cpp (GGML, quantisiert; Modelle 75 MB tiny bis 1,5 GB large-v3-turbo) oder Argmax Pro SDK (Android, kommerziell). Batterie: 15–30 % pro Stunde Dauer-Transkription mit whisper.cpp auf modernem iPhone (Sekundärquelle) — für 2–5-minütige Tagebucheinträge unkritisch.

**Whisper-Modellgrößen** (OpenAI-Tabelle): tiny 39M, base 74M, small 244M, medium 769M, large-v3 1550M, large-v3-turbo 809M (Decoder von 32 auf 4 Layer gekürzt, ~8x schneller als large). WhisperKit empfiehlt "Large v3 Turbo (compressed): 626 MB" für iOS/macOS; Whisper Notes lässt turbo auf iPhone bewusst weg zugunsten kleinerer Modelle.

**Schweizerdeutsch**
- Korpus STT4SG-350 (Plüss et al., ACL 2023, ZHAW/FHNW): 343 h, 316 Sprecher, alle 7 Dialektregionen, Standarddeutsch-Annotation; Lizenz laut Snippet Apache-2.0 (mustVerify — ZHAW-Seiten sprechen von Lizenzhürden bei Modellen).
- Dolev et al. (VarDial 2024): Whisper zero-shot 23–33 % WER, BLEU 52–63; 28 menschliche Bewerter; "viable ASR system for Swiss German, so long as the Standard German output is desired".
- Timmel et al. (FHNW, 2024): Long-form-Training (502 h Korpora + 406 h pseudo-gelabelte SRG-Sendungen + 125 h Common Voice DE) → 12,1 % WER auf STT4SG-350-Test mit Whisper large-v2. Naives Fine-Tuning von Whisper medium verschlechterte dagegen (+4,2 % WER, −7,6 BLEU auf SRB-300).
- D'Intino & Hutter (ZHAW, 2025): 17,1 % WER mit large-v3 auf SRB-300 (300 h Radio/TV).
- Flix-AI (arXiv 2606.07608, Juni 2026): 1.367 h Untertitel-alignierte Sendungen; 25,6 % WER, 13,8 % cWER auf strikt disjunkten Daten; Paper warnt vor Benchmark-Kontamination und Konventions-Mismatch (64 % der "Fehler" semantisch korrekt). Modell öffentlich: Flix-AI/flix-swissgerman-full. Weitere: Flurin17/whisper-large-v3-turbo-swiss-german (20.3.2026), nizarmichaud/whisper-large-v3-turbo-swissgerman (QLoRA, 2024, MIT), jayr23/...-ct2 (CTranslate2).
- Kommerzielle CH-Anbieter (recapp.ch, Töggl) transkribieren auf Schweizer Servern — genau das Gegenmodell zu "lokal".
- **Chance**: Ein optional nachladbares "Mundart-Modell" (turbo-Fine-Tune, quantisiert, ~600–800 MB) mit klarer Erwartungssteuerung ("Ausgabe auf Hochdeutsch, ca. 85 % Wortgenauigkeit") wäre im App-Store-Segment Tagebuch einzigartig. Aufwand L (Lizenzprüfung, Größe, Qualitätssicherung, Android-Runtime).

**Code-Switching / Sprachwechsel im Satz**
- Whisper versagt an Wechselpunkten (wortweise Sprach-ID falsch, phonetisches Mapping in falsche Sprache); Reviews sprechen von 30–50 % WER-Anstieg an Sprachgrenzen (Gladia, 2026; mustVerify). Forschung (arXiv 2412.16507, IEEE 2025) adaptiert Encoder/Decoder. Für DACH relevant: Deutsch/Englisch-Mischsätze, Deutsch/Türkisch, Schweizerdeutsch/Französisch.
- **Chance**: Pragmatisch: Sprach-Auto-Erkennung pro Eintrag + manuelle Sprachwahl pro Eintrag + "Zweitsprache" im Prompt (Whisper `initial_prompt`). Echtes intra-sententielles Code-Switching bleibt Forschungsstand.

**Halluzinationen bei Stille** (wichtig für Tagebuch-Pausen)
- Whisper erzeugt bei Stille "Thank you for watching" (24,76 % der Halluzinationen "thank you", 10,32 % "thanks for watching"; arXiv 2501.11378), "Untertitel im Auftrag des ZDF"-artige Credits. Gegenmaßnahmen (GitHub #1606, OpenWhispr #462): Silero/WebRTC-VAD vor der Transkription, `no_speech_prob`/`avg_logprob`-Filter, `condition_on_previous_text=False`, Pausen >1,5 s auf 0,3–0,5 s kürzen, `initial_prompt` "Tagebucheintrag, gesprochen".

**Transkript-Korrektur per Sprache**
- iOS Voice Control kann "Replace 'X' with 'Y'" und "Correct that" (Menü mit Alternativen, Qualität laut AppleVis begrenzt); Windows Voice Access "Correct <text>"; Android Voice Access "replace coffee with tea". Keine der Tagebuch-Apps bietet In-App-Sprachkorrektur.
- **Chance**: Nach der Aufnahme "Korrektur"-Modus: Nutzer sagt "ersetze Meier durch Maier" → lokales Pattern-Matching auf dem Transkript; plus persönliches Wörterbuch (Namen, Orte) als `initial_prompt`/Kontext-Bias für die nächste Transkription. Aufwand M.

### 2.4 Lokale Suche, Zusammenfassungen, Rückblicke

- On-device-Embeddings: Apple `NLContextualEmbedding` (iOS 17+, BERT-artig, Latin-Script-Modell 20 Sprachen inkl. Deutsch, 512 Dimensionen); Google EmbeddingGemma (308M, 100+ Sprachen, 768→128 Dim Matryoshka, <200 MB RAM quantisiert, Apache-2.0, 2.048 Token Kontext). Damit ist semantische Suche ("wann war ich zuletzt so wütend auf meinen Chef?") komplett lokal machbar.
- Zusammenfassungen: Apple Foundation Models (iOS 26, 3B on-device, 4.096 Token kombiniert Ein-/Ausgabe, iPhone 15 Pro+, Deutsch unterstützt); Android ML Kit GenAI Summarization nur EN/JA/KO (Stand Snippet 2026, mustVerify), Prompt API (Gemini Nano) auf Pixel 9/10, Galaxy S25 u. a. Für Deutsch auf Android bleibt ggf. ein eigenes kleines Modell (Gemma 3n / llama.cpp) nötig — Aufwand L.
- Rückblicke: Day Ones "On This Day" wird in Reviews als "a constant source of joy" beschrieben; "Year in Review" ist bei Day One nur eine 14-tägige E-Mail-Challenge. Ein lokal generierter Wochen-/Jahresrückblick (Audio-Collage der Highlights + Textzusammenfassung) existiert bei keiner der geprüften Apps.
- Warnsignal: Google Journals on-device-KI (Prompts, Zusammenfassungen, Mood-Emojis) löste 2026 trotz lokaler Verarbeitung Kritik aus — "defeats journaling's core purpose". Lehre: KI strikt opt-in, erklärbar, abschaltbar.

### 2.5 Stimmungserkennung aus der Stimme

- Evidenz: Systematic Review (Journal of Voice, 2025; 12 Studien, 16.872 Teilnehmer): akustische/prosodische Merkmale liefern Hinweise auf Depressionsschwere, aber "methodological heterogeneity and generalizability concerns". SER-Review (PMC12521853, 2025): meist indirekte Nutzung, uneinheitliche Architekturen; Gender-Bias dokumentiert.
- Regulierung: AI Act Art. 3(39) definiert Emotionserkennung über biometrische Daten (Stimme zählt). Art. 5(1)(f) verbietet sie am Arbeitsplatz/in Bildung (seit 2.2.2025, Ausnahme medizinisch/Sicherheit). Art. 50 (seit 2.8.2026): Betreiber müssen exponierte Personen informieren. Annex III stuft Emotionserkennung sonst als Hochrisiko ein (Pflichten ab 2.12.2027 nach Digital Omnibus; mustVerify). Zusätzlich DSGVO Art. 9 (biometrische/Gesundheitsdaten).
- **Empfehlung**: Kein automatisches Stimmungs-Inferieren im MVP. Stattdessen: freiwillige 1-Tipp-Selbsteinschätzung nach der Aufnahme oder Stimmung per Sprache ("heute eher müde") als Tag, das aus dem Transkript per Schlüsselwort extrahiert wird — transparent, editierbar.

### 2.6 Geführtes Tagebuch, Zeitkapsel, Nachlass, Export

- Geführte Prompts: Rosebud (Voice Mode seit 2024, KI-Rückfragen, CBT/IFS), Stoic (gesprochene Prompts als Einstieg). Evidenz: strukturierte Prompts helfen besonders Einsteigern; Gratitude-Interventionen kleine Effekte (PNAS 2025); Gold et al.: "three good things"-SMS-Prompts hielten positiven Affekt 3 Monate, aber ≤4 Einträge änderten nichts messbar (Sekundärquelle steps.org; mustVerify). Lokale Prompt-Bibliothek (kuratiert, ohne KI) per TTS vorgelesen: Aufwand S.
- Zeitkapsel: FutureMe (>20 Mio. Briefe, seit 2025 kostenpflichtig 9–36 USD/Jahr), PersonalCapsule/Echoeback (Voice/Video). Lokal umsetzbar: Eintrag mit "Öffnen ab"-Datum, bis dahin nur Titel sichtbar. Aufwand S.
- Nachlass/Notfallzugang: Verbraucherzentrale (Nov. 2025) empfiehlt Vertrauensperson mit Vollmacht "über den Tod hinaus", warnt vor kommerziellen Nachlassdiensten. Apple Legacy Contact / Google Inactive Account Manager decken Konten ab, nicht App-Daten ohne Cloud. Dead-Man's-Switch-Dienste (AbsentKey, Killswitch, Cipherwill, Alcazar) arbeiten mit Servern. Lücke: **Offline-Nachlass**: verschlüsseltes Export-Archiv + Wiederherstellungsschlüssel als druckbares "Notfallblatt" (QR + Passphrase-Split), das die Vertrauensperson erhält. Aufwand M.
- Export/Buch: Day One Books ab 19,99 USD (50 Farbseiten, +0,10 USD/Seite, max. 384 Seiten, nur iPhone/iPad; Abonnenten −25 %). Apple Journal exportiert nur PDF (Mac über Druckdialog); Nutzerkritik: "work trapped in a proprietary locker". Für die lokale App: Export als Markdown + JSON + Audio (offen), PDF-Buchlayout lokal generiert, Druck über Drittanbieter (PrestoPhoto akzeptiert Day-One-PDFs) ohne Datenweitergabe durch die App. Aufwand S (Text/JSON) bis M (schönes PDF).

### 2.7 Barrierefreiheit, Kinder/Familie/Paare, Therapie

- Voice-first als Zugänglichkeitsvorteil: Menschen mit Legasthenie/Dysgrafie berichten, Sprechen umgeht "spelling and motor coordination battles"; Blinde/Sehbehinderte erzeugen Text ohne Tastaturnavigation; Sprechen ~150 Wörter/Min vs. ~40 Tippen. Voraussetzung: VoiceOver/TalkBack-saubere UI, große Touch-Ziele, komplette Bedienbarkeit per Sprache/Action Button.
- Eltern/Kinder: Kiddays (Voice Notes, Briefe ans Kind, E2E), Mama Diary (Voice Memos, Briefe ans Baby), Qeepsake (Print-Alben). COPPA-Update 2025 zählt Stimmdaten explizit zu personenbezogenen Kinderdaten; DSGVO-K verlangt Elterneinwilligung. Eine rein lokale App umgeht das Server-Problem — starkes Argument für "Briefe an mein Kind" als Profil ohne Cloud. Aufwand M.
- Paar/Familie ohne Server: Sharing Me wirbt mit "completely offline with end-to-end encryption" (Premium), Waffle/Connected sind cloudbasiert. Lokale Alternative: verschlüsselte Datei-Übergabe per QR (bereits geplant) plus optional Multipeer Connectivity (iOS) / Nearby Connections (Android); plattformübergreifend ist P2P nicht standardisiert. Aufwand L.
- Therapie-Begleitung: EMA-Studien (JMIR 2025: 91,6 % Compliance bei 2x täglich, 2 Wochen) zeigen Machbarkeit von Symptomtagebüchern; DiGAs (Selfapy, edupression, HelloBetter) haben Tagebuchfunktionen und BfArM-Nachweis. Für eine lokale App: "Therapie-Export" (Zeitraum, nur Text, PDF) als bewusste Übergabe an Behandelnde — ohne Medizinprodukt-Anspruch. Aufwand S.

### 2.8 Anti-Patterns (belegt)

- Strafende Streaks und Vorwurfs-Notifications (Daylogue, LogRocket).
- Tracker/Werbe-SDKs in Tagebuch-Apps (Kuketz: Journey/Diaro; heise 2021: "Digitale Logbücher mit Sicherheitslücken").
- Cloud-Transkription als Default ohne Hinweis (Whisper Memos → OpenAI; AudioPen Serverpflicht, 3 Min. Limit gratis/15 Min. Prime).
- Export-Lock-in (Apple Journal PDF-only; Day One proprietäre Sync-Begründung fürs Abo).
- KI-Zwang: Google-Journal-Backlash trotz On-Device; Empfehlung "make AI features opt-in".
- Abo ohne Kaufoption: Day One 34,99 USD/Jahr, Nutzerzitat "$25-50 a year for a single purpose app is prohibitively expensive"; Journey 29,99–44,99 USD/Jahr.
- Feature-Überladung: "Elaborate journaling apps tend to get abandoned while simple apps get used" (Lite Journal, 2026).

---

## 3. Priorisierte Differenzierungsideen (Aufwand S/M/L, MVP ja/nein)

| # | Idee | Beleg (Kurz) | Aufwand | MVP |
|---|------|--------------|---------|-----|
| 1 | Ein-Geste-Aufnahme: Action Button, Lockscreen-Widget, Siri/App-Shortcut, Android Quick-Settings-Tile, Quick Tap | Just Press Record, Google Recorder Tile | S | ja |
| 2 | Sanftes Ritual: keine Streak-Zähler, Heatmap statt Kette, "nicht heute" ohne Nachfrage, Ruhezeiten | Daylogue, Finch, LogRocket | S | ja |
| 3 | Adaptive Erinnerung: lernt tatsächliche Aufnahmezeit (lokaler Median), 1-Tipp-Verschieben | JITAI-Receptivity, MindScape (Abend-Check-ins) | S | ja |
| 4 | Transkription strikt on-device mit Sprach-Badge pro Eintrag (de/ch/at/en/fr/it), Pausen-VAD gegen Halluzinationen | SpeechTranscriber-Locales, Whisper #1606 | M | ja |
| 5 | Offene Exporte: Markdown+JSON+Audio, PDF-Buchlayout lokal | Apple-Journal-Lock-in-Kritik, Day One Books | S | ja |
| 6 | Volltextsuche lokal (SQLite FTS5) + Sprachfilter + Datumssprung | Basis | S | ja |
| 7 | Gesprochene Prompts (kuratierte Fragen, TTS lokal), abschaltbar | Stoic, Evidenz für strukturierte Prompts | S | ja |
| 8 | Persönliches Wörterbuch (Namen/Orte) als Kontext-Bias für die Transkription | Whisper initial_prompt-Praxis | S | ja |
| 9 | Korrektur per Sprache ("ersetze X durch Y") nach der Aufnahme | Voice Control/Voice Access-Befehle | M | nein (v1.1) |
| 10 | "Auf den Tag genau"-Rückblick (vor 1/2/3 Jahren) mit Audio-Wiedergabe | Day One "On This Day" ("constant source of joy") | S | ja |
| 11 | Wochen-/Jahresrückblick lokal (Foundation Models iOS; Android später) | Apple FM 3B/4096 Token; ML-Kit-Sprachlücke | M (iOS) / L (Android) | nein |
| 12 | Semantische Suche lokal (NLContextualEmbedding / EmbeddingGemma) | 512-Dim DE; 308M, <200 MB | M | nein |
| 13 | Mundart-Paket Schweizerdeutsch (nachladbares Fine-Tune, Ausgabe Hochdeutsch) | 12,1–25,6 % WER; HF-Modelle; App-Store-Kritik | L | nein (Wachstumsfeature CH) |
| 14 | Zeitkapsel / "Brief an mich" mit Öffnungsdatum | FutureMe >20 Mio. Briefe, jetzt kostenpflichtig | S | ja (klein) |
| 15 | Offline-Nachlass: verschlüsseltes Archiv + druckbares Notfallblatt für Vertrauensperson | Verbraucherzentrale-Empfehlung, Dead-Man's-Switch nur mit Servern | M | nein (v1.2) |
| 16 | "Briefe an mein Kind"-Profil (lokal, keine COPPA/DSGVO-K-Serverproblematik) | Kiddays, COPPA 2025 Stimmdaten | M | nein |
| 17 | Therapie-Export (Zeitraum, nur Text, PDF/Markdown) | EMA-Compliance 91,6 %, DiGA-Tagebuchfunktionen | S | nein (v1.1) |
| 18 | Barrierefreiheit als Kernversprechen: vollständige Sprach-/VoiceOver-Bedienung, Legasthenie-Modus (Vorlesen des Transkripts) | Dyslexie/Sehbehinderung-Berichte | M | teilweise (VoiceOver/TalkBack ja) |
| 19 | Manuelle Stimmungs-Selbsteinschätzung per Sprache oder 1 Tipp, keine Inferenz | AI Act Art. 50/Annex III, SER-Reviews | S | optional |
| 20 | Geräteübergreifender Transfer per QR + verschlüsselte Datei; später Multipeer/Nearby | Sharing Me offline-E2E als einziger Anbieter | M | ja (geplant) |
| 21 | Einmalkauf/Lifetime-Option statt reinem Abo | Day-One-Preiskritik | S | ja (Geschäftsmodell) |
| 22 | Transparenz-Screen "Was verlässt dein Gerät: nichts" mit Netzwerk-Verzicht (kein INTERNET-Permission auf Android) | Kuketz/heise-Kritik | S | ja |

---

## 4. MVP-Empfehlung

MVP = Ideen 1–8, 10, 14, 20, 21, 22. Das ergibt: reibungsloser Start (Hardware-Taste/Widget), vergebendes Ritual, adaptive Erinnerung, lokale Transkription mit Sprachwahl und VAD, offene Exporte, Volltextsuche, "vor einem Jahr", kleine Zeitkapsel, QR-Transfer, Einmalkauf, Transparenz-Nachweis. Bewusst nicht im MVP: KI-Zusammenfassungen (Android-Sprachlücke, Backlash-Risiko), Stimmungs-Inferenz (Regulierung), Mundart-Modell (Größe/Lizenz), Nachlass (braucht sorgfältiges Krypto-UX).

Für den CH-Markt ist das Mundart-Paket die stärkste spätere Differenzierung; es sollte als klar gekennzeichnetes Beta-Feature mit Erwartungssteuerung (Hochdeutsch-Ausgabe, ~85 % Wortgenauigkeit) und nachladbarem Modell kommen.

## 5. Offene Fragen

- Exakte Lizenzlage der Swiss-German-Fine-Tunes (Flix-AI, Flurin17) und der Trainingsdaten (SRG-Untertitel) für kommerzielle Nutzung.
- Ob Apples SpeechTranscriber bei `de_CH` Dialekt-Audio nutzbar transkribiert (eigener Test nötig).
- Android: Verfügbarkeit von ML Kit Summarization für Deutsch bis Ende 2026; sonst eigenes kleines Modell.
- Ob iOS erlaubt, die AirPods-Stem-Geste an eine Drittanbieter-Aufnahme zu binden (vermutlich nur über Siri/Shortcut).
- Realer Speicher-/Batterie-Fußabdruck von large-v3-turbo quantisiert auf Mittelklasse-Android.

## 6. Quellen

Hands-free/Plattform
- https://apps.apple.com/us/app/just-press-record/id1033342465
- https://whispermemos.com/
- https://www.androidcentral.com/apps-software/google-recorder-android-quick-settings
- https://pixel.gadgethacks.com/how-to/your-pixels-best-gesture-gives-you-quick-access-your-favorite-app-from-any-screen-0385175/
- https://www.androidcentral.com/wearables/how-use-pixel-watch-recorder-app

Ritual/Streaks/Erinnerung
- https://daylogue.com/learn/journaling-app-guilt
- https://blog.logrocket.com/product-management/streaks-user-retention/
- https://calmevo.com/finch-app-review/
- https://techanjan.com/finch-review-boosting-productivity-without-the-shame/
- https://duolingo.deconstructoroffun.com/mechanics/streaks
- https://www.trypropel.ai/resources/duolingo-customer-retention-strategy
- https://pmc.ncbi.nlm.nih.gov/articles/PMC5364076/ (JITAI)
- https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0169162
- https://pmc.ncbi.nlm.nih.gov/articles/PMC11275533/ (MindScape)
- https://arxiv.org/abs/2409.09570

Transkription/On-device
- https://developer.apple.com/documentation/speech/speechtranscriber/supportedlocales
- https://developer.apple.com/forums/thread/806765
- https://antongubarenko.substack.com/p/ios-26-speechanalyzer-guide
- https://dayoneapp.com/guides/tips-and-tutorials/audio-recording/
- https://forums.dayoneapp.com/forums/topic/language-transcription-in-audio-recording/
- https://discussions.apple.com/thread/255916391
- https://klu.so/blog/apple-voice-memos-transcription-limits
- https://github.com/argmaxinc/WhisperKit
- https://arxiv.org/abs/2507.10860 (WhisperKit)
- https://openwhispr.com/blog/whisper-model-sizes-explained
- https://cactuscompute.com/compare/argmax-vs-whisper-cpp
- https://github.com/openai/whisper/discussions/1606
- https://github.com/OpenWhispr/openwhispr/issues/462
- https://arxiv.org/pdf/2501.11378 (Whisper-Halluzinationen)
- https://support.google.com/pixelphone/answer/16267698
- https://www.samsung.com/us/support/answer/ANS10000942/

Schweizerdeutsch/Code-Switching
- https://aclanthology.org/2023.acl-short.150/ (STT4SG-350)
- https://arxiv.org/abs/2305.18855
- https://aclanthology.org/2024.vardial-1.3/ (Dolev et al.)
- https://arxiv.org/html/2606.07608v1 (Flix-AI, 25,6 % WER)
- https://www.alphaxiv.org/abs/2412.15726 (Timmel et al., 12,1 % WER)
- https://huggingface.co/Flix-AI/flix-swissgerman-full
- https://huggingface.co/Flurin17/whisper-large-v3-turbo-swiss-german
- https://huggingface.co/nizarmichaud/whisper-large-v3-turbo-swissgerman
- https://www.zhaw.ch/de/engineering/ueber-uns/news/news/event-news/mithilfe-der-bevoelkerung-zhaw-und-fhnw-digitalisieren-schweizer-dialekte
- https://www.fhnw.ch/en/about-fhnw/schools/school-of-engineering/institutes/research-projects/speech-recognition-for-swiss-german
- https://apex-ai.ch/blog/whisper-fuer-schweizerdeutsch
- https://apps.apple.com/ch/app/sprachmemos-transkription/id6451387537 (Rezension: Schweizerdeutsch nicht erkannt)
- https://recapp.ch/
- https://www.gladia.io/blog/what-is-code-switching-in-speech-recognition
- https://arxiv.org/abs/2412.16507
- https://arxiv.org/pdf/2507.07741

Lokale KI/Suche
- https://developer.apple.com/documentation/naturallanguage/nlcontextualembedding
- https://www.callstack.com/blog/on-device-ai-introducing-apple-embeddings-in-react-native
- https://github.com/huggingface/blog/blob/main/embeddinggemma.md
- https://developers.googleblog.com/en/introducing-embeddinggemma/
- https://developer.apple.com/videos/play/wwdc2025/286/
- https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/
- https://www.natashatherobot.com/p/apple-foundation-models
- https://developers.google.com/ml-kit/genai/summarization/android
- https://android-developers.googleblog.com/2025/08/the-latest-gemini-nano-with-on-device-ml-kit-genai-apis.html
- https://www.techbuzz.ai/articles/google-journal-ai-features-spark-privacy-backlash
- https://dayoneapp.com/features/on-this-day/

Stimmungserkennung/Regulierung
- https://pubmed.ncbi.nlm.nih.gov/40410060/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC12521853/
- https://fpf.org/blog/red-lines-under-eu-ai-act-unpacking-the-prohibition-of-emotion-recognition-in-the-workplace-and-education-institutions/
- https://artificialintelligenceact.eu/article/50/
- https://www.goodwinlaw.com/en/insights/publications/2026/08/alerts-technology-dpc-eu-ai-act-transparency-obligations-now-in-force
- https://labs.cloudsecurityalliance.org/research/csa-research-note-eu-ai-act-article-50-transparency-20260729/

Evidenz Journaling
- https://onlinelibrary.wiley.com/doi/abs/10.1002/(SICI)1097-4679(199910)55:10%3C1243::AID-JCLP6%3E3.0.CO;2-N (Pennebaker & Seagal 1999)
- https://www.sciencedirect.com/science/article/abs/pii/S0092656606001097 (expressive talking)
- https://www.researchgate.net/publication/6721971_Experimental_Disclosure_and_its_moderators_A_meta-analysis (Frattaroli 2006)
- https://onlinelibrary.wiley.com/doi/abs/10.1111/cpsp.12224 (Reinhold 2018)
- https://www.pnas.org/doi/10.1073/pnas.2425193122 (Gratitude-Meta-Analyse 2025)
- https://steps.org/articles/does-journaling-work/
- https://formative.jmir.org/2025/1/e66187 (EMA-Compliance)
- https://www.diga-verzeichnis.de/digas/psyche/depression

Markt/Anti-Patterns/Export
- https://www.kuketz-blog.de/android-miserabler-datenschutz-bei-tagebuch-apps/
- https://www.heise.de/tests/Sechs-Tagebuch-Apps-im-Test-Digitale-Logbuecher-mit-Sicherheitsluecken-4981737.html
- https://www.yaps.ai/blog/audiopen-alternative
- https://aitoptools.com/tool/whisper-memos/
- https://www.choosingtherapy.com/dayone-app-review/
- https://forums.dayoneapp.com/forums/topic/premium-fees-for-legacy-plus-users/
- https://dayoneapp.com/book-printing/
- https://support.apple.com/guide/journal/print-and-export-entries-dev883fc2329/mac
- https://daringfireball.net/linked/2024/05/31/whats-next-for-journal
- https://litejournal.co/compare/best-journaling-app
- https://www.researchgate.net/figure/App-30-day-retention-by-mental-health-focus-The-percentages-reflect-the-number-of-users_fig2_334562120

Zeitkapsel/Nachlass/Familie/Barrierefreiheit
- https://www.openwhenitstime.com/blog/is-futureme-free
- https://www.verbraucherzentrale.de/wissen/digitale-welt/datenschutz/digitale-vorsorge-digitaler-nachlass-was-passiert-mit-meinen-daten-12002
- https://absentkey.com/en/blog/dead-man-switch-apps-compared/
- https://kiddays.app/
- https://www.fenwick.com/insights/publications/ftcs-new-coppa-guidance-on-recording-childrens-voices-five-tips-for-app-developers-and-toymakers-to-comply
- https://sharingme.app/blog/best-journal-apps-for-couples-2026
- https://developer.apple.com/documentation/multipeerconnectivity
- https://github.com/google/nearby/discussions/2447
- https://weesperneonflow.ai/en/blog/2025-10-19-voice-dictation-accessibility-dyslexia-disabilities-guide/
- https://www.applevis.com/forum/ios-ipados/dictation-needs-massive-improvements
- https://mindsera.com/articles/voice-journaling-benefits-and-the-5-best-apps-2026
