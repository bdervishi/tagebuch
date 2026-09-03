# Geschäftsmodell, Preise und Go-to-Market für ein lokales Sprach-Tagebuch (Indie, DACH)

Lens: `geschaeftsmodell` · Stand: 3. September 2026 · Zielprodukt: Voice Diary für iOS + Android, Transkription ausschließlich on-device, keine Konten/Server, verschlüsselter Geräte-Transfer per QR-Code.

## 0. Methodik und Einschränkungen

Der Web-Suchindex war in dieser Sitzung erschöpft; der Netzwerk-Proxy blockierte zudem fast alle kommerziellen Domains (`dayoneapp.com`, `apps.apple.com`, `play.google.com`, `revenuecat.com`, `bitwarden.com`, `obsidian.md`, `proton.me`, `heise.de`, `kuketz-blog.de`, `alternativeto.net`, `privacyguides.org`, `statista.com`, `support.google.com`). Direkt lesbar waren `developer.apple.com`, `developer.android.com`, `github.com` und `raw.githubusercontent.com`. Konsequenz:

- Plattformregeln (Apple-Kommission, EU-Terms, StoreKit-Funktionen, Google-Play-Billing-Funktionen) sind aus Primärquellen belegt (hohe Konfidenz).
- RevenueCat-Kennzahlen stammen aus zwei GitHub-Repositorien, die den Report 2025 (PDF) tabellarisch extrahiert bzw. den Report 2026 zitiert haben; Originalquelle jeweils angegeben. Konfidenz mittel, `mustVerify`.
- Wettbewerberpreise stammen aus den Parallel-Recherchen `wettbewerb-mainstream.md` und `wettbewerb-voice-first.md` derselben Sitzung (dort mit URLs, ebenfalls aus Suchsnippets rekonstruiert). Alle Beträge sind `mustVerify`.
- Privacy-App-Preise (Bitwarden, Proton, Standard Notes, Obsidian) stammen aus mehreren unabhängigen GitHub-Dokumenten mit Datumsangabe 2026; Originalpreisseiten waren nicht erreichbar.

## 1. Kernaussagen

1. **Preisanker im Segment (2026):** Einmalkäufe für lokale Voice-Apps liegen bei 6,99–14,99 $ (Local Journal 6,99 $, Whisper Notes 7,99 $, Flint 12 $, Diarium Pro 14,99 $ je Plattform); Jahresabos für Tagebuch-Apps zwischen ca. 24 $ (Diarly) und 49,99 $ (Day One Silver, Journey), KI-Tarife bis 74,99 $ (Day One Gold) und 99–130 $ (Voicenotes, Mindsera). Cloud-Voice-Apps mit hohen Abos (Talknotes 197 $/J, Untold ~364 $/J) werden in Rezensionen kritisiert.
2. **Plattformabgaben:** Apple Small Business Program 15 % (bis 1 Mio. $ Vorjahres-Proceeds), Google Play 15 % auf die erste Million bzw. auf alle Abos. Ab 1. Oktober 2026 gelten in der EU einheitliche Apple-Terms: 15 % IAP für Small-Business-Teilnehmer (Standard 26 %), 10 % bei alternativer Zahlungsabwicklung in der App, 10 % bei Link-outs, 5 % Core Technology Commission nur bei Vertrieb außerhalb des App Store. Für einen Indie mit < 1 Mio. $ ist der Unterschied zwischen IAP (15 %) und eigener Zahlungsabwicklung (10 % plus Zahlungsdienstleister ~3 % plus Steuerabwicklung) wirtschaftlich fast null, aber die Komplexität ist erheblich größer.
3. **Benchmarks (RevenueCat 2025/2026, Nordamerika):** Median Download→Paid 1,7 % (Top-Apps 4,2 %); Freemium D35 2,1 % vs. Hard Paywall 10,7 %; Trial→Paid Health & Fitness 37,7–39,9 %, Productivity 32 %; 12-Monats-Retention Jahresabos 44,1 %, Monatsabos 17,0 %; Median-Jahrespreis Health & Fitness 39,99 $, Productivity 29,99 $, Utilities 26,99 $; Hybrid-Monetarisierung (Abo + Einmalkauf) bei 26–39 % der Apps. Adapty 2026: Median-Monatsumsatz einer Abo-App 492 $, 59,3 % aller Apps unter 1.000 $/Monat. Realistische Erwartung: Ein DACH-Indie-Tagebuch liegt ohne Marketingbudget im ersten Jahr im niedrigen vierstelligen Euro-Bereich.
4. **Privacy-Publikum bezahlt, aber anders:** Bitwarden (19,80 $/J seit Januar 2026, vorher zehn Jahre 10 $), Obsidian (App kostenlos, Sync 4 $/M, Catalyst 25 $ einmalig), Cryptomator (Desktop spendenbasiert, GPLv3), Standard Notes (~90 $/J). Muster: Kern kostenlos und dauerhaft, Bezahlung für Komfort/Sync/Support, niedrige Beträge, kein „Bait-and-Switch". Privacy Guides nimmt nur Apps mit Open-Source-Clients auf; Awesome-Privacy listet kostenlos.
5. **Empfehlung:** Hybridmodell „Free Core forever + Plus" mit Jahresabo 14,99 €, Monatsabo 1,99 € und Lifetime 44,99 € (3×-Anker), Familienfreigabe aktiv, 7-Tage-Trial nur für das Jahresabo; ab Jahr 2 B2B-Erweiterung (Praxis-/Coaching-Lizenzen per Offer Codes bzw. Apple Volume Purchasing) und bezahlte, lokal laufende Zusatzpakete. Detailrechnung in Abschnitt 8.

## 2. Preis-Benchmarks Tagebuch- und Voice-Apps

| App | Modell | Beträge (Quelle, Datum) |
|---|---|---|
| Day One (Automattic) | Freemium + Abo | Basic kostenlos; Silver 49,99 $/J (ehem. Premium 24,99 $/J für Altkunden); Gold 74,99 $/J mit KI (9to5Mac 08.04.2026, 5typos.net) |
| Journey (Two App Studio) | Freemium + Abo + Lifetime | Membership 49,99 $/J, Lifetime 199 $ (help.journey.cloud, 2026) – Lifetime = 4× Jahrespreis |
| Diarium (Timo Partl, DE) | Einmalkauf je Plattform | Pro 14,99 $ (Android/iOS/macOS), Windows 19,99 $; kein Abo; ca. 740.000 Android-Downloads, 4,86 Sterne (AppBrain 2026) |
| Diarly (Apple-only) | Abo | „less than $2 per month" / „less than $24 per year", 7-Tage-Test; separates „AI+"-Abo für Transkription (diarly.app/pricing 2026); DE-Listing nennt 27 €/J |
| Daylio (Relaxio) | Freemium + Abo | 4,99 $/M, 35,99 $/J; IAP-Spanne 4,99–59,99 $; 19 Mio. Downloads (AppBrain 2026) |
| Flint (Klu Technologies Oy) | Einmalkauf | 12 $ „instead of a recurring fee"; Nutzer: „worth the $12" (klu.so/blog, Juli 2026) |
| DailyVox (Open Source, iOS) | kostenlos | „Free forever. No subscriptions, no in-app purchases, no ads." (README, Aug. 2026) |
| Speakwise | Abo | 59,99 $/J plus Wochenabo („yearly saves 81 %") |
| CortexOS | Freemium + Abo + Lifetime | 7,99 $/M, 49,99 $/J, Lifetime 99,99 $ (andere Quelle 9,99/79,99/199,99 $) |
| Local Journal / Whisper Notes | Einmalkauf | 6,99 $ bzw. 7,99 $ |
| Rosebud / Mindsera / Voicenotes (Cloud-KI) | Abo | 107,99 $/J; 129 $/J; 99,99 $/J |
| Apple Journal | kostenlos | Systemapp, Transkription nur Englisch (Apple-Support) |

Beobachtungen: (a) Der Markt teilt sich in „Einmalkauf 7–15 $" für lokale Tools und „Abo 25–50 $/J" für Sync-Produkte; (b) Lifetime-Preise liegen beim 2–4-Fachen des Jahresabos; (c) KI-Funktionen werden marktweit als separates Tier verkauft (Day One Gold, Diarly AI+, Stoic Premium+AI); (d) das Free-Tier ist überall großzügig, weil Apple Journal den Nullpreis setzt.

## 3. Modelle bei Privacy-Apps

- **Bitwarden:** Free-Tier vollständig (unbegrenzte Einträge und Geräte), Premium 19,80 $/J seit Januar 2026 („its first price change in about a decade", vorher 9,99 $), Families 40–47,88 $/J für bis zu 6 Personen. Mehrere GitHub-Quellen (anoni-net/docs, Qutaifan/THEHUB, nakazono1011) bestätigen unabhängig voneinander den neuen Preis; Originalseite bitwarden.com/pricing nicht erreichbar.
- **Obsidian:** App kostenlos ohne Limit (auch kommerziell), Sync 4 $/M (jährlich) mit E2E, Publish 8 $/M, Catalyst 25 $ einmalig als Unterstützer-Lizenz, Commercial 50 $/Nutzer/J (obsidian.md/pricing, zitiert Juli 2026). Muster „lokal kostenlos, Server-Dienst kostenpflichtig".
- **Cryptomator:** GPLv3, „provided free of charge as an open-source project" und „dependent on donations"; Sponsoren-Tiers Gold/Silber (github.com/cryptomator/cryptomator). Mobile-Apps haben historisch einen Einmalkauf; Betrag nicht prüfbar.
- **Proton:** Mail Plus 3,99 $/M jährlich (4,99 $ monatlich), Unlimited 9,99 $/M jährlich (12,99 $ monatlich), Family 29,99 $/M (Checkout-Beobachtung 01.08.2026 in ThePhaseless/Interstellar). Hohe Preise funktionieren dort, weil Serverleistung geliefert wird – für eine serverlose App nicht übertragbar.
- **Standard Notes:** Free-Tier mit Sync; Productivity ~90 $/J, Professional ~120 $/J (Preisvergleichsseite, August 2026); seit April 2024 Teil von Proton (Privacy Guides).
- **Open-Source-Tagebücher:** Journiv (self-hosted) führte im Januar 2026 „Journiv Plus" (kompilierte Zusatzmodule, PolyForm-Noncommercial) ein, nachdem Spenden „bare minimum" blieben; Nutzer reagierten mit der Frage nach Paywall vs. Dienstleistung (Discussion #425). Der Maintainer benötigt „$100/month or first $1,200 total" für eine LLC, weil Stores Klarnamen und Adresse veröffentlichen (Discussion #348). Dictus (iOS, MIT) legt sich fest: „No bait-and-switch — free features never become paid", Preismodell „TBD (monthly sub vs yearly vs lifetime)" (Issue #54).

Lehre für das Produkt: Das Privacy-Publikum akzeptiert Bezahlung, erwartet aber (1) einen vollwertigen, dauerhaft kostenlosen Kern, (2) Einmalkauf-Option, (3) niedrige Jahresbeträge (10–25 €), (4) transparente Begründung, wofür bezahlt wird (Entwicklung, nicht Server).

## 4. Benchmarks RevenueCat / Adapty

RevenueCat „State of Subscription Apps 2025" (Nordamerika, extrahiert in best-trading-indicator-tools/devrel-hackaton-adapty aus dem PDF):

| Kategorie | Trial-Start | Trial→Paid | Download→Paid D35 | Refund | Median-Preise W/M/J | Anteil Jahresabos | Hybrid-Anteil | LTV Jahr 1 (Median/Q3) |
|---|---|---|---|---|---|---|---|---|
| Health & Fitness | 3,9 % | 39,9 % | 1,0 % | 4,71 % | 4,99/9,70/39,99 $ | 66,6 % | 25,7 % | 33,91/54,22 $ |
| Productivity | 2,6 % | 32,0 % | 1,0 % | 2,55 % | 4,99/5,99/29,99 $ | 40,6 % | 33,3 % | 16,27/32,35 $ |
| Utilities | 3,7 % | 39,1 % | 1,1 % | 3,16 % | 4,99/4,99/26,99 $ | 53,8 % | 38,7 % | 11,17/24,84 $ |
| Social & Lifestyle | 1,9 % | 38,3 % | 0,9 % | 3,34 % | 4,99/7,99/29,99 $ | 19,1 % | 38,3 % | 8,62/30,45 $ |

RevenueCat 2026 (115.000+ Apps, zitiert in Nikolai-Iakubovskii/app-paywall-pilot, März 2026): Download→Paid D35 Hard Paywall 10,7 % vs. Freemium 2,1 %; Trial→Paid H&F 37,7 %; Trials von 17–32 Tagen konvertieren 42,5 %, ≤4 Tage 25,5 %; 12-Monats-Retention Jahresabo 44,1 %, Monatsabo 17,0 %, Wochenabo 3,4 %; unfreiwillige Kündigungen durch Zahlungsfehler iOS 14 %, Android 31 %; 12-Monats-RLTV je Zahler H&F 35,64 $. RevenueCat-Codelab (offizielles Repo): „only 1.7% of app downloads convert to paying subscribers within 30 days. However, top-performing apps achieve 4.2%". Adapty 2026 (16.000 Apps): Median-Monatsumsatz 492 $, 59,3 % unter 1.000 $ gesamt, Top 10 % vereinen 94,5 % des Umsatzes; Install→Trial global 10,9 %, Trial→Paid 25,6 % (H&F 35,0 %); 86 % der H&F-Konversionen an Tag 0.

Interpretation: Für ein Tagebuch (Kategorie Lifestyle oder Health & Fitness) sind 1–2 % Download→Paid und 35–40 % Trial→Paid realistische Planwerte; Jahresabo ist die einzige Abo-Form mit brauchbarer Retention; Monatsabos dienen als Einstieg, nicht als Umsatzträger.

## 5. Marktgröße

- „Digital Journal Apps": 5,69 Mrd. $ (2025) → 6,34 Mrd. $ (2026), CAGR ~11,4 % (Straits Research; andere Quelle 6,53 Mrd. $ 2025). Zahlen aus Marktforschungs-Pressetexten, Definition unklar – nur als Größenordnung nutzbar, `mustVerify`.
- Belastbarer sind Produktzahlen: Day One „über 15 Mio. Downloads", Daylio 19 Mio. Downloads, Diarium ~740.000 Android-Downloads (DACH-lastig), Voicenotes „1M+ downloads". Ein DACH-Sprachtagebuch mit 50.000–200.000 Downloads über drei Jahre wäre ein realistisches Erfolgsszenario; Diarium zeigt, dass ein deutscher Solo-Entwickler mit Einmalkauf ein sechsstelliges Nutzervolumen erreichen kann.
- Rosebud erhielt im Juni 2025 6 Mio. $ Seed (Bessemer) – KI-Voice-Journaling gilt als investierbar; für ein serverloses Produkt ist VC aber irrelevant.

## 6. Plattformabgaben, EU-DMA, Steuer

**Apple, weltweit:** Small Business Program 15 % auf Paid Apps und IAP für Entwickler mit ≤ 1 Mio. $ Proceeds im Vorjahr (Proceeds = „sales net of Apple's commission and certain taxes"). Wird die Grenze im laufenden Jahr überschritten, gilt der Standardsatz für den Rest des Jahres; Re-Qualifikation im Folgejahr nach Unterschreiten. Abos: 30 % im ersten Jahr, 15 % ab dem zweiten Jahr; Small-Business-Teilnehmer erhalten 85 % von Anfang an. Free Trials zählen nicht zur Jahresfrist.

**Apple, EU ab 1. Oktober 2026 (developer.apple.com/support/dma-and-apps-in-the-eu, News 18.08.2026):** Ein einheitliches Term-Set; Core Technology Fee wird durch eine Core Technology Commission von 5 % ersetzt, die nur für Vertrieb außerhalb des App Store gilt (alternative Marktplätze, Web Distribution). Initial Acquisition Fee und Store Services Fee entfallen. Sätze im App Store: 26 % Standard-IAP / 15 % für Small Business und Abos ab Jahr 2; alternative Zahlungsabwicklung in der App 20 % / 10 %; Out-of-App-Links 15 % / 10 % (nur Käufe innerhalb 7 Tagen nach Link-Tap kommissionspflichtig). Wahl der Zahlungsoption bindet 12 Monate; Monatsreport innerhalb 15 Tagen; Alterssperre unter 13 Jahren. Für einen Small-Business-Indie sinkt die Abgabe durch alternative Zahlung von 15 % auf 10 %, wogegen Zahlungsdienstleister (~1,5–3 %), Steuerabwicklung (Merchant-of-Record entfällt), Rechnungsstellung, Rückerstattungen und der Verlust von Family Sharing, Ask-to-Buy und Apple-Abo-Verwaltung stehen (vgl. mjmirza/app-store-compliance). Empfehlung: bei IAP bleiben, DMA-Option erst ab mittlerem fünfstelligem Jahresumsatz prüfen.

**Google Play:** 15 % auf die erste Million $ Jahresumsatz und auf alle Abos, darüber 30 % (Play-Console-Hilfe answer/112622, nicht direkt abrufbar; Google-Blog März 2021). EU-Programm „External Offers" (März 2024): Initial Acquisition Fee 10 % (5 % Abos) für zwei Jahre plus Ongoing Services Fee 17 % (7 % Abos) – zusammen nicht günstiger als 15 %; Google hat 2025/2026 eine 10–20-%-Struktur angekündigt (`mustVerify`). Play Billing bietet Free Trials, Introductory Pricing, Grace Period, Account Hold, Prepaid-Pläne (nicht auto-renewing) und Installment-Abos (nicht in DACH).

**StoreKit-Neuerungen 2025/2026, relevant für die Preisgestaltung:** Offer Codes für alle IAP-Typen inkl. Non-Consumables (seit 29.10.2025; Promo-Codes ab 26.03.2026 eingestellt) – damit lassen sich Lifetime-Lizenzen an Presse, Therapeuten oder Beta-Tester verteilen; Monatsabo mit 12-Monats-Bindung (iOS 26.4, weltweit außer USA/Singapur); Subscription Bundles/Suites, Group Purchases (Mehrfachsitze mit Einladungsfluss) und Volume Purchasing über Apple Business Manager (angekündigt für Herbst 2026); Retention Messaging bei Kündigung; Analytics mit Peer-Benchmarks für Download→Paid und Proceeds pro Download. Family Sharing: bis zu 5 weitere Personen, gilt für Non-Consumables und Auto-Renewables, einmal aktiviert nicht rücknehmbar. Bis zu 20 IAPs können auf der Produktseite beworben werden; Non-Consumables und Abos erscheinen in der Suche, Consumables nicht.

**Steuer und Vertrieb DACH:**
- Apple und Google treten gegenüber Endkunden als Kommissionär/Händler auf. Apples Finanzberichte definieren „Customer Price" als „inclusive of any applicable taxes we collect and remit per Schedule 2 of the Paid Apps Agreement", „Partner Share" = Kundenpreis minus Steuern minus Kommission. Exhibit B des Paid Applications Agreement listet die Länder, in denen Apple Steuern einzieht (zuletzt erweitert um Marokko und Republik Kongo, News 27.08.2026; Deutschland, Österreich, Schweiz gehören seit Jahren dazu – `mustVerify`). Google-Vertragspartner für den EWR ist Google Commerce Limited, Dublin (Developer Distribution Agreement).
- Umsatzsteuerlich erbringt der Entwickler damit eine B2B-Leistung an die irische Apple- bzw. Google-Gesellschaft (Kommissionsmodell nach Art. 9a MwSt-DVO 282/2011, „deemed supplier"); es gilt Reverse-Charge, der Entwickler braucht eine USt-IdNr. und muss Zusammenfassende Meldungen abgeben. Endkunden-Mehrwertsteuer (DE 19 %, AT 20 %, CH 8,1 %) wird vom Store einbehalten und abgeführt. `mustVerify` mit Steuerberater; eur-lex war nicht erreichbar.
- Kleinunternehmerregelung § 19 UStG seit 01.01.2025: Vorjahresumsatz ≤ 25.000 €, laufendes Jahr ≤ 100.000 €; Überschreiten der 100.000 € wirkt sofort; Verzicht bindet fünf Jahre (ELSTER-Hilfetext USt 2025). Für die Store-Auszahlungen ist der Status weitgehend neutral (Reverse-Charge), er entscheidet aber über den Vorsteuerabzug (Entwicklergeräte, Apple-Developer-Programm 99 $/J, Werbung) und über Direktverkäufe (B2B-Lizenzen an Praxen, Buchdruck).
- Rechtsform: Einzelunternehmen genügt für den Start; Stores veröffentlichen bei Einzelpersonen Name und Anschrift (DSA-Händlerpflicht seit 2024; Journiv-Maintainer gründet deshalb eine LLC). Für DACH-Indies ist ein c/o-Impressumsservice oder eine UG/GmbH (Kosten ab ~1.000 €/J) die Abwägung. Apple Developer Program 99 $/J, Google Play einmalig 25 $.

## 7. Zusatzerlöse ohne Kompromiss bei der Privatsphäre

1. **Lokale KI-Auswertungen** (Stimmungsverlauf, Wochenrückblick, Themen-Cluster) mit Apple Foundation Models on-device bzw. kleinem Android-Modell: marktüblich als separates Tier (Day One Gold +25 $/J, Diarly AI+, Stoic +50 $/J). Für Small-Business-Apps hat Apple Zugang zu Foundation Models auf Private Cloud Compute „at no cloud API cost" angekündigt – für das Datenschutzversprechen aber nur on-device nutzen.
2. **Längere Aufnahmen / mehrere Einträge pro Tag / mehrere Tagebücher**: klassischer Free/Plus-Schnitt (Cleft: 5 Min. frei, 30 Min. Plus; Day One 10-Min-Transkriptionslimit).
3. **Mehrsprachigkeit und Dialektmodelle**: Deutsch/Englisch im Free-Tier, weitere Sprachpakete oder ein Schweizerdeutsch-Modell als Plus (Lizenz der Fine-Tunes prüfen, CC-BY-NC).
4. **Themes, App-Icons, Widgets**: geringe Zahlungsbereitschaft, aber gute Lifetime-Beigabe.
5. **Buchdruck-/PDF-Export**: PDF/Markdown-Export muss frei bleiben (Lock-in ist der größte Kritikpunkt an Apple Journal), ein gestaltetes Jahrbuch-PDF oder Print-on-Demand-Kooperation (Affiliate) kann bezahlt sein; Print erfordert Datenübergabe an Dritte – nur opt-in und explizit gekennzeichnet.
6. **Familienlizenz**: Family Sharing kostenlos aktivieren (RevenueCat 2025 nennt +52 % Retention durch Familienpläne, `mustVerify`); Android über Google Play Family Library für Einmalkäufe.
7. **B2B:** Therapie-Hausaufgaben (Expressives Schreiben, Stimmungstagebuch), Coaching, Unternehmens-Wellness. Ohne Server ist kein Dashboard möglich – das ist ein Verkaufsargument (keine Auftragsverarbeitung nötig), erfordert aber Distribution über Codes: Offer Codes (einmalig, bis 18-stellig, seit 2025 für Non-Consumables), Apple Business Manager Custom Apps/Volume Purchasing (Bildung 50 % Rabatt ab 20 Lizenzen; Volume Purchasing für Abos ab Herbst 2026), Google Managed Play. Preisidee: Praxis-Paket 10 Lifetime-Codes 199 € (entspricht 19,90 €/Klient, Direktverkauf mit Rechnung, umsatzsteuerlich beim Entwickler).
8. **Spenden/Open-Core**: Für ein Einzelprodukt ohne Server bringt Spende wenig (Journiv: „bare minimum"); Open-Source-Client ist jedoch Voraussetzung für Privacy-Guides-Listung und stärkt das Vertrauensargument. Möglicher Weg: Kern-Engine (Aufnahme/Transkription/Verschlüsselung) als offene Bibliothek, App proprietär – oder komplett offen mit bezahlten Store-Builds (Modell F-Droid-gratis/Store-bezahlt, wie bei vielen Android-Tools).

## 8. Drei durchgerechnete Monetarisierungsvarianten

Annahmen (konservativ, aus Abschnitt 4): 10.000 Downloads im ersten Jahr (organisch, DACH), Store-Abgabe 15 %, deutsche Umsatzsteuer 19 % im Kundenpreis enthalten (Nettofaktor 0,8403), Auszahlung = Bruttopreis × 0,8403 × 0,85 = 71,4 % des Ladenpreises. Monatsabo-Zahler bleiben im Mittel 5 Monate, Jahresabo-Retention 44 %.

**Variante A – Paymium/Einmalkauf:** Free-Kern (Aufnahme, lokale Transkription, Wiedergabe, Erinnerung, Export) + „Vollversion" 14,99 € einmalig (mehrere Tagebücher, unbegrenzte Länge, Geräte-Transfer, Themes). Konversion 3 % (Einmalkauf ohne Trial konvertiert erfahrungsgemäß besser als Abo). 300 Käufe × 14,99 € = 4.497 € brutto → 3.211 € Auszahlung im Jahr 1; Jahr 2 bei gleichem Download-Volumen identisch, kein wiederkehrender Umsatz aus Jahr 1. Vorteile: maximale Akzeptanz beim Privacy-Publikum (Flint-, Diarium-Muster), einfachste Umsetzung, Family Sharing möglich. Nachteile: keine Finanzierung von Modell-Updates/OS-Anpassungen, Umsatz skaliert nur mit Downloads.

**Variante B – Freemium + Abo mit Lifetime-Anker (empfohlen):** Free-Kern wie A. Plus: 14,99 €/Jahr (Median Productivity 29,99 $ bewusst unterboten, weil keine Serverkosten und DACH-Preissensibilität), 1,99 €/Monat, Lifetime 44,99 € (3× Jahr). 7-Tage-Trial nur im Jahresabo. Download→Paid 2 %: 200 Zahler, Mix 55 % Jahr / 20 % Monat / 25 % Lifetime. Jahr 1 brutto: 110 × 14,99 = 1.649 € + 40 × 1,99 × 5 = 398 € + 50 × 44,99 = 2.250 € = 4.297 € → 3.068 € Auszahlung. Jahr 2 (gleiche Neukohorte + 44 % Verlängerer): 4.297 € + 48 × 14,99 = 726 € → 5.023 € brutto → 3.586 €; Jahr 3 → ca. 3.900 €. Vorteile: wiederkehrender Anteil wächst, Lifetime bedient die Abo-Verweigerer und liefert Frühcash, Preisstruktur entspricht dem 2026 üblichen Zwei-/Drei-Plan-Paywall (41–60 % der Apps). Nachteile: Abo-Skepsis in Rezensionen einkalkulieren; Kommunikation „wofür zahle ich" (Modelle, OS-Updates, keine Server) ist Pflicht.

**Variante C – „Pay once, upgrade later" (Update-Pass):** Vollversion 19,99 € einmalig inkl. 12 Monaten Updates, danach funktioniert alles weiter; neue Funktionen erfordern einen Update-Pass 7,99 €/Jahr (Sketch/Agenda-Muster; im StoreKit als Non-Consumable + Non-Renewing-Subscription abbildbar). Konversion 2,5 % → 250 × 19,99 € = 4.998 € brutto → 3.569 € im Jahr 1; Jahr 2: Neukohorte 3.569 € + 30 % Pass-Käufer (75 × 7,99 = 599 € → 428 €) = 3.997 €. Vorteile: höchste Glaubwürdigkeit („Ihr Tagebuch läuft für immer"), planbare Zusatzeinnahmen. Nachteile: Feature-Gating nach Kaufdatum ist technisch und im Review fehleranfällig, für Nutzer erklärungsbedürftig, kein Family-Sharing-Standardfall.

**Skalierung:** Bei 30.000 Downloads/Jahr verdreifachen sich die Werte (B: ca. 9.200 € Jahr 1, 10.800 € Jahr 2); bei 100.000 Downloads (Diarium-Klasse über mehrere Jahre) liegt B bei 30.000–36.000 €/Jahr – oberhalb der Kleinunternehmergrenze, aber weit unter 1 Mio. $ Proceeds. Break-even gegenüber Fixkosten (99 $ Apple, 25 $ Google, ~300 € Rechtsbausteine) ist in jeder Variante im ersten Quartal erreicht; die eigentliche Investition ist Arbeitszeit.

**Empfehlung:** Variante B, ergänzt um (1) Offer-Code-basierte B2B-Pakete ab Jahr 2, (2) ein optionales lokales KI-Paket als zweites Plus-Tier erst nach Validierung der Basisnachfrage, (3) dauerhafte Garantie „Free-Funktionen werden nie kostenpflichtig" im Store-Text und in der Datenschutzerklärung. Falls der Inhaber Abos grundsätzlich ablehnt: Variante C mit Lifetime-Preis 24,99 € und Update-Pass ist die zweitbeste Option; reines A nur, wenn kein längerfristiger Weiterbetrieb geplant ist.

## 9. ASO und Marketing für ein Privacy-Publikum

**Keywords (Hypothesen, Suchvolumen nicht prüfbar):** DE: „Tagebuch", „Tagebuch App", „Sprachtagebuch", „Audio Tagebuch", „Tagebuch mit Sprache", „Journal App deutsch", „Diktiergerät Tagebuch", „Stimmungstagebuch", „Dankbarkeitstagebuch", „offline Tagebuch", „Tagebuch ohne Cloud", „verschlüsseltes Tagebuch". EN: „voice journal", „voice diary", „audio journal", „private journal", „offline journal", „encrypted diary", „journal no account". Apple: Keyword-Feld 100 Zeichen, kommagetrennt ohne Leerzeichen, keine Wiederholungen aus Titel/Untertitel, Plurale weglassen; Suche gewichtet Titel, Untertitel, Keywords, Primärkategorie sowie Downloads/Bewertungen; Produktseite lokalisieren (developer.apple.com/app-store/search). Product Page Optimization: bis zu 3 Varianten, 90 Tage, ein Test gleichzeitig. Google Play: Titel 30 Zeichen, Kurzbeschreibung 80, Beschreibung 4.000 (Play-Hilfe answer/9866151, `mustVerify`). Kategorie: iOS „Lifestyle" (Day One, Journey) oder „Health & Fitness" (Daylio); Health-Kategorie bringt Apple-Guideline 5.1.3 (keine Weitergabe von Gesundheitsdaten) und Google-Health-Apps-Deklaration mit sich – für eine serverlose App unproblematisch und sogar ein Argument.

**Kanäle:** (1) Privacy Guides – Aufnahme setzt Open-Source-Clients, E2EE bei jeder Sync-Funktion und Standard-Export voraus; Einreichung über das Forum, Threat-Model erklären; (2) pluja/awesome-privacy (GitHub-PR, kostenlos); (3) AlternativeTo-Eintrag mit Tags „offline", „no account", „end-to-end encryption"; (4) Reddit r/privacy, r/de_EDV, r/Journaling, r/PrivacyGuides mit Fokus auf Architektur, nicht Werbung; (5) Mastodon/Fediverse (chaos.social, mastodon.social) – dort sitzt das deutschsprachige Privacy-Publikum; (6) Kuketz-Blog (Empfehlungsecke, App-Prüfungen; strenger Maßstab: keine Tracker, F-Droid-Verfügbarkeit); (7) heise online/c't App-Tests, Golem, t3n mit Presseargument „erstes Sprachtagebuch mit lokaler Transkription auf Android"; (8) F-Droid-Build (falls Open Source) als Vertrauensbeweis; (9) Apple-Search-Ads auf „Tagebuch"/„Journal" nur mit kleinem Testbudget, da Freemium-RPI D60 laut RevenueCat 2026 nur 0,27–0,38 $ beträgt. Presse-Argumente: „Data Not Collected"-Label wie DailyVox, keine Netzwerkaufrufe, Apple Journal transkribiert nur Englisch, Diarium/Daylio/Journey transkribieren auf Android gar nicht, Transfer per QR statt Cloud, Zero-Knowledge auch gegenüber dem Hersteller.

## 10. Offene Fragen

- Exakte EUR-Preise von Day One, Journey, Daylio, Diarium, Diarly in den DACH-Stores (Store-Seiten blockiert).
- Genaue aktuelle Fee-Struktur des Google-Play-Programms für externe Angebote im EWR (2025/2026-Revision).
- Ob Exhibit B des Apple Paid Applications Agreement die Schweiz weiterhin als Land mit Apple-Steuereinzug führt.
- Umsatzsteuerliche Behandlung der Kommission (Reverse-Charge, ZM-Pflicht) für einen Kleinunternehmer – Steuerberater.
- Suchvolumen der DE-Keywords (Apple Search Ads Popularity, AppTweak/Sensor Tower).
- RevenueCat-2026-Originalzahlen für „Lifestyle" bzw. „Health & Fitness" in Europa (Report nur über Drittzitate zugänglich).

## Quellen

- Apple Small Business Program: https://developer.apple.com/app-store/small-business-program/
- Apple EU-Terms (Stand 18.08.2026, gültig ab 01.10.2026): https://developer.apple.com/support/dma-and-apps-in-the-eu/ ; News: https://developer.apple.com/news/
- Apple Auto-renewable Subscriptions (Kommission, Trials, Family Sharing, Offers): https://developer.apple.com/app-store/subscriptions/
- Apple Business Models: https://developer.apple.com/app-store/business-models/
- Apple App Review Guidelines (3.1.1, 3.1.3, 5.1.1, 5.1.3): https://developer.apple.com/app-store/review/guidelines/
- Apple App Store Search / Keywords: https://developer.apple.com/app-store/search/
- Apple Product Page Optimization: https://developer.apple.com/app-store/product-page-optimization/
- Apple Promoting In-App Purchases: https://developer.apple.com/app-store/promoting-in-app-purchases/
- Apple What's New (12-Monats-Bindung, Bundles, Group/Volume Purchasing, Retention Messaging): https://developer.apple.com/app-store/whats-new/
- Apple News (Offer Codes für alle IAP-Typen 29.10.2025; Analytics 25.03.2026; 12-Monats-Bindung 27.04.2026): https://developer.apple.com/news/?id=r1s3hw2b
- Apple Custom Apps / Apple Business Manager: https://developer.apple.com/custom-apps/
- Apple Financial Report Fields (Customer Price, Partner Share, Schedule 2): https://developer.apple.com/help/app-store-connect/reference/financial-report-fields/
- Apple Preispunkte (800 + 100): https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price
- Apple Tax and Price Updates 27.08.2026 (Exhibit B): https://developer.apple.com/news/?id=artln8br
- Google Play Billing Subscriptions (Trials, Grace Period, Prepaid): https://developer.android.com/google/play/billing/subscriptions
- Google Play Alternative Billing: https://developer.android.com/google/play/billing/alternative
- Google Play Service Fee (nicht direkt abrufbar): https://support.google.com/googleplay/android-developer/answer/112622
- Google External Offers EEA Fees (März 2024, Slashdot/TechCrunch-Kopie): https://github.com/textbrowser/spot-on-shared-pages ; Google-Blog: https://blog.google/around-the-globe/google-europe/complying-with-the-digital-markets-act/
- Google Developer Distribution Agreement (Google Commerce Limited): https://github.com/mnov88/dsacontracts ; Original: https://play.google.com/about/developer-distribution-agreement.html
- RevenueCat State of Subscription Apps 2025 (Extrakt): https://raw.githubusercontent.com/best-trading-indicator-tools/devrel-hackaton-adapty/main/revenuecat-data/conversion-benchmarks.json , .../pricing-benchmarks.json , .../revenue-benchmarks.json ; Original: https://www.revenuecat.com/pdf/state-of-subscription-apps-2025.pdf
- RevenueCat 2026 / Adapty 2026 (Zitatsammlung März 2026): https://raw.githubusercontent.com/Nikolai-Iakubovskii/app-paywall-pilot/main/outputs/2026-paywall-research.md ; Originale: https://www.revenuecat.com/state-of-subscription-apps/ , https://adapty.io/state-of-in-app-subscriptions/
- RevenueCat Codelab (1,7 % / 4,2 %): https://github.com/RevenueCat/codelab (rc/monetization-strategies/codelab.md)
- Straits Research Digital Journal Apps Market: https://straitsresearch.com/report/digital-journal-apps-market
- Day One Preise: https://9to5mac.com/2026/04/08/day-one-journaling-app-introduces-gold-plan-with-ai-summaries-and-daily-chat/ ; https://5typos.net/2026/04/8/day-one-introduces-silver-and-gold-with-price-increases
- Flint Preis/Positionierung: https://klu.so/blog/private-voice-journaling ; https://www.danrecommends.com/reviews/flint
- DailyVox (kostenlos, MIT, Data Not Collected): https://github.com/intrepidkarthi/dailyvox
- Diarly DE-Listing: https://apps.apple.com/de/app/diarly-mein-tagebuch-journal/id1387167765
- CortexOS Preise: https://cortexos.app/faq/ ; Speakwise: https://speakwiseapp.com/
- Parallel-Recherchen dieser Sitzung mit weiteren Preisquellen: /tmp/claude-0/-home-user-tagebuch/6e7ee5ed-3c99-505b-8436-5a39ab967544/scratchpad/research/wettbewerb-mainstream.md und .../wettbewerb-voice-first.md
- Bitwarden Preis 2026: https://github.com/anoni-net/docs (docs/en/tools/password-manager.md) ; https://github.com/Qutaifan/THEHUB (reviews/bitwarden.html) ; Original: https://bitwarden.com/pricing/
- Obsidian Preise: https://github.com/s0shaheen/commonplace (docs/research/2026-07-06-refounding-research.md) ; Original: https://obsidian.md/pricing
- Proton Preise (Checkout 01.08.2026): https://github.com/ThePhaseless/Interstellar (docs/email-provider-research.md) ; Original: https://proton.me/mail/pricing
- Standard Notes Preise (Aug. 2026): https://github.com/LifetimeLabsDev/PrivacyNotes.app ; Original: https://standardnotes.com/plans
- Cryptomator Lizenz/Spenden: https://github.com/cryptomator/cryptomator
- Privacy Guides Kriterien: https://raw.githubusercontent.com/privacyguides/privacyguides.org/main/docs/notebooks.md ; https://raw.githubusercontent.com/privacyguides/privacyguides.org/main/docs/about/criteria.md
- Awesome Privacy: https://raw.githubusercontent.com/pluja/awesome-privacy/main/README.md
- Journiv Finanzierung/Paywall/Encryption-Poll: https://github.com/orgs/journiv/discussions/348 ; https://github.com/orgs/journiv/discussions/425 ; https://github.com/orgs/journiv/discussions/567
- Dictus Open-Core-Grundsatz: https://github.com/getdictus/dictus-ios/issues/54
- Kleinunternehmer § 19 UStG 2025 (ELSTER-Hilfetext): https://raw.githubusercontent.com/dennismenken/elster-form-helper-data/main/Formulare/USt/2025/elster_ust2025_help.md
- EU-Compliance-Notizen zu externen Käufen (Verlust von Family Sharing etc.): https://github.com/mjmirza/app-store-compliance (docs/EU-REGULATORY-2026.md)
