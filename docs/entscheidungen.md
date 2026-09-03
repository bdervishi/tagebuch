# Entscheidungen D1 bis D15

Stand: 3. September 2026 · Status: Entwurf zur Abstimmung

Diese Entscheidungen sind die gemeinsame Grundlage aller Konzeptdokumente. Sie wurden aus den Rechercheberichten in `docs/recherche/` abgeleitet; jede Entscheidung ist eine Empfehlung an den Inhaber, bis sie bestätigt ist.

## D1 · Stack

Flutter (stable 3.47.x) als eine Codebasis, ergänzt um drei kleine native Brücken: (a) Swift-Plugin für SpeechAnalyzer/SpeechTranscriber/DictationTranscriber, (b) Android-Anbindung von sherpa-onnx (Kotlin), (c) Feinheiten von Keychain/Keystore (SecAccessControl, StrongBox, BiometricPrompt.CryptoObject). Begründung: Flutter ist das einzige Cross-Platform-Ökosystem, in dem Streaming-AEAD (package:sodium, libsodium 1.0.22), Argon2id, PCM-Streaming-Aufnahme (record 7.x), SQLCipher (sqlite3 3.5.x mit source: sqlcipher + drift 2.34) und Secure Storage als gepflegte Pakete existieren. Alternativen (zweimal nativ SwiftUI + Compose; Kotlin Multiplatform) kurz nennen, nicht empfehlen. Rückfalloption: Wenn ein Spike zeigt, dass die nativen Brücken zu groß werden, ist zweimal nativ die zweite Wahl.

## D2 · Transkription iOS

Primär SpeechTranscriber (iOS 26+, Preset .transcription nach der Aufnahme, optional .progressiveTranscription für Live-Vorschau), Locale über supportedLocale(equivalentTo:) aus de-DE/de-AT/de-CH/en-*; SpeechDetector aktiv; Modell-Assets werden einmalig von Apple nachgeladen (AssetInventory) und im Onboarding erklärt. Fallback DictationTranscriber (.longDictation) auf iOS-26-Geräten ohne 16-Kern-Neural-Engine (iPhone 11-Reihe, SE 2). Optional als Zusatzpaket "Hohe Genauigkeit": WhisperKit mit large-v3-turbo (626 MB), Sprache fest gesetzt, VAD-Chunking. Mindestanforderung iOS 26, empfohlen iPhone 12 oder neuer. Kein Whisper-Zwang im MVP.

## D3 · Transkription Android

Primär gebündelte Engine sherpa-onnx mit Moonshine German Small Streaming und English Small Streaming (MIT, je 123 M Parameter, Deutsch-WER 7,5 %). Optionales Zusatzpaket "Hohe Genauigkeit": Parakeet TDT 0.6B v3 int8 (≈ 640 MB, Deutsch-WER ≈ 4 %, ab 6 GB RAM; Modelllizenz CC-BY-4.0 im Spike verifizieren). Systemeigener createOnDeviceSpeechRecognizer nur als vom Nutzer aktivierbare Option mit klarem Hinweis, dass eine Google/OEM-Komponente arbeitet. ML Kit GenAI Speech nicht verwenden. minSdk 31 (Android 12), nur arm64-v8a, Richtwert 4 GB RAM. Die App fordert keine android.permission.INTERNET an; Modelle kommen per Play Asset Delivery (fast-follow für Standard, on-demand für "Hohe Genauigkeit"); ob Play Asset Delivery ohne INTERNET-Permission funktioniert, ist ein offener Spike-Punkt.

## D4 · Audio und Speicherung

Aufnahme 16 kHz mono PCM im Speicher; parallel Opus in OGG mit 16 bis 24 kbit/s (Rechenbasis: 24 kbit/s = 0,18 MB/Minute); PCM geht in den STT-Puffer und wird nicht auf Disk geschrieben. Audio wird chunkweise (64 KiB) mit libsodium crypto_secretstream_xchacha20poly1305 verschlüsselt geschrieben; kein Klartext-Audio auf dem Dateisystem, auch nicht temporär. Metadaten und Transkripte in SQLCipher (drift + sqlite3, PRAGMA key als 32-Byte-Raw-Key, SQLCipher 4.18) mit FTS5-Volltextsuche. Audio wird standardmäßig behalten; Nutzer können Audio pro Eintrag oder global löschen (nur Text behalten).

## D5 · Schlüssel und Zugriffsschutz

Envelope-Verschlüsselung: pro Eintrag ein zufälliger 256-Bit-Dateischlüssel, gewrappt mit einem Master-Key. iOS: Master-Key im Keychain mit kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, optional SecAccessControl (.biometryCurrentSet); Dateien mit NSFileProtectionComplete. Android: AES-256-GCM-Wrapping-Key im Keystore (StrongBox mit TEE-Fallback, setUserAuthenticationParameters mit 30 bis 60 s Gültigkeit), gewrappter Master-Key in getNoBackupFilesDir(); android:allowBackup="false" plus dataExtractionRules. App-Sperre per Biometrie/Gerätecode mit kurzem Timeout; Privacy-Overlay im App-Switcher, FLAG_SECURE. Optionale Passphrase (Argon2id 64 MiB, t=3, p=1, Salt 16 Byte) nur für Export/Wiederherstellung, nicht für den Alltag. Löschen = Crypto-Shredding (Dateischlüssel vernichten) plus SQLCipher secure_delete. Keine Root-/Jailbreak-Sperre (nur Hinweis, wenn Keystore nicht hardwaregestützt). Benachrichtigungen enthalten nie Tagebuchinhalt.

## D6 · Gerätewechsel und Backup

Der QR-Code transportiert Schlüsselmaterial, nicht die Daten (ein QR fasst maximal 2953 Byte; ein Jahr Audio wären rund 88 000 animierte Frames, also 12 bis 36 Stunden). MVP-Verfahren "QR + Datei", Empfänger zeigt den Code: (1) Das neue Gerät erzeugt ein X25519-Schlüsselpaar (privater Schlüssel im Keychain/Keystore) und zeigt EINEN QR-Code (unter 200 Byte: Formatversion, Sitzungs-ID, öffentlicher Schlüssel, Plattform); alternativ zeigt es den öffentlichen Schlüssel als Wortfolge zum Abtippen. (2) Das alte Gerät scannt, leitet per X25519/HKDF einen Container-Schlüssel ab und packt alle Einträge (NDJSON-Export der Datenbank + Opus-Dateien; Text mit zstd komprimiert, Opus ist bereits komprimiert) in einen Container: Header (Magic, Formatversion, Sitzungs-ID, ephemerer öffentlicher Schlüssel, secretstream-Header), Nutzlast in 64-KiB-Chunks mit libsodium crypto_secretstream_xchacha20poly1305 (erkennt Abschneiden, Umsortieren, Manipulation), abschließender Manifest-Hash. (3) Die Datei wandert über einen beliebigen Kanal: System-Teilen-Blatt (AirDrop, Quick Share, Dateien-App/USB-Stick, Kabel) oder auf Wunsch über einen vom Nutzer gewählten Speicher; weil nur der Empfänger den privaten Schlüssel hat, ist der Kanal sicherheitstechnisch egal, und ein abfotografierter QR nützt nichts. (4) Das neue Gerät wählt die Datei, prüft Version und Hash, importiert atomar; danach bietet das alte Gerät "Einträge hier löschen" an. Kein eigener Netzwerkcode, keine INTERNET-Permission auf Android, funktioniert iOS↔Android, iOS↔iOS, Android↔Android identisch. Backup: dieselbe Containerdatei, aber mit Passphrase (Argon2id 64 MiB, t=3, p=1, Salt 16 Byte, Parameter im Header) statt Empfängerschlüssel; die App erinnert monatlich an ein Backup und erklärt im Onboarding, dass Betriebssystem-Backups die Daten ohne Schlüssel nicht wiederherstellen. Spätere Ausbaustufe (Version 1.x, nicht MVP): direkte Übertragung im selben WLAN nach dem LocalSend-Muster (mDNS/Multicast-Discovery, TLS mit Zertifikat-Fingerprint im QR, Trust-on-QR), dann bewusst mit INTERNET-Permission und Local-Network-Berechtigung; noch später Wi-Fi Aware (iOS 26+, iPhone 12+) nach Interoperabilitäts-Prototyp. Verworfen: animierte QR-Codes für Audio, 7z/AES (kein AEAD), Bluetooth LE als Hauptweg (40 bis 80 kB/s), Quick-Share/AirDrop-Interop als Kernpfad (nur bestimmte Geräte, "Alle"-Modus, keine API). Datenmengen-Rechenbasis: 3 Minuten Sprache täglich ergibt bei Opus 16 kbit/s 0,36 MB/Tag und rund 131 MB/Jahr (24 kbit/s: 0,54 MB/Tag, 197 MB/Jahr); Text rund 1 KB/Minute, 1,1 MB/Jahr roh, mit zstd 0,3 bis 1 MB.

## D7 · Erinnerung

Eine tägliche Erinnerung zu einer vom Nutzer gewählten Uhrzeit, jederzeit änderbar, mit "Heute nicht" und "In 1 Stunde"; kein Streak-Druck. iOS: UNCalendarNotificationTrigger (täglich wiederholend), Time-Sensitive nur nach Nutzerwahl. Android: setAlarmClock() mit SCHEDULE_EXACT_ALARM-Anfrage, bei Ablehnung setWindow() mit ±10 Minuten; Onboarding-Schritt "Erinnerungen zuverlässig machen" mit Herstellerhinweisen (Samsung, Xiaomi, Huawei, OnePlus). Aufnahme direkt aus der Benachrichtigung startbar. Nachträgliches Aufnehmen für vergangene Tage erlaubt.

## D8 · Lokale Auswertung

MVP ohne generative KI: Kalender, Volltextsuche (FTS5), einfache Rückblicke ("vor einem Jahr", Monatsübersicht, Wortzahl). Version 1.x optional: Tageszusammenfassung mit Apple Foundation Models (nur auf Apple-Intelligence-Geräten, Opt-in, Refusals abfangen); auf Android kein Gemini Nano (Deutsch nicht unterstützt, Flaggschiff-Geräte); Alternative dort später ein kleines eigenes On-Device-Modell. Keine Stimmungs-Diagnostik aus der Stimme, keine medizinischen Aussagen.

## D9 · Geschäftsmodell (Empfehlung)

"Kostenloser Kern für immer + Plus". Kostenlos und dauerhaft: unbegrenzt viele Einträge, Aufnahmen bis 5 Minuten je Eintrag, lokale Transkription Deutsch/Englisch, Wiedergabe, Suche, Verschlüsselung, tägliche Erinnerung, verschlüsseltes Backup, QR-Gerätewechsel, Export (Markdown/JSON/PDF). Damit gibt es keinen Lock-in und die Kernversprechen sind nie hinter einer Bezahlschranke. Plus (Jahresabo 14,99 €, Monatsabo 1,99 €, Lifetime 44,99 €, Familienfreigabe aktiv, 7-Tage-Test nur im Jahresabo): Aufnahmen bis 30 Minuten, Zusatzpaket "Hohe Genauigkeit" (große Modelle), lokale Rückblicke und Zusammenfassungen, mehrere Tagebücher, gestaltetes Jahrbuch-PDF, weitere Sprachen, Themes/Icons/Widgets. Garantie im Store-Text: kostenlose Funktionen werden nie kostenpflichtig. Ab Jahr 2: B2B-Codes (Offer Codes) für Praxen und Coaches, z. B. Praxis-Paket mit 10 Lifetime-Codes. Alternativen, falls der Inhaber Abos grundsätzlich ablehnt: Variante C "Kaufen, später Update-Pass" (19,99 € einmalig mit 12 Monaten Updates, danach Update-Pass 7,99 €/Jahr) oder Variante A reiner Einmalkauf 14,99 €. Rechenannahmen (nur in 07-geschaeftsmodell.md ausführen, andere Dokumente nennen keine Preise): 10 000 Downloads im ersten Jahr, Download-zu-Zahler 2 % (Einmalkauf 3 %), Store-Abgabe 15 % (Apple Small Business Program, Google Play bis 1 Mio. $), 19 % MwSt im Preis, Auszahlung rund 71 % des Ladenpreises. Keine Werbung, kein Datenverkauf, keine Cloud-Upsells, keine Monetarisierung über Server.

## D10 · Lizenz (Empfehlung)

Quellcode öffentlich unter GPLv3, Store-Builds und Marke beim Inhaber; Krypto- und Containerkern als separat auditierbare Dart-Bibliothek; Android zusätzlich über F-Droid mit reproduzierbarem Build. Das ist Voraussetzung für Listungen bei Privacy Guides und Kuketz-Blog und der stärkste Vertrauensbeweis für "es geht nichts ins Netz". Bewusst benannter Preis dieser Wahl: Ein F-Droid-Build enthält alle Plus-Funktionen kostenlos; Erlöse entstehen aus Bequemlichkeit und Unterstützung über die Stores (wie bei vielen Indie-Tools). Alternative, wenn der Inhaber das nicht will: Open Core (Engine, Krypto, Containerformat offen; Oberfläche proprietär), womit die Privacy-Guides-Listung entfällt.

## D11 · Name

Arbeitstitel "Abendton" (Alternativen: "Tonlade", "Tagschloss"). Der Inhaber entscheidet nach Marken- und Store-Prüfung; bis dahin verwenden die Dokumente "die App" und nennen den Arbeitstitel nur in README und 08-namensfindung.md. Das Repository heißt weiterhin "tagebuch".

## D12 · Sprachen

MVP Deutsch (de-DE, de-AT, de-CH als Standarddeutsch mit Schweizer Orthografie) und Englisch. Schweizerdeutsche Mundart wird nicht versprochen; die App erklärt, dass Hochdeutsch die zuverlässigsten Ergebnisse liefert. Weitere Sprachen folgen der Verfügbarkeit lokaler Modelle.

## D13 · Plattform-Minimum

iOS 26 (iPhone 12 oder neuer empfohlen), Android 12 (API 31), 64-Bit, Richtwert 4 GB RAM; Zusatzpaket "Hohe Genauigkeit" ab 6 GB RAM.

## D14 · Kein Netz

keine Analytics-, Crash-Reporting- oder Werbe-SDKs, keine Konten, keine Server des Inhabers. Apple-Datenschutzlabel "Es werden keine Daten erfasst" und Play Data Safety "Es werden keine Daten erhoben" sind Zielvorgaben; die einzigen Netzkontakte sind Modell-Downloads durch das Betriebssystem bzw. den Play Store. Der Nachweis im Flugmodus ist Teil der Teststrategie.

## D15 · Quellenlage

Aus der Recherche-Sandbox waren apple.com, support.apple.com, play.google.com, apps.apple.com, huggingface.co, Wikipedia und viele Nachrichtenseiten gesperrt; Apple-Dokumentation wurde über developer.apple.com-JSON-Endpunkte, Android-Dokumentation über developer.android.com und Quellcode über GitHub gelesen. Wo eine Zahl nur aus Sekundärquellen stammt oder in verifikation.json als "unklar" steht, ist sie im Dokument so zu kennzeichnen.
