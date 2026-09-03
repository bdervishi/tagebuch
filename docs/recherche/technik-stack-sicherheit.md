# Technologie-Stack und Sicherheitsarchitektur für ein local-only Sprach-Tagebuch (iOS + Android)

Blickwinkel: `technik-stack-sicherheit`. Stand der Recherche: 3. September 2026. Quellenlage: pub.dev, npm-Registry, GitHub (Apple-Dokumentation über den JSON-Endpunkt `developer.apple.com/tutorials/data/documentation/...`, Android-Developer-Dokumentation, OWASP MASTG/MASVS, libsodium-Doku-Spiegel, Projekt-Repositories). Nicht erreichbar aus der Sandbox waren u. a. zetetic.net, doc.libsodium.org (Spiegel auf GitHub genutzt), docs.flutter.dev, expo.dev, blog.jetbrains.com, support.apple.com, source.android.com, signal.org, cryptomator.org, standardnotes.com, joplinapp.org, bitwarden.com, grapheneos.org, 404media, Ars Technica, Wikipedia. Wo eine Zahl nur aus Sekundärquellen oder Repositories stammt, ist das in den Findings mit `mustVerify` markiert. Bei einigen GitHub-Release-Seiten wurde das Jahr vom Abruf-Parser offenkundig falsch wiedergegeben (z. B. „2024" für Releases, die nach der Versionsfolge 2026 sein müssen); diese Datumsangaben sind entsprechend gekennzeichnet.

## 1. Anforderungen, die den Stack bestimmen

1. Transkription ausschließlich auf dem Gerät, Deutsch (DE/AT/CH) und Englisch.
2. Audioaufnahme (kurze tägliche Einträge, 1–5 Minuten), Wiedergabe.
3. Verschlüsselung ruhender Daten (Audio + Text + Metadaten), Schlüssel in Hardware-Verwahrung, optional biometrische Freigabe.
4. Kein Cloud-Backup der Klardaten; stattdessen verschlüsselter Export/Transfer (QR-initiiert).
5. Ein Indie-Entwickler: eine Codebasis, wenige, gepflegte Abhängigkeiten, gute Barrierefreiheit, kleine App.

## 2. On-Device-STT: Was die Plattformen 2026 bieten

### iOS
- **SpeechAnalyzer / SpeechTranscriber (iOS 26+)**: Apple-Dokumentation nennt Verfügbarkeit „iOS 26.0+, iPadOS 26.0+, macOS 26.0+". Aus der WWDC25-Session 277: „Our new, on-device model achieves all of that. The model is retained in system storage and does not increase the download or storage size of your application, nor does it increase the run-time memory size. It operates outside of your application's memory space." Modelle werden per `AssetInventory.assetInstallationRequest(supporting:)` nachgeladen; für ältere Geräte gibt es `DictationTranscriber`. Locales: `SpeechTranscriber.supportedLocales` („empty if the device does not support the transcriber"); Apple veröffentlicht keine statische Liste. Der Schwester-Bericht `technik-ios.md` zitiert eine empirische Liste (VoiceInk-Repository) mit **de-AT, de-DE, de-CH**, en-*, fr, it, es, pt, ja, ko, zh. Quellen: https://developer.apple.com/videos/play/wwdc2025/277/, https://developer.apple.com/documentation/speech/speechanalyzer, https://developer.apple.com/documentation/speech/speechtranscriber/supportedlocales
- **SFSpeechRecognizer** (iOS 13+): `requiresOnDeviceRecognition` „prevents the SFSpeechRecognitionRequest from sending audio over the network", wird aber nur beachtet, wenn `SFSpeechRecognizer.supportsOnDeviceRecognition == true`; Apple warnt: „On-device requests won't be as accurate". Quelle: https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition

### Android
- **`SpeechRecognizer.createOnDeviceSpeechRecognizer(Context)`** (API 31+): „Factory method to create a new on-device SpeechRecognizer"; wirft `UnsupportedOperationException iff isOnDeviceRecognitionAvailable(Context) is false`. Modelle: `triggerModelDownload(...)` – „This might trigger user interaction to approve the download"; `ERROR_LANGUAGE_UNAVAILABLE` (13) = „Requested language is supported, but not available currently (e.g. not downloaded yet)". Realität: Der On-Device-Dienst ist Googles „Speech Services by Google"; Umfang und Qualität für Deutsch sind herstellerabhängig (Samsung/Xiaomi/Huawei ohne GMS liefern anderes oder gar nichts). Quelle: https://github.com/aosp-mirror/platform_frameworks_base/blob/main/core/java/android/speech/SpeechRecognizer.java
- Fazit: Auf Android braucht man für eine verlässliche „nie verlässt das Gerät"-Garantie ein **eigenes Modell in der App** (whisper.cpp oder sherpa-onnx), das Plattform-API nur als optionalen Beschleuniger.

### Framework-unabhängige Modell-Engines
- **whisper.cpp** (MIT): Modelle tiny 75 MB/~273 MB RAM, base 142 MB/~388 MB, small 466 MB/~852 MB, medium 1,5 GB/~2,1 GB; iOS „Optimized via ARM NEON, Accelerate framework, Metal and Core ML", Android-Beispiel + Java-Bindings; Quantisierung; VAD. Releases (Abruf 3. 9. 2026): v1.9.3 (Pre-Release, Sicherheitsfixes „Heap out-of-bounds read in log_mel_spectrogram on very short audio"), v1.9.2, v1.9.1, v1.9.0 (Parakeet-Unterstützung). Quellen: https://github.com/ggml-org/whisper.cpp, https://github.com/ggml-org/whisper.cpp/releases
- **sherpa-onnx** (Apache-2.0, k2-fsa): Whisper, Zipformer, SenseVoice, Moonshine, Paraformer, Dolphin, NeMo Parakeet; Plattformen Android, iOS, Flutter (`sherpa_onnx` 1.13.7 auf pub.dev, „published 2 days ago"), React Native (`@siteed/sherpa-onnx.rn`). Deutsch über Whisper-Multilingual bzw. Parakeet TDT v3 (25 europäische Sprachen). Quellen: https://github.com/k2-fsa/sherpa-onnx, https://pub.dev/packages/sherpa_onnx

## 3. Framework-Vergleich

### Flutter (Stable 3.47.2 vom 27. 8. 2026)
- Releases-JSON: 3.47.2 (2026-08-27), 3.47.1 (08-19), 3.47.0 (08-12), 3.44.9 (08-06). Quelle: https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
- **STT**: `speech_to_text` 7.4.0 (csdcorp, BSD-3, 1,62k Likes, 508k Downloads/Woche) kapselt Apple Speech und Android `SpeechRecognizer`; `SpeechListenOptions(onDevice: true)`: „if true the listen attempts to recognize locally with speech never leaving the device. If it cannot do this the listen attempt will fail." Einschränkungen laut README: „one-minute limit on audio duration", Android „very short timeout when the speaker pauses". Für SpeechAnalyzer (iOS 26) gibt es (Stand heute) kein etabliertes Plugin – Eigenbau als Swift-Plugin nötig. `whisper_ggml` 2.6.0 (MIT, whisper.cpp v1.9.1, Android API 21+, iOS 15.6+, Live-Transkription, 99 Sprachen, benötigt Flutter 3.29+/Dart 3.7+) und `sherpa_onnx` 1.13.7 decken das eigene Modell ab. Quellen: https://pub.dev/packages/speech_to_text, https://github.com/csdcorp/speech_to_text, https://pub.dev/packages/whisper_ggml, https://pub.dev/packages/sherpa_onnx
- **Audio**: `record` 7.1.1 (BSD-3, 890 Likes, 885k Downloads): AAC LC/HE/ELD, Opus, WAV, FLAC, PCM 16-bit; **Streaming PCM 16-bit** (wichtig: PCM-Stream kann direkt in einen Verschlüsselungs-Stream und in den STT-Puffer geleitet werden, ohne Klartextdatei); native AVFoundation/MediaCodec. Quelle: https://pub.dev/packages/record
- **Datenbank/Verschlüsselung**: `sqlite3` 3.5.2 + `drift` 2.34.4 (beide simonbinder.eu). Seit `sqlite3` 3.x werden native Binaries per Dart-Build-Hooks gebaut; `sqlcipher_flutter_libs` ist „0.7.0+eol … Not used anymore". Auswahl per `pubspec.yaml`:
  ```yaml
  hooks:
    user_defines:
      sqlite3:
        source: sqlcipher   # oder sqlite3mc
  ```
  Schlüssel über `PRAGMA key` im `NativeDatabase(setup: ...)`; Drift empfiehlt Laufzeitprüfung „check for the `cipher` pragma at runtime". `sqlite3`-Changelog: „Upgrade SQLCipher to 4.18.0". Quellen: https://pub.dev/packages/sqlite3, https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md, https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md, https://github.com/simolus3/drift/blob/develop/docs/content/platforms/encryption.md, https://pub.dev/packages/drift
- **Kryptografie**: `sodium` 4.1.0+1 (1. 9. 2026, libsodium 1.0.22, Build-Hooks, secretstream, pwhash Argon2id, AEGIS-256; `sodium_libs` ist discontinued). Quellen: https://pub.dev/packages/sodium, https://pub.dev/packages/sodium/changelog, https://pub.dev/packages/sodium_libs
- **Schlüsselverwahrung**: `flutter_secure_storage` 11.0.0 (4,49k Likes, 3,74M Downloads): iOS `KeychainAccessibility` (`unlocked` Default, `first_unlock`, `*_this_device`), Android seit 10.0 ohne Jetpack `EncryptedSharedPreferences` („no longer recommended"), stattdessen RSA-OAEP + AES-GCM über Android KeyStore, optional biometrisch erzwungen; README: Auto-Backup kann `InvalidKeyException` auslösen → `android:allowBackup="false"`. `local_auth` 3.0.2 liefert nur ein Bool, keine Schlüsselbindung. Quellen: https://pub.dev/packages/flutter_secure_storage, https://pub.dev/packages/local_auth
- **Screenshot/App-Switcher**: `screen_protector` 1.5.3 (FLAG_SECURE, iOS-Blur/Overlay, Aufnahme-Erkennung; Warnung: 1.4.4–1.4.13 Abstürze). Quelle: https://pub.dev/packages/screen_protector
- **Barrierefreiheit**: Flutter-Doku: „first-class framework support for accessibility", Release-Checkliste (TalkBack/VoiceOver, 4,5:1 Kontrast, 48x48 Ziele, große Schriftskalierung). Quelle: https://github.com/flutter/website/blob/main/sites/docs/src/content/ui/accessibility/index.md

### React Native / Expo (RN 0.87.1, Expo SDK 57)
- npm: `react-native` 0.87.1; `expo` 57.0.19 (Publish-Timestamp entspricht 28. 8. 2026). Quellen: https://registry.npmjs.org/react-native/latest, https://registry.npmjs.org/expo/latest
- **STT**: `expo-speech-recognition` 57.0.0 (MIT, jamsch): `requiresOnDeviceRecognition`, `androidRecognitionServicePackage`; „Android 13+ supports on-device models; versions 12 and below have limited support"; persistente Audioaufnahme parallel (Android 13+/iOS). `whisper.rn` 0.7.4 (MIT, whisper.cpp + Parakeet TDT 0.6B v3, Core ML iOS 15+, Expo nach `prebuild`). Quellen: https://github.com/jamsch/expo-speech-recognition, https://registry.npmjs.org/expo-speech-recognition/latest, https://github.com/mybigday/whisper.rn, https://registry.npmjs.org/whisper.rn/latest
- **DB**: `@op-engineering/op-sqlite` 18.1.4 (MIT) mit SQLCipher als Compile-Target; expo-sqlite baut SQLCipher (README: Skript „to use sqlite 3.45.3 and sqlcipher 4.6.0"). Quellen: https://github.com/OP-Engineering/op-sqlite, https://github.com/expo/expo/blob/main/packages/expo-sqlite/README.md
- **Krypto**: `react-native-libsodium` 1.7.0 bietet `crypto_aead_xchacha20poly1305_ietf`, `crypto_secretbox`, `crypto_kdf`, aber **kein `crypto_secretstream`** und `crypto_pwhash` „web only". `react-native-quick-crypto` 1.x (Nitro, New Architecture) ist Node-`crypto`-kompatibel, Abdeckung unvollständig. Quellen: https://github.com/serenity-kit/react-native-libsodium, https://github.com/margelo/react-native-quick-crypto
- **Secure Store**: `expo-secure-store` 57.0.3; das dokumentierte 2048-Byte-Limit konnte nicht direkt geprüft werden (docs.expo.dev blockiert). Quelle: https://registry.npmjs.org/expo-secure-store/latest
- Bewertung: Ökosystem groß, aber die für dieses Projekt kritischen Bausteine (Streaming-AEAD, Argon2id nativ, PCM-Streaming aus der Aufnahme) sind fragmentiert; mehr Eigenbau in nativen Modulen als bei Flutter.

### Kotlin Multiplatform + Compose Multiplatform (CMP 1.12.0 vom 25. 8. 2026)
- JetBrains: KMP und CMP für iOS „Stable" (Seite datiert 10. 9. 2025); CMP 1.12.0 am 25. 8. 2026. iOS-Accessibility: Semantik wird auf native UIAccessibility abgebildet, VoiceOver, Full Keyboard Access, `performAccessibilityAudit()`; Einschränkung: kein High-Contrast out of the box. Quellen: https://kotlinlang.org/docs/multiplatform/supported-platforms.html, https://kotlinlang.org/docs/multiplatform/whats-new-compose-112.html, https://kotlinlang.org/docs/multiplatform/compose-ios-accessibility.html
- Bibliotheken: `kotlin-multiplatform-libsodium` 0.9.5 (SecretStream, pwhash; Warnung im README: „you shouldn't use it in production until it has been reviewed by community", Audit von 0.9.2 vorhanden); `cryptography-kotlin` 0.6.0 (AES-GCM, ChaCha20-Poly1305, PBKDF2, HKDF – **kein Argon2**); `KVault` (Keychain/EncryptedSharedPreferences – letzteres ist seit security-crypto 1.1.0-beta01 deprecated); SQLDelight ohne dokumentierte SQLCipher-Unterstützung auf iOS im README. Kein KMP-Plugin für STT/Audio – beides pro Plattform nativ. Quellen: https://github.com/ionspin/kotlin-multiplatform-libsodium, https://github.com/whyoleg/cryptography-kotlin, https://github.com/Liftric/KVault, https://github.com/sqldelight/sqldelight, https://developer.android.com/jetpack/androidx/releases/security
- Bewertung: Technisch sauber (native UI-Semantik auf Android, Kotlin/Native auf iOS), aber für einen Indie-Entwickler entsteht der meiste Aufwand genau dort, wo KMP nichts liefert (Audio, STT, Keychain/Keystore, SQLCipher-Anbindung auf iOS).

### Zweimal nativ (SwiftUI + Jetpack Compose)
- Beste Plattformintegration (SpeechAnalyzer direkt, `CryptoKit`, `SecAccessControl`; Android Keystore/StrongBox, `BiometricPrompt.CryptoObject`). CryptoKit bietet AES-GCM und ChaCha20-Poly1305 (12-Byte-Nonce), **kein XChaCha**. Kosten: zwei UI-Codebasen, doppelte Wartung. Quelle: https://developer.apple.com/documentation/cryptokit/chachapoly

### Empfehlung Stack
**Flutter 3.47.x** als Basis, mit drei kleinen nativen Brücken: (1) Swift-Plugin für `SpeechAnalyzer`/`DictationTranscriber` (iOS 26) mit Fallback auf `speech_to_text(onDevice: true)` für iOS ≤ 18 – oder komplett `whisper_ggml`/`sherpa_onnx`; (2) Android: `sherpa_onnx` bzw. `whisper_ggml` mit Bundled-/Download-Modell (Whisper small q5 oder Parakeet TDT v3 für DE), optional `createOnDeviceSpeechRecognizer`; (3) Keystore/Keychain-Feinheiten (StrongBox, `SecAccessControl`), soweit `flutter_secure_storage` sie nicht abdeckt. Datenschicht: `drift` + `sqlite3` (Quelle `sqlcipher`), Krypto: `sodium` (libsodium 1.0.22). Begründung: Flutter ist das einzige der drei Cross-Platform-Ökosysteme, in dem Streaming-AEAD (secretstream), Argon2id, PCM-Streaming-Aufnahme, SQLCipher und Keychain/Keystore jeweils als gepflegte, verifizierte Pakete existieren.

## 4. Verschlüsselungsdesign

### Schlüsselhierarchie (Envelope-Verschlüsselung)
- **DEK-Ebene**: pro Eintrag ein zufälliger 256-Bit-Dateischlüssel (Audio) bzw. Datenbankschlüssel (SQLCipher-`PRAGMA key` als 32-Byte-Raw-Key `x'...'`).
- **KEK-Ebene**: ein 256-Bit-Master-Key (CSPRNG), der die DEKs wrappt (libsodium `crypto_secretbox`/AEAD). Master-Key liegt ausschließlich in Keychain/Keystore (siehe 5). Optional zusätzlich passphrasen-gewrappte Kopie des Master-Keys (Argon2id) für Export/Wiederherstellung.
- Vorbild: Cryptomator (Masterkey per scrypt „scryptCostParam: 32768, scryptBlockSize: 8", Key-Wrap RFC 3394, `"format": 8`, Modi `SIV_GCM`/`SIV_CTRMAC`), Standard Notes v004 (Root-Key → Items-Key → per Item ein zufälliger 256-Bit `item_key`, XChaCha20-Poly1305 mit 192-Bit-Nonce, Argon2id 64 MiB/5 Iterationen), Joplin (Master-Key mit `KeyV1`: AES-256-GCM, PBKDF2 `iterationCount: 220000`; Inhalte `StringV1`/`FileV1`). Quellen: https://github.com/cryptomator/docs/blob/main/docs/security/architecture.mdx, https://github.com/standardnotes/app/blob/main/packages/snjs/specification.md, https://github.com/laurent22/joplin/blob/dev/packages/lib/services/e2ee/EncryptionService.ts

### Datenbank: SQLCipher
- Design laut README: AES-256-CBC pro Seite mit eigenem IV, HMAC-SHA512, PBKDF2-HMAC-SHA512 mit 256.000 Iterationen (bei Passphrasen), Seitengröße 4096, Overhead „5-15%", BSD-3 Community Edition. Releases 2026: 4.18.0 (18. 8. 2026, SQLite 3.53.4), 4.17.0 (8. 7.), 4.16.0 (12. 5.), 4.15.0 (28. 4.), 4.14.0 (17. 3.), 4.13.0 (20. 1.). Empfehlung: Raw-Key statt Passphrase (`PRAGMA key = "x'<64 hex>'"`), damit kein PBKDF2 bei jedem Öffnen und der Schlüssel aus dem Keystore stammt. Signal-Android nutzt SQLCipher (`libs.signal.android.database.sqlcipher`). Quellen: https://github.com/sqlcipher/sqlcipher, https://github.com/sqlcipher/sqlcipher/releases, https://github.com/signalapp/Signal-Android/blob/main/app/build.gradle.kts
- Alternative SQLite3MultipleCiphers (`source: sqlite3mc`) hat den Vorteil, auch auf Web zu laufen; Migration von SQLCipher via `PRAGMA cipher = 'sqlcipher'; PRAGMA legacy = 4`.

### Audio-Dateien: Streaming-AEAD mit libsodium secretstream
- `crypto_secretstream_xchacha20poly1305`: „Messages cannot be truncated, removed, reordered, duplicated or modified without this being detected", Tags `TAG_MESSAGE`/`TAG_PUSH`/`TAG_REKEY`/`TAG_FINAL` („erases the secret key used to encrypt the previous sequence"); empfohlenes Muster „a loop, that reads data from the network or from disk". Für die Aufnahme: PCM-Stream aus `record` → Encoder (Opus/AAC) → Chunks von z. B. 64 KiB → secretstream push → Datei. Kein Klartext-Audio auf dem Dateisystem, auch nicht temporär. Quelle: https://github.com/jedisct1/libsodium-doc/blob/master/secret-key_cryptography/secretstream.md
- **XChaCha20-Poly1305 vs. AES-256-GCM**: XChaCha (192-Bit-Nonce) erlaubt zufällige Nonces ohne Zählerverwaltung und ist in Dart/FFI ohne Hardware-AES konstant schnell; AES-GCM ist auf modernen ARM-Chips hardwarebeschleunigt und in CryptoKit/Keystore nativ, hat aber 96-Bit-Nonce (Zähler oder Schlüsselrotation nötig). Cryptomator (AES-GCM, 32-KiB-Chunks) und Standard Notes (XChaCha) zeigen, dass beides in Produktion trägt. Empfehlung: secretstream (XChaCha) für Dateien, SQLCipher-Default für die DB, AES-GCM nur dort, wo der Keystore selbst rechnet (Key-Wrapping mit Biometrie-Bindung).

### Passphrasen: Argon2id
- libsodium: Argon2id seit 1.0.15 Default; Presets INTERACTIVE 64 MiB, MODERATE 256 MiB (~0,7 s auf 2,8-GHz-i7), SENSITIVE 1024 MiB (~3,5 s); Mindest-opslimit 3; „a 1 second computation is likely to be the acceptable maximum". OWASP: gleichwertige Sets m=47104 (46 MiB)/t=1/p=1, m=19456 (19 MiB)/t=2/p=1, m=12288/t=3, m=9216/t=4, m=7168/t=5; PBKDF2-HMAC-SHA256 600.000, -SHA512 220.000. Bitwarden-Client (main, Abruf 3. 9. 2026): PBKDF2 Default 600.000; Argon2 `MEMORY (16..1024, default 32)`, `PARALLELISM (1..16, default 4)`, `ITERATIONS (2..10, default 6)`. Empfehlung für den Export-Container: Argon2id, 64 MiB, t=3, p=1 (Mobile-RAM-Budget; MODERATE 256 MiB ist auf 3–4-GB-Android-Geräten riskant), Salt 16 Byte, Parameter im Header speichern. Quellen: https://github.com/jedisct1/libsodium-doc/blob/master/password_hashing/default_phf.md, https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Password_Storage_Cheat_Sheet.md, https://github.com/bitwarden/clients/blob/main/libs/legacy-crypto/src/models/kdf-config.ts

## 5. Schlüsselverwahrung

### iOS
- Keychain-Klasse **`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`** oder strenger **`kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`**: „Items with this attribute do not migrate to a new device"; bei PasscodeSet: „prevents items from being stored if the device has no passcode … becomes unavailable if the user removes the passcode … isn't eligible for the iCloud keychain and won't be included if the user restores a device backup to a new device". Biometrie: `SecAccessControlCreateWithFlags(.userPresence | .biometryCurrentSet)` – „The Secure Enclave passes back a pass/fail result that gates keychain item access." Secure-Enclave-Schlüssel selbst sind nur P-256 („Works only with NIST P-256 elliptic curve keys … Not having a mechanism to transfer plain-text key data into or out of the Secure Enclave is fundamental to its security") – ein symmetrischer Master-Key kann also nicht *in* der SE liegen, aber per ECDH-Wrapping an einen SE-Key gebunden werden. Datei-Klassen: `complete` („cannot be read from or written to while the device is locked or booting"), `completeUnlessOpen`, `completeUntilFirstUserAuthentication`, `none`; Entitlement `com.apple.developer.default-data-protection`. Empfehlung: Datenbank + Audio mit `NSFileProtectionComplete`; Aufnahme-Puffer in `completeUnlessOpen`, falls die Aufnahme bei Sperre weiterlaufen soll. Quellen: https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly, https://developer.apple.com/documentation/localauthentication/accessing-keychain-items-with-face-id-or-touch-id, https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave, https://developer.apple.com/documentation/foundation/fileprotectiontype, https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.default-data-protection

### Android
- Keystore: „Key material never enters the application process"; TEE oder StrongBox (API 28+, `setIsStrongBoxBacked(true)`; „slower, more resource-constrained"). `setUserAuthenticationParameters(timeout, AUTH_BIOMETRIC_STRONG | AUTH_DEVICE_CREDENTIAL)`; Standard: Schlüssel wird bei neuer Biometrie-Registrierung ungültig (`setInvalidatedByBiometricEnrollment`). `BiometricPrompt` + `CryptoObject` (`Cipher`) mit `BIOMETRIC_STRONG` = „Class 3". Speicherort: Credential-Encrypted-Storage ist Default und „only available after the user has unlocked the device". Jetpack `security-crypto` 1.1.0 (30. 7. 2025): „Deprecated all APIs in favour of existing platform APIs and direct use of Android Keystore." Empfehlung: AES-256-GCM-Wrapping-Key im Keystore (StrongBox mit TEE-Fallback), Master-Key damit gewrappt in App-Storage (`getNoBackupFilesDir()`), Freigabe per BiometricPrompt mit `validityDuration` 30–60 s. Quellen: https://developer.android.com/privacy-and-security/keystore, https://developer.android.com/identity/sign-in/biometric-auth, https://developer.android.com/privacy-and-security/direct-boot, https://developer.android.com/jetpack/androidx/releases/security

## 6. Backups, Screenshots, Speicherhygiene, Löschen

- **iOS-Backup**: `isExcludedFromBackup` – Apple: „intended only for excluding cache and other application support files … Do NOT use this on user documents — some common file operations on user documents will automatically reset this property to false" und „make sure you set an excluded file's resource values each time you save it". Konsequenz: Verschlüsselte Daten dürfen ins iCloud-Backup (Klardaten nie), aber der Master-Key liegt in `ThisDeviceOnly`-Keychain → Restore auf neuem Gerät liefert unlesbare Daten, außer der Nutzer hat einen passphrasen-gesicherten Export. Genau das muss das Onboarding erklären. Quellen: https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup, https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
- **Android-Backup**: Auto Backup, 25 MB/App, „end-to-end encrypted on devices running Android 9 or higher"; `android:allowBackup`, `android:fullBackupContent` (≤ Android 11), `android:dataExtractionRules` (Android 12+) mit `<cloud-backup disableIfNoEncryptionCapabilities="true">` und `<device-transfer>`; `getNoBackupFilesDir()` ist immer ausgeschlossen; Android 16 QPR2+: `<cross-platform-transfer platform="ios">`. Empfehlung: `allowBackup="false"` plus explizite `dataExtractionRules` (beides, wegen `flutter_secure_storage`-Hinweis und weil D2D-Transfer sonst Keystore-lose Daten überträgt). Quelle: https://developer.android.com/identity/data/autobackup
- **Screenshots/App-Switcher**: Android `FLAG_SECURE` (MASTG-TEST-0010: „the snapshot will be empty"); iOS: „UIKit takes a snapshot of your app's current user interface … Your app's UI must not contain any sensitive user information" → Overlay in `sceneWillResignActive`. In Flutter: `screen_protector`. Quellen: https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-PLATFORM/MASTG-TEST-0010.md, https://developer.apple.com/documentation/uikit/preparing-your-ui-to-run-in-the-background
- **Speicherhygiene**: MASTG: Geheimnisse in `byte[]`/`char[]`, nach Gebrauch überschreiben, Löschen bei `onPause`; keine `String`/`BigInteger`. In Dart: `Uint8List` + `sodium.secureAlloc`/`SecureKey` (mlock, zeroing) aus `package:sodium`. Quellen: https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-STORAGE/MASTG-TEST-0011.md, https://github.com/OWASP/owasp-mastg/blob/master/tests/ios/MASVS-STORAGE/MASTG-TEST-0060.md
- **Sicheres Löschen**: Auf Flash gibt es kein zuverlässiges Überschreiben; die einzige belastbare Löschung ist **Crypto-Shredding**: pro Eintrag eigener DEK, Löschen = DEK vernichten (SQLCipher `secure_delete` zusätzlich). Für „Alles löschen": Master-Key aus Keychain/Keystore entfernen.
- **Root-/Jailbreak-Erkennung**: MASVS: „The absence of these measures does not in itself constitute a vulnerability"; MASTG listet Bypass (Frida, Xposed, Patching). Play Integrity braucht Netz und Google Play Services (10.000 Requests/Tag frei) – widerspricht „keine Server". Empfehlung: **keine** Blockade; nur Hinweis, wenn Keystore nicht hardwarebacked (`getSecurityLevel()`), damit GrapheneOS-/Custom-ROM-Nutzer (Kernzielgruppe) nicht ausgesperrt werden. Quellen: https://github.com/OWASP/owasp-masvs/blob/master/Document/11-MASVS-RESILIENCE.md, https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-RESILIENCE/MASTG-TEST-0045.md, https://developer.android.com/google/play/integrity/overview

## 7. Threat Model

| Angreifer | Fähigkeit | Gegenmaßnahme |
|---|---|---|
| Neugierige Mitbewohner/Partner | entsperrtes Gerät in der Hand | App-Sperre (Biometrie/PIN) mit kurzem Timeout, Privacy-Overlay im App-Switcher, keine Klartext-Vorschau in Benachrichtigungen |
| Gerätedieb | gesperrtes Gerät, ggf. AFU | Datei-Klasse `complete`/CE-Storage, Keychain `WhenPasscodeSet…`, App-eigene Sperre (Keystore-Key mit `setUserAuthenticationRequired`) |
| Forensik (Cellebrite/GrayKey) | AFU-Extraktion auf vielen Geräten; BFU deutlich schwerer | Nutzerhinweis: Gerät ausschalten; Apple iOS 18.1 „inactivity reboot" und GrapheneOS-Auto-Reboot bringen Geräte in BFU (Primärquellen blockiert, siehe Findings); App-Schlüssel nur bei Nutzerauthentifizierung freigeben, kurze Cache-Fenster |
| Schadsoftware auf dem Gerät | läuft im Nutzerkontext | Sandbox; Keystore verhindert Schlüsselexport; Biometrie pro Freigabe; kein Root-Requirement |
| Staatlicher Zugriff auf Cloud | Herausgabeanordnung | Es gibt keine Cloud; iCloud-/Google-Backups enthalten nur Chiffrat ohne Schlüssel |
| Backup-/Transfer-Leck | D2D, iTunes-Backup | `ThisDeviceOnly`, `dataExtractionRules`, passphrasen-geschützter Export |

## 8. Ende des Geräts: Datenverlust ohne Cloud mitigieren

1. **Verschlüsselter Export-Container** (`.vdiary`): Header (Magic, Version, Argon2id-Parameter, Salt) + secretstream-Body (Tar/Zstd aller Einträge). Passphrase oder 64-stelliger Recovery-Key (Signal-Modell: Backup-Schlüssel getrennt vom Konto). Ziel: Dateien-App/SAF, USB, AirDrop/Nearby.
2. **QR-initiierter Gerätewechsel**: QR enthält nur ephemeren Schlüssel + lokale Adresse (Wi-Fi Direct/LAN/Multipeer); Datei wird verschlüsselt übertragen. Kein Server.
3. **Erinnerung an Export** (z. B. monatlich) als Teil der Reminder-Logik.
4. Optional (Monetarisierung ohne Widerspruch zum Prinzip): Nutzer-eigener Speicher (iCloud Drive/Google Drive/WebDAV) empfängt nur den Container – Zero-Knowledge wie Cryptomator/Obsidian Sync.

## 9. Vertrauensbeweise

- **Open Source** (GPLv3/AGPL für App, kommerzielle Lizenz optional – Cryptomator-Modell „No backdoors, control is better than trust").
- **Reproducible Builds Android**: Signal seit 3.15.0 (März 2016) mit Docker-Image und `apkdiff.py`, das Signaturen/Play-Metadaten ignoriert; Apple-Signatur und App-Store-Umverpackung machen iOS-Reproduzierbarkeit praktisch unmöglich (Signal-iOS Issue #641 seit 2015 offen). Für Android zusätzlich F-Droid-Veröffentlichung. Quellen: https://github.com/signalapp/Signal-Android/blob/main/reproducible-builds/README.md, https://github.com/signalapp/Signal-iOS/issues/641
- **Audit**: Cryptomator cryptolib 1.1.5 durch Cure53; ionspin-libsodium 0.9.2 auditiert. Für ein Indie-Projekt realistisch: Crypto-Kern (Container-Format, Key-Hierarchie) als kleine, separat auditierbare Dart-Bibliothek + öffentliches Threat Model + Bug-Bounty-light. Quelle: https://github.com/cryptomator/cryptolib
- **App-Store-Formalien**: `ITSAppUsesNonExemptEncryption` – Eigenkrypto (libsodium/SQLCipher) ist nicht „built into the operating system" und damit nicht automatisch exempt; ggf. Self-Classification-Report. Quelle: https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations

## 10. Konkrete Bibliotheksliste (Stand 3. 9. 2026)

| Zweck | Paket | Version | Quelle |
|---|---|---|---|
| Framework | Flutter stable | 3.47.2 (27. 8. 2026) | releases_linux.json |
| Aufnahme | `record` | 7.1.1 | pub.dev |
| STT iOS 26 | eigenes Swift-Plugin auf `SpeechAnalyzer` | iOS 26 SDK | developer.apple.com |
| STT Fallback | `speech_to_text` | 7.4.0 | pub.dev |
| STT eigenes Modell | `whisper_ggml` 2.6.0 (whisper.cpp 1.9.1) oder `sherpa_onnx` 1.13.7 | – | pub.dev |
| DB | `drift` 2.34.4 + `sqlite3` 3.5.2 (`source: sqlcipher`, SQLCipher 4.18.0) | – | pub.dev/GitHub |
| Krypto | `sodium` 4.1.0+1 (libsodium 1.0.22) | – | pub.dev |
| Schlüssel | `flutter_secure_storage` 11.0.0 | – | pub.dev |
| Biometrie-Gate | `local_auth` 3.0.2 (+ Keystore-CryptoObject nativ) | – | pub.dev |
| Screenshot-Schutz | `screen_protector` 1.5.3 | – | pub.dev |

## 11. Offene Fragen
- Offizielle Locale-/Hardware-Liste von `SpeechTranscriber` (Apple dokumentiert nur die API).
- Deutsch-WER von Google-On-Device-`SpeechRecognizer` vs. Whisper small/Parakeet auf Mittelklasse-Android.
- Aktuelle Cellebrite/GrayKey-Fähigkeiten gegen iOS 26 / Android 16 (Primärquellen aus der Sandbox nicht erreichbar).
- Ob `flutter_secure_storage` 11 auf Android StrongBox nutzt oder nur TEE (Code-Review nötig).
- Größe der App mit gebündeltem Whisper-small (≈ 500 MB) vs. Download beim Onboarding – Store-Limits und Nutzerakzeptanz.

## Quellenliste
1. https://developer.apple.com/videos/play/wwdc2025/277/
2. https://developer.apple.com/documentation/speech/speechanalyzer
3. https://developer.apple.com/documentation/speech/speechtranscriber
4. https://developer.apple.com/documentation/speech/speechtranscriber/supportedlocales
5. https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition
6. https://github.com/aosp-mirror/platform_frameworks_base/blob/main/core/java/android/speech/SpeechRecognizer.java
7. https://github.com/ggml-org/whisper.cpp
8. https://github.com/ggml-org/whisper.cpp/releases
9. https://github.com/k2-fsa/sherpa-onnx
10. https://pub.dev/packages/sherpa_onnx
11. https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
12. https://pub.dev/packages/speech_to_text
13. https://github.com/csdcorp/speech_to_text
14. https://pub.dev/packages/whisper_ggml
15. https://pub.dev/packages/record
16. https://pub.dev/packages/sqlite3
17. https://pub.dev/packages/drift
18. https://pub.dev/packages/sqlcipher_flutter_libs
19. https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md
20. https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md
21. https://github.com/simolus3/drift/blob/develop/docs/content/platforms/encryption.md
22. https://pub.dev/packages/sodium
23. https://pub.dev/packages/sodium/changelog
24. https://pub.dev/packages/sodium_libs
25. https://pub.dev/packages/flutter_secure_storage
26. https://pub.dev/packages/local_auth
27. https://pub.dev/packages/screen_protector
28. https://github.com/flutter/website/blob/main/sites/docs/src/content/ui/accessibility/index.md
29. https://registry.npmjs.org/react-native/latest
30. https://registry.npmjs.org/expo/latest
31. https://github.com/jamsch/expo-speech-recognition
32. https://registry.npmjs.org/expo-speech-recognition/latest
33. https://github.com/mybigday/whisper.rn
34. https://registry.npmjs.org/whisper.rn/latest
35. https://github.com/OP-Engineering/op-sqlite
36. https://registry.npmjs.org/@op-engineering/op-sqlite/latest
37. https://github.com/expo/expo/blob/main/packages/expo-sqlite/README.md
38. https://github.com/serenity-kit/react-native-libsodium
39. https://registry.npmjs.org/react-native-libsodium/latest
40. https://github.com/margelo/react-native-quick-crypto
41. https://registry.npmjs.org/expo-secure-store/latest
42. https://kotlinlang.org/docs/multiplatform/supported-platforms.html
43. https://kotlinlang.org/docs/multiplatform/whats-new-compose-112.html
44. https://kotlinlang.org/docs/multiplatform/compose-ios-accessibility.html
45. https://github.com/JetBrains/compose-multiplatform/releases/tag/v1.8.0
46. https://github.com/ionspin/kotlin-multiplatform-libsodium
47. https://github.com/whyoleg/cryptography-kotlin
48. https://github.com/Liftric/KVault
49. https://github.com/sqldelight/sqldelight
50. https://developer.apple.com/documentation/cryptokit/chachapoly
51. https://github.com/cryptomator/docs/blob/main/docs/security/architecture.mdx
52. https://github.com/cryptomator/cryptolib
53. https://github.com/cryptomator/cryptomator
54. https://github.com/standardnotes/app/blob/main/packages/snjs/specification.md
55. https://github.com/laurent22/joplin/blob/dev/packages/lib/services/e2ee/EncryptionService.ts
56. https://github.com/sqlcipher/sqlcipher
57. https://github.com/sqlcipher/sqlcipher/releases
58. https://github.com/signalapp/Signal-Android/blob/main/app/build.gradle.kts
59. https://github.com/jedisct1/libsodium-doc/blob/master/secret-key_cryptography/secretstream.md
60. https://github.com/jedisct1/libsodium-doc/blob/master/password_hashing/default_phf.md
61. https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Password_Storage_Cheat_Sheet.md
62. https://github.com/bitwarden/clients/blob/main/libs/legacy-crypto/src/models/kdf-config.ts
63. https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly
64. https://developer.apple.com/documentation/localauthentication/accessing-keychain-items-with-face-id-or-touch-id
65. https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave
66. https://developer.apple.com/documentation/foundation/fileprotectiontype
67. https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.default-data-protection
68. https://developer.android.com/privacy-and-security/keystore
69. https://developer.android.com/identity/sign-in/biometric-auth
70. https://developer.android.com/privacy-and-security/direct-boot
71. https://developer.android.com/jetpack/androidx/releases/security
72. https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup
73. https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
74. https://developer.android.com/identity/data/autobackup
75. https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-PLATFORM/MASTG-TEST-0010.md
76. https://developer.apple.com/documentation/uikit/preparing-your-ui-to-run-in-the-background
77. https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-STORAGE/MASTG-TEST-0011.md
78. https://github.com/OWASP/owasp-mastg/blob/master/tests/ios/MASVS-STORAGE/MASTG-TEST-0060.md
79. https://github.com/OWASP/owasp-mastg/blob/master/tests/ios/MASVS-STORAGE/MASTG-TEST-0052.md
80. https://github.com/OWASP/owasp-mastg/blob/master/tests/ios/MASVS-STORAGE/MASTG-TEST-0058.md
81. https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-STORAGE/MASTG-TEST-0009.md
82. https://github.com/OWASP/owasp-masvs/blob/master/Document/11-MASVS-RESILIENCE.md
83. https://github.com/OWASP/owasp-mastg/blob/master/tests/android/MASVS-RESILIENCE/MASTG-TEST-0045.md
84. https://developer.android.com/google/play/integrity/overview
85. https://github.com/GrapheneOS/os-issue-tracker/issues/8505
86. https://github.com/GrapheneOS/os-issue-tracker/issues/4006
87. https://github.com/aosp-mirror/platform_frameworks_base/blob/main/core/java/android/security/advancedprotection/AdvancedProtectionManager.java
88. https://github.com/signalapp/Signal-Android/blob/main/reproducible-builds/README.md
89. https://github.com/signalapp/Signal-iOS/issues/641
90. https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
