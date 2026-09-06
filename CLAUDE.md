# Tagebuch (Arbeitstitel „Abendton“)

Lokales Sprach-Tagebuch für iOS und Android: täglich zu einer selbst gewählten Uhrzeit sprechen, die App transkribiert auf dem Gerät und gibt Audio und Text wieder. Keine Cloud, keine Konten, keine Server, keine Telemetrie. Gerätewechsel und Backup als verschlüsselte Datei, der QR-Code trägt nur Schlüsselmaterial.

## Wo was steht

- `docs/00-anforderungen.md` bis `docs/09-roadmap.md`: Konzept (Anforderungen, Markt, Produkt, Technik, Sicherheit, Transfer, Geschäftsmodell, Name, Roadmap). Sprache Deutsch.
- `docs/entscheidungen.md`: verbindliche Entscheidungen D1 bis D15. Erst lesen, dann bauen. Abweichungen dort begründen, nicht still im Code.
- `docs/recherche/`: Rechercheberichte und Faktenprüfung (`verifikation.json`).
- `docs/ressourcen.md`: kostenlose Dienste aus free-for.dev und wo wir sie einsetzen (CI, iOS-Builds ohne Mac, Übersetzung, Website, Support-Mail) und wo bewusst nicht (Crash-Reporter, Analytics). Vor dem Anbinden eines Dienstes dort nachsehen und eintragen.
- `app/`: Flutter-App (Paket `tagebuch_app`, Anwendungs-ID `dev.tagebuch.app` als Platzhalter bis zur Namenswahl).
- `packages/`: Kernpakete, jedes einzeln testbar:
  - `diary_core` Domänenmodell, Ports, Anwendungsfall `RecordDayUseCase` (reines Dart)
  - `diary_crypto` AEAD-Schnittstelle, Key-Wrapping, HKDF, Argon2id-Parameter (reines Dart, Referenz mit `package:cryptography`)
  - `diary_chunkfile` Chunk-AEAD-Dateiformat mit wahlfreiem Zugriff (Format in dessen README, Testvektoren für Swift/Kotlin)
  - `diary_container` Kopf, QR-Nutzlast, Manifest und Rahmung des Transfer-/Backup-Containers
  - `diary_storage` drift-Schema, FTS5, SQLCipher-Öffnung
  - `diary_audio`, `diary_stt`, `diary_keys`, `diary_reminders` Schnittstellen mit Fakes; native Brücken folgen in den Spikes
- `tool/check_no_network.sh`: Netz-Wächter (keine INTERNET-Berechtigung, keine gesperrten Pakete, keine Netzwerk-APIs). Läuft in der CI.
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
```

Kein Android-SDK und kein Xcode in dieser Umgebung: Builds laufen in der CI (`.github/workflows/ci.yml`) oder lokal beim Inhaber.

## Regeln

- **Kein Netz.** Keine Abhängigkeit mit Netzwerkzugriff, keine Analytics-, Crash- oder Werbe-SDKs, keine `INTERNET`-Berechtigung im Release. Der Netz-Wächter muss vor jedem Commit bestehen. Die spätere WLAN-Direktübertragung (D6, Version 1.x) ändert diese Regel sichtbar in `tool/check_no_network.sh` und in den Docs, nicht nebenbei.
- **Kein Klartext auf dem Dateisystem.** Audio nur über `diary_chunkfile`, Metadaten nur in SQLCipher, Schlüssel nur über `diary_keys`. Keine Temp-Dateien mit Nutzdaten, keine Inhalte in Benachrichtigungen, Widgets oder Logs.
- **Entscheidungen zuerst.** Was in `docs/entscheidungen.md` steht, gilt. Wer davon abweichen muss, ändert zuerst die Entscheidung mit Begründung (Historie oben in der Datei), dann den Code.
- **Sprache.** Bezeichner im Code Englisch; Kommentare, Doku, Commit-Nachrichten und Oberflächentexte Deutsch (Oberfläche zusätzlich Englisch über ARB in `app/lib/l10n`). Keine hartkodierten UI-Strings.
- **Tests gehören zur Änderung.** Kryptografie und Dateiformate mit Testvektoren; Format- und Schemaänderungen brauchen Migration und Test.
- **Abhängigkeiten sparsam.** Neue Pakete nur mit Begründung im Commit und Prüfung auf Netzwerkzugriff; `pubspec.lock` ist eingecheckt.
- **Platzhalter kennzeichnen.** Fakes und Simulationen heißen `Fake…`/`Simulated…` und werden in den Spikes durch native Umsetzungen ersetzt (Reihenfolge in `docs/09-roadmap.md`).

## Offen (Inhaber entscheidet)

Name, Lizenz (GPLv3 oder Open Core), Rechtsform und veröffentlichte Adresse, Umfang von Plus zum Start, Budget für Krypto-Review und Testgeräte. Siehe `docs/09-roadmap.md` Abschnitt 13.
