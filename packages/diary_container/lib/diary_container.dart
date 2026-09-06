/// Export- und Transfer-Container (D6): "QR + Datei" für den Gerätewechsel
/// und dieselbe Datei mit Passphrase als Offline-Backup.
///
/// Dieses Paket enthält die plattformunabhängigen Teile: Kopf-Codec,
/// QR-Nutzlast, Manifest und die Rahmung der Nutzdaten. Die Verschlüsselung
/// des Stroms ist eine Schnittstelle ([ContainerStreamCipher]); die
/// produktive Umsetzung mit libsodium `crypto_secretstream_xchacha20poly1305`
/// folgt in Spike S5 (Format siehe README.md). Ohne libsodium kann der
/// Container mit der Chunk-AEAD-Referenz aus `diary_chunkfile` gebaut werden,
/// falls der Spike das als gleichwertig bewertet; die Kopf-Kennung
/// `cipher` hält beide Wege auseinander.
library;

export 'src/framing.dart';
export 'src/header.dart';
export 'src/manifest.dart';
export 'src/qr_payload.dart';
export 'src/stream_cipher.dart';
