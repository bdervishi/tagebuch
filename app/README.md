# tagebuch_app

Flutter-App des lokalen Sprach-Tagebuchs (Arbeitstitel siehe Repo-README, Name offen nach D11). Alles läuft auf dem Gerät: keine Konten, keine Server, kein Tracking (D14).

## Start

```sh
export PATH=/opt/flutter/bin:$PATH   # falls Flutter nicht im PATH liegt
cd app
flutter pub get        # löst den Pub-Workspace auf und erzeugt lib/l10n/app_localizations*.dart
flutter run            # Gerät oder Simulator/Emulator
flutter analyze
flutter test
```

Die Lokalisierung wird über `l10n.yaml` aus `lib/l10n/app_de.arb` (Vorlage) und `app_en.arb` erzeugt. Nach Änderungen an den ARB-Dateien `flutter gen-l10n` ausführen; die erzeugten Dateien liegen in `lib/l10n/` und sind eingecheckt.

## Struktur

```
lib/
  main.dart                      Einstieg, ProviderScope
  app/
    app.dart                     MaterialApp (Material 3, warmes Schema, hell/dunkel), RootScreen (Onboarding oder Hauptansicht)
    theme.dart                   Farbschema und Bedienmaße (Touch-Ziele mindestens 48 dp)
    routes.dart                  Benannte Routen: /record (Vollbild), /entry, /onboarding
    shell.dart                   Untere Leiste: Heute, Kalender, Einstellungen
    formats.dart                 Dauer- und Uhrzeitformatierung
  data/
    diary_entry.dart             In-Memory-Modell eines Eintrags plus Abfragen (Tag, Monat, Suche)
    entries_notifier.dart        Riverpod-Notifier für alle Einträge (flüchtig)
    settings_notifier.dart       Riverpod-Notifier für Einstellungen (flüchtig)
    day.dart                     Kalendertag-Hilfen
  features/
    heute/                       Startbildschirm mit großer Aufnahmetaste und heutigem Eintrag
    aufnahme/                    Vollbild-Aufnahme: Timer, Pegel-Platzhalter, Pause, Fertig, Abbrechen mit Rückfrage
    eintrag/                     Eintrag: Datum, Dauer, Sprache, Player-Platzhalter, Transkript
    kalender/                    Monatsraster (selbst gebaut) mit markierten Tagen und Suche
    einstellungen/               Erinnerung, Transkriptionssprache, Audio, App-Sperre, Daten, Datenschutz
    onboarding/                  Vier Textschritte (docs/03 Abschnitt 3), überspringbar
  widgets/entry_tile.dart        Listenzeile eines Eintrags
  l10n/                          ARB-Dateien und erzeugte AppLocalizations
test/                            Widget-Tests: Ablauf Heute → Aufnahme → Eintrag, Kalender-Markierung, Lokalisierung
android/                         Härtung: kein INTERNET im Haupt-Manifest, allowBackup=false, dataExtractionRules, FLAG_SECURE, minSdk 31, nur arm64-v8a
ios/Runner/                      Info.plist (Mikrofon-Text, UIBackgroundModes audio, ITSAppUsesNonExemptEncryption), PrivacyInfo.xcprivacy
```

## Platzhalter und Fakes

Die Pakete `diary_*` im Workspace entstehen parallel. Die App importiert derzeit **nichts** daraus und läuft mit eigenen In-Memory-Fakes:

| Heute Platzhalter | Später echt verdrahtet mit |
|---|---|
| `EntriesNotifier` (Liste im Speicher, Suche per `contains`) | `diary_core` (Modell, Anwendungsfälle) und `diary_storage` (SQLCipher, FTS5) |
| Simulierte Aufnahme (Timer, Zufallspegel, kein Mikrofon) | `diary_audio` (PCM im Speicher, Pegel, Wellenform) und `diary_chunkfile`/`diary_crypto` (chunkweise Verschlüsselung) |
| Transkript "Transkription folgt" | `diary_stt` (iOS SpeechTranscriber, Android sherpa-onnx) |
| Player-Platzhalter ohne Wiedergabe | `diary_audio` (Wiedergabe direkt aus der verschlüsselten Datei) |
| Erinnerungseinstellungen ohne Benachrichtigung | `diary_reminders` (Planung, "Heute nicht", "In 1 Stunde", Pause) |
| Schalter "App-Sperre" ohne Funktion | `diary_keys` (Keychain/Keystore, Biometrie) plus Privacy-Overlay |
| "Backup erstellen" und "Gerätewechsel" deaktiviert | `diary_container` (Passphrase-Backup, QR + Datei) |
| Einstellungen flüchtig | Persistenz (verschlüsselt) |

Ebenfalls noch offen: Mikrofon-Berechtigung (Android `RECORD_AUDIO`, iOS-Systemabfrage), Privacy-Overlay auf iOS (`sceneWillResignActive`), Nachtrag "Für gestern nachtragen", Karte "Vor einem Jahr", Text bearbeiten, Export.

## iOS: PrivacyInfo.xcprivacy in Xcode hinzufügen

`ios/Runner/PrivacyInfo.xcprivacy` liegt im Dateisystem, ist aber noch **nicht** im Xcode-Projekt registriert (hier gibt es kein Xcode). Einmalig in Xcode: `Runner.xcworkspace` öffnen, Rechtsklick auf die Gruppe `Runner` → "Add Files to Runner…" → `PrivacyInfo.xcprivacy` wählen, Target "Runner" ankreuzen. Danach erscheint die Datei unter "Copy Bundle Resources". Inhalt: kein Tracking, keine Domains, keine erhobenen Datentypen, Required-Reason-APIs Datei-Zeitstempel (C617.1), User Defaults (CA92.1), System-Boot-Time (35F9.1).

`ITSAppUsesNonExemptEncryption` steht auf `true` (eigene Kryptografie, Selbstklassifizierung als Ausnahme; docs/05 Abschnitt 5.4). Vor der ersten Einreichung prüfen lassen.

## Namensplatzhalter

`applicationId` ist `dev.tagebuch.app` (Platzhalter). Nach der Namenswahl (D11) anpassen: `android/app/build.gradle.kts` (`applicationId`, `namespace`), Kotlin-Paket `dev.tagebuch.tagebuch_app`, iOS `PRODUCT_BUNDLE_IDENTIFIER` im Xcode-Projekt, `android:label` und `CFBundleDisplayName` (derzeit "Tagebuch").

## Android: INTERNET-Berechtigung

Das Haupt-Manifest fordert keine `INTERNET`-Berechtigung an (D14). Die von Flutter erzeugten Manifeste in `android/app/src/debug` und `src/profile` behalten sie, weil Hot Reload, Breakpoints und DevTools sie brauchen; Release-Builds enthalten sie nicht. Der Nachweis läuft im Flugmodus.
