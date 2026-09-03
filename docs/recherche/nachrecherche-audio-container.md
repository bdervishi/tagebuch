# Nachrecherche Lücke 2: Audio-Container, Aufnahme-Pipeline und Wiedergabe-Architektur (iOS + Android)

Stand: 3. September 2026. Linse: Entscheidungsvorlage für Aufnahmeformat, Container, verschlüsselte Wiedergabe, transkript-synchrone Wiedergabe und Systemintegration eines rein lokalen Sprach-Tagebuchs.

Hinweis zur Quellenlage: Web-Suchen waren begrenzt möglich; die zentralen Aussagen wurden direkt an Primärquellen (Apple-Dokumentations-JSON, Android-Referenz, AOSP-Quellcode-Spiegel, GitHub-Repositories von Signal, Element, androidx/media, k2-fsa) nachgelesen. Wo nur ein Suchtreffer-Auszug vorlag (openradar, ProAndroidDev), ist das markiert.

---

## 1. Befund: Der Container-Konflikt ist real

### 1.1 iOS: Opus nur in CAF, kein Ogg in AVFoundation

- `kAudioFormatOpus` existiert in Core Audio seit iOS 11.0 / macOS 10.13 (Apple-Doku `coreaudiotypes/kaudioformatopus`).
- Die Liste der `AudioFileTypeID`-Konstanten in AudioToolbox enthält AIFF, WAVE, MP3, AAC-ADTS, MPEG-4, M4A, **CAF**, 3GP, AMR – **keinen Ogg- oder Opus-Dateityp**. `AVAudioFile(forWriting:settings:)` leitet den Dateityp aus der Dateiendung ab (Apple-Doku `avaudiofile/init(forwriting:settings:)`). Folge: Opus lässt sich mit `AVAudioRecorder`/`AVAudioFile` ausschließlich in `.caf` schreiben.
- Wiedergabe von Ogg über `AVAudioPlayer` schlägt fehl mit `AVFoundationErrorDomain Code=-11828 "Cannot Open" ... This media format is not supported.` (developer.apple.com/forums/thread/128434, Jan. 2020, unbeantwortet).
- Drittquellen bestätigen unabhängig: Das Flutter-Paket `record` 7.1.1 (pub.dev, Stand ca. Juli 2026) dokumentiert für iOS: „Opus in CAF container. This means that your file will be playable only on iOS platforms." Das Dart-Paket `ogg_caf_converter` 0.1.4 begründet seine Existenz damit, dass „Apple does not conform to the standard OGG container spec for OPUS files" und dass „iOS devices cannot play OPUS audio files in OGG format, and Android devices cannot play OPUS audio files in CAF format". flutter_sound PR #199 spricht von einer „proprietary envelope" (CAF/OPUS) und band ffmpeg ein, um Standard-Ogg zu erzeugen.

### 1.2 iOS: Opus-Bitrate über AVAudioRecorder nicht steuerbar

- rdar://49315600 (openradar, März 2019; nur als Suchauszug lesbar, Seite selbst geblockt): `AVAudioRecorder` mit `kAudioFormatOpus`, 16.000 Hz, `AVEncoderBitRateKey = 32000` → ffprobe zeigt **16 kb/s**; `AVEncoderBitRateStrategyKey` ohne Wirkung. Zitat aus dem Auszug: „According to Apple Developer Technical Support, there is no way to control bitrate for Opus." CBR sei nicht unterstützt.
- Gegenprobe: Ein Apple-Engineer zeigt in developer.apple.com/forums/thread/763362 (Sept. 2024) ein `AVAudioConverter`-Beispiel für Opus mit `mSampleRate = 48000`, `mFramesPerPacket = 960` (20 ms), mono, `converter.bitRateStrategy = AVAudioBitRateStrategy_Constant` – d. h. auf Converter-Ebene wird eine Strategie gesetzt, aber ohne dokumentierte Bitratenwerte. Ob `AVAudioConverter.bitRate` bei Opus greift, ist nicht belegt (mustVerify; eigener Messlauf nötig).
- Praktische Konsequenz: Bei 16 kHz Eingang liefert Apples Encoder offenbar ca. 16 kb/s VBR. Das entspricht ~120 KB/min bzw. **~88 MB/Jahr bei 2 min/Tag** – weniger als die 131 MB/Jahr des Transfer-Berichts (die 131 MB entsprechen 24 kb/s × 730 min). Die Größenrechnung ist also nicht „zu klein", sondern die iOS-Seite ist schlicht nicht kontrollierbar: höhere Qualität lässt sich nicht erzwingen, niedrigere auch nicht zuverlässig.

### 1.3 Android: Ogg/Opus nativ, CAF nicht

- AOSP `MediaRecorder.java`: `/** Opus audio codec */ public static final int OPUS = 7;` und `/** Opus data in a Ogg container */ public static final int OGG = 11;`. `setAudioEncodingBitRate`: „sometimes the passed bitRate will be clipped internally to ensure the audio recording can proceed smoothly based on the capabilities of the platform." API-Level laut Drittquellen 29 (record-Paket: „Opus requires 29"; Element Android wählt den nativen Pfad nur bei `Build.VERSION_CODES.Q`+) – mustVerify, da die Android-Referenzseite nicht maschinell lesbar war.
- Android-Plattformtabelle „Supported media formats": Opus-**Encoder ab Android 10**, Decoder ab Android 5.0; Container Ogg (.ogg), MP4, Matroska; Muxer Ogg/WebM.
- AOSP `StagefrightRecorder.cpp` (LineageOS-Spiegel lineage-22.2): `setupOggRecording()` → `new OggWriter(mOutputFd)`; Defaults `mAudioBitRate = 12200`, `mSampleRate = 8000`, `mAudioChannels = 1` – also unbedingt explizit `setAudioSamplingRate` und `setAudioEncodingBitRate` setzen. `OggWriter.cpp`: „Support is limited to single track of Opus audio", Granule = 48000 × Dauer.
- AOSP `C2SoftOpusEnc.cpp`: erlaubte Sample-Raten 8000/12000/16000/24000/48000, Bitrate 500–512 000 bit/s (Default 128 000), Komplexität 1–10 (Default 10), `OPUS_APPLICATION_AUDIO`, VBR = `OPUS_SET_VBR(1)` + `OPUS_SET_VBR_CONSTRAINT(1)`, CBR bei `BITRATE_CONST`, `OPUS_SET_DTX(0)`. Damit ist die Bitrate auf Android – anders als auf iOS – tatsächlich steuerbar.
- Media3 „Supported formats": Ogg („Containing Vorbis, Opus and FLAC") wird als progressiver Container unterstützt; **CAF ist nicht gelistet**. Zusätzlich existiert das Modul `media3-decoder-opus` (`LibopusAudioRenderer`, libopus per NDK selbst zu bauen) als Fallback, falls der Plattform-Decoder fehlt.
- Media3 1.11.0 (5. Aug. 2026): „Add `OggMuxer` to allow muxing of `OPUS` or `VORBIS` media streams into the `ogg` file format" – `@UnstableApi`, ein Track, keine Metadaten.

### 1.4 Referenzimplementierungen für Aufnahme

- **Element Android** (`VoiceRecorderProvider.kt`): API 29+ mit vorhandenem Opus-Encoder → `VoiceRecorderQ` (MediaRecorder, `OutputFormat.OGG`, `AudioEncoder.OPUS`, `setAudioEncodingBitRate(24_000)`, `setAudioSamplingRate(48_000)`); sonst `VoiceRecorderL` (AudioRecord 48 kHz mono + `OggOpusEncoder`, `BITRATE = 24 * 1024`). Feature-Flag `forceUsageOfOpusEncoder()` deutet auf problematische native Encoder bei einzelnen Geräten hin.
- **Element X Android**: `io.element.android:opusencoder:1.2.0` (libopusenc-Wrapper, Apache-2.0, `ope_encoder_create_file`, mono, `OPUS_SET_BITRATE_REQUEST`), `AudioConfig(bitRate = 24_000, ENCODING_PCM_16BIT, CHANNEL_IN_MONO, AudioSource.MIC)`, Datei `.ogg`; Wellenform: `AudioLevelCalculator` (dBov) pro Puffer, danach `resample()` auf 100 Werte. Media3 dort 1.11.0.
- **Element iOS** (`element-hq/swift-ogg`, Tag 0.0.4 vom 5. Mai 2026): nimmt nativ M4A/AAC auf und **transkodiert** mit libopus/libogg zu Ogg-Opus (`OGGConverter.convertM4aFileToOpusOGG`) bzw. zurück – kein Remux, sondern Re-Encoding; basiert auf `opus-swift` 0.8.0 mit **libopus 1.3.1** (veraltet gegenüber libopus 1.6.1 vom 13. Jan. 2026).
- **Signal Android** (`AudioCodec.java`): Sprachnachrichten als **AAC-LC `audio/mp4a-latm`, 44.100 Hz, 32.000 bit/s, mono, ADTS** über `MediaCodec` – kein Opus.

### 1.5 Bitraten-Referenz

RFC-6716-Entwurf (xiph/opus, doc): „sweet spots" bei 20-ms-Frames – Narrowband-Sprache 8–12 kb/s, **Wideband-Sprache 16–20 kb/s**, Fullband-Sprache 28–40 kb/s. Ogg-Overhead laut libogg-Framing-Doku: Seitenheader 27 Byte + Segmenttabelle, „flat .25-.5% space overhead" plus „.5-1%" Segmentierung bei ~8-KB-Seiten; bei Sprach-Paketen von 40–60 Byte und 1-s-Seiten liegt der Overhead real bei ca. 2–4 %. CAF: Header `desc` + `pakt`-Pakettabelle (variable-length Integers, `mPrimingFrames`, `mRemainderFrames`) + `data`; ähnliche Größenordnung.

Rechenbasis (2 min/Tag, 730 min/Jahr): 16 kb/s → 120 KB/min → 88 MB/Jahr; 24 kb/s → 180 KB/min → 131 MB/Jahr; AAC-LC 32 kb/s (Signal) → 240 KB/min → 175 MB/Jahr; AAC-LC 64 kb/s → 350 MB/Jahr.

---

## 2. Optionenvergleich

| Kriterium | a) Plattformnativ: CAF (iOS) / Ogg (Android) + Remux beim Transfer | b) Eigener Chunk-Container + libopus/libopusenc per FFI beidseitig | c) AAC-LC in M4A überall |
|---|---|---|---|
| Aufnahme iOS | `AVAudioRecorder`/`AVAudioEngine`→`AVAudioFile` Opus in CAF; Bitrate nicht steuerbar (~16 kb/s bei 16 kHz) | `AVAudioEngine` Tap → PCM → libopus (eigenes xcframework, libopus 1.6.x) → Ogg oder eigener Container; Bitrate/VBR/Komplexität frei | `AVAudioRecorder` `kAudioFormatMPEG4AAC`, `AVEncoderBitRateKey` wird beachtet |
| Aufnahme Android | `MediaRecorder` OGG/OPUS (API 29+), Bitrate steuerbar | `AudioRecord` → libopusenc (z. B. `io.element.android:opusencoder:1.2.0`) | `MediaRecorder` MPEG_4/AAC oder `MediaCodec` |
| Wiedergabe iOS | CAF nativ (`AVAudioFile`/`AVAudioPlayerNode`); Ogg **nicht** nativ | libopus-Decoder → PCM-Puffer → `AVAudioPlayerNode.scheduleBuffer` | nativ |
| Wiedergabe Android | Ogg nativ (Media3/Plattform-Decoder); CAF **nicht** | Media3 mit eigenem `Extractor`, oder libopus → `AudioTrack` | nativ |
| Transfer | Remux CAF↔Ogg nötig (verlustfrei, z. B. Portierung von `ogg_caf_converter` – Pure Dart, 416 Downloads, wenig erprobt) | Format identisch auf beiden Seiten, kein Remux | identisch, kein Remux |
| Größe (2 min/Tag) | iOS ~88 MB/Jahr (unkontrolliert), Android frei 88–131 MB/Jahr | 88–131 MB/Jahr, kontrolliert | 175–350 MB/Jahr |
| Aufwand | gering für Aufnahme, mittel für Remux-Code und Tests beider Richtungen (Pre-Skip/Priming, Pakettabelle, Granule) | hoch: zwei native Builds (NDK/CMake, Xcode xcframework), Decoder-Integration in Player, Wartung der libopus-Version | gering |
| Risiken | Apple-Encoder-Verhalten undokumentiert (VBR, Rate), Remux-Fehler bei Randfällen; Android-Geräte mit fehlerhaftem Opus-Encoder (Element-Flag) | Binärgröße (+~1 MB je Plattform), Crash-Risiko in nativem Code, Audit-Aufwand | Patentfreiheit irrelevant (AAC-LC-Decoder überall), nur Dateigröße; Qualität bei 32 kb/s mono für Sprache gut |
| Wort-Zeitstempel/Waveform | unabhängig vom Container | unabhängig | unabhängig |

**Empfehlung:** Für ein MVP **Option c (AAC-LC/M4A, 32–48 kb/s, 16–24 kHz mono)**: beidseitig nativ aufnehmbar und abspielbar, Bitrate auf beiden Plattformen kontrollierbar, kein Remux, keine FFI. Mehrverbrauch gegenüber Opus ca. 90–200 MB/Jahr bei 2 min/Tag – für ein Tagebuch unkritisch, für den QR-Transfer relevant (Transfer-Bericht anpassen). Wer Opus will, sollte **Option b nur auf der iOS-Seite** ergänzen (libopus-Decoder + Encoder als xcframework, Ogg beidseitig) und auf Android bei `MediaRecorder`/Media3 bleiben; Option a (CAF+Remux) ist wegen der unkontrollierbaren Apple-Bitrate und der dünnen Remux-Werkzeuglage die riskanteste Variante.

---

## 3. Wiedergabe verschlüsselter Audios ohne Klartext-Tempdatei

### 3.1 Android

- Media3 bringt selbst ein seekbares Muster mit: `AesCipherDataSource` initialisiert `AesFlushingCipher` mit Schlüssel, IV aus `dataSpec.key` und `offset = dataSpec.uriPositionOffset + dataSpec.position`; `AesFlushingCipher` ist „AES/CTR/NoPadding", Counter = `offset / blockSize`, Vorlauf = `offset % blockSize`. Exakt dieses Prinzip trägt einen eigenen `DataSource` für lokale Dateien: bei `open(DataSpec)` Counter aus `position/16` ableiten, `position%16` Bytes verwerfen, dann `read()` per `cipher.update`.
- Referenz **Signal Android**: `core/util/.../ModernDecryptingPartInputStream.java` – „AES/CTR/NoPadding", Schlüssel = HMAC-SHA256(modernKey, 32-Byte-Random aus dem Dateikopf), IV-Bytes 12–15 = `offset/16` big-endian, Stream-Skip auf Blockgrenze, `offset%16` Bytes verwerfen; **keine Integritätsprüfung** auf Dateiebene. `ModernEncryptedMediaDataSource` (implementiert `android.media.MediaDataSource`) öffnet für `readAt(position)` einen solchen Stream direkt am Offset.
- Historische ExoPlayer-Issues (#662, #2387, #6122, #5307) drehen sich sämtlich um die fehlende Seekbarkeit der HLS-`Aes128DataSource` (CBC) und die Empfehlung, eine eigene CTR-basierte `DataSource` zu bauen; der ProAndroidDev-Artikel von Mohsen Mousavi (nur Suchauszug) beschreibt dasselbe Muster.
- Integrität: AES-CTR allein ist nicht authentifiziert. Für Seekbarkeit **und** Authentizität empfiehlt sich das **Cryptomator-Schema**: 68-Byte-Header (12 B Nonce, 40 B AES-GCM-Payload mit 32-B-Content-Key, 16 B Tag), Inhalt in Chunks „up to 32 KiB + 28 bytes" (12 B Nonce, ≤32 KiB Payload, 16 B Tag), AAD = Chunk-Nummer (64-bit BE) + Header-Nonce gegen Umordnung; jeder Chunk unabhängig entschlüsselbar → Random Access = Chunk-Index = `position / 32768`. Java-Implementierung `org.cryptomator:cryptolib` 2.2.2 (30. Jan. 2025, AGPLv3/kommerziell – Lizenz beachten), Swift `cryptolib-swift` 1.1.x (iOS 13+, CryptoKit AES-GCM). Ein eigener Nachbau des Schemas mit Plattform-Primitiven ist klein.

### 3.2 iOS

- Keine `DataSource`-Abstraktion in `AVAudioPlayer`. Praktikabel: Datei chunkweise entschlüsseln → mit `AVAudioConverter`/`AudioFileOpenWithCallbacks` dekodieren → `AVAudioPCMBuffer` → `AVAudioPlayerNode.scheduleBuffer(_:completionHandler:)` (iOS 8+; Float32 non-interleaved ist der robuste Weg laut Forenthreads 747009/768309). Seeking = Chunk-Index berechnen, Decoder neu aufsetzen, ab Paketgrenze dekodieren (bei Opus 80 ms Pre-Roll, bei AAC ein bis zwei Pakete Priming beachten).
- `AudioFileOpenWithCallbacks` erlaubt einen eigenen Read-Callback über die verschlüsselte Datei, so dass `AVAudioFile`-ähnliches Lesen ohne Klartextdatei möglich ist (Forumsthread 674155 beschreibt dasselbe Muster für HLS-Downloads).
- Geschwindigkeit: `AVAudioUnitTimePitch.rate` 1/32–32 (iOS 8+) im `AVAudioEngine`-Graph; `AVAudioPlayer.rate` wäre 0,5–2,0 mit `enableRate`, entfällt aber ohne Klartextdatei.

### 3.3 libsodium secretstream vs. AES-CTR/GCM-Chunks

- `crypto_secretstream_xchacha20poly1305`: Header 24 B, pro Nachricht 17 B Overhead (1 Tag-Byte + 16 B Poly1305), Tags MESSAGE/PUSH/REKEY/FINAL; **strikt sequenziell**, kein Random Access („messages cannot be truncated, removed, reordered ... without detection"). Für Seeking müsste man einen eigenen Chunk-Index führen und dennoch von vorne bis zum Ziel entschlüsseln oder pro Chunk eigene Streams beginnen – dann ist ein Chunk-Format mit AEAD pro Chunk (Cryptomator-Muster, wahlweise mit XChaCha20-Poly1305 statt AES-GCM) die sauberere Wahl.
- Bibliotheksstand: libsodium 1.0.22 (9. Apr. 2026), `swift-sodium` (ISC, bündelt Clibsodium.xcframework, SecretStream-API vorhanden), `lazysodium-android` 5.2.0 (libsodium 1.0.20, 16-KB-Alignment, minSdk 24, MPL-2.0). Plattformalternativen: CryptoKit `AES.GCM`/`ChaChaPoly` (iOS 13+, 12-B-Nonce) und Android `javax.crypto` AES/GCM mit Keystore-Schlüssel. Achtung: **Jetpack Security `security-crypto` 1.1.0 (30. Juli 2025) hat alle APIs deprecated** („in favour of existing platform APIs and direct use of Android Keystore") – `EncryptedFile` ist kein Zukunftspfad.
- Auflösung des Widerspruchs Stack- vs. Rechtsbericht: Für lokale Speicherung genügen Plattform-Primitive (CryptoKit / Keystore + `Cipher`), Schlüssel im Secure Enclave/Keystore. libsodium lohnt sich nur, wenn ein plattformidentisches, auditierbares Transferformat (QR-Übergabe, XChaCha20-Poly1305, Argon2id für Passphrase) gewünscht ist – dort ist secretstream (sequenzielle Übertragung, kein Seeking nötig) passend.

### 3.4 Wellenform aus verschlüsselten Daten

Wellenform **bei der Aufnahme** berechnen (Element X: dBov-Level pro Puffer, auf 100 Punkte resampled) und als kleines Array mit den Metadaten verschlüsselt ablegen. Nachträgliche Berechnung erfordert Volldekodierung: Android `Amplituda` (FFmpeg-basiert, +Binärgröße, Datei-Input) bzw. iOS `DSWaveformImage` 15 (arbeitet mit lokalen Datei-URLs, akzeptiert aber auch `[Float]`-Samples) – beide erwarten Klartextdateien, daher nur über Sample-Arrays aus der eigenen Decoder-Pipeline nutzbar.

---

## 4. Transkript-synchrone Wiedergabe

- **iOS 26 `SpeechTranscriber`** (Speech-Framework, iOS/macOS 26.0+): `attributeOptions: [.audioTimeRange]` liefert pro Run des `AttributedString` einen `CMTimeRange`; WWDC25-Session 277 zeigt „highlighting each word as it's played back ... based on its audioTimeRange attribute and the current playback time". `ResultAttributeOption` hat genau zwei Fälle: `audioTimeRange`, `transcriptionConfidence`. `reportingOptions: [.volatileResults]` liefert vorläufige Ergebnisse, `isFinal` die endgültigen. Modelle laufen on-device außerhalb des App-Speichers, Download über `AssetInventory.assetInstallationRequest(supporting:)`; Sprachumfang „more to come" – **Deutsch-Unterstützung an Primärquelle nicht verifiziert (offene Frage)**.
- **`DictationTranscriber`** (iOS 26.0+): gleiche Modelle wie Systemdiktat/on-device `SFSpeechRecognizer`, für ältere Geräte; hat eine eigene `ResultAttributeOption` (Zeitstempel-Verfügbarkeit dort nicht separat verifiziert), unterstützt `ContentHint` `.farField`, `contextualStrings`, `SFSpeechLanguageModel`.
- **sherpa-onnx** (v1.13.7, 1. Sept. 2026; SPM-Support für iOS seit 1.13.5, Flutter-/Android-Builds): C-API `SherpaOnnxOfflineRecognizerResult` mit `timestamps` (pro Token, Sekunden), `durations`, `segment_timestamps`. Codebefund: Transducer- und CTC-Modelle (Parakeet TDT/CTC, NeMo, Zipformer) berechnen `time = frame_shift_ms/1000 * subsampling_factor * frame` pro Token; **Whisper** nur mit `enable_token_timestamps` (Cross-Attention-DTW, benötigt ONNX-Export mit Attention-Ausgaben) oder `enable_segment_timestamps`; **Moonshine liefert keine Zeitstempel** (Convert() enthält keinen Timestamp-Code). Token ≠ Wort: für Wortgrenzen müssen BPE-Token zusammengeführt werden (Token mit führendem Leerzeichen/▁).
- **whisper.cpp** v1.9.3 (20. Aug. 2026): Wort-Zeitstempel experimentell (`-ml 1`), DTW-Token-Timestamps; Genauigkeit typischerweise ±100–200 ms, nicht als Primärquelle geprüft (mustVerify).
- Architektur: Zeitstempel im Transkript (JSON: `[{w, t0, t1, conf}]`) neben Text speichern, Highlight per Timer auf Player-Position; bei Geschwindigkeitsänderung Position aus Player, nicht aus Wanduhr ableiten.

---

## 5. Systemintegration

### iOS
- Aufnahme: `AVAudioSession.Category.playAndRecord` (oder `.record`, das aber „virtually all output on the system" stummschaltet). Hintergrund-Aufnahme/-Wiedergabe: `UIBackgroundModes = audio` (Apple-Doku zu `.record`/`.playAndRecord`).
- Bluetooth-Mikrofon: `CategoryOptions.allowBluetoothHFP` (nur `record`/`playAndRecord`; `allowBluetooth` ist als „renamed" deprecated). Neu in iOS 26.0: `bluetoothHighQualityRecording` – Vollband-Aufnahme über unterstützte AirPods, nur mit `.default`-Mode, erhöht Latenz, **„is not currently supported in the European Union"** – für DACH also faktisch HFP-Qualität (8/16 kHz) bei Headset-Aufnahme.
- Sperrbildschirm: `MPNowPlayingInfoCenter.default().nowPlayingInfo` (`MPMediaItemPropertyPlaybackDuration`, `MPNowPlayingInfoPropertyElapsedPlaybackTime`, `MPNowPlayingInfoPropertyPlaybackRate`), `MPRemoteCommandCenter.shared()` mit `playCommand`, `pauseCommand`, `togglePlayPauseCommand`, `skipForward/BackwardCommand`, `changePlaybackPositionCommand`, `changePlaybackRateCommand` (iOS 7.1+). Funktioniert mit `AVAudioEngine`-Wiedergabe, solange die Session aktiv ist.

### Android
- **Android 17 Background Audio Hardening** (developer.android.com/about/versions/17/changes/bg-audio): Für alle Apps auf Android 17 gilt – Audio-Wiedergabe im Hintergrund (`AudioTrack`, AAudio, OpenSL, media3) wird **stumm unterdrückt**, Fokus-Anfragen liefern `AUDIOFOCUS_REQUEST_FAILED`, Lautstärke-APIs werden ignoriert, sofern keine sichtbare Activity oder ein Foreground Service (nicht `SHORT_SERVICE`) läuft; Apps mit **targetSdk 37** brauchen zusätzlich einen FGS mit While-In-Use-Fähigkeit (Start aus dem Vordergrund). Ausnahmen: Alarme mit `EXACT_ALARM`. Empfehlung von Google: `MediaSessionService` aus media3 („not likely to be impacted"). Test: `adb shell cmd audio set-enable-hardening throw`.
- Umsetzung: `MediaSessionService` + `ExoPlayer`, Manifest `foregroundServiceType="mediaPlayback"`, Permissions `FOREGROUND_SERVICE` und `FOREGROUND_SERVICE_MEDIA_PLAYBACK`; Notification wird automatisch erzeugt, Service beendet Foreground nach 10 min Inaktivität. Media3 1.11.0 (5. Aug. 2026; 1.9.0 hob minSdk auf 23; 1.10.0 machte `MediaSessionService` zum `LifecycleService`).
- Geschwindigkeit: `Player.setPlaybackParameters(PlaybackParameters(speed, pitch))`, beide > 0, Default 1.0; Pitch 1.0 = Time-Stretch.
- Bluetooth-Headset-Mikrofon: `startBluetoothSco()`/`setBluetoothScoOn()` deprecated; stattdessen `AudioManager.setCommunicationDevice()`/`getAvailableCommunicationDevices()` (API 31, mustVerify) oder `AudioRecord.setPreferredDevice()` mit `TYPE_BLUETOOTH_SCO`/`TYPE_BLE_HEADSET`. Google-Play-Zielversion: ab 31. Aug. 2026 targetSdk 36 Pflicht; Frist für 37 vermutlich Aug. 2027 (Sekundärquelle, mustVerify).

---

## 6. Entscheidungsmatrix und Empfehlung

| Baustein | Empfehlung MVP | Alternative (Opus-Pfad) |
|---|---|---|
| Codec/Container | AAC-LC in M4A, mono, 24 kHz, 32–48 kb/s, beidseitig nativ | Ogg-Opus 20–24 kb/s VBR, 48 kHz Eingang; Android `MediaRecorder` (API 29+) / `opusencoder` 1.2.0; iOS libopus 1.6.1 + libogg als xcframework, Decoder → `AVAudioPlayerNode` |
| Verschlüsselte Datei | Chunk-AEAD (32 KiB, AES-GCM oder XChaCha20-Poly1305, AAD = Chunk-Nr + Header-Nonce), Schlüssel in Keystore/Secure Enclave | gleich; libsodium nur für Transferformat |
| Wiedergabe Android | Media3 1.11.0 `ExoPlayer` + eigener `DataSource` (Chunk-Entschlüsselung, seekbar per Chunk-Index) in `MediaSessionService` | + `media3-decoder-opus`, falls Geräte-Decoder fehlt |
| Wiedergabe iOS | `AVAudioEngine` + `AVAudioPlayerNode` + `AVAudioUnitTimePitch`; AAC-Dekodierung per `AudioFileOpenWithCallbacks`/`AVAudioConverter` aus entschlüsselten Chunks | libopus-Decoder |
| Wort-Zeitstempel | iOS 26 `SpeechTranscriber` `.audioTimeRange`; Android sherpa-onnx 1.13.7 Parakeet-TDT/Zipformer (Token-Timestamps) | Whisper nur mit DTW-Export; Moonshine ohne Zeitstempel |
| Wellenform | bei Aufnahme berechnen (100 Werte), mit Metadaten verschlüsseln | – |
| Systemintegration | `MPNowPlayingInfoCenter`/`MPRemoteCommandCenter`; `MediaSessionService` (Android-17-konform) | – |
| Bluetooth | iOS `allowBluetoothHFP` (+ `bluetoothHighQualityRecording` außerhalb EU), Android `setCommunicationDevice`/`setPreferredDevice` | – |

Offene Punkte für eine Messkampagne: reale iOS-Opus-Dateigrößen bei 16/24/48 kHz; ob `AVAudioConverter.bitRate` bei Opus greift; Deutsch in `SpeechTranscriber.supportedLocales`; Zeitstempel-Genauigkeit von Parakeet-TDT vs. Whisper-DTW auf deutscher Sprache; Verhalten von `MediaRecorder` OGG/OPUS auf Samsung/Xiaomi-Geräten.

---

## Quellen

- https://developer.apple.com/documentation/coreaudiotypes/kaudioformatopus (JSON-Endpunkt, abgerufen 2026-09-03)
- https://developer.apple.com/documentation/audiotoolbox/audiofiletypeid
- https://developer.apple.com/documentation/avfaudio/avaudiofile/init(forwriting:settings:)
- https://developer.apple.com/forums/thread/128434 (Ogg/Opus „This media format is not supported")
- http://www.openradar.appspot.com/49315600 (rdar://49315600, Opus-Bitrate; nur Suchauszug)
- https://developer.apple.com/forums/thread/763362 (Apple-Engineer-Beispiel AVAudioConverter Opus, Sept. 2024)
- https://developer.apple.com/forums/thread/127317
- https://developer.apple.com/library/archive/documentation/MusicAudio/Reference/CAFSpec/CAF_spec/CAF_spec.html
- https://pub.dev/packages/record (7.1.1)
- https://pub.dev/packages/ogg_caf_converter (0.1.4) und https://github.com/jt274/ogg_caf_converter
- https://github.com/Canardoux/flutter_sound/pull/199
- https://github.com/element-hq/swift-ogg (Tags), https://github.com/element-hq/opus-swift
- https://github.com/aosp-mirror/platform_frameworks_base/blob/main/media/java/android/media/MediaRecorder.java
- https://github.com/LineageOS/android_frameworks_av/blob/lineage-22.2/media/libmediaplayerservice/StagefrightRecorder.cpp
- https://github.com/LineageOS/android_frameworks_av/blob/lineage-22.2/media/codec2/components/opus/C2SoftOpusEnc.cpp
- https://github.com/LineageOS/android_frameworks_av/blob/lineage-22.2/media/libstagefright/OggWriter.cpp
- https://developer.android.com/media/platform/supported-formats
- https://developer.android.com/media/media3/exoplayer/supported-formats
- https://github.com/androidx/media/blob/release/libraries/decoder_opus/README.md
- https://github.com/androidx/media/blob/release/RELEASENOTES.md und https://developer.android.com/jetpack/androidx/releases/media3
- https://github.com/androidx/media/blob/release/libraries/muxer/src/main/java/androidx/media3/muxer/OggMuxer.java
- https://github.com/androidx/media/blob/release/libraries/datasource/src/main/java/androidx/media3/datasource/AesFlushingCipher.java
- https://github.com/androidx/media/blob/release/libraries/datasource/src/main/java/androidx/media3/datasource/AesCipherDataSource.java
- https://github.com/androidx/media/blob/release/libraries/common/src/main/java/androidx/media3/common/PlaybackParameters.java
- https://github.com/google/ExoPlayer/issues/662, /2387, /6122, /5307
- https://medium.com/@s.m.mousavi1993/how-to-play-an-aes-encrypted-audio-video-from-a-local-file-and-a-remote-server-on-android-part-1-c7a841daf0e0 (nur Suchauszug)
- https://github.com/signalapp/Signal-Android/blob/main/core/util/src/main/java/org/signal/core/util/crypto/ModernDecryptingPartInputStream.java
- https://github.com/signalapp/Signal-Android/blob/main/app/src/main/java/org/thoughtcrime/securesms/video/ModernEncryptedMediaDataSource.java
- https://github.com/signalapp/Signal-Android/blob/main/app/src/main/java/org/thoughtcrime/securesms/audio/AudioCodec.java
- https://github.com/element-hq/element-android/blob/develop/vector/src/main/java/im/vector/app/features/voice/VoiceRecorderProvider.kt, VoiceRecorderQ.kt, VoiceRecorderL.kt, AbstractVoiceRecorderQ.kt
- https://github.com/element-hq/element-x-android (libraries/voicerecorder, gradle/libs.versions.toml)
- https://github.com/element-hq/libopusencoder-android
- https://github.com/cryptomator/docs/blob/develop/docs/security/vault.mdx, https://github.com/cryptomator/cryptolib/releases, https://github.com/cryptomator/cryptolib-swift
- https://github.com/jedisct1/libsodium-doc/blob/master/secret-key_cryptography/secretstream.md, https://github.com/jedisct1/libsodium/releases, Header crypto_secretstream_xchacha20poly1305.h / crypto_aead_xchacha20poly1305.h
- https://github.com/jedisct1/swift-sodium, https://github.com/terl/lazysodium-android/releases
- https://developer.apple.com/documentation/cryptokit/chachapoly
- https://developer.android.com/jetpack/androidx/releases/security
- https://developer.apple.com/documentation/speech/speechtranscriber, .../dictationtranscriber, .../speechtranscriber/resultattributeoption
- https://developer.apple.com/videos/play/wwdc2025/277/
- https://gist.github.com/lanserxt/77780783adfa179c7a009042b9cf5a95
- https://github.com/k2-fsa/sherpa-onnx (c-api/c-api.h, offline-recognizer-whisper-impl.h, -moonshine-impl.h, -transducer-impl.h, -ctc-impl.h, offline-whisper-model-config.h, Releases), https://pypi.org/project/sherpa-onnx/
- https://github.com/ggml-org/whisper.cpp (README, Tags)
- https://github.com/xiph/opus/tags, https://github.com/xiph/opus/blob/main/doc/draft-ietf-codec-opus.xml, https://github.com/xiph/ogg/blob/master/doc/framing.html
- https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/allowbluetoothhfp, .../bluetoothhighqualityrecording, .../allowbluetooth
- https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playandrecord, .../record
- https://developer.apple.com/documentation/avfaudio/avaudiounittimepitch/rate, .../avaudioplayer/rate, .../avaudioplayer/enablerate, .../avaudioplayernode/schedulebuffer(_:completionhandler:)
- https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter, .../mpremotecommandcenter, .../becoming-a-now-playable-app
- https://developer.android.com/about/versions/17/changes/bg-audio, https://developer.android.com/about/versions/17/behavior-changes-17
- https://developer.android.com/media/media3/session/background-playback
- https://developer.android.com/reference/android/media/AudioManager
- https://developer.android.com/google/play/requirements/target-sdk
- https://github.com/lincollincol/Amplituda, https://github.com/dmrschmidt/DSWaveformImage
