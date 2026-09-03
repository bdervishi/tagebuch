# 07 · geschaeftsmodell

Stand: 3. September 2026 · Status: Entwurf

Dieses Dokument beantwortet M10 aus `00-anforderungen.md` (wirtschaftliche Verwertbarkeit) und setzt die verbindlichen Entscheidungen D9 (Preismodell) und D10 (Lizenz) um. Es ist das einzige Konzeptdokument, das Preise nennt und Erlöse rechnet. Marktdaten und Wettbewerber stehen in `01-markt-und-wettbewerb.md`, die rechtlichen Pflichten in `05-sicherheit-und-datenschutz.md` (Abschnitt 5); hier werden sie nur so weit wiederholt, wie das Geschäftsmodell davon abhängt.

Hinweis zur Quellenlage: Eine Faktenprüfung (`verifikation.json`) lag zum Redaktionsschluss nicht vor. Plattformregeln von Apple und Google sind aus Primärquellen belegt. Wettbewerberpreise, Branchen-Benchmarks (RevenueCat, Adapty) und Marktgrößen stammen aus Suchsnippets oder Drittzitaten und sind mit "(unverifiziert)" gekennzeichnet. Alle Erlösrechnungen sind eigene Rechnungen mit offen gelegten Annahmen.

## 1. Ergebnis in Kürze

- **Empfehlung: "Kostenloser Kern für immer + Plus" (D9, Variante B).** Alle Kernversprechen (Aufnahme, lokale Transkription Deutsch/Englisch, Wiedergabe, Suche, Verschlüsselung, Erinnerung, Backup, QR-Gerätewechsel, offener Export) sind dauerhaft kostenlos. Plus kostet 14,99 €/Jahr, 1,99 €/Monat oder 44,99 € einmalig (Lifetime), mit Familienfreigabe und 7-Tage-Test nur im Jahresabo.
- **Erwartung realistisch halten.** Mit 10.000 Downloads im ersten Jahr und 2 % Zahlern ergibt Variante B rund 3.100 € Auszahlung im ersten und rund 3.600 € im zweiten Jahr (eigene Rechnung, Abschnitt 4). Das Produkt finanziert Nebenkosten und wächst mit den Downloads; ein Vollzeit-Einkommen ist im ersten Jahr nicht zu erwarten. Branchenmediane für Abo-Apps liegen bei rund 500 $ Monatsumsatz (unverifiziert) [12].
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

Alle drei Varianten teilen den kostenlosen Kern aus D9. Die Rechnung ist bewusst konservativ und stammt aus dem Recherchebericht; ich habe sie nachgerechnet.

| Annahme | Wert | Herkunft |
|---|---|---|
| Downloads im ersten Jahr | 10.000 (organisch, DACH) | D9; Größenordnung eines Indie-Starts ohne Werbebudget |
| Download-zu-Zahler | 2 % (Abo-Modelle), 3 % (reiner Einmalkauf), 2,5 % (Update-Pass) | RevenueCat-Median 1,7 % bis Top 4,2 % (unverifiziert) [11]; Einmalkauf ohne Test konvertiert erfahrungsgemäß besser |
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

Plus: 14,99 €/Jahr, 1,99 €/Monat, Lifetime 44,99 € (dreifacher Jahrespreis als Anker). 7-Tage-Test nur im Jahresabo, Familienfreigabe aktiv.

- Jahr 1: 200 Zahler, Mischung 55 % Jahr / 20 % Monat / 25 % Lifetime. 110 × 14,99 € = 1.649 € + 40 × 1,99 € × 5 Monate = 398 € + 50 × 44,99 € = 2.250 €. Summe 4.297 € brutto, Auszahlung rund 3.070 €.
- Jahr 2: gleiche Neukohorte 4.297 € + 48 Verlängerer × 14,99 € = 726 €. Summe 5.023 € brutto, Auszahlung rund 3.590 €.
- Jahr 3: 4.297 € + 726 € (Verlängerer aus Jahr 2) + 21 × 14,99 € = 315 € (zweite Verlängerung aus Jahr 1). Summe rund 5.340 € brutto, Auszahlung rund 3.810 € (eigene Rechnung; der Recherchebericht nennt rund 3.900 €).

Vorteile: wiederkehrender Anteil wächst; Lifetime bedient Abo-Verweigerer und bringt frühes Geld; die Struktur mit zwei bis drei Plänen entspricht dem, was Nutzer 2026 aus anderen Apps kennen. Nachteile: Abo-Skepsis in Rezensionen ist einzukalkulieren; die Begründung "wofür zahle ich" muss im Store-Text und in der App stehen.

Der Free/Plus-Schnitt aus D9:

| Kostenlos, dauerhaft garantiert | Plus |
|---|---|
| Unbegrenzt viele Einträge | Aufnahmen bis 30 Minuten je Eintrag |
| Aufnahmen bis 5 Minuten je Eintrag | Zusatzpaket "Hohe Genauigkeit" (große Modelle, D2/D3) |
| Lokale Transkription Deutsch und Englisch | Gestaltete Rückblicke (Woche, Monat, Jahr) und lokale Zusammenfassungen (ab Version 1.x, D8) |
| Wiedergabe, Volltextsuche, Kalender, "vor einem Jahr" | Mehrere Tagebücher |
| Verschlüsselung, App-Sperre | Gestaltetes Jahrbuch-PDF |
| Tägliche Erinnerung | Weitere Sprachen, später Mundart-Paket |
| Verschlüsseltes Backup und QR-Gerätewechsel | Themes, App-Icons, Widgets |
| Export als Markdown, JSON, PDF | |

Der Schnitt ist so gewählt, dass es keinen Lock-in gibt: Wer nie zahlt, verliert nie Daten und kann jederzeit vollständig exportieren oder das Gerät wechseln. Die 5-Minuten-Grenze deckt ein normales Tagesritual (Rechenbasis in D6: 3 Minuten pro Tag) und liegt unter den 10 Minuten von Day One und Journey, aber ohne Internetpflicht. Store-Text und Datenschutzerklärung enthalten die Garantie: **Kostenlose Funktionen werden nie kostenpflichtig.** Diese Selbstverpflichtung ist rechtlich bindend und deshalb bewusst zu formulieren (siehe `05-sicherheit-und-datenschutz.md`).

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

**Empfehlung: Variante B**, weil sie als einzige laufende Pflege finanziert (Modellwechsel, iOS- und Android-Jahresversionen, neue Sprachpakete), ohne den kostenlosen Kern anzutasten, und weil Lifetime die Einmalkauf-Erwartung des Privacy-Publikums bedient. Falls der Inhaber Abos grundsätzlich ablehnt, ist C die zweitbeste Wahl; A nur, wenn kein längerfristiger Weiterbetrieb geplant ist (D9).

Skalierung: Bei 30.000 Downloads im Jahr verdreifachen sich alle Werte (B: rund 9.200 € im ersten, 10.800 € im zweiten Jahr). Bei 100.000 Downloads (Diarium-Klasse über mehrere Jahre) liegt B bei 30.000 bis 36.000 €/Jahr, oberhalb der Kleinunternehmergrenze, aber weit unter der Schwelle von 1 Mio. $ des Small Business Program. Fixkosten (Apple Developer Program 99 $/Jahr, Google Play einmalig 25 $, Rechtsbausteine rund 300 €) sind in jeder Variante im ersten Quartal gedeckt; die eigentliche Investition ist Arbeitszeit [13][15].

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
- **DSA-Händlerstatus ist Pflicht, sobald Geld fließt.** Apple verlangt von Einzelpersonen Adresse oder Postfach, Telefon und E-Mail, jeweils verifiziert, und veröffentlicht sie in allen 27 EU-Storefronts [37]. Google analog (unverifiziert). Konsequenz für die Rechtsform: Einzelunternehmen genügt für den Start; wer Privatadresse nicht veröffentlichen will, braucht eine c/o-Adresse oder eine UG/GmbH (Kosten ab rund 1.000 €/Jahr, Schätzung aus dem Recherchebericht) [15].
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
| **Umsatz bleibt niedrig** | hoch | Motivation, Weiterbetrieb | Fixkosten unter 500 €/Jahr; Erwartung "niedrig vierstellig im ersten Jahr" von Anfang an; B2B ab Jahr 2 |
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

## Quellen

1. Wettbewerbsanalyse Mainstream dieser Sitzung mit Einzelquellen: `01-markt-und-wettbewerb.md`; Daylio: https://www.choosingtherapy.com/daylio-app-review/
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
15. Recherchebericht Geschäftsmodell dieser Sitzung (Rechenannahmen, Fixkosten, Rechtsform, Praxis-Paket): Scratchpad `research/geschaeftsmodell.md`; Journiv-Finanzierung: https://github.com/orgs/journiv/discussions/348
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
26. Recherchebericht Innovationslücken dieser Sitzung (Day-One-Preiskritik, Barrierefreiheit, Kinderprofil, Therapie-Export, Google-Journal-Kritik, Kuketz/heise): Scratchpad `research/innovationsluecken.md`; Kuketz: https://www.kuketz-blog.de/android-miserabler-datenschutz-bei-tagebuch-apps/ ; heise: https://www.heise.de/tests/Sechs-Tagebuch-Apps-im-Test-Digitale-Logbuecher-mit-Sicherheitsluecken-4981737.html ; Google-Journal-Kritik: https://www.techbuzz.ai/articles/google-journal-ai-features-spark-privacy-backlash
27. Privacy Guides, Kriterien: https://raw.githubusercontent.com/privacyguides/privacyguides.org/main/docs/about/criteria.md
28. Kuketz-Blog, Empfehlungsecke: https://www.kuketz-blog.de/empfehlungsecke/
29. awesome-privacy: https://raw.githubusercontent.com/pluja/awesome-privacy/main/README.md
30. Lizenzen: Moonshine https://raw.githubusercontent.com/moonshine-ai/moonshine/main/LICENSE ; sherpa-onnx https://github.com/k2-fsa/sherpa-onnx ; WhisperKit https://github.com/argmaxinc/WhisperKit ; whisper.cpp https://github.com/ggml-org/whisper.cpp/blob/master/LICENSE ; Schweizerdeutsch-Fine-Tunes (CC-BY-NC): https://github.com/napoleonmm83/Transkribor/issues/130
31. Apple App Store Search und Keywords: https://developer.apple.com/app-store/search/
32. Google Play Store-Eintrag (Zeichenlimits, nicht direkt abrufbar): https://support.google.com/googleplay/android-developer/answer/9866151
33. Namens-Nachprüfung dieser Sitzung ("Tagebuch mit Schloss"-Kategorie): Scratchpad `naming/nachpruefung.md`
34. Recherchebericht Nutzerfeedback dieser Sitzung (Export-Schmerz, Konverter-Projekte, Monetarisierungsakzeptanz): Scratchpad `research/nutzerfeedback.md`
35. Apple Journal Export und Konverter: https://support.apple.com/en-us/121822 ; https://github.com/kpod13/journal2day1 ; https://github.com/journiv/journiv-app/issues/253
36. Apple Financial Report Fields (Customer Price, Partner Share): https://developer.apple.com/help/app-store-connect/reference/financial-report-fields/
37. Apple, DSA-Händleranforderungen: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements
38. § 5 DDG (nicht direkt abrufbar): https://www.gesetze-im-internet.de/ddg/__5.html ; Recherchebericht Recht dieser Sitzung: Scratchpad `research/recht-compliance.md`
39. Kleinunternehmerregelung § 19 UStG 2025 (ELSTER-Hilfetext): https://raw.githubusercontent.com/dennismenken/elster-form-helper-data/main/Formulare/USt/2025/elster_ust2025_help.md
40. MDCG 2019-11 (Software-Qualifikation): https://health.ec.europa.eu/system/files/2020-09/md_mdcg_2019_11_guidance_qualification_classification_software_en_0.pdf ; AI Act Art. 50: https://artificialintelligenceact.eu/article/50/
41. Apple Custom Apps und Apple Business Manager: https://developer.apple.com/custom-apps/
42. Apple What's New (Volume Purchasing für Abos, Group Purchases, 12-Monats-Bindung): https://developer.apple.com/app-store/whats-new/
