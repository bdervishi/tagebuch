# Ressourcen: kostenlose Dienste für den Betrieb des Projekts

Stand: 6. September 2026 · Quelle: [free-for.dev](https://free-for.dev/) (gepflegt im Repository [ripienaar/free-for-dev](https://github.com/ripienaar/free-for-dev), Stand der Auswertung 6. 9. 2026)

## Wozu diese Liste

Die App selbst braucht keine Server (D14). Kostenlose Dienste sind trotzdem an vielen Stellen um die App herum nützlich: Build und Test, iOS-Builds ohne eigenen Mac, Beta-Verteilung, Übersetzung, Website, Support-Adresse, Domain und Design. free-for.dev sammelt solche Angebote mit den Bedingungen des Gratis-Tarifs. Diese Datei hält fest, welche Kategorien für dieses Projekt relevant sind, welche Dienste dort in Frage kommen und wo wir bewusst nichts einsetzen. Bedingungen ändern sich; vor dem Einsatz immer die aktuelle Preisseite prüfen.

Grundregel für jede Auswahl: Der Dienst darf nie Nutzerdaten der App sehen. Er verarbeitet Quellcode, Builds, Übersetzungen, Website-Besuche oder Support-Mails, nie Tagebuchinhalte oder Testaufnahmen echter Personen (`docs/04-technik-architektur.md`, Abschnitt 10).

## Wo wir was einsetzen können

| Bedarf | Wann | Kandidaten (Gratis-Bedingung laut free-for.dev) | Hinweis für dieses Projekt |
|--------|------|------------------------------------------------|----------------------------|
| Quellcode, Issues, Projektplanung | ab sofort | GitHub (unbegrenzt öffentliche und private Repos, Actions, Pages, Projects) | Bereits im Einsatz. Codeberg (Forgejo, Codeberg Pages) als europäischer Spiegel, falls gewünscht. |
| CI für Analyse, Tests, Android-Build | Phase 0/1 | GitHub Actions (Linux-Minuten für öffentliche Repos kostenlos), CircleCI (kostenloser Plan mit macOS/ARM-Executors), Buildkite (5 000 Job-Minuten) | Primär GitHub Actions, wie in `04-technik-architektur.md` Abschnitt 10 vorgesehen; Netz-Wächter-Skript dort einbauen. |
| iOS-Build und TestFlight ohne eigenen Mac | Phase 1 bis Beta | Codemagic (500 Minuten/Monat, Mac-Mini-Instanz), Bitrise (200 Builds/Monat, für Open Source 45 Minuten Build-Zeit), Appcircle (20 Builds/Monat) | Codemagic ist auf Flutter zugeschnitten und übernimmt Signierung und TestFlight-Upload. Achtung: Signaturzertifikate liegen dann beim Dienst; nur für Beta-Builds, Store-Builds gemäß Abschnitt 10 lokal signieren. |
| Testabdeckung und Codequalität | ab Phase 1 | Codecov (frei für Open Source), Coveralls, SonarCloud (frei für Open Source, prüft auch Swift und Kotlin), CodeFactor, CodeRabbit (KI-Review, frei für Open Source) | Nur bei öffentlichem Repository (D10). KI-Reviews sehen den Quellcode; das ist bei Open Source unkritisch. |
| Abhängigkeiten und Lieferkette | ab Phase 1 | Dependabot (in GitHub enthalten), Socket (frei für Einzelentwickler und Open Source), semgrep (unbegrenzt öffentliche Repos), GitGuardian (Secret-Scanning, frei bis 25 Entwickler) | Ergänzt den Netz-Wächter: neue Pakete auf Netzwerkzugriff prüfen, Geheimnisse im Repo sofort erkennen. |
| Emulatoren im Browser für Screenshots und Demos | Store-Vorbereitung | Appetize (2 gleichzeitige Sitzungen, 30 Minuten/Monat) | Nur mit synthetischen Testdaten, nie mit echten Aufnahmen. |
| Beta-Verteilung an Tester | Beta | TestFlight und Google Play Internal Testing (Standardwege der Stores, kostenlos); für Android-Direktverteilung Diawi, InstallOnAir, Loadly, GetUpdraft | iOS-Direktverteilung ohne TestFlight braucht Geräte-UDIDs; deshalb TestFlight. F-Droid als späterer Kanal für den reproduzierbaren Build (D10). |
| Übersetzung der App-Texte (ARB-Dateien) | ab Version 1.x, weitere Sprachen | Crowdin (unbegrenzt für Open Source, kennt Flutter-ARB), Transifex (frei für Open Source), Localizely (frei für Open Source, Flutter-Fokus), Tolgee (selbst hostbar), Lokalise nicht gelistet | Deutsch und Englisch pflegen wir selbst im Repo. Community-Übersetzungen erst, wenn es eine Community gibt. |
| Website und Landing-Page | vor dem Store-Start | GitHub Pages (im Repo), Cloudflare Pages, Netlify (300 Credits/Monat), Codeberg Pages, surge.sh | Statische Seite ohne Tracker, ohne externe Schriften-CDN, sonst fällt sie bei Kuketz-Blog und Privacy Guides durch. Datenschutzerklärung und Impressum gehören dorthin. |
| Dokumentation | optional | Read the Docs (MkDocs, kostenlos mit Versionierung), GitHub Pages | Die Konzeptdokumente bleiben Markdown im Repo; eine gerenderte Fassung ist Komfort. |
| Kontakt- und Support-Formular ohne Server | Website | Tally (fast alles kostenlos, EU-Anbieter), Web3Forms (250 Einsendungen/Monat), Formspree (50/Monat) | Für Support reicht eine E-Mail-Adresse; Formulare nur, wenn Spam zum Problem wird. |
| Support-E-Mail unter eigener Domain | Store-Start | forwardemail.net (unbegrenzte Weiterleitungen, Open Source), ImprovMX (Weiterleitung), DNSExit (2 Postfächer) | Weiterleitung auf ein bestehendes Postfach genügt; keine Newsletter-Werkzeuge nötig. |
| Ankündigungen und Newsletter | optional | Buttondown (bis 100 Abonnenten), MailerLite (1 000 Abonnenten) | Nur Double-Opt-in, nur wenn es eine Warteliste geben soll. Mastodon und GitHub Releases reichen für den Start. |
| DNS für die Projektdomain | mit der Domain | deSEC (kostenlos, DNSSEC, gemeinnützig aus Berlin), Hetzner DNS Console, Cloudflare | deSEC passt zur Datenschutz-Positionierung. Domains selbst sind nicht kostenlos; free-for.dev listet nur Subdomains. |
| TLS-Zertifikate für die Website | mit der Website | Let's Encrypt | Bei GitHub/Cloudflare Pages automatisch enthalten. |
| Design, Mockups, Store-Grafiken | Produktkonzept bis Store | Figma (2 Bearbeiter, 3 Projekte), Excalidraw (Diagramme für `docs/`), Canva, smartmockups (200 Gerätemockups), SVGicons, Fontshare und Google Fonts (Schriften herunterladen und in die App bündeln) | Schriften nie zur Laufzeit von einem CDN laden; die App hat keine Internet-Berechtigung. |
| Zeiterfassung für die Aufwandsfrage | ab Phase 0 | Clockify (unbegrenzt kostenlos), Pulse.red | `09-roadmap.md` schätzt 1 000 bis 2 000 Stunden; die Erfassung macht die Schätzung überprüfbar. |
| Datenschutzerklärung und Impressum | Store-Start | Iubenda (eingeschränkter Gratis-Tarif) | Die Erklärung der App ist kurz ("es werden keine Daten erhoben"); besser selbst schreiben, Vorlagen in `05-sicherheit-und-datenschutz.md`. |
| Werkzeuge für Krypto-Debugging | Entwicklung | CyberChef (vollständig kostenlos, läuft im Browser) | Zum Prüfen von Containern, Base32/Hex, HKDF-Ableitungen bei Testvektoren. |

## Wo wir bewusst nichts einsetzen

| Kategorie auf free-for.dev | Warum nicht |
|----------------------------|-------------|
| Crash and Exception Handling (Sentry, Bugsnag, Embrace usw.) | Verstößt gegen D14 (keine Crash-Reporter mit Upload). Abstürze werden lokal protokolliert; Nutzer können ein Protokoll manuell per E-Mail schicken. |
| Analytics, Events and Statistics; Visitor Session Recording | Kein Tracking in App und Website. Store-Konsolen liefern Downloadzahlen ohne Zutun. |
| BaaS, PaaS, Managed Data Services, Messaging | Die App hat keinen Server. Ein späterer Nutzer-eigener Speicher (Cryptomator-Modell) wäre ein Ausbau, kein Dienst des Inhabers. |
| Feature Toggles Management, Authentication | Keine Konten, keine Fernkonfiguration. Feature-Flags sind Build-Konstanten. |
| Generative AI (API-Dienste) | Zusammenfassungen laufen nur lokal (D8). Für Entwicklungswerkzeuge ist der Einsatz Sache des Entwicklers, nie der App. |
| Mobile App Distribution über Drittanbieter für Store-Builds | Store-Builds gehen nur über TestFlight, Play Console und F-Droid; Drittverteiler höchstens für Android-Testbuilds an bekannte Tester. |
| Cloud-Gerätefarmen mit echten Daten | Nur synthetische Testdaten (Abschnitt 10 Punkt 6 im Technikkonzept). |

## Im Einsatz

| Dienst | Seit | Konto | Was der Dienst sieht |
|--------|------|-------|----------------------|
| GitHub (Repository, Actions, Pages) | September 2026 | Inhaber | Quellcode, Build-Protokolle, die statischen Dateien der PWA. Keine Nutzerdaten; die PWA sendet nichts an den Host zurück. GitHub Pages protokolliert Zugriffe serverseitig ohne Einfluss von uns; wer das vermeiden will, hostet die Dateien selbst. |

## Pflege

- Wenn ein Dienst eingesetzt wird: hier eintragen, mit Datum, Kontoinhaber und was der Dienst sieht.
- Vierteljährlich prüfen, ob die Gratis-Bedingungen noch gelten (free-for.dev aktualisiert die Liste laufend).
- Neue Kandidaten zuerst gegen die Grundregel oben prüfen: Sieht der Dienst Nutzerdaten? Dann nein.
