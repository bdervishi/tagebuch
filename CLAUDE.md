# Tagebuch (Arbeitstitel „Abendton“)

Lokales Sprach-Tagebuch für iOS und Android: täglich zu einer selbst gewählten Uhrzeit sprechen, die App transkribiert auf dem Gerät und gibt Audio und Text wieder. Keine Cloud, keine Konten, keine Server, keine Telemetrie. Gerätewechsel und Backup als verschlüsselte Datei, der QR-Code trägt nur Schlüsselmaterial.

## Wo was steht

- `docs/00-anforderungen.md` bis `docs/09-roadmap.md`: Konzept (Anforderungen, Markt, Produkt, Technik, Sicherheit, Transfer, Geschäftsmodell, Name, Roadmap). Sprache Deutsch.
- `docs/entscheidungen.md`: verbindliche Entscheidungen D1 bis D15. Erst lesen, dann bauen. Abweichungen dort begründen, nicht still im Code.
- `docs/12-gestaltung.md`: Gestaltung und Bewegung (Tokens in `app/lib/app/motion.dart`, Bausteine `Pressable`, `Reveal`, `SurfaceCard` in `app/lib/widgets/`). Vor jeder neuen Animation oder Karte die Prüfliste dort durchgehen; keine eigenen Dauern oder Kurven im Code.
- `docs/recherche/`: Rechercheberichte und Faktenprüfung (`verifikation.json`).
- `docs/ressourcen.md`: kostenlose Dienste aus free-for.dev und wo wir sie einsetzen (CI, iOS-Builds ohne Mac, Übersetzung, Website, Support-Mail) und wo bewusst nicht (Crash-Reporter, Analytics). Vor dem Anbinden eines Dienstes dort nachsehen und eintragen.
- `app/`: Flutter-App (Paket `tagebuch_app`, Anwendungs-ID `dev.tagebuch.app` als Platzhalter bis zur Namenswahl). Erste Zielplattform ist das Web als installierbare PWA (D16, `docs/10-pwa.md`); `app/web/` enthält Manifest, `index.html` mit Content-Security-Policy und Icons.
- `packages/`: Kernpakete, jedes einzeln testbar:
  - `diary_core` Domänenmodell (auch `EntryNote` für geschriebene Texte und Rückblick-Antworten, D17; `Goal` und `Milestone` für Wege mit Etappen, D19), Ports, Anwendungsfälle `RecordDayUseCase`, `GoalsUseCase` (höchstens drei aktive Ziele) und `TransferUseCase` (Backup, Gerätewechsel; reines Dart)
  - `diary_crypto` AEAD-Schnittstelle, Key-Wrapping, HKDF, Argon2id-Parameter (reines Dart, Referenz mit `package:cryptography`)
  - `diary_chunkfile` Chunk-AEAD-Dateiformat mit wahlfreiem Zugriff (Format in dessen README, Testvektoren für Swift/Kotlin)
  - `diary_container` Transfer-/Backup-Container: Kopf, QR-Nutzlast, Manifest, Rahmung, Schlüsselableitung (Argon2id, X25519/HKDF), Stromverschlüsselung (Referenz Kennung 2) und Writer/Reader (Format in dessen README)
  - `diary_storage` drift-Schema, FTS5, SQLCipher-Öffnung
  - `diary_audio`, `diary_stt`, `diary_keys`, `diary_reminders` Schnittstellen mit Fakes; native Brücken folgen in den Spikes. `diary_reminders` enthält außerdem `CalendarLinks` (vorbefüllte Links für Google Kalender und Outlook, D18)
  - `diary_stt_web` Whisper im Browser (transformers.js + ONNX Runtime Web im Worker `app/web/stt/`, Modell vom eigenen Origin; Dateiliste `app/web/stt/MODELS.md`), experimentell (W5)
  - `diary_web` Web-Umsetzungen der Ports: WebCrypto-Master-Key, verschlüsselte Datensätze und Audiodateien in IndexedDB, MediaRecorder-Aufnahme, Player, ICS-Erinnerung (Tests laufen im Chromium)
- `tool/check_no_network.sh`: Netz-Wächter (keine INTERNET-Berechtigung, keine gesperrten Pakete, keine Netzwerk-APIs). Läuft in der CI.
- `app/assets/quotes/`: gebündelter Zitatenschatz (D20; Regeln in dessen README: nur gemeinfreie Autorinnen und Autoren, eigene Übertragungen, belegte Quellen).
- `models/`, `test_assets/`: nur Manifeste und Skripte, keine Binärdateien, keine echten Aufnahmen.

## Befehle

```bash
export PATH=/opt/flutter/bin:$PATH          # in dieser Umgebung; Flutter 3.47.x stable
flutter pub get                              # einmal an der Workspace-Wurzel (pub workspace)
dart format .
flutter analyze
(cd packages/diary_crypto && dart test)      # reine Dart-Pakete: dart test
(cd packages/diary_reminders && flutter test) # Flutter-Pakete und app/: flutter test
tool/check_no_network.sh
(cd packages/diary_storage && dart run build_runner build --delete-conflicting-outputs)  # nach Schemaänderungen

# Web / PWA
export CHROME_EXECUTABLE=/opt/pw-browsers/chromium-1243/chrome-linux64/chrome   # Chromium für Browser-Tests
(cd packages/diary_web && flutter test --platform chrome)
tool/fetch_stt_vendor.sh                                          # einmalig: transformers.js/ONNX-Runtime (43 MB, nicht im Git) nach app/web/stt/vendor
tool/build_web.sh [base-href]                                    # kompletter PWA-Build: Flutter Web ohne CDN + eigener Service Worker (tool/generate_sw.py)
(cd app/build/web && python3 -m http.server 8765)                 # lokal ansehen; Headless-Screenshot siehe Git-Historie
```

Web-Regeln (D16): immer über `tool/build_web.sh` bauen (Flutter 3.47 liefert keinen Offline-Service-Worker mehr; `tool/generate_sw.py` erzeugt `sw.js`, `app/web/sw_register.js` registriert ihn); `--no-web-resources-cdn` ist Pflicht; die CSP in `app/web/index.html` bleibt bei `connect-src 'self'`; keine externen Skripte, Schriften oder Modelle von fremden Hosts (Modelle für die Browser-Erkennung werden vom eigenen Origin ausgeliefert). GitHub Pages veröffentlicht den Standardzweig über `.github/workflows/web.yml`.

Kein Android-SDK und kein Xcode in dieser Umgebung: Builds laufen in der CI (`.github/workflows/ci.yml`) oder lokal beim Inhaber.

## Regeln

- **Kein Netz.** Keine Abhängigkeit mit Netzwerkzugriff, keine Analytics-, Crash- oder Werbe-SDKs, keine `INTERNET`-Berechtigung im Release. Der Netz-Wächter muss vor jedem Commit bestehen. Einzige Ausnahme sind die vorbefüllten "Termin anlegen"-Links für Google Kalender und Outlook (D18): nur die drei Hosts aus `CalendarLinks.allowedHosts`, geöffnet nur auf Tipp über `PlatformFeatures.openExternalLink`, nie von der App geladen. Die spätere WLAN-Direktübertragung (D6, Version 1.x) ändert diese Regel sichtbar in `tool/check_no_network.sh` und in den Docs, nicht nebenbei.
- **Kein Klartext auf dem Dateisystem.** Audio nur über `diary_chunkfile`, Metadaten nur in SQLCipher, Schlüssel nur über `diary_keys`. Keine Temp-Dateien mit Nutzdaten, keine Inhalte in Benachrichtigungen, Widgets oder Logs.
- **Entscheidungen zuerst.** Was in `docs/entscheidungen.md` steht, gilt. Wer davon abweichen muss, ändert zuerst die Entscheidung mit Begründung (Historie oben in der Datei), dann den Code.
- **Sprache.** Bezeichner im Code Englisch; Kommentare, Doku, Commit-Nachrichten und Oberflächentexte Deutsch (Oberfläche zusätzlich Englisch über ARB in `app/lib/l10n`). Keine hartkodierten UI-Strings.
- **Tests gehören zur Änderung.** Kryptografie und Dateiformate mit Testvektoren; Format- und Schemaänderungen brauchen Migration und Test.
- **Abhängigkeiten sparsam.** Neue Pakete nur mit Begründung im Commit und Prüfung auf Netzwerkzugriff; `pubspec.lock` ist eingecheckt.
- **Platzhalter kennzeichnen.** Fakes und Simulationen heißen `Fake…`/`Simulated…` und werden in den Spikes durch native Umsetzungen ersetzt (Reihenfolge in `docs/09-roadmap.md`).

## Offen (Inhaber entscheidet)

Name, Lizenz (GPLv3 oder Open Core), Rechtsform und veröffentlichte Adresse, Umfang von Plus zum Start, Budget für Krypto-Review und Testgeräte. Siehe `docs/09-roadmap.md` Abschnitt 13.
