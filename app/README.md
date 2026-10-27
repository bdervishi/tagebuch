# tagebuch_app

Flutter-App des lokalen Sprach-Tagebuchs (Arbeitstitel siehe Repo-README, Name offen nach D11). Alles läuft auf dem Gerät: keine Konten, keine Server, kein Tracking (D14).

## Start

```sh
export PATH=/opt/flutter/bin:$PATH   # falls Flutter nicht im PATH liegt
cd app
flutter pub get        # löst den Pub-Workspace auf und erzeugt lib/l10n/app_localizations*.dart
flutter run            # Gerät oder Simulator/Emulator; `flutter run -d chrome` für die Web-Fassung
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn   # PWA (D16), CanvasKit und Schrift lokal
```

Die Lokalisierung wird über `l10n.yaml` aus `lib/l10n/app_de.arb` (Vorlage) und `app_en.arb` erzeugt. Nach Änderungen an den ARB-Dateien `flutter gen-l10n` ausführen. Die erzeugten Dateien `lib/l10n/app_localizations*.dart` sind per `.gitignore` ausgeschlossen; `flutter pub get` (bzw. `flutter run`/`flutter test`) erzeugt sie neu.

## Struktur

```
lib/
  main.dart                      Einstieg, ProviderScope
  app/
    app.dart                     MaterialApp (Material 3, warmes Schema, hell/dunkel), RootScreen (lädt Dienste und Einstellungen, dann Onboarding oder Hauptansicht)
    theme.dart                   Farbschema, gebündelte Schrift Inter, Bedienmaße (Touch-Ziele mindestens 48 dp)
    routes.dart                  Benannte Routen: /record (Vollbild), /entry (ID oder EntryRouteArgs mit Sprungziel), /onboarding
    shell.dart                   Untere Leiste: Heute, Kalender, Einstellungen
    formats.dart                 Dauer- und Uhrzeitformatierung
  services/
    app_services.dart            AppServices: Bündel der Ports aus diary_core (Repositories, Recorder, Transcriber, Player-Fabrik), RecordDayUseCase; Riverpod-Provider
    create_services.dart         Bedingter Export: Web (dart.library.js_interop) -> create_services_web.dart, sonst create_services_io.dart
    create_services_web.dart     Web-Fassung: diary_web (WebCrypto-Master-Key, verschlüsselte Datensätze und Audiodateien in IndexedDB, MediaRecorder, WebAudioPlayer, ICS)
    create_services_io.dart      Nativ bis zu den Spikes: In-Memory-Repositories, SimulatedRecorder, SimulatedPlayer, FakeSttEngine
    memory_repositories.dart     In-Memory-Umsetzungen der Repository-Ports (native App ohne Speicherschicht, Tests)
    platform_features.dart       Plattformfunktionen der Oberfläche: PWA installiert?, iOS?, Speicherstatus, Kalenderdatei
  data/
    entry_view.dart              EntryView (Eintrag + Aufnahmen + Transkripte) und Provider: heute, Monat, Eintrag, Suche; dataVersionProvider lädt nach Änderungen neu
    settings_notifier.dart       AppSettings und AsyncNotifier über das SettingsRepository (persistiert)
    day.dart                     Kalendertag-Hilfen
  features/
    heute/                       Startbildschirm mit großer Aufnahmetaste und heutigem Eintrag aus dem Repository
    aufnahme/                    Vollbild-Aufnahme über RecordDayUseCase: Zähler, echte Pegel, Pause, Fertig, Verwerfen (löscht Aufnahme, Transkript, Datei)
    eintrag/                     Eintrag: Datum, Dauer, Sprache, Player (Play/Pause, Wellenform aus Recording.waveform, Schieberegler, 0,8× bis 2,0×), Transkript
    kalender/                    Monatsraster (selbst gebaut) mit markierten Tagen; Suche über das SearchRepository mit Sprung zur Trefferposition
    einstellungen/               Erinnerung (Web: Kalenderdatei statt Benachrichtigung), Sprache, Audio, App-Sperre, Daten (Web: Speicherstatus), Datenschutz (Web: CSP-Satz)
    onboarding/                  Textschritte (docs/03 Abschnitt 3); Web: voran "Als App installieren", solange nicht installiert
  widgets/entry_tile.dart        Listenzeile eines Eintrags
  l10n/                          ARB-Dateien und erzeugte AppLocalizations
test/                            Widget-Tests mit In-Memory-Fakes: Ablauf Heute → Aufnahme → Eintrag, Pause, Verwerfen, Audio löschen, Kalender, Suche, Player, Einstellungen, Web-Oberfläche (Fake-Plattform), Lokalisierung
web/                             PWA: index.html mit CSP, manifest.json, Icons (D16)
android/                         Härtung: kein INTERNET im Haupt-Manifest, allowBackup=false, dataExtractionRules, FLAG_SECURE, minSdk 31, nur arm64-v8a
ios/Runner/                      Info.plist (Mikrofon-Text, UIBackgroundModes audio, ITSAppUsesNonExemptEncryption), PrivacyInfo.xcprivacy
```

## Dienste je Plattform

Die Oberfläche kennt nur die Ports aus `diary_core` (`AppServices`). Welche Umsetzung dahinter läuft, entscheidet der bedingte Import in `lib/services/create_services.dart`:

| Port | Web (PWA, D16) | Nativ (bis zu den Spikes) |
|---|---|---|
| `EntryRepository`, `RecordingRepository`, `TranscriptRepository`, `SettingsRepository` | `diary_web`: verschlüsselte JSON-Datensätze in IndexedDB (AES-256-GCM, Datensatz-Schlüssel mit dem WebCrypto-Master-Key gewrappt) | `InMemory…Repository` (flüchtig); später `diary_storage` (SQLCipher) |
| `SearchRepository` | `WebSearchRepository` (Index im Speicher, `ß → ss`, Diakritika gefaltet) | `InMemorySearchRepository`; später FTS5 |
| `AudioRecorderPort` | `MediaRecorderCapture` (Mikrofon, WebM/Opus oder MP4/AAC, Pegel über AnalyserNode, Datei als Chunk-AEAD in IndexedDB) | `SimulatedRecorder` (Sinuston, keine Datei) |
| `DiaryPlayer` | `WebAudioPlayer` (entschlüsselt in den Speicher, Blob-URL, Audio-Element) | `SimulatedPlayer` (Uhr ohne Ton) |
| `TranscriberPort` | `FakeSttEngine` mit Text "Transkription folgt (experimentell)" bis Spike W1/W5 | `FakeSttEngine`; später `diary_stt` nativ |
| Plattformfunktionen | `WebPlatformFeatures`: installiert?, iOS?, `navigator.storage`, ICS-Download | `NativePlatformFeatures` (nichts davon nötig) |

Noch Platzhalter auf beiden Plattformen: Erinnerung als Benachrichtigung (`diary_reminders`), App-Sperre (`diary_keys`, Biometrie), "Backup erstellen" und "Gerätewechsel" (`diary_container`, auf dem Web Schritt W4).

Ebenfalls noch offen: Mikrofon-Berechtigung nativ (Android `RECORD_AUDIO`, iOS-Systemabfrage), Privacy-Overlay auf iOS (`sceneWillResignActive`), Nachtrag "Für gestern nachtragen", Karte "Vor einem Jahr", Text bearbeiten, Export.

## iOS: PrivacyInfo.xcprivacy in Xcode hinzufügen

`ios/Runner/PrivacyInfo.xcprivacy` liegt im Dateisystem, ist aber noch **nicht** im Xcode-Projekt registriert (hier gibt es kein Xcode). Einmalig in Xcode: `Runner.xcworkspace` öffnen, Rechtsklick auf die Gruppe `Runner` → "Add Files to Runner…" → `PrivacyInfo.xcprivacy` wählen, Target "Runner" ankreuzen. Danach erscheint die Datei unter "Copy Bundle Resources". Inhalt: kein Tracking, keine Domains, keine erhobenen Datentypen, Required-Reason-APIs Datei-Zeitstempel (C617.1), User Defaults (CA92.1), System-Boot-Time (35F9.1).

`ITSAppUsesNonExemptEncryption` steht auf `true` (eigene Kryptografie, Selbstklassifizierung als Ausnahme; docs/05 Abschnitt 5.4). Vor der ersten Einreichung prüfen lassen.

## Namensplatzhalter

`applicationId` ist `dev.tagebuch.app` (Platzhalter). Nach der Namenswahl (D11) anpassen: `android/app/build.gradle.kts` (`applicationId`, `namespace`), Kotlin-Paket `dev.tagebuch.tagebuch_app`, iOS `PRODUCT_BUNDLE_IDENTIFIER` im Xcode-Projekt, `android:label` und `CFBundleDisplayName` (derzeit "Tagebuch").

## Android: INTERNET-Berechtigung

Das Haupt-Manifest fordert keine `INTERNET`-Berechtigung an (D14). Die von Flutter erzeugten Manifeste in `android/app/src/debug` und `src/profile` behalten sie, weil Hot Reload, Breakpoints und DevTools sie brauchen; Release-Builds enthalten sie nicht. Der Nachweis läuft im Flugmodus.
