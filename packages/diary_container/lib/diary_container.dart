/// Export- und Transfer-Container (D6): "QR + Datei" für den Gerätewechsel
/// und dieselbe Datei mit Passphrase als Offline-Backup.
///
/// Dieses Paket enthält die plattformunabhängigen Teile: Kopf-Codec,
/// QR-Nutzlast, Manifest, Rahmung der Nutzdaten, Schlüsselableitung
/// ([ContainerKeys]: Argon2id für Backups, X25519/HKDF für den
/// Gerätewechsel) sowie [ContainerWriter]/[ContainerReader] für den
/// verschlüsselten Strom. Die Verschlüsselung des Stroms ist eine
/// Schnittstelle ([ContainerStreamCipher]) mit der Referenz
/// [ChunkAeadStreamCipherFactory] (Kopf-Kennung 2, XChaCha20-Poly1305 aus
/// `diary_crypto`, ohne libsodium); libsodium secretstream (Kennung 1) kann
/// in Spike S5 nachgerüstet werden, die Kopf-Kennung `cipher` hält beide
/// Wege auseinander. Format siehe README.md.
library;

export 'src/chunk_aead_stream_cipher.dart';
export 'src/container_io.dart';
export 'src/container_keys.dart';
export 'src/framing.dart';
export 'src/header.dart';
export 'src/manifest.dart';
export 'src/qr_payload.dart';
export 'src/stream_cipher.dart';
