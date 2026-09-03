# Geräteübergreifender Transfer per QR-Code – technische Machbarkeitsanalyse (Lens: technik-qr-transfer)

Stand der Recherche: 3. September 2026. Hinweis zur Quellenlage: Die Web-Suche war in dieser Sitzung kontingentiert, viele Nachrichten- und Wiki-Domains waren durch den Egress-Proxy blockiert. Primärquellen (Apple-/Android-Entwicklerdokumentation, GitHub-Repositories, Spezifikationen) wurden direkt gelesen; Presseinformationen zu Quick Share/AirDrop stammen aus GitHub-Spiegeln von Artikeln (BleepingComputer, The Hacker News, 9to5Google-Titel) und sind entsprechend als "zu verifizieren" markiert.

## 1. Kurzfazit

1. **QR-Codes als Datenkanal für Audio sind unrealistisch.** Ein Version-40-QR fasst maximal 2.953 Bytes (ECC L) bzw. 2.331 Bytes (ECC M). Animierte QR-Codes mit Fountain-Codes erreichen zwischen zwei Smartphones in der Praxis 1–3 kB/s (Rekord im TXQR-Experiment: ~25 kbit/s ≈ 3,1 kB/s bei 12 FPS und 1.850 Byte/Frame, ECC L). Ein Jahr Sprachtagebuch (3 min/Tag, Opus 16 kbit/s ≈ 131 MB) bräuchte damit 12–36 Stunden Kamera-vor-Display – nicht zumutbar.
2. **Der QR-Code soll ausschließlich Pairing + Schlüssel transportieren** (ca. 100–200 Bytes: Ephemeral-Public-Key oder 256-Bit-PSK, Session-ID, Adresse/Port, Protokollversion). Die Nutzdaten laufen über einen lokalen Kanal.
3. **Nutzdatenkanal nach Plattformpaar:**
   - iOS↔iOS: Network framework mit `peerToPeerIncluded(true)` (AWDL) oder ab iOS 26 `WiFiAware` + `DeviceDiscoveryUI`. Multipeer Connectivity ist seit Xcode 27 komplett deprecated (TN3213).
   - Android↔Android: Wi-Fi Direct (`WifiP2pManager`, wie Signal) oder Nearby Connections (`P2P_POINT_TO_POINT`), alternativ Wi-Fi Aware (Android 8+, Pairing-API ab API 34).
   - iOS↔Android: primär **gemeinsames WLAN + TCP/TLS** (LocalSend-Modell: UDP-Multicast 224.0.0.167:53317 zur Discovery, HTTPS mit selbstsigniertem Zertifikat, Fingerprint = SHA-256 des Zertifikats). Fallback 1: Android `startLocalOnlyHotspot()` (API 26) + iOS `NEHotspotConfigurationManager` (iOS 11+) – Zugangsdaten stecken im QR. Fallback 2: BLE (iPhone→Android gemessen 40–80 kB/s, d. h. 131 MB in 30–60 min). Wi-Fi Aware iOS 26 ↔ Android ist standardbasiert, aber praktische Interoperabilität ist bislang unbelegt (offene Frage).
4. **Container:** age-Format (ChaCha20-Poly1305, 64-KiB-Chunks, 16 Byte Overhead/Chunk, scrypt-Passphrase-Empfänger) oder libsodium `secretstream` (XChaCha20-Poly1305, Tags MESSAGE/PUSH/REKEY/FINAL, erkennt Truncation/Reordering). 7z/AES-256 (SHA-256 mit 2^19 Iterationen, CBC) ist möglich, aber ohne AEAD und ohne Streaming-Integrität – nicht empfohlen.
5. **Kompression:** Audio bereits als Opus speichern (kein Nachkomprimieren); Text/JSON mit zstd (Silesia-Ratio 2,9 bei 510 MB/s) – Text ist mit < 1 MB/Jahr ohnehin vernachlässigbar.

## 2. QR-Code-Kapazität (ISO/IEC 18004)

Kapazitäten nach Modus und Fehlerkorrektur (Quelle: node-qrcode-README, Zahlen identisch mit der Denso-Wave-Tabelle; ECB-Struktur nachgerechnet aus zxing `Version.java`):

| Modus | L (~7 %) | M (~15 %) | Q (~25 %) | H (~30 %) |
|---|---|---|---|---|
| Numerisch | 7.089 | 5.596 | 3.993 | 3.057 |
| Alphanumerisch | 4.296 | 3.391 | 2.420 | 1.852 |
| Byte (8 Bit) | **2.953** | **2.331** | 1.663 | 1.273 |
| Kanji | 1.817 | 1.435 | 1.024 | 784 |

Version 40 = 177×177 Module. Nachrechnung aus zxing (Version 40: Gesamt 3.706 Codewörter): L = 19×118 + 6×119 = 2.956 Daten-Codewörter → 2.953 Bytes Nutzlast (nach Modus-Indikator und Längenfeld); M = 18×47 + 31×48 = 2.334 → 2.331; Q = 34×24 + 34×25 = 1.666 → 1.663; H = 20×15 + 61×16 = 1.276 → 1.273. Kleinere, kamerafreundlichere Versionen: V20-L 858 Bytes, V20-M 666 Bytes, V30-L 1.732 Bytes, V30-M 1.370 Bytes.

Praxis: Version 40 wird auf Smartphone-Displays/-Kameras unzuverlässig gelesen. TXQR ermittelte den Sweet Spot bei 550–900 Byte/Frame (ECC M) bzw. 1.800–2.000 Byte (ECC L, mit Fountain-Codes). Die BC-UR-Spezifikation (Blockchain Commons) beschreibt den Trade-off explizit: "Larger fragment sizes yield denser QR codes, which make it more likely the camera will fail to scan a code correctly in the allotted time. Smaller fragment sizes will result in less dense QR codes, but more fragments will be required."

## 3. Animierte QR-Codes und Fountain-Codes

### 3.1 TXQR (Ivan Daniluk, 2018) – die einzige öffentlich dokumentierte Messreihe
- Post 1 (18.11.2018, Repetition-Code, Frames im Loop): 13 KB Zufallsdaten, 3–12 FPS, Chunks 100–1.000 Byte, alle vier ECC-Stufen. Bestwert: "1.4 secs, which is almost 9KB/s!" bei 11 FPS, 850-Byte-Chunks, ECC M. Typisch: "1-2KB/s". Hauptproblem: verpasste Frames erzwingen einen vollständigen weiteren Loop-Durchlauf; "low chunk sizes result in too much overhead for QR encoding and overall transferring time skyrockets".
- Post 2 (01.12.2018, Luby-Transform-Fountain-Codes via google/gofountain): "The record time for transferring ~13KB of data is now is half a second or 501ms to be precise – it's almost 25kbps." Konfiguration: "12FPS and 1850 bytes per QR code with low error correction level". Angenommene Frame-Verlustrate ≤ 20 %; die meisten Dekodierläufe "less them 4 seconds". Der iOS-Reader (txqr-reader) wurde über Gomobile gebaut.
- Einordnung: 25 kbit/s ist ein Laborbestwert (feste Halterung, 13 KB). Für Planungen sind 1–3 kB/s realistisch.

### 3.2 Blockchain Commons UR / Multipart UR (BCR-2020-005, BCR-2024-001)
- Zweck: "Transport binary data of arbitrary content and length using a sequence of one or more URIs or QR codes"; "agnostic about whether QR codes are displayed together or time-sequenced (animated)".
- Verfahren: "hybrid fixed-rate and rateless partitioning scheme called Multipart UR (MUR)"; die ersten seqLen Teile sind reine Fragmente, danach XOR-Mixe mit harmonischer Gradverteilung (1/1, 1/2, … 1/seqLen), PRNG Xoshiro256**. Kodierung als Bytewords (2 Zeichen/Byte) im QR-Alphanumerik-Modus → effektiv max. ~2.148 Byte Nutzlast pro V40-L-QR, abzüglich CBOR-Header.
- Implementierungen: bc-ur (C++), URKit (Swift, iOS 13+, "late alpha"), Hummingbird (Java, Beispiel `MAX_FRAGMENT_LENGTH = 100`), Python (Foundation Devices), Rust, TypeScript (NGRAVE). URDemo (iOS) zeigt einstellbare Framerate. Keine Durchsatz-Benchmarks in den READMEs.
- Bewertung: BC-UR ist der ausgereifteste offene Standard für animierte QR-Codes; Einsatzgebiet sind Kilobyte-Payloads (PSBT, Schlüssel) – nicht Megabytes.

### 3.3 Weitere Projekte
- qifi-dev/qrs: Browser-basiert, `luby-transform`-Bibliothek, keine Durchsatzangaben.
- libcimbar (sz3): eigenes Farb-Matrix-Format (kein QR), "850 kilobits/s (~106 KB/s)", Wirehair-Fountain-Codes, Reed-Solomon, Dateien bis 33 MB; Decoder nur Android (App "cfc") und WASM. Kein iOS-Decoder, experimentell, nicht als Produktbasis geeignet.
- qrcp, qr-filetransfer: QR transportiert nur eine URL (`http://{address}:{port}/{random_path}`) zu einem lokalen HTTP-Server – exakt das "QR nur für Pairing"-Muster.

### 3.4 Rechenbeispiel: 1 Jahr Sprachtagebuch
Annahmen: 365 Tage × 3 min = 1.095 min = 65.700 s Sprache, mono.

| Format | Bitrate | Größe/min | Größe/Jahr |
|---|---|---|---|
| WAV 16 kHz/16 Bit | 256 kbit/s | 1,92 MB | ~2,1 GB |
| AAC-LC | 64 kbit/s | 480 kB | ~526 MB |
| Opus (Fullband-Sprache) | 32 kbit/s | 240 kB | ~263 MB |
| Opus (Fullband-Sprache, untere Empfehlung) | 24 kbit/s | 180 kB | ~197 MB |
| **Opus (Wideband-Sprache)** | **16 kbit/s** | **120 kB** | **~131 MB** |
| Opus (Wideband-Sprache, untere Empfehlung) | 12 kbit/s | 90 kB | ~99 MB |

Mit VBR und DTX (Pausen) sinken die Werte um weitere 10–20 %. Ogg-Container-Overhead ~1–2 %.

Text: Deutsche Sprache ~120–150 Wörter/min, ~7 Byte/Wort (UTF-8, Umlaute 2 Byte) → ~1 kB/min Rohtext → ~1,1 MB/Jahr; mit Zeitstempeln/Segment-JSON 2–3 MB; nach zstd/brotli (Ratio ~3–4 bei natürlicher Sprache) **0,3–1 MB/Jahr**.

QR-Frames (1.800 Byte Nutzlast/Frame, +20 % Fountain-Redundanz):
- Audio 131 MB → ~73.000 Frames roh, ~88.000 mit Redundanz. Bei 10 FPS nominal 2,4 h; bei realistischen 1–3 kB/s **12–36 h**. Bei 263 MB (32 kbit/s) doppelt so lang.
- Text 0,5 MB → ~280 Frames roh, ~340 mit Redundanz → **3–8 min** bei 1–3 kB/s. Machbar als Notfall-Export der reinen Transkripte, aber kein Komfortpfad.
- Pairing-Payload 150 Byte → **1 Frame** (QR-Version ~7–8 bei ECC M).

## 4. Nutzdaten-Kanäle im Vergleich

### 4.1 Apple-only
- **Multipeer Connectivity**: iOS 7+, Transporte "Infrastructure Wi-Fi networks, Peer-to-peer Wi-Fi, Bluetooth personal area networks"; `MCEncryptionPreference` (.required verlangt `securityIdentity`). Apple-Doku (Stand 2026): "Multipeer Connectivity is deprecated. Migrate any code using this framework to the Network framework." TN3213: "Xcode 27 deprecates the entire Multipeer Connectivity framework." Für Neuentwicklung nicht mehr wählen.
- **Network framework**: P2P-WLAN (AWDL) nur mit Opt-in: "By default, Network framework doesn't enable peer-to-peer Wi-Fi. If you want that, explicitly enable it using the `peerToPeerIncluded(_:)` modifier." (`includePeerToPeer` seit iOS 12). Sicherheitsmodell TLS-PKI; TLS-PSK "doesn't work with QUIC, it doesn't support TLS 1.3, and it only works with the older Network framework API". Empfehlung: pro Gerät ein selbstsigniertes Zertifikat, Fingerprint via QR verifizieren (Signal-Muster).
- **Wi-Fi Aware (iOS 26+)**: iPhone 12 und neuer, iPad (10. Gen.)+, iPad Air (4.)+, iPad Pro 11" (3.)+, iPad Pro 12,9" (5.)+, iPad mini (6.)+. Entitlement `com.apple.developer.wifi-aware` (Publish/Subscribe), Info.plist `WiFiAwareServices` (`_name._tcp`/`_udp`, max. 15 Zeichen). Pairing über `DeviceDiscoveryUI` (`DevicePicker`/`DevicePairingView`, PIN-Bestätigung), "fully authenticated and encrypted at the Wi-Fi layer". Performance-Modi `bulk` (empfohlen) und `realtime`. Keine Durchsatzzahlen von Apple; "Wi-Fi Aware and QUIC is not supported prior to iOS 27". Wichtig: Signal iOS nutzt weiterhin `MCSession(peer:securityIdentity:encryptionPreference: .required)` und prüft den SHA-256-Hash des Peer-Zertifikats aus dem QR-Code in konstanter Zeit (`expectedCertificateHash.ows_constantTimeIsEqual(to: certificateHash)`) – das Verifikationsmuster ist auf Network framework übertragbar.

### 4.2 Android-only
- **Nearby Connections**: Laut google/nearby-README Mediums: Bluetooth Classic, BLE (Fast/GATT/Extended/L2CAP), Wi-Fi LAN, Wi-Fi Hotspot, Wi-Fi Direct, Wi-Fi Aware, WebRTC, NFC, USB, AWDL – "Android has the most comprehensive support"; Schlüsselaustausch mit UKEY2 (P-256/Curve25519 + Auth-String zur Out-of-Band-Verifikation). Flutter-Plugin `nearby_connections` 4.3.0 ist explizit "ANDROID only"; Hinweis: "Location/GPS service must be turned on or devices may disconnect more often".
- **Wi-Fi Direct** (`WifiP2pManager`, API 14+): Signal Android (Modul `lib/device-transfer`) nutzt DNS-SD-Instanznamen `_devicetransfer._signal.org`, `groupOwnerIntent = 0`, Permission `NEARBY_WIFI_DEVICES` (Android 13+) bzw. `ACCESS_FINE_LOCATION`; Standortmodus muss aktiv sein.
- **Wi-Fi Aware** (API 26+): `AwarePairingConfig` (API 34) mit Bootstrapping-Methoden u. a. `PAIRING_BOOTSTRAPPING_QR_DISPLAY` (1<<3) und `PAIRING_BOOTSTRAPPING_QR_SCAN` (1<<7); nur gültig wenn `Characteristics#isAwarePairingSupported()`.
- **Local-only Hotspot**: `WifiManager.startLocalOnlyHotspot()` (API 26) liefert SSID/Passphrase über `LocalOnlyHotspotReservation`/`SoftApConfiguration`.

### 4.3 Plattformübergreifend iOS↔Android
- **Gemeinsames WLAN (LocalSend-Modell)**: Protokoll v2.x: Discovery per UDP-Multicast 224.0.0.167:53317 (Fallback HTTP-POST an lokale IPs), Endpunkte `/api/localsend/v2/register|prepare-upload|upload|cancel`, HTTPS mit selbstgeneriertem Zertifikat, Fingerprint = SHA-256 des Zertifikats, optionale PIN. Bekannte Hürden: Firewall-Port 53317 TCP/UDP, "AP isolation must be disabled". LocalSend läuft auf iOS 12+/Android 5+, ~90k GitHub-Sterne, Apache-2.0 – geprüfte Referenzarchitektur.
- **Nearby Connections für iOS**: Das Swift-Package existiert, aber die Medium-Tabelle zeigt für iOS/macOS nur "Wi-Fi LAN" für Advertising/Scanning/Transfer – also faktisch dieselbe Voraussetzung (gemeinsames WLAN). Kein Vorteil gegenüber einem eigenen TCP/TLS-Protokoll, dafür eine schwergewichtige Abhängigkeit.
- **Hotspot-Fallback**: Android öffnet `startLocalOnlyHotspot()`, iOS tritt per `NEHotspotConfigurationManager` (iOS 11+, Entitlement `com.apple.developer.networking.HotspotConfiguration`, Nutzer muss zustimmen) bei; SSID/Passphrase kommen aus dem QR. Umgekehrt (iOS als Hotspot) gibt es keine programmatische API – der Android→iOS-Fall braucht daher Android als Hotspot-Host, egal in welche Richtung die Daten fließen.
- **BLE**: iOS 11+ `CBL2CAPChannel`, `CBPeripheralManager` (Hintergrund nur mit `bluetooth-peripheral`-Mode). Messwerte 2026 (MeshLink-Projekt, iPhone→Samsung/OPPO, L2CAP bzw. GATT-Notify): 39–80 kB/s (Serien: Samsung avg 62–64 kB/s, OPPO avg 77–79 kB/s), GATT-Prototyp 21,96 kB/s für 64 KiB. Apple WWDC17 nannte für L2CAP + Extended Data Length + 15-ms-Intervall ~394 kbit/s (≈ 49 kB/s) als Obergrenze. Nordic-Sample (Dev-Kits, LE 2M, MTU 498, DLE 251): 1.504 kbit/s – nicht auf Smartphones übertragbar. Rechnung: 131 MB bei 60 kB/s ≈ 36 min, bei 22 kB/s ≈ 100 min. Als Fallback für Text + letzte Wochen Audio geeignet, für Vollmigration nur "über Nacht".
- **Wi-Fi Aware iOS 26 ↔ Android**: Apple: "Wi-Fi Aware™ … is a Wi-Fi Alliance™ standard specification"; Kompatibilität wird nur mit "Wi-Fi Aware certified accessories" beschrieben. Presse (Ars Technica, 25.11.2025, "The EU made Apple adopt new Wi-Fi standards, and now Android can support AirDrop") führt Apples Wi-Fi-Aware-Übernahme auf den DMA zurück. Ob ein Android-Publisher und ein iOS-Subscriber (mit Apples PIN-Pairing-UI) tatsächlich einen Datenpfad aufbauen, ist nicht belegt – Prototyp nötig.
- **Quick Share ↔ AirDrop (Stand 2026)**: 20./21.11.2025 startete Google die Interoperabilität auf der Pixel-10-Reihe; Voraussetzung ist AirDrop-Modus "Everyone for 10 minutes" bzw. Quick Share "Everyone"; direkte Geräteverbindung ohne Server, Kern in Rust, Pentest durch NetSPI (August 2025, ein Low-Finding CVSS 2.1); keine Apple-Kooperation ("open to working with Apple to enable 'Contacts Only' mode"). Ausweitung: Samsung Galaxy S26 ab ~22.03.2026, weitere Galaxy-Modelle mit One UI 8.5 (April 2026), Ankündigung weiterer Geräte im "June Android Drop" (02.06.2026). Für die App relevant nur als System-Share-Sheet-Pfad für eine Exportdatei – keine API, keine Kontrolle, nicht flächendeckend.
- **USB / Dateien-App**: iOS `UIDocumentPickerViewController(forExporting:asCopy:)` (iOS 8+) exportiert in Dateien-App/USB-Stick/iCloud-freie Ziele; Android `ACTION_CREATE_DOCUMENT` (API 19) "doesn't require any system permissions". Universeller Offline-Fallback: verschlüsselte Datei auf USB-C-Stick, an beiden Geräten anstecken.

## 5. Container, Verschlüsselung, Kompression

- **age (C2SP-Spezifikation)**: Header `age-encryption.org/v1`, Empfänger-Stanzas (X25519, scrypt mit r=8, p=1, außerdem MLKEM768-X25519 PQ-Hybrid), Header-MAC HMAC-SHA-256; Payload in 64-KiB-Chunks mit ChaCha20-Poly1305, 12-Byte-Nonce (11 Byte Zähler + Last-Chunk-Flag), **16 Byte Overhead pro Chunk** (≈ 0,024 %); "Streaming decryption MUST signal an error if the end of file is reached without successfully decrypting a final chunk" → Truncation wird erkannt. Vorteil: bestehende, auditierte Bibliotheken (Go, Rust `age`, Swift-Ports), Datei bleibt auch mit Drittwerkzeugen entschlüsselbar (Notfall-Export mit Passphrase).
- **libsodium secretstream**: XChaCha20-Poly1305, Header `crypto_secretstream_xchacha20poly1305_HEADERBYTES` (24 Byte), `ABYTES` (17 Byte) pro Nachricht, Tags `MESSAGE/PUSH/REKEY/FINAL`; erkennt "truncation, removal, reordering, duplication or modification". Ideal für ein proprietäres Transferformat, da libsodium auf iOS (Swift-Sodium) und Android (Lazysodium/libsodium-jni) verfügbar ist.
- **7z/AES**: Coder `06F10701` "7zAES (AES-256 + SHA-256)", Key-Derivation mit `NumCyclesPower = 19` (2^19 SHA-256-Runden), AES-CBC. Kein AEAD, keine Chunk-Integrität → nicht empfohlen.
- **Schlüsselableitung für Passphrase-Fallback**: scrypt (age) oder Argon2id (libsodium `crypto_pwhash`).
- **Kompression**: Opus-Dateien sind inkompressibel; nur Text/Metadaten komprimieren. zstd 1.5.7 -1: Ratio 2,896 bei 510 MB/s (Silesia); brotli 1.1.0 -1: 2,883 bei 290 MB/s. Bei < 3 MB Text/Jahr ist der Unterschied irrelevant – zstd wegen Geschwindigkeit und breiter Mobil-Unterstützung.
- **Opus auf den Plattformen**: iOS `kAudioFormatOpus` seit iOS 11.0; Android Opus-Encoder ab Android 10, Muxer Ogg/WebM, Decoder ab Android 5.0. Encoder-Parameter: `OPUS_APPLICATION_VOIP`, Bitraten "500 to 512000 bits per second", DTX (`OPUS_SET_DTX`), VBR Standard, Bandbreiten NB 4 kHz / WB 8 kHz / FB 20 kHz. Empfohlene Sprachbitraten laut RFC 7587 (nicht direkt abrufbar, zu verifizieren): NB 8–12, WB 16–20, FB 28–40 kbit/s.

## 6. Konkreter Transfer-Entwurf

### 6.1 Rollen und Ablauf
1. **Empfänger (neues Gerät)** startet "Tagebuch übernehmen": erzeugt X25519-Ephemeral-Keypair, 128-Bit-Session-ID, selbstsigniertes TLS-Zertifikat (Ed25519/P-256), öffnet Listener (TCP, Bonjour/mDNS `_voicediary._tcp` + UDP-Multicast-Beacon) und zeigt **einen** QR-Code (~180 Byte, Version ≤ 8, ECC M) mit: Protokollversion, Session-ID, Public Key, SHA-256-Zertifikat-Fingerprint, Liste der Kanalangebote (LAN-IP:Port, Hotspot-SSID/Passphrase falls Android, BLE-Service-UUID), Plattformkennung.
2. **Sender (altes Gerät)** scannt, prüft Version, leitet aus ECDH (eigener Ephemeral-Key × Empfänger-Public-Key) + Session-ID per HKDF einen Sitzungsschlüssel ab, verbindet über den besten verfügbaren Kanal und authentifiziert die TLS-Verbindung über den Fingerprint aus dem QR (Trust-on-QR statt PKI). Optional zusätzlich Noise `XXpsk3`/`NNpsk0` mit dem QR-PSK; Noise verlangt 256 Bit Entropie für PSKs.
3. **Payload**: ein age- oder secretstream-Container (Streaming, Chunks 64 KiB), Inhalt: `manifest.json` (zstd), `transcripts/*.json.zst`, `audio/*.opus`; Container-Schlüssel = HKDF(shared secret, "container"). Resume über Chunk-Index, Fortschritt in beiden Apps.
4. **Abschluss**: Sender zeigt SHA-256 des Containers; Empfänger prüft, entschlüsselt in temporäres Verzeichnis, importiert atomar, meldet Erfolg. Sender bietet danach "Daten auf altem Gerät löschen" an.

### 6.2 Kanalauswahl (Reihenfolge)
| Paar | Primär | Fallback 1 | Fallback 2 | Notfall |
|---|---|---|---|---|
| iOS↔iOS | Network framework, Bonjour + `peerToPeerIncluded(true)`, TLS mit QR-Fingerprint | Wi-Fi Aware (iOS 26+, iPhone 12+) via DeviceDiscoveryUI | gemeinsames WLAN | age-Datei via Dateien-App/USB-C |
| Android↔Android | Wi-Fi Direct (`WifiP2pManager`, DNS-SD) | Nearby Connections `P2P_POINT_TO_POINT` | gemeinsames WLAN | age-Datei via SAF/USB |
| iOS↔Android | gemeinsames WLAN (Multicast + mDNS, TCP/TLS) | Android `startLocalOnlyHotspot()` + iOS `NEHotspotConfigurationManager` (Credentials im QR) | BLE L2CAP (40–80 kB/s; Text zuerst, Audio nach) | age-Datei via USB-C-Stick; oder Text-only per animiertem QR (BC-UR, 3–8 min) |

Zeitbudget iOS↔Android für 131 MB: WLAN (802.11ac/ax, konservativ 5–20 MB/s) 7–30 s; Hotspot ähnlich; BLE 30–100 min.

### 6.3 Sicherheitsbewertung
- **Vertraulichkeit**: Ende-zu-Ende zwischen den beiden Apps; TLS oder Noise plus zusätzlicher Container-Layer (age/secretstream) – der Container schützt auch beim USB-/Share-Sheet-Fallback. Keine Server, keine Konten.
- **Authentizität/MitM**: Der QR ist der Vertrauensanker (Kamera = physischer Nähe-Kanal). Zertifikats-Fingerprint bzw. Public Key im QR verhindern MitM im WLAN; Vergleich in konstanter Zeit (Signal-Muster). QR-Inhalt nie ins Netz spiegeln, Session-ID einmalig, Ablauf nach 5 min.
- **Shoulder-Surfing des QR**: Ein Angreifer, der den QR abfotografiert, kennt Public Key + Fingerprint, aber nicht den Sender-Ephemeral-Key – ECDH schützt. Beim Hotspot-Fallback stehen SSID/Passphrase im QR: zusätzlich 6-stelligen SAS auf beiden Displays anzeigen und bestätigen lassen (UKEY2-Auth-String-Prinzip).
- **Integrität/Truncation**: age und secretstream erkennen abgeschnittene oder umsortierte Chunks; zusätzlich Manifest-Hash.
- **Plattformrisiken**: iOS Local Network Privacy (`NSLocalNetworkUsageDescription`, `NSBonjourServices`), Android Standortmodus für Wi-Fi Direct/Nearby, AP-Isolation in Gäste-/Hotel-WLANs (dann Hotspot-Fallback), Hintergrundbeschränkungen (Transfer im Vordergrund halten, Bildschirm wach).
- **Nicht empfohlen**: Quick-Share/AirDrop-Interop als Kernpfad (nur Pixel 10/Galaxy S26+, "Everyone"-Modus, keine API), 7z/AES (kein AEAD), animierte QR für Audio.

## 7. Offene Fragen / zu prüfen
1. Funktioniert Wi-Fi Aware zwischen iOS 26 (DeviceDiscoveryUI-Pairing) und Android 14+ (`AwarePairingConfig` mit QR-Bootstrapping) tatsächlich end-to-end? Prototyp mit Pixel 8/9 und iPhone 15 nötig.
2. Reale WLAN-Durchsätze der App-zu-App-TCP-Verbindung auf typischen Heimroutern (Ziel > 5 MB/s) und Verhalten bei AP-Isolation.
3. BLE-Durchsatz iOS→Android mit L2CAP auf mehr Gerätepaaren (bisherige Messungen: 40–80 kB/s, Samsung schwächer).
4. Verfügbarkeit von age-Implementierungen in Swift/Kotlin mit Streaming und Audit-Status vs. eigenes secretstream-Format.
5. Ob Apple `peerToPeerIncluded(true)` in iOS 27 weiter zulässt oder Wi-Fi Aware verpflichtend wird (TN3213 verweist auf beide).
6. RFC-7587-Bitratenempfehlungen und Höreindruck von Opus 12 vs. 16 vs. 24 kbit/s für deutsche Sprache mit lokalen Transkriptions-Modellen – beeinflusst die Datenmenge um Faktor 2.

## 8. Quellen
- node-qrcode README (Kapazitätstabelle, ECC-Stufen): https://github.com/soldair/node-qrcode
- zxing `Version.java` (ECB-Struktur V20/V30/V40): https://raw.githubusercontent.com/zxing/zxing/master/core/src/main/java/com/google/zxing/qrcode/decoder/Version.java
- BC-UR Spezifikation BCR-2020-005: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-005-ur.md
- Multipart UR BCR-2024-001: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2024-001-multipart-ur.md
- URKit: https://github.com/BlockchainCommons/URKit ; URDemo: https://github.com/BlockchainCommons/URDemo ; bc-ur: https://github.com/BlockchainCommons/bc-ur ; Hummingbird: https://github.com/sparrowwallet/hummingbird
- TXQR Repo: https://github.com/divan/txqr ; Blogquellen (Markdown): https://raw.githubusercontent.com/divan/blog/master/content/posts/181118_animated_qr.md ; https://raw.githubusercontent.com/divan/blog/master/content/posts/181201_fountain_codes_txqr.md (publiziert unter https://divan.dev/posts/animatedqr/ und https://divan.dev/posts/fountaincodes/)
- qifi-dev/qrs: https://github.com/qifi-dev/qrs ; libcimbar: https://github.com/sz3/libcimbar ; qrcp: https://github.com/claudiodangelis/qrcp ; qr-filetransfer: https://github.com/sdushantha/qr-filetransfer
- Google Nearby (Medium-Tabelle, iOS = Wi-Fi LAN): https://raw.githubusercontent.com/google/nearby/main/connections/README.md ; UKEY2: https://github.com/google/ukey2 ; Flutter nearby_connections: https://pub.dev/packages/nearby_connections
- Apple Wi-Fi Aware: https://developer.apple.com/documentation/wifiaware ; Sample "Building peer-to-peer apps": https://developer.apple.com/documentation/wifiaware/building-peer-to-peer-apps ; WACapabilities: https://developer.apple.com/documentation/wifiaware/wacapabilities ; WWDC25 Session 228: https://developer.apple.com/videos/play/wwdc2025/228/ ; DeviceDiscoveryUI: https://developer.apple.com/documentation/devicediscoveryui
- Apple Multipeer Connectivity (deprecated): https://developer.apple.com/documentation/multipeerconnectivity ; TN3213: https://developer.apple.com/documentation/technotes/tn3213-moving-from-multipeer-connectivity-to-network-framework ; includePeerToPeer: https://developer.apple.com/documentation/network/nwparameters/includepeertopeer
- Apple NEHotspotConfigurationManager: https://developer.apple.com/documentation/networkextension/nehotspotconfigurationmanager ; CBL2CAPChannel: https://developer.apple.com/documentation/corebluetooth/cbl2capchannel ; CBPeripheralManager: https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager ; kAudioFormatOpus: https://developer.apple.com/documentation/coreaudiotypes/kaudioformatopus ; UIDocumentPickerViewController: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller ; WWDC19 Core Bluetooth: https://developer.apple.com/videos/play/wwdc2019/901/
- Android Wi-Fi Aware: https://developer.android.com/develop/connectivity/wifi/wifi-aware ; AwarePairingConfig (API 34, Quelle AOSP-Spiegel): https://raw.githubusercontent.com/Reginer/aosp-android-jar/main/android-34/src/android/net/wifi/aware/AwarePairingConfig.java ; Wi-Fi Direct: https://developer.android.com/develop/connectivity/wifi/wifip2p ; startLocalOnlyHotspot: https://developer.android.com/reference/android/net/wifi/WifiManager#startLocalOnlyHotspot(android.net.wifi.WifiManager.LocalOnlyHotspotCallback,%20android.os.Handler) ; SAF: https://developer.android.com/training/data-storage/shared/documents-files ; Medienformate (Opus-Encoder ab Android 10): https://developer.android.com/media/platform/supported-formats ; Android 16 Features: https://developer.android.com/about/versions/16/features
- Signal iOS (MCSession + Zertifikat-Hash aus QR): https://github.com/signalapp/Signal-iOS/blob/main/Signal/DeviceTransfer/MultiPeerConnectivity/MPCDeviceTransferSession.swift ; Signal Android Wi-Fi Direct: https://github.com/signalapp/Signal-Android/blob/main/lib/device-transfer/src/main/java/org/signal/devicetransfer/WifiDirect.java
- LocalSend Protokoll: https://github.com/localsend/protocol ; App: https://github.com/localsend/localsend ; PairDrop: https://github.com/schlagmichdoch/PairDrop ; Magic Wormhole (PAKE-Muster): https://github.com/magic-wormhole/magic-wormhole
- Quick Share ↔ AirDrop: The Hacker News 21.11.2025 (Spiegel): https://raw.githubusercontent.com/mthcht/ThreatIntel-Reports/main/Intel%20Reports/thehackernews_com/2025_11_google-adds-airdrop-compatibility-to_html/content.txt ; Google Security Blog: https://security.googleblog.com/2025/11/android-quick-share-support-for-airdrop-security.html ; Google Blog: https://blog.google/products/android/quick-share-airdrop/ ; BleepingComputer: https://www.bleepingcomputer.com/news/mobile/google-enables-pixel-to-iphone-file-sharing-via-quick-share-airdrop/ ; Ars Technica 25.11.2025: https://arstechnica.com/gadgets/2025/11/the-eu-made-apple-adopt-new-wi-fi-standards-and-now-android-can-support-airdrop/ ; 9to5Google 22.03.2026 (Galaxy S26): http://9to5google.com/2026/03/22/samsung-galaxy-s26-airdrop-quick-share/ ; Android Police (One UI 8.5): https://www.androidpolice.com/samsung-galaxy-airdrop-iphone-one-ui-8-5-beta-quick-share/ ; Google Support Quick Share: https://support.google.com/android/answer/9286773
- BLE-Durchsatz: MeshLink-Messungen 2026: https://github.com/trancee/MeshLink/blob/main/specs/ble-mesh-sdk/research.md ; Nordic Throughput-Sample: https://github.com/nrfconnect/sdk-nrf/blob/main/samples/bluetooth/throughput/README.rst ; ESP-IDF BLE-Throughput: https://github.com/espressif/esp-idf/tree/master/examples/bluetooth/bluedroid/ble/ble_throughput ; Sekundärzusammenfassung WWDC17-Zahlen: https://github.com/hayden1126/apocalypto/blob/main/docs/research/2026-07-07-offline-apocalypse-nav-research.md
- Krypto/Container: age-Spec: https://github.com/C2SP/C2SP/blob/main/age.md ; libsodium secretstream: https://github.com/jedisct1/libsodium-doc/blob/master/secret-key_cryptography/secretstream.md ; Noise-Spec (PSK-Modifier): https://github.com/noiseprotocol/noise_spec/blob/master/noise.md ; 7z Methods: https://raw.githubusercontent.com/ip7z/7zip/main/DOC/Methods.txt ; 7zAes.cpp: https://raw.githubusercontent.com/ip7z/7zip/main/CPP/7zip/Crypto/7zAes.cpp
- Kompression/Codec: zstd README (Silesia-Benchmark): https://github.com/facebook/zstd ; Opus `opus_defines.h`: https://github.com/xiph/opus/blob/main/include/opus_defines.h ; opusenc-Manpage: https://raw.githubusercontent.com/xiph/opus-tools/master/man/opusenc.1 ; RFC 7587 (nicht abrufbar, zu verifizieren): https://www.rfc-editor.org/rfc/rfc7587.html
