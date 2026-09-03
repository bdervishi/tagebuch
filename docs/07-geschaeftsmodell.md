# 07 · Geschäftsmodell

Stand: 3. September 2026 · Status: Entwurf

Dieses Dokument beantwortet M10 aus `00-anforderungen.md` (wirtschaftliche Verwertbarkeit) und setzt die verbindlichen Entscheidungen D9 (Preismodell) und D10 (Lizenz) um. Es ist das einzige Konzeptdokument, das Preise nennt und Erlöse rechnet. Marktdaten und Wettbewerber stehen in `01-markt-und-wettbewerb.md`, die rechtlichen Pflichten in `05-sicherheit-und-datenschutz.md` (Abschnitt 5); hier werden sie nur so weit wiederholt, wie das Geschäftsmodell davon abhängt.

Hinweis zur Quellenlage: Die Faktenprüfung (`docs/recherche/verifikation.json`) umfasst 30 technische Aussagen; keine Preis-, Benchmark- oder Marktzahl dieses Dokuments war darunter. Plattformregeln von Apple und Google sind aus Primärquellen belegt. Wettbewerberpreise, Branchen-Benchmarks (RevenueCat, Adapty) und Marktgrößen stammen aus Suchsnippets oder Drittzitaten und sind mit "(unverifiziert)" gekennzeichnet. Alle Erlösrechnungen sind eigene Rechnungen mit offen gelegten Annahmen.

## 1. Ergebnis in Kürze

- **Empfehlung: "Kostenloser Kern für immer + Plus" (D9, Variante B).** Alle Kernversprechen (Aufnahme, lokale Transkription Deutsch/Englisch, Wiedergabe, Suche, Verschlüsselung, Erinnerung, Backup, QR-Gerätewechsel, offener Export) sind dauerhaft kostenlos. Plus kostet 14,99 €/Jahr, 1,99 €/Monat oder 44,99 € einmalig (Lifetime, zugleich Unterstützer-Lizenz), mit Familienfreigabe und 7-Tage-Test nur im Jahresabo. Die einzige Grenze im kostenlosen Kern, 5 Minuten, gilt je Aufnahme, nicht je Tag (Abschnitt 4.3).
- **Plus ab Version 1.0, klein und mit einer greifbaren Hauptleistung je Plattform** (Abschnitt 4.3): Kaufgerüst, 30-Minuten-Aufnahmen und mehrere Tagebücher auf beiden Plattformen, auf Android zusätzlich das Zusatzpaket "Hohe Genauigkeit"; die iOS-Fassung des Pakets, Zusammenfassungen und Gestaltung folgen in 1.x. Das ist die Empfehlung aus `09-roadmap.md` (Abschnitt 13, Punkt 4), hier konkretisiert; `03-produktkonzept.md` ist entsprechend anzupassen.
- **Erwartung realistisch halten, als Bandbreite.** Die Auszahlung im ersten Jahr liegt je nach Szenario zwischen rund 330 € (3.000 Downloads, 1 % Zahler) und rund 11.200 € (30.000 Downloads, 2,5 %); das Basisszenario (10.000 Downloads, 1,5 %) ergibt rund 2.000 €, die D9-Punktannahmen (10.000, 2 %) rund 3.100 € (eigene Rechnung, Abschnitt 4.3). Branchenmediane für Abo-Apps liegen bei rund 500 $ Monatsumsatz (unverifiziert) [12].
- **Nebenerwerb mit Unterstützer-Erlösen, kein Geschäft.** Dem stehen nach den Aufwandsklassen aus `09-roadmap.md` rund 6 bis 13 Personenmonate Arbeit und 8.000 bis 21.000 € externe Einmalausgaben (Krypto-Review, Rechtsprüfung, Testgeräte; Bandbreiten als Setzung) gegenüber. Sobald die Arbeitszeit mitgerechnet wird, amortisiert sich die Investition in keinem Szenario unter drei Jahren; nur das optimistische Szenario deckt die externen Ausgaben innerhalb von zwei Jahren (Abschnitt 4.6). M10 ist damit beantwortet: verwertbar als Nebenerwerb mit wachsendem wiederkehrendem Anteil und B2B-Option ab Jahr 2, nicht als Haupterwerb im Planungshorizont.
- **Bezahlen ohne Datenabfluss ist möglich:** StoreKit 2 und Google Play Billing arbeiten ohne eigenen Server und ohne Drittanbieter-SDK; Kaufbelege werden auf dem Gerät geprüft (Abschnitt 5).
- **Lizenz (D10): GPLv3 für den Quellcode, Marke und Store-Builds beim Inhaber, Android zusätzlich über F-Droid.** Das kostet Erlöse aus dem F-Droid-Publikum, ist aber Voraussetzung für Listungen bei Privacy Guides und Kuketz und der stärkste Beleg für "es geht nichts ins Netz".
- **Go-to-Market ohne Werbebudget:** Privacy-Community DACH (Kuketz, heise, Mastodon, Reddit), Verzeichnisse (Privacy Guides, awesome-privacy, AlternativeTo), F-Droid, lokalisierte Store-Seiten mit klaren Keywords.
- **Größtes Risiko:** Apple Journal erhält deutsche Transkription. Gegenmittel: Android, Gerätewechsel ohne Cloud, offener Export und offener Code sind Differenzierungen, die Apple nicht kopieren wird.

## 2. Zielgruppen und Zahlungsbereitschaft

Die App bedient eine Nische, die heute niemand vollständig besetzt: täglich per Sprache, ausnahmslos lokal, iOS und Android, Deutsch als erstklassige Sprache (Befund aus `01-markt-und-wettbewerb.md`). Daraus ergeben sich fünf Zielgruppen, sortiert nach Priorität für die erste Version.

| Zielgruppe | Warum sie die App braucht | Was sie zahlt (Belege) | Wie man sie erreicht |
|---|---|---|---|
| **Datenschutzbewusste Selbstnutzer (DACH)** | Lehnen Konten, Cloud und Tracker ab; wollen nachprüfbare Aussagen statt Versprechen | Zahlen kleine, dauerhafte Beträge für Werkzeuge, deren Kern kostenlos bleibt: Bitwarden Premium 19,80 $/Jahr, Obsidian Catalyst 25 $ einmalig, Cryptomator spendenbasiert (unverifiziert) [7]. Reagieren empfindlich auf nachträgliche Bezahlschranken (Journiv-Diskussion) [25] | Kuketz-Blog, heise, Mastodon (chaos.social), Reddit r/de_EDV, r/privacy, Privacy Guides, F-Droid |
| **Android-Nutzer ohne Pixel oder aktuelles Galaxy** | Haben keine konto- und cloudfreie Systemlösung für lokale Transkription; Journey und Day One transkribieren auf Android nicht bzw. nur auf iOS (unverifiziert) [3][4] | Diarium zeigt, dass ein deutscher Solo-Entwickler mit Einmalkauf 14,99 $ rund 740.000 Android-Downloads erreicht (unverifiziert) [5] | Play-Store-Suche ("Tagebuch", "Sprachtagebuch"), Android-Foren, F-Droid |
| **Tagebuch-Umsteiger** (Day One, Journey, Apple Journal) | Ärgern sich über Preiserhöhungen (Day One Silver 49,99 $/Jahr), 10-Minuten-Grenzen, Internetpflicht und Export-Lock-in [3][4][26] | Sind Abos zwischen 24 und 50 $/Jahr gewohnt; Zitat aus Rezensionen: "25 bis 50 $ im Jahr für eine Einzweck-App ist unverhältnismäßig" (unverifiziert) [26] | Importfunktion für Day-One-JSON und Apple-Journal-ZIP (späterer Ausbau), Vergleichsseiten, Reddit r/Journaling |
| **Menschen mit Schreibhürden** (Legasthenie, Sehbehinderung, motorische Einschränkungen) | Sprechen umgeht Tastatur und Rechtschreibung; Transkript ist zugleich Untertitel | Keine belastbaren Zahlen; Zielgruppe zahlt für Barrierefreiheit, wenn sie vollständig ist (VoiceOver/TalkBack) [26] | Behindertenverbände, Selbsthilfeforen, Accessibility-Blogs; Apples Accessibility Nutrition Labels ausfüllen |
| **Schweizer Nutzer** | Bekommen Schweizer Hochdeutsch (de-CH) als Standard; Mundart ist ein späteres Zusatzpaket (D12) | Höhere Zahlungsbereitschaft im Markt üblich, aber keine Nischenzahlen | Schweizer Storefront mit eigenen Texten, Schweizer Technikpresse |

Zwei Gruppen kommen später: **Therapeuten, Coaches und Beratungsstellen**, die Klienten ein Stimmungs- oder Reflexionstagebuch als Hausaufgabe geben (Abschnitt 10), und **Eltern**, die "Briefe an mein Kind" sprechen möchten (Profil ohne Cloud, damit keine Kinderdaten auf Servern liegen) [26].

Was das Privacy-Publikum erwartet, lässt sich aus den untersuchten Projekten ableiten [7][25]:

1. Ein vollwertiger, dauerhaft kostenloser Kern ("free features never become paid", Dictus) [24].
2. Eine Einmalkauf-Option neben dem Abo.
3. Niedrige Jahresbeträge (10 bis 25 €), weil keine Serverkosten anfallen.
4. Eine transparente Begründung, wofür bezahlt wird: Modellpflege, Betriebssystem-Anpassungen, neue Funktionen, nicht Server.

## 3. Preis-Benchmarks

Alle Beträge sind US-Dollar-Angaben der Quellen, sofern nicht anders vermerkt; DACH-Preise in Euro weichen ab. Alle Zeilen: unverifiziert (Suchsnippets, Store-Seiten waren nicht abrufbar).

| App | Modell | Beträge | Bezug zum Zielprodukt | Quelle |
|---|---|---|---|---|
| Apple Journal | kostenlos | 0 | Setzt den Nullpreis auf iOS; Transkription laut Apple-Support nur Englisch | [2] |
| Day One (Automattic) | Freemium + Abo | Silver 49,99 $/J, Gold 74,99 $/J (April 2026); Altkunden 24,99 $/J | Obergrenze für Abos; KI als eigenes Tier | [3] |
| Journey | Freemium + Abo + Lifetime | 49,99 $/J, Lifetime 199 $ (4× Jahrespreis) | Lifetime-Anker | [4] |
| Diarium (Deutschland) | Einmalkauf je Plattform | 14,99 $ (Android/iOS/macOS), 19,99 $ (Windows) | Preisanker Einmalkauf für DACH | [5] |
| Diarly (Apple) | Abo | unter 2 $/Monat bzw. unter 24 $/Jahr; DE-Listing 27 €/J; separates AI+-Abo | Untergrenze Abo für ein Privacy-Tagebuch | [6] |
| Daylio | Freemium + Abo | 4,99 $/M, 35,99 $/J | Mittelfeld ohne Voice | [1] |
| Flint (Klu) | Einmalkauf | 12 $ "instead of a recurring fee" | Direktester Einmalkauf-Benchmark im Voice-Segment | [8] |
| Local Journal, Whisper Notes | Einmalkauf | 6,99 $ bzw. 7,99 $ | Untergrenze Einmalkauf | [9] |
| CortexOS | Freemium + Abo + Lifetime | 7,99 $/M, 49,99 $/J, Lifetime 99,99 $ (andere Quelle 9,99/79,99/199,99 $) | Nächster Wettbewerber, aber KI-Analyse und Cloud-Vault | [9] |
| Cleft Notes | Freemium + Abo | Basic 5-Minuten-Notizen frei; Plus 6,99 $/M, 39,99 $/J | Vorbild für den Schnitt "5 Minuten frei, 30 Minuten Plus" | [9] |
| DailyVox (Open Source, iOS) | kostenlos | 0, keine In-App-Käufe | Kostenloses Open-Source-Vorbild mit "Data Not Collected" | [10] |
| Bitwarden, Obsidian, Proton, Standard Notes | Privacy-Apps | 19,80 $/J; App frei + Sync 4 $/M + Catalyst 25 $; ab 3,99 $/M; ~90 $/J | Muster: Kern frei, Bezahlung für Komfort und Unterstützung | [7] |

Beobachtungen: Der Markt teilt sich in "Einmalkauf 7 bis 15 $" für lokale Werkzeuge und "Abo 25 bis 50 $/Jahr" für Sync-Produkte. Lifetime liegt beim Zwei- bis Vierfachen des Jahresabos. KI-Funktionen werden überall als eigenes Tier verkauft. Die kostenlosen Stufen sind großzügig, weil Apple Journal den Nullpreis setzt.

Branchenbenchmarks zur Einordnung (RevenueCat 2025/2026, Adapty 2026; alle unverifiziert, aus Drittzitaten) [11][12]: Median Download-zu-Zahler 1,7 % (Top-Apps 4,2 %); Freemium konvertiert innerhalb 35 Tagen zu 2,1 %, harte Bezahlschranke zu 10,7 %; Test-zu-Zahler bei Health & Fitness 37,7 bis 39,9 %; 12-Monats-Verbleib bei Jahresabos 44,1 %, bei Monatsabos 17,0 %; Median-Jahrespreis Health & Fitness 39,99 $, Productivity 29,99 $. Adapty: Median-Monatsumsatz einer Abo-App 492 $, 59,3 % aller Apps unter 1.000 $/Monat.

## 4. Drei Varianten mit Rechnung

### 4.1 Gemeinsame Annahmen

Alle drei Varianten teilen den kostenlosen Kern aus D9. Die Punktannahmen stammen aus D9 und dem Recherchebericht [15]; ich habe die Rechnung nachgerechnet. Sie ist nicht konservativ, sondern ein Mittelwert nach oben: Die Downloads sind eine Setzung, die Zahlerquote stammt aus nordamerikanischen Daten mit Test- und Hard-Paywall-Trichtern, und der F-Droid-Build enthält alle Plus-Funktionen kostenlos (D10). Deshalb rechnet Abschnitt 4.3 zusätzlich drei Szenarien.

| Annahme | Wert | Herkunft |
|---|---|---|
| Downloads im ersten Jahr | 10.000 (organisch, DACH) | Setzung aus D9, keine hergeleitete Zahl. Vergleichswerte im eigenen Material: WhisperJournal (Android, kostenlos, kein Ritual) rund 1.100 Downloads; Diarium rund 740.000 Android-Downloads über viele Jahre; der Recherchebericht hält 50.000 bis 200.000 Downloads über drei Jahre für ein Erfolgsszenario (alle unverifiziert) [5][15][45]. Suchvolumen und Reichweite der Privacy-Medien waren nicht prüfbar (offene Frage 2) |
| Download-zu-Zahler | 2 % (Abo-Modelle), 3 % (reiner Einmalkauf), 2,5 % (Update-Pass); Szenarien 1 %, 1,5 %, 2,5 % | RevenueCat: Median 1,7 %, Top-Apps 4,2 %, Freemium nach 35 Tagen 2,1 %; Daten aus Nordamerika, überwiegend mit Test oder harter Bezahlschranke (unverifiziert) [11]. Hier: großzügiger Gratis-Kern und F-Droid-Build, deshalb Bandbreite nach unten |
| Lifetime-Anteil an den Zahlern | 25 % (D9-Punktwert); Szenarien 10 bis 25 % | Setzung; 44,99 € liegt über dem Einmalkauf-Anker des Segments (Abschnitt 3), deshalb im pessimistischen Fall 10 % |
| Erstattungen und unfreiwillige Kündigung | 0 % (D9-Punktwert); Szenarien 5 bis 10 % der Abo-Erlöse | RevenueCat 2025: Erstattungsquote 2,55 % (Productivity) bis 4,71 % (Health & Fitness); RevenueCat 2026: unfreiwillige Kündigung durch Zahlungsfehler iOS 14 %, Android 31 % (unverifiziert) [11]; Abzug als eigene Zusammenfassung beider Effekte |
| Store-Abgabe | 15 % | Apple Small Business Program (bis 1 Mio. $ Vorjahres-Proceeds) [13]; Google Play 15 % auf die erste Million und alle Abos (unverifiziert) [14] |
| Mehrwertsteuer im Ladenpreis | 19 % (Deutschland) | D9; Österreich 20 % und Schweiz 8,1 % weichen ab (unverifiziert) |
| Auszahlung je Euro Ladenpreis | 1/1,19 × 0,85 = 0,714, also rund 71 % | eigene Rechnung |
| Verbleib Jahresabo | 44 % verlängern | RevenueCat 2026 (unverifiziert) [11] |
| Monatsabo-Zahler | bleiben im Mittel 5 Monate | Annahme |

### 4.2 Variante A: reiner Einmalkauf

Kern kostenlos, "Vollversion" 14,99 € einmalig mit allen Plus-Funktionen.

- Jahr 1: 300 Käufe × 14,99 € = 4.497 € brutto, Auszahlung rund 3.210 €.
- Jahr 2: bei gleichem Download-Volumen identisch; kein wiederkehrender Umsatz aus Jahr 1.

Vorteile: höchste Akzeptanz beim Privacy-Publikum (Flint-, Diarium-Muster), einfachste Umsetzung, Familienfreigabe möglich. Nachteile: Modellpflege, Betriebssystem-Anpassungen und neue Sprachpakete werden nicht finanziert; Umsatz wächst nur mit Downloads.

### 4.3 Variante B: kostenloser Kern + Plus (Empfehlung, D9)

Plus: 14,99 €/Jahr, 1,99 €/Monat, Lifetime 44,99 € (dreifacher Jahrespreis als Anker, zugleich als Unterstützer-Lizenz beschrieben). 7-Tage-Test nur im Jahresabo, Familienfreigabe aktiv.

**Rechnung mit den D9-Punktannahmen** (Referenz, eigene Rechnung):

- Jahr 1: 200 Zahler, Mischung 55 % Jahr / 20 % Monat / 25 % Lifetime. 110 × 14,99 € = 1.649 € + 40 × 1,99 € × 5 Monate = 398 € + 50 × 44,99 € = 2.250 €. Summe 4.297 € brutto, Auszahlung rund 3.070 €.
- Jahr 2: gleiche Neukohorte 4.297 € + 48 Verlängerer × 14,99 € = 726 €. Summe 5.023 € brutto, Auszahlung rund 3.590 €.
- Jahr 3: 4.297 € + 726 € (Verlängerer aus Jahr 2) + 21 × 14,99 € = 315 € (zweite Verlängerung aus Jahr 1). Summe rund 5.340 € brutto, Auszahlung rund 3.810 € (der Recherchebericht nennt rund 3.900 €).

**Szenarien statt Punktwert** (eigene Rechnung; Rechenweg: Abo-Zahler teilen sich 55:20 in Jahres- und Monatsabo, Monatsabo 5 Monate, Jahresabo verlängert 44 % pro Jahr, Abzug für Erstattungen und unfreiwillige Kündigung nur auf Abo-Erlöse, Auszahlung 71 % des Ladenpreises; Beträge gerundet):

| Szenario | Downloads | Zahler | Lifetime-Anteil | Abzug Abo | Brutto Jahr 1 | Auszahlung Jahr 1 | Jahr 2 | Jahr 3 | Summe 3 Jahre |
|---|---|---|---|---|---|---|---|---|---|
| Pessimistisch | 3.000 | 1,0 % = 30 | 10 % | 10 % | ~470 € | ~330 € | ~420 € | ~450 € | ~1.200 € |
| Basis | 10.000 | 1,5 % = 150 | 20 % | 7,5 % | ~2.860 € | ~2.050 € | ~2.430 € | ~2.600 € | ~7.100 € |
| D9-Punktwert | 10.000 | 2,0 % = 200 | 25 % | 0 % | 4.297 € | ~3.070 € | ~3.590 € | ~3.810 € | ~10.500 € |
| Optimistisch | 30.000 | 2,5 % = 750 | 25 % | 5 % | ~15.700 € | ~11.200 € | ~13.100 € | ~13.900 € | ~38.200 € |

Das pessimistische Szenario ist kein Ausreißer, sondern der Fall, dass die Privacy-Community die App lobt, aber über F-Droid oder ohne Plus nutzt. Das optimistische Szenario setzt eine Erwähnung in reichweitenstarken Medien und eine Zahlerquote oberhalb des Freemium-Medians voraus; belegt ist beides nicht.

Vorteile: wiederkehrender Anteil wächst; Lifetime bedient Abo-Verweigerer und bringt frühes Geld; die Struktur mit zwei bis drei Plänen entspricht dem, was Nutzer 2026 aus anderen Apps kennen. Nachteile: Abo-Skepsis in Rezensionen ist einzukalkulieren; die Begründung "wofür zahle ich" muss im Store-Text und in der App stehen; Lifetime liegt über dem Einmalkauf-Anker des Segments (Abschnitt 9).

Der Free/Plus-Schnitt aus D9:

| Kostenlos, dauerhaft garantiert | Plus |
|---|---|
| Unbegrenzt viele Einträge | Aufnahmen bis 30 Minuten je Aufnahme |
| Aufnahmen bis 5 Minuten je Aufnahme, unbegrenzt viele Aufnahmen pro Tag | Zusatzpaket "Hohe Genauigkeit" (große Modelle, D2/D3) |
| Lokale Transkription Deutsch und Englisch | Gestaltete Rückblicke (Woche, Monat, Jahr) und lokale Zusammenfassungen (ab Version 1.x, D8) |
| Wiedergabe, Volltextsuche, Kalender, "vor einem Jahr" | Mehrere Tagebücher |
| Verschlüsselung, App-Sperre | Gestaltetes Jahrbuch-PDF |
| Tägliche Erinnerung | Weitere Sprachen, später Mundart-Paket |
| Verschlüsseltes Backup und QR-Gerätewechsel | Themes, App-Icons, Widgets |
| Export als Markdown, JSON, PDF | |

Der Schnitt ist so gewählt, dass es keinen Lock-in gibt: Wer nie zahlt, verliert nie Daten und kann jederzeit vollständig exportieren oder das Gerät wechseln. Die 5-Minuten-Grenze deckt ein normales Tagesritual (Rechenbasis in D6: 3 Minuten pro Tag) und liegt unter den 10 Minuten von Day One und Journey, aber ohne Internetpflicht. Store-Text und Datenschutzerklärung enthalten die Garantie: **Kostenlose Funktionen werden nie kostenpflichtig.** Diese Selbstverpflichtung ist rechtlich bindend und deshalb bewusst zu formulieren (siehe `05-sicherheit-und-datenschutz.md`).

**Festlegung: Die 5-Minuten-Grenze gilt je Aufnahme, nicht je Tag.** D9 formuliert "je Eintrag"; nach A4 ist ein Eintrag ein Tag mit mehreren Aufnahmen. Gälte die Grenze als Tagessumme, stieße das kostenlose Ritual (Eintrag am Abend plus eine Ergänzung) schon am ersten Tag an die Bezahlschranke, im Widerspruch zur Garantie, dass Kernversprechen nie hinter einer Bezahlschranke liegen. Also: jede einzelne Aufnahme bis 5 Minuten kostenlos, unbegrenzt viele Aufnahmen pro Tag; Plus hebt die Grenze je Aufnahme auf 30 Minuten. Verhalten an der Grenze (für `03-produktkonzept.md`, Abschnitt 2.1, und als Testfall in `09-roadmap.md`, Phase 3): dezenter Hinweis bei 4:30, weicher Stopp bei 5:00 mit sofortigem Angebot "Ergänzen" (neue Aufnahme im selben Tageseintrag); Audio wird nie verworfen; der Hinweis auf Plus erscheint erst nach dem Stopp und höchstens einmal am Tag, nie mitten im Satz. Damit schließt sich die offene Frage 3 aus `03-produktkonzept.md`; die Formulierung "je Eintrag" in D9 ist in diesem Sinn zu lesen.

**Wortwahl für "Hohe Genauigkeit".** Das Paket heißt im Store-Text nicht "besseres Deutsch", sondern "größeres Modell für schwierige Aufnahmen (Nebengeräusche, Akzent, leise Stimme)". Wer für gute deutsche Transkription zahlen müsste, erlebte das kostenlose Versprechen "Deutsch als erstklassige Sprache" als beschnitten; das Standardmodell muss den Alltag tragen, das Paket ist die Reserve.

**Plus ab Version 1.0, nicht erst 1.x.** `03-produktkonzept.md` (Abschnitt 8.2) legt heute alle Plus-Funktionen in 1.x, `09-roadmap.md` (Abschnitt 13, Punkt 4) empfiehlt Kaufgerüst und ein kleines Plus schon in 1.0. Empfehlung: die Roadmap-Variante, mit folgendem Umfang, weil 30-Minuten-Aufnahmen allein für ein Drei-Minuten-Ritual kein Kaufgrund sind und Lifetime-Codes für Beta-Tester (Abschnitt 7.1) ein Plus-Produkt voraussetzen:

1. Kaufgerüst in 1.0: StoreKit 2, Play Billing, "Käufe wiederherstellen", Offer Codes; damit laufen DSA-Händlerstatus, In-App-Kauf-Review und der Billing-ohne-`INTERNET`-Test (Spike S3) nur einmal.
2. Auf beiden Plattformen in 1.0: Aufnahmen bis 30 Minuten und mehrere Tagebücher (in einer Flutter-Codebasis beides klein; mehrere Tagebücher sind die greifbare Hauptleistung für iOS).
3. Auf Android zusätzlich in 1.0: Zusatzpaket "Hohe Genauigkeit" mit Parakeet TDT 0.6B v3 über dieselbe sherpa-onnx-Engine als on-demand-Asset, weil dort der Abstand zwischen Standardmodell (Deutsch-WER 7,5 %) und großem Modell (rund 4 %) sichtbar ist (D3; Lizenz und RAM-Bedarf aus Phase 1).
4. In 1.x: das iOS-Paket (WhisperKit), weil der Gewinn gegenüber `SpeechTranscriber` erst im Spike S1 messbar wird (D2); Zusammenfassungen (D8), Jahrbuch-PDF, weitere Sprachen, Themes und Widgets.

Alternative: 1.0 vollständig kostenlos, Plus mit 1.1. Dann fehlen im ersten Jahr die Monate ohne Plus; bei drei Monaten Abstand (Annahme) sinkt die Auszahlung des ersten Jahres anteilig auf rund 1.500 € (Basis) bzw. rund 2.300 € (D9-Punktwert), und die Beta-Tester erhalten ihre Codes erst nachträglich. `03-produktkonzept.md` (Abschnitt 8) und `09-roadmap.md` (Phase 3, Paket 14; Phase 8) sind an die gewählte Variante anzupassen.

### 4.4 Variante C: "Kaufen, später Update-Pass"

Vollversion 19,99 € einmalig inklusive 12 Monaten Updates; danach läuft alles weiter, neue Funktionen erfordern einen Update-Pass für 7,99 €/Jahr (im StoreKit als Non-Consumable plus Non-Renewing Subscription abbildbar).

- Jahr 1: 250 Käufe × 19,99 € = 4.998 € brutto, Auszahlung rund 3.570 €.
- Jahr 2: Neukohorte 3.570 € + 30 % Pass-Käufer (75 × 7,99 € = 599 €, Auszahlung 428 €) = rund 4.000 €.

Vorteile: höchste Glaubwürdigkeit ("Ihr Tagebuch läuft für immer"), planbare Zusatzeinnahmen. Nachteile: Funktionsfreigabe nach Kaufdatum ist technisch und im Store-Review fehleranfällig, für Nutzer erklärungsbedürftig, und Familienfreigabe ist kein Standardfall.

### 4.5 Vergleich und Empfehlung

| | A Einmalkauf | B Kern + Plus | C Update-Pass |
|---|---|---|---|
| Auszahlung Jahr 1 (eigene Rechnung) | ~3.210 € | ~3.070 € | ~3.570 € |
| Auszahlung Jahr 2 | ~3.210 € | ~3.590 € | ~4.000 € |
| Wiederkehrender Anteil | keiner | wächst | gering |
| Akzeptanz Privacy-Publikum | sehr hoch | hoch, wenn Lifetime und Garantie sichtbar | sehr hoch |
| Umsetzungsaufwand | gering | mittel | hoch (Datumslogik) |
| Familienfreigabe | ja | ja | eingeschränkt |

**Empfehlung: Variante B**, weil sie als einzige laufende Pflege finanziert (Modellwechsel, iOS- und Android-Jahresversionen, neue Sprachpakete), ohne den kostenlosen Kern anzutasten. Lifetime liegt bewusst über dem Einmalkauf-Anker des Segments (7 bis 15 $, Abschnitt 3) und ist als Unterstützer-Preis gedacht; die Einmalkauf-Erwartung des Privacy-Publikums wird damit nur teilweise bedient (Risiko in Abschnitt 9, Preisfrage in Abschnitt 11). Falls der Inhaber Abos grundsätzlich ablehnt, ist C die zweitbeste Wahl; A nur, wenn kein längerfristiger Weiterbetrieb geplant ist (D9).

Skalierung mit den D9-Punktannahmen: Bei 30.000 Downloads im Jahr verdreifachen sich alle Werte (B: rund 9.200 € im ersten, 10.800 € im zweiten Jahr). Bei 100.000 Downloads (Diarium-Klasse über mehrere Jahre) liegt B bei 30.000 bis 36.000 €/Jahr, oberhalb der Kleinunternehmergrenze, aber weit unter der Schwelle von 1 Mio. $ des Small Business Program [13][15]. Die laufenden Fixkosten ohne Einmalausgaben sind klein (Apple Developer Program 99 $/Jahr, Google Play einmalig 25 $, Rechtsbausteine rund 300 €) [13][15]; über die Wirtschaftlichkeit entscheiden aber die Einmalausgaben und die Arbeitszeit, die der folgende Abschnitt beziffert.

### 4.6 Investition und Break-even

Bisher fehlte der Rechnung die Kostenseite. Sie besteht aus drei Teilen: Arbeitszeit einer Person, externe Einmalausgaben, laufende Kosten. Alle Beträge sind eigene Rechnungen mit ausgewiesenen Annahmen; wo keine Quelle existiert, steht "Setzung".

**Arbeitszeit** nach den Aufwandsklassen aus `09-roadmap.md` (Abschnitt 1: S = wenige Tage, M = ein bis drei Wochen, L = ein bis zwei Monate, XL = mehr als zwei Monate). Umrechnung als Setzung: S = 0,25 Monat, M = 0,25 bis 0,75, L = 1 bis 2, XL = 3 bis 4 Monate; ein Personenmonat = 160 Stunden.

| Phase (09) | Klasse | Personenmonate |
|---|---|---|
| 0 Vorbereitung | S | 0,25 |
| 1 Technische Spikes | L | 1 bis 2 |
| 2 Durchstich | M | 0,25 bis 0,75 |
| 3 MVP-Aufbau | XL | 3 bis 4 |
| 4 Härtung und Alpha | L | 1 bis 2 |
| 5 Beta | M bis L | 0,25 bis 2 |
| 6 Store-Vorbereitung | M | 0,25 bis 0,75 |
| 7 Start | S bis M | 0,25 bis 0,75 |
| **Summe bis Version 1.0** | | **rund 6 bis 13 Personenmonate (1.000 bis 2.080 Stunden)** |

Kalkulatorischer Stundensatz als Setzung ohne Quelle: 50 €/Stunde (untere Grenze, Opportunitätskosten eines Nebenerwerbs) bis 80 €/Stunde (Freiberufler-Niveau). Ergebnis: 50.000 € (6 Monate, 50 €) bis 166.000 € (13 Monate, 80 €); bei 10 Monaten 80.000 bis 128.000 €. Pflege nach dem Start (jährliche Betriebssystem-Versionen, Modellwechsel, 1.x-Funktionen) kommt hinzu und ist hier nicht bewertet.

**Externe Einmalausgaben** (Bandbreiten sind Setzungen; vor Beauftragung Angebote einholen, offene Frage 13):

| Posten | Herkunft der Empfehlung | Betrag |
|---|---|---|
| Bezahlter Kurz-Review des Krypto- und Containerkerns | `09-roadmap.md` Abschnitt 7, `05-sicherheit-und-datenschutz.md` Abschnitt 4.2 | 5.000 bis 15.000 € (Setzung) |
| Rechtsprüfung der unverifizierten Punkte (Impressum, Exportkontrolle, Play-Richtlinien, MDR-Abgrenzung, GPL und Store) | `09-roadmap.md` Abschnitt 13, Punkt 6; Abschnitt 6 dieses Dokuments | 1.000 bis 3.000 € (Setzung) |
| Testgerätepool, fünf Geräte (zwei iPhones, Pixel, Samsung-Mittelklasse, Xiaomi) | `09-roadmap.md` Phase 0 | 2.000 bis 3.000 € (Setzung) |
| Entwicklerkonten und Rechtsbausteine | [13][15] | Apple 99 $/Jahr, Google 25 $ einmalig, Rechtsbausteine rund 300 € |
| **Summe einmalig, ohne Arbeitszeit** | | **rund 8.000 bis 21.000 €** |

**Laufende Kosten ohne Einmalausgaben:** Apple Developer Program 99 $/Jahr plus Domain; mit UG oder GmbH zusätzlich ab rund 1.000 €/Jahr (Schätzung des Rechercheberichts) [15]. Ein Einzelunternehmen mit c/o-Adresse bleibt darunter (Abschnitt 8).

**Break-even** (kumulierte Auszahlung aus der Szenariotabelle in Abschnitt 4.3 gegen die Kosten; eigene Rechnung, laufende Kosten nicht abgezogen):

| Szenario | Auszahlung kumuliert nach 3 Jahren | Externe Einmalausgaben (8.000 bis 21.000 €) gedeckt | Externe Ausgaben plus Arbeitszeit (50.000 bis 166.000 €) gedeckt |
|---|---|---|---|
| Pessimistisch | ~1.200 € | nie; mit UG übersteigen schon die laufenden Kosten die Erlöse | nie |
| Basis | ~7.100 € | frühestens Jahr 4 (untere Grenze), Jahr 9 (obere Grenze) | rechnerisch nach 20 bis 60 Jahren, also nie |
| D9-Punktwert | ~10.500 € | Jahr 3 bis Jahr 6 | rechnerisch nach 14 bis 40 Jahren, also nie |
| Optimistisch | ~38.200 € | Jahr 1 bis Jahr 2 | Jahr 4 bis Jahr 13 |

Ergebnis: **Nebenerwerb mit Unterstützer-Erlösen, kein Geschäft.** Sobald die Arbeitszeit mitgerechnet wird, amortisiert sich die Investition in keinem Szenario unter drei Jahren; nur das optimistische Szenario deckt die externen Ausgaben innerhalb von zwei Jahren. Was das Bild ändern würde, sind nicht Preisdetails, sondern Reichweite (Diarium-Klasse, Abschnitt 4.5), B2B-Pakete (Abschnitt 10) oder ein bewusst kleinerer Bau. Am externen Review und an der Rechtsprüfung zu sparen, ist keine Option, weil beides das Kernversprechen trägt. Für den Inhaber heißt das: Die App lohnt sich, wenn er sie ohnehin bauen und selbst nutzen will und die Arbeitszeit nicht als Investition mit Rendite verbucht; als Einkommensprojekt lohnt sie sich im Planungshorizont nicht.

## 5. Bezahlfunktionen, die die Privatsphäre nicht verletzen

Die Bezahlung darf D14 nicht aufweichen: keine Konten, keine Server des Inhabers, keine Drittanbieter-SDKs mit Netzwerkzugriff, Datenschutzlabel "Es werden keine Daten erfasst".

**Was geht:**

1. **StoreKit 2 (iOS) und Google Play Billing Library (Android) direkt.** Beide laufen über das Betriebssystem bzw. die Play-Dienste; die App selbst öffnet keine Verbindung. Apples App-Privacy-Definition zählt nur Daten als "erfasst", die die App vom Gerät wegsendet und auf die der Entwickler oder seine Partner zugreifen; Käufe über den Store verarbeitet Apple als eigener Verantwortlicher [16].
2. **Kaufbeleg lokal prüfen.** StoreKit 2 liefert signierte Transaktionen (JWS), die auf dem Gerät verifiziert werden; Play Billing liefert Kaufdaten mit Signatur, die gegen den öffentlichen Lizenzschlüssel der App geprüft werden. Kein eigener Server, keine Belegweiterleitung an Dritte.
3. **Berechtigung lokal cachen.** Der Plus-Status wird im sicheren Speicher der App abgelegt, damit die App auch im Flugmodus vollständig funktioniert; Abo-Verlängerungen aktualisiert das Betriebssystem im Hintergrund. Auf Android ist im Spike zu bestätigen, dass die Billing Library ohne `android.permission.INTERNET` der App arbeitet (D3).
4. **Familienfreigabe** für Non-Consumables (Lifetime) und Auto-Renewables: bis zu fünf weitere Personen, einmal aktiviert nicht rücknehmbar [17]. Auf Android über die Play Family Library für Einmalkäufe.
5. **Offer Codes** für alle Kauftypen inklusive Non-Consumables (seit 29. Oktober 2025) für Presse, Tester, Therapeuten [18]. Der Code wird im Store eingelöst; die App erfährt nur den Kauf.
6. **Käufe wiederherstellen** ohne Konto: die Store-Identität des Betriebssystems genügt; die App speichert nichts über die Person.
7. **Karenzzeit und Zahlungsfehler** überlässt man dem Store (Grace Period, Account Hold bei Google) [19]; die App reagiert nur auf den Status.

**Was nicht geht, auch wenn es bequem wäre:**

- Abo-Dienstleister wie RevenueCat oder Adapty: Ihre SDKs senden Gerätedaten an eigene Server und machen das Label "Es werden keine Daten erfasst" unmöglich.
- Server-seitige Belegprüfung, Werbe-Attribution, A/B-Test-SDKs für Bezahlschranken (Product Page Optimization von Apple ist die datenschutzkonforme Alternative, weil sie im Store läuft [20]).
- Freischaltung über eigene Lizenzschlüssel oder über den QR-Code: Apple-Richtlinie 3.1.1 erlaubt Funktionsfreischaltung nur über In-App-Käufe; der Transfer-QR darf nichts freischalten [21].
- Alternative Zahlungsabwicklung nach den EU-Terms: Ab 1. Oktober 2026 gelten 10 % statt 15 % für Small-Business-Teilnehmer, dagegen stehen Zahlungsdienstleister (rund 1,5 bis 3 %), eigene Steuerabwicklung, Rechnungen, Erstattungen und der Verlust von Familienfreigabe und Store-Abo-Verwaltung [22]. Empfehlung: bei In-App-Käufen bleiben; die Option erst ab mittlerem fünfstelligem Jahresumsatz prüfen.

Auf der Produktseite lassen sich bis zu 20 In-App-Käufe bewerben; Non-Consumables und Abos erscheinen in der Store-Suche [23]. Der 7-Tage-Test gilt nur für das Jahresabo, weil Tests von 17 bis 32 Tagen zwar besser konvertieren (42,5 %, unverifiziert), aber bei einem Tagebuch der Nutzen erst nach einigen Tagen sichtbar wird und ein kurzer Test das Abo-Risiko für Nutzer klein hält [11].

## 6. Lizenzfrage: Vertrauen und Erlöse zusammenbringen

**Empfehlung (D10): Quellcode öffentlich unter GPLv3; Marke, Store-Konten und Store-Builds beim Inhaber; Krypto- und Containerkern als separat auditierbare Dart-Bibliothek; Android zusätzlich über F-Droid mit reproduzierbarem Build.**

Begründung:

1. **Das Kernversprechen ist nur mit Quellcode belegbar.** "Wir können Ihre Einträge nicht lesen, technisch nicht" ist eine Behauptung; einsehbarer Code plus reproduzierbarer Android-Build machen sie prüfbar (`05-sicherheit-und-datenschutz.md`, Abschnitt 4).
2. **Reichweite im Privacy-Publikum hängt daran.** Privacy Guides nimmt nur Apps mit Open-Source-Clients auf; Kuketz-Blog erwartet Trackerfreiheit und F-Droid-Verfügbarkeit; awesome-privacy listet kostenlos [27][28][29]. Diese drei Kanäle ersetzen für die Zielgruppe ein Werbebudget.
3. **GPLv3 statt MIT/Apache schützt das Geschäftsmodell.** Wer die App forkt und als geschlossene Cloud-Variante vertreiben will, muss den Quellcode offenlegen. AGPL bringt nichts zusätzlich, weil es keinen Server gibt.
4. **Die Marke bleibt beim Inhaber.** Name, Logo und Store-Einträge sind nicht Teil der Lizenz; Forks müssen umbenennen. Das ist das übliche Muster (Signal, Cryptomator) und sichert, dass "die App im Store" die vom Inhaber signierte ist.
5. **Lizenzkompatibilität ist gegeben.** libsodium (ISC), SQLCipher (BSD), sherpa-onnx (Apache 2.0), Moonshine (MIT), WhisperKit (MIT), Flutter (BSD) lassen sich in ein GPLv3-Projekt einbinden; Hinweispflichten stehen in `05-sicherheit-und-datenschutz.md` [30].

**Der Preis dieser Wahl, offen benannt:** Der F-Droid-Build enthält keinen Store-Kaufmechanismus und damit alle Plus-Funktionen kostenlos. Erlöse entstehen aus Bequemlichkeit (Store-Installation, automatische Updates, Familienfreigabe, Modelle per Play Asset Delivery) und aus Unterstützung, wie bei vielen Indie-Werkzeugen. Das F-Droid-Publikum ist klein und überschneidet sich stark mit Nutzern, die ohnehin nicht über Stores kaufen würden; der Reichweitengewinn wiegt den Erlösverzicht nach Einschätzung dieses Dokuments auf. Zusätzlich sollte der Store-Build eine sichtbare, freiwillige Unterstützungsoption bieten (Lifetime als "Unterstützer-Lizenz", nach dem Vorbild Obsidian Catalyst).

**Alternative, falls der Inhaber das nicht will:** Open Core. Engine, Kryptografie und Containerformat offen (damit der Sicherheitskern auditierbar bleibt), Oberfläche und Plus-Funktionen proprietär mit öffentlichem Repository. Damit entfällt die Listung bei Privacy Guides, und der Nachweis "keine Netzverbindung" hängt am reproduzierbaren Build der proprietären Teile, was auf iOS ohnehin nicht möglich ist.

**Zu regeln vor dem ersten fremden Beitrag:** Ob GPLv3-Code im App Store vertrieben werden darf, ist umstritten, sobald fremde Beiträge ohne Zusatzerlaubnis enthalten sind; der Inhaber ist an seine eigene Lizenz nicht gebunden, Dritte schon. Deshalb: entweder Beiträge nur mit Contributor License Agreement annehmen, das dem Inhaber Store-Vertrieb und Doppellizenzierung erlaubt, oder eine ausdrückliche "App-Store-Ausnahme" in die Lizenzdatei aufnehmen. Rechtlich prüfen lassen (offene Frage 4).

## 7. Go-to-Market für ein Privacy-Publikum in DACH

### 7.1 Reihenfolge

1. **Vor dem Start (Monate -3 bis 0):** Repository öffentlich, Threat-Model und Netzwerk-Null-Nachweis dokumentiert, Transparenz-Bildschirm "Was verlässt dein Gerät: nichts" in der App, Datenschutzerklärung online. Geschlossener Test über TestFlight und Play Closed Testing mit 50 bis 100 Personen aus der Privacy-Community; Tester erhalten Lifetime per Offer Code. Ziel: erste ehrliche Rezensionen am Starttag.
2. **Start:** Store-Seiten in Deutsch (DE, AT, CH) und Englisch; Pressemappe mit den Argumenten aus 7.3; Einreichung bei awesome-privacy (Pull Request) und AlternativeTo (Tags "offline", "no account", "end-to-end encryption"); Beiträge auf Mastodon (chaos.social, mastodon.social), Reddit (r/de_EDV, r/privacy, r/PrivacyGuides, r/Journaling, r/degoogle, r/androidapps) mit Fokus auf Architektur, nicht Werbung.
3. **Nach dem Start (Monate 1 bis 3):** F-Droid-Einreichung mit reproduzierbarem Build; Vorstellung im Privacy-Guides-Forum mit Threat-Model; Pitch an Kuketz-Blog (Empfehlungsecke, App-Prüfungen), heise online/c't (App-Tests), Golem, t3n, Schweizer Technikpresse. Product Page Optimization mit bis zu drei Varianten über 90 Tage [20].
4. **Monate 4 bis 12:** Apple Search Ads nur als kleiner Test auf "Tagebuch"/"Journal", weil der Umsatz pro Installation bei Freemium-Apps niedrig ist (RevenueCat 2026: 0,27 bis 0,38 $ nach 60 Tagen, unverifiziert) [11]; Importer für Day One und Apple Journal als Umsteiger-Argument; erste B2B-Gespräche (Abschnitt 10).

### 7.2 ASO-Keywords

Suchvolumen waren nicht prüfbar; die Listen sind Hypothesen, die mit Apple Search Ads Popularity oder einem ASO-Werkzeug zu validieren sind.

| | Deutsch | Englisch |
|---|---|---|
| Kernbegriffe | Tagebuch, Tagebuch App, Sprachtagebuch, Audio Tagebuch, Tagebuch mit Sprache, Journal App deutsch | voice journal, voice diary, audio journal, journal app |
| Privatsphäre | offline Tagebuch, Tagebuch ohne Cloud, verschlüsseltes Tagebuch, Tagebuch ohne Konto, Tagebuch mit Schloss | private journal, offline journal, encrypted diary, journal no account, no cloud |
| Ritual | Stimmungstagebuch, Dankbarkeitstagebuch, tägliches Tagebuch, Erinnerung Tagebuch | daily journal, gratitude journal, mood diary |
| Technik | Diktiergerät Tagebuch, Sprachnotizen Tagebuch, Transkription offline | voice to text journal, offline transcription, speech to text diary |

Regeln der Stores: Apple-Keyword-Feld 100 Zeichen, kommagetrennt ohne Leerzeichen, keine Wiederholungen aus Titel und Untertitel, Plurale weglassen; die Suche gewichtet Titel, Untertitel, Keywords, Primärkategorie sowie Downloads und Bewertungen; Produktseite je Storefront lokalisieren [31]. Google Play: Titel 30 Zeichen, Kurzbeschreibung 80, Beschreibung 4.000 (unverifiziert) [32]. Kategorie: iOS "Lifestyle" (Day One, Journey) oder "Health & Fitness" (Daylio); die Gesundheitskategorie zieht Apple-Richtlinie 5.1.3 und die Play-Health-Deklaration nach sich, was für eine serverlose App unproblematisch ist [21]. Die Namens-Nachprüfung warnt, dass die Kategorie voll mit "Tagebuch mit Schloss"-Apps ist; Titel und Untertitel müssen deshalb "Sprache" und "lokal" tragen, nicht "Schloss" [33].

### 7.3 Presseargumente

Alle Aussagen müssen technisch stimmen und prüfbar sein (Formulierungsregeln in `05-sicherheit-und-datenschutz.md`, Abschnitt 6).

1. **Deutsch, lokal, auf iPhone und Android.** Apple Journal transkribiert laut Apple-Support nur Englisch; Journey transkribiert nur auf iOS, Day One nur auf iOS und mit Internet (unverifiziert) [2][3][4].
2. **Datenschutzlabel "Es werden keine Daten erfasst" auf beiden Plattformen** und auf Android keine `INTERNET`-Berechtigung. Das ist per Flugmodus in einer Minute nachprüfbar.
3. **Gerätewechsel iPhone zu Android ohne Cloud** per QR-Code und verschlüsselter Datei (D6). Kein Wettbewerber bietet das [9].
4. **Offener Quellcode, reproduzierbarer Android-Build, F-Droid.** Die Zeitschriftenkritik an Tagebuch-Apps drehte sich um Tracker und Werbenetzwerke (Kuketz 2020/21, heise 2021, unverifiziert) [34]; hier gibt es nichts zu finden.
5. **Kein Lock-in.** Export als Markdown, JSON, PDF mit Audio, kostenlos; Backup ist dieselbe Datei wie der Gerätewechsel. Apple Journal exportiert nur HTML/PDF-Pakete, und allein 2026 sind zehn Konverter-Projekte für "Apple Journal raus" entstanden [26][35].
6. **Kein Streak-Druck, kein Konto, keine Werbung** (D7), und die Garantie, dass kostenlose Funktionen kostenlos bleiben.

## 8. Rechtliches für den Indie-Inhaber in Kürze

Die vollständige Pflichtenliste (Datenschutzerklärung, Privacy Manifest, Berechtigungstexte, Exportkontrolle, Altersfreigabe) steht in `05-sicherheit-und-datenschutz.md`, Abschnitt 5. Hier nur, was das Geschäftsmodell direkt betrifft.

- **Der Store ist Händler gegenüber dem Kunden.** Apple und Google treten als Kommissionär auf; Apples Finanzberichte definieren "Customer Price" inklusive der Steuern, die Apple einzieht, und "Partner Share" als Kundenpreis minus Steuern minus Kommission [36]. Widerruf und Erstattung wickeln die Stores über ihre Bedingungen ab; der Entwickler muss nur die Store-Regeln einhalten. Bei alternativer Zahlungsabwicklung würde der Inhaber selbst Verkäufer mit vollen Fernabsatzpflichten (unverifiziert) [21][22].
- **DSA-Händlerstatus ist Pflicht, sobald Geld fließt.** Apple verlangt von Einzelpersonen Adresse oder Postfach, Telefon und E-Mail, jeweils verifiziert, und veröffentlicht sie in allen 27 EU-Storefronts [37]. Google analog (unverifiziert). Konsequenz für die Rechtsform: Einzelunternehmen genügt für den Start; wer Privatadresse nicht veröffentlichen will, braucht eine c/o-Adresse oder eine UG/GmbH (Kosten ab rund 1.000 €/Jahr, Schätzung aus dem Recherchebericht) [15]. Wird eine Gesellschaft gegründet, sind Apple- und Play-Entwicklerkonto von Anfang an auf die Gesellschaft anzulegen, nicht auf die Privatperson; eine spätere Übertragung ist bei beiden Stores ein eigener Vorgang mit Prüfung (Ablauf in der Sandbox nicht geprüft).
- **Impressum in der App** (§ 5 DDG, § 5 ECG in Österreich; Schweiz Art. 3 UWG), nicht nur auf der Store-Seite (unverifiziert) [38].
- **Steuern, nur als Hinweis, mit Steuerberater klären:** Der Entwickler erbringt umsatzsteuerlich eine Leistung an die irische Apple- bzw. Google-Gesellschaft (Kommissionsmodell, Reverse-Charge); nötig sind USt-IdNr. und Zusammenfassende Meldungen. Die Endkunden-Mehrwertsteuer führt der Store ab. Die Kleinunternehmerregelung (§ 19 UStG, seit 2025: Vorjahr bis 25.000 €, laufendes Jahr bis 100.000 €) ist für Store-Auszahlungen weitgehend neutral, entscheidet aber über Vorsteuerabzug und über Direktverkäufe wie B2B-Pakete (unverifiziert) [39][15].
- **Freischaltung nur über In-App-Kauf** (Apple 3.1.1); der Transfer-QR darf nichts freischalten [21].
- **Keine Gesundheitsversprechen.** Die App ist ein Tagebuch, kein Medizinprodukt; Store-Texte vermeiden "erkennt Stress", "verbessert mentale Gesundheit", "Stimmungsanalyse der Stimme" (MDR, AI Act Art. 50; Details in `05-sicherheit-und-datenschutz.md`) [40].
- **Exportkontrolle:** libsodium und SQLCipher sind keine Betriebssystem-Kryptografie; die Einordnung als gebündelte Standardalgorithmen und die daraus folgenden Erklärungen (Frankreich, BIS-Jahresbericht) sind in `05-sicherheit-und-datenschutz.md`, Abschnitt 5.4, behandelt und als offener Punkt markiert.

## 9. Risiken und Gegenmaßnahmen

| Risiko | Wahrscheinlichkeit | Wirkung | Gegenmaßnahme |
|---|---|---|---|
| **Apple Journal erhält deutsche Transkription** (Notizen und Sprachmemos können es seit iOS 26 bereits) | hoch | iOS-Differenzierung "Deutsch lokal" entfällt | "Deutsch" nie als einziges Kernversprechen kommunizieren; Android, Gerätewechsel ohne iCloud, offener Export, offener Code und Tagesritual ohne Streak bleiben |
| **Google bringt ein Journal mit On-Device-KI auf Android** | mittel | Nullpreis-Konkurrenz auch auf Android | Konto- und Google-Freiheit, F-Droid, kein KI-Zwang (der Google-Journal-Ansatz löste 2026 Kritik aus, unverifiziert) [26] |
| **Apple ändert oder beschränkt SpeechTranscriber** | niedrig | Transkription auf iOS bricht | WhisperKit als Zusatzpfad (D2); Engine-Schicht austauschbar (D1) |
| **Play Asset Delivery funktioniert nicht ohne INTERNET-Permission** | offen (Spike) | Modellauslieferung auf Android | Modelle bündeln oder Permission bewusst nur für den Download erklären; F-Droid-Build braucht ohnehin eine Alternative |
| **Abo-Skepsis in Rezensionen** | hoch | Bewertungsschnitt, Konversion | Lifetime sichtbar neben dem Abo, Garantie im Store-Text, Begründung "wofür" in der App, keine dunklen Muster |
| **F-Droid-Build kannibalisiert Store-Käufe** | mittel | geringe Erlösminderung | bewusst akzeptiert (Abschnitt 6); Unterstützer-Lizenz anbieten |
| **Umsatz bleibt niedrig** | hoch | Motivation, Weiterbetrieb | Laufende Fixkosten ohne Einmalausgaben klein halten (Abschnitt 4.6); Erwartung "Nebenerwerb, niedrig vierstellig im ersten Jahr" von Anfang an; B2B ab Jahr 2 |
| **Lifetime liegt über dem Einmalkauf-Anker des Segments** (44,99 € gegen 7 bis 15 $ bei Flint, Diarium, Local Journal) | mittel | Lifetime-Quote deutlich unter 25 %, Preiskritik in Rezensionen | Jahresabo als Standardauswahl auf der Kaufseite; Lifetime sichtbar als Unterstützung mit Begründung; Kaufverteilung nach sechs Monaten prüfen und Preis gegebenenfalls anpassen (offene Frage 11) |
| **Verlust des Store-Kontos** (Sperrung oder Löschung des Play- oder Apple-Entwicklerkontos durch automatisierte Richtlinienprüfung, erfolglose Einsprüche) | niedrig, für einen Solo-Entwickler aber Totalrisiko | Vertrieb und Bezahlung fallen aus; auf Android zusätzlich die Modellauslieferung per Play Asset Delivery, denn F-Droid liefert keine Play-Assets | Signaturschlüssel (Upload-Key, Play-App-Signing) und Store-Metadaten außerhalb des Kontos gesichert; zweiter Verwaltungszugang; GitHub-Releases und F-Droid als Ausweichvertrieb mit im Build gebündelten Modellen; in der App jederzeit "Backup jetzt exportieren"; Konten auf die Rechtsform anlegen (Abschnitt 8) |
| **Play-Deklaration des Vordergrunddienst-Typs `microphone` wird abgelehnt** | niedrig bis mittel (Ablehnungsquote nicht prüfbar) | Startverzögerung auf Android | Deklaration unter Policy > App content in Phase 6 vorbereiten [43]; kurzes Demovideo bereithalten, das Aufnahme aus Benachrichtigung und Widget mit sichtbarer Dauerbenachrichtigung zeigt, weil Google zu Vordergrunddiensten Nachweise verlangen kann (Art und Umfang in der Sandbox nicht prüfbar, offene Frage 12) |
| **Testpflicht neuer persönlicher Play-Konten** (geschlossener Test mit Mindestzahl Tester über Mindestzeitraum; Zahlen unverifiziert) | sicher, falls das Konto neu ist | Start um Wochen verzögert | Play-Konto in Phase 0 anlegen (`09-roadmap.md`, Abschnitt 3); das Closed Testing der Beta erfüllt die Pflicht zugleich [44] |
| **DSA-Veröffentlichung der Privatadresse** | sicher | Privatsphäre des Inhabers | c/o-Adresse oder Rechtsform vor Monetarisierung klären |
| **Modell-Lizenzen** (Parakeet CC-BY-4.0 unbestätigt; Schweizerdeutsch-Fine-Tunes CC-BY-NC) | mittel | Zusatzpakete nicht verkaufbar | Lizenzen im Spike verifizieren; CC-NC-Modelle für eine bezahlte App tabu [30] |
| **Ausfall des Solo-Inhabers** | niedrig, aber real | Nutzer verlieren Pflege | Open Source plus reproduzierbarer Build als Kontinuitätsgarantie; Export ist immer kostenlos |
| **Store-Review lehnt ab** (3.1.1, 5.1.1, Altersfreigabe) | mittel | Startverzögerung | Checkliste in `05-sicherheit-und-datenschutz.md`; QR ohne Freischaltfunktion; Datenschutzerklärung von Tag eins |
| **Änderung der EU-Store-Bedingungen** (Apple ab 1. Oktober 2026, Google-Programm für externe Angebote) | mittel | Abgaben, Regeln | bei In-App-Käufen bleiben; Bedingungen jährlich prüfen [22][14] |

## 10. B2B als spätere Stufe (ab Jahr 2)

Die Architektur ohne Server ist im B2B-Umfeld ein Verkaufsargument, kein Hindernis: Es gibt kein Dashboard, keine Auftragsverarbeitung, keine Patientendaten beim Anbieter. Der Nutzen entsteht beim Klienten, die Übergabe an Behandelnde erfolgt bewusst per Export.

**Zielkunden:** Psychotherapie-Praxen und Beratungsstellen (Stimmungs- und Reflexionstagebuch als Hausaufgabe; Studien zu Symptomtagebüchern zeigen hohe Mitwirkung, unverifiziert) [26], Coaches, betriebliche Gesundheitsförderung, Schulen und Hochschulen (Apple Bildungsrabatt 50 % ab 20 Lizenzen, unverifiziert) [41].

**Produktbausteine:**

1. **Therapie-Export**: Zeitraum wählen, nur Text, PDF oder Markdown, bewusste Übergabe durch den Klienten. Kleiner Aufwand, kein Medizinprodukt-Anspruch.
2. **Praxis-Paket**: zehn Lifetime-Lizenzen als Offer Codes, Preisidee 199 € (entspricht 19,90 € je Klient, eigene Rechnung), Direktverkauf mit Rechnung; umsatzsteuerlich beim Inhaber [15]. Offen ist, ob Apple den Verkauf von Offer Codes außerhalb des Stores erlaubt; Alternative ist Volume Purchasing über Apple Business Manager (für Abos ab Herbst 2026 angekündigt) und Managed Google Play [42].
3. **Gesprochene Reflexionsfragen** als kuratierte, lokale Bibliothek, die Behandelnde zusammenstellen und als Datei weitergeben können (kein Server).

**Grenzen:** Keine Auswertung durch die App, keine automatische Stimmungserkennung, keine Diagnose- oder Therapiehinweise; sonst wird aus dem Tagebuch ein Medizinprodukt (MDR Klasse IIa bei psychischer Gesundheit, unverifiziert) und ein Emotionserkennungssystem nach AI Act [40]. B2B startet erst, wenn die Basisnachfrage im Consumer-Markt bestätigt ist und die Store-Mechanik für Mehrfachlizenzen (Volume Purchasing, Group Purchases) verfügbar ist.

## 11. Offene Fragen

1. Euro-Preise von Day One, Journey, Diarium, Diarly, Daylio, CortexOS und Flint in den DACH-Stores (Store-Seiten waren nicht abrufbar); Prüfung, ob 14,99 €/44,99 € im Vergleich richtig liegen.
2. Suchvolumen der deutschen Keywords (Apple Search Ads Popularity, ASO-Werkzeug) vor der Festlegung von Titel und Untertitel.
3. Funktioniert die Google Play Billing Library ohne `INTERNET`-Berechtigung der App? (Spike, zusammen mit Play Asset Delivery, D3.)
4. GPLv3 und App-Store-Vertrieb: Contributor License Agreement oder Lizenzausnahme vor dem ersten fremden Beitrag rechtlich prüfen.
5. Darf der Inhaber Offer Codes als B2B-Paket verkaufen, oder ist Volume Purchasing der einzige zulässige Weg?
6. Umsatzsteuerliche Behandlung (Reverse-Charge, Zusammenfassende Meldung, Kleinunternehmerstatus) und Rechtsform mit Steuerberater klären; c/o-Adresse für den DSA-Händlerstatus.
7. Aktuelle Gebührenstruktur des Google-Play-Programms für externe Angebote im EWR (2025/2026-Revision).
8. RevenueCat-Originalzahlen für Lifestyle und Health & Fitness in Europa (Report nur über Drittzitate zugänglich).
9. Modelllizenzen für Zusatzpakete: Parakeet TDT 0.6B v3 (CC-BY-4.0?) und kommerziell nutzbare Schweizerdeutsch-Modelle.
10. Ob eine sichtbare "Unterstützer-Lizenz" im Store-Build (Lifetime ohne Zusatzfunktionen) den Apple-Richtlinien zu Spenden entspricht oder als normaler Non-Consumable mit Plus-Umfang laufen muss.
11. Bleibt D9 bei Lifetime 44,99 €, oder prüft der Inhaber den Wert 24,99 €, den der Recherchebericht für die Lifetime-Stufe der Variante C nennt [15]? Die eigenen Benchmarks (Einmalkauf 7 bis 15 $) sprechen für den niedrigeren Wert, die Unterstützer-Logik für den höheren; Entscheidung nach sechs Monaten Kaufverteilung.
12. Welche Nachweise verlangt die Play Console für den Vordergrunddienst-Typ `microphone` (Beschreibung, Demovideo), und welche Testpflicht gilt für das konkret gewählte Konto (Privatperson oder Organisation) [43][44]?
13. Angebote für den Krypto-Review und die Rechtsprüfung einholen; die Bandbreiten in Abschnitt 4.6 sind Setzungen ohne Quelle und entscheiden über den Break-even.

## Quellen

1. Wettbewerbsanalyse Mainstream mit Einzelquellen: `01-markt-und-wettbewerb.md` und `docs/recherche/wettbewerb-mainstream.md`; Daylio: https://www.choosingtherapy.com/daylio-app-review/
2. Apple Support, Journal iPhone (Transkription nur Englisch): https://support.apple.com/en-kz/guide/iphone/iph492ee70a8/ios
3. Day One Preise (Silver/Gold, April 2026): https://9to5mac.com/2026/04/08/day-one-journaling-app-introduces-gold-plan-with-ai-summaries-and-daily-chat/ ; https://5typos.net/2026/04/8/day-one-introduces-silver-and-gold-with-price-increases ; Audio-Guide: https://dayoneapp.com/guides/tips-and-tutorials/audio-recording/
4. Journey Membership und Transkription: https://help.journey.cloud/en/article/journeycloud-membership-k32g8e/ ; https://spokenly.app/blog/voice-journaling
5. Diarium Preise und Kennzahlen: https://forum.diariumapp.com/d/4901-cost-of-app-please-read-for-explanation ; https://www.appbrain.com/app/diarium-journal-diary/partl.Diarium
6. Diarly Preise: https://diarly.app/pricing ; DE-Listing: https://apps.apple.com/de/app/diarly-mein-tagebuch-journal/id1387167765
7. Privacy-App-Preise: Bitwarden https://bitwarden.com/pricing/ (zitiert über https://github.com/anoni-net/docs) ; Obsidian https://obsidian.md/pricing (zitiert über https://github.com/s0shaheen/commonplace) ; Proton https://proton.me/mail/pricing ; Standard Notes https://standardnotes.com/plans ; Cryptomator https://github.com/cryptomator/cryptomator
8. Flint Preis und Positionierung: https://klu.so/blog/private-voice-journaling ; https://www.danrecommends.com/reviews/flint
9. Voice-first-Wettbewerber (CortexOS, Cleft, Local Journal, Whisper Notes, Offscript): https://cortexos.app/faq/ ; https://cleftnotes.com/pricing ; https://localjournal.app/ ; https://whispernotes.app/ ; https://www.richfieldlabs.com/apps/offscript
10. DailyVox (kostenlos, MIT, Data Not Collected): https://github.com/intrepidkarthi/dailyvox
11. RevenueCat State of Subscription Apps 2025/2026 (über Drittextrakte): https://www.revenuecat.com/pdf/state-of-subscription-apps-2025.pdf ; https://www.revenuecat.com/state-of-subscription-apps/ ; Extrakte: https://raw.githubusercontent.com/best-trading-indicator-tools/devrel-hackaton-adapty/main/revenuecat-data/conversion-benchmarks.json ; https://raw.githubusercontent.com/Nikolai-Iakubovskii/app-paywall-pilot/main/outputs/2026-paywall-research.md ; Codelab (1,7 %/4,2 %): https://github.com/RevenueCat/codelab
12. Adapty State of In-App Subscriptions 2026: https://adapty.io/state-of-in-app-subscriptions/
13. Apple Small Business Program: https://developer.apple.com/app-store/small-business-program/
14. Google Play Servicegebühr (nicht direkt abrufbar): https://support.google.com/googleplay/android-developer/answer/112622 ; EU-Programm externe Angebote: https://blog.google/around-the-globe/google-europe/complying-with-the-digital-markets-act/
15. Recherchebericht Geschäftsmodell (Rechenannahmen, Fixkosten, Rechtsform, Praxis-Paket, Variante C mit Lifetime 24,99 €): `docs/recherche/geschaeftsmodell.md`; Journiv-Finanzierung: https://github.com/orgs/journiv/discussions/348
16. Apple App Privacy Details (Definition "collect"): https://developer.apple.com/app-store/app-privacy-details/
17. Apple Auto-renewable Subscriptions (Kommission, Family Sharing, Trials): https://developer.apple.com/app-store/subscriptions/
18. Apple News, Offer Codes für alle In-App-Kauftypen (29.10.2025): https://developer.apple.com/news/?id=r1s3hw2b
19. Google Play Billing Subscriptions (Trials, Grace Period, Account Hold): https://developer.android.com/google/play/billing/subscriptions
20. Apple Product Page Optimization: https://developer.apple.com/app-store/product-page-optimization/
21. Apple App Review Guidelines (3.1.1, 5.1.1, 5.1.3): https://developer.apple.com/app-store/review/guidelines/
22. Apple, DMA und Apps in der EU (Terms ab 1.10.2026): https://developer.apple.com/support/dma-and-apps-in-the-eu/ ; Verlust von Family Sharing bei externer Zahlung: https://github.com/mjmirza/app-store-compliance
23. Apple Promoting In-App Purchases: https://developer.apple.com/app-store/promoting-in-app-purchases/
24. Dictus, Grundsatz "free features never become paid": https://github.com/getdictus/dictus-ios/issues/54
25. Journiv, Reaktion auf nachträgliche Bezahlschranke: https://github.com/orgs/journiv/discussions/425
26. Recherchebericht Innovationslücken (Day-One-Preiskritik, Barrierefreiheit, Kinderprofil, Therapie-Export, Google-Journal-Kritik, Kuketz/heise): `docs/recherche/innovationsluecken.md`; Kuketz: https://www.kuketz-blog.de/android-miserabler-datenschutz-bei-tagebuch-apps/ ; heise: https://www.heise.de/tests/Sechs-Tagebuch-Apps-im-Test-Digitale-Logbuecher-mit-Sicherheitsluecken-4981737.html ; Google-Journal-Kritik: https://www.techbuzz.ai/articles/google-journal-ai-features-spark-privacy-backlash
27. Privacy Guides, Kriterien: https://raw.githubusercontent.com/privacyguides/privacyguides.org/main/docs/about/criteria.md
28. Kuketz-Blog, Empfehlungsecke: https://www.kuketz-blog.de/empfehlungsecke/
29. awesome-privacy: https://raw.githubusercontent.com/pluja/awesome-privacy/main/README.md
30. Lizenzen: Moonshine https://raw.githubusercontent.com/moonshine-ai/moonshine/main/LICENSE ; sherpa-onnx https://github.com/k2-fsa/sherpa-onnx ; WhisperKit https://github.com/argmaxinc/WhisperKit ; whisper.cpp https://github.com/ggml-org/whisper.cpp/blob/master/LICENSE ; Schweizerdeutsch-Fine-Tunes (CC-BY-NC): https://github.com/napoleonmm83/Transkribor/issues/130
31. Apple App Store Search und Keywords: https://developer.apple.com/app-store/search/
32. Google Play Store-Eintrag (Zeichenlimits, nicht direkt abrufbar): https://support.google.com/googleplay/android-developer/answer/9866151
33. Namens-Nachprüfung ("Tagebuch mit Schloss"-Kategorie): `docs/recherche/namensfindung/nachpruefung.md`
34. Recherchebericht Nutzerfeedback (Export-Schmerz, Konverter-Projekte, Monetarisierungsakzeptanz): `docs/recherche/nutzerfeedback.md`
35. Apple Journal Export und Konverter: https://support.apple.com/en-us/121822 ; https://github.com/kpod13/journal2day1 ; https://github.com/journiv/journiv-app/issues/253
36. Apple Financial Report Fields (Customer Price, Partner Share): https://developer.apple.com/help/app-store-connect/reference/financial-report-fields/
37. Apple, DSA-Händleranforderungen: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements
38. § 5 DDG (nicht direkt abrufbar): https://www.gesetze-im-internet.de/ddg/__5.html ; Recherchebericht Recht: `docs/recherche/recht-compliance.md`
39. Kleinunternehmerregelung § 19 UStG 2025 (ELSTER-Hilfetext): https://raw.githubusercontent.com/dennismenken/elster-form-helper-data/main/Formulare/USt/2025/elster_ust2025_help.md
40. MDCG 2019-11 (Software-Qualifikation): https://health.ec.europa.eu/system/files/2020-09/md_mdcg_2019_11_guidance_qualification_classification_software_en_0.pdf ; AI Act Art. 50: https://artificialintelligenceact.eu/article/50/
41. Apple Custom Apps und Apple Business Manager: https://developer.apple.com/custom-apps/
42. Apple What's New (Volume Purchasing für Abos, Group Purchases, 12-Monats-Bindung): https://developer.apple.com/app-store/whats-new/
43. Android, Vordergrunddienst-Typen und Deklaration in der Play Console (Policy > App content): https://developer.android.com/develop/background-work/services/fgs/service-types ; https://developer.android.com/about/versions/14/changes/fgs-types-required
44. Google Play, Testanforderungen für neue persönliche Entwicklerkonten (in der Sandbox nicht geprüft, unverifiziert): https://support.google.com/googleplay/android-developer/answer/14151465
45. Recherchebericht Voice-first-Wettbewerb (WhisperJournal rund 1.100 Downloads, unverifiziert): `docs/recherche/wettbewerb-voice-first.md` ; AppBrain: https://www.appbrain.com/app/openai-voice-journal/com.kaizoco.whisperjournal
