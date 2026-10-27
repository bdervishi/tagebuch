/// Krypto-Kern des Sprach-Tagebuchs (separat auditierbar, D10).
///
/// Enthält nur Schnittstellen und kleine, testbare Bausteine:
/// AEAD-Primitive, Zufallsquelle, Key-Wrapping für die Envelope-Verschlüsselung,
/// HKDF und X25519 für den Gerätewechsel, SHA-256 für Manifest-Prüfsummen und die
/// Argon2id-Parameter für Backups mit Passphrase.
/// Die Referenzimplementierung nutzt `package:cryptography` (reines Dart); auf den
/// Zielplattformen kann dieselbe Schnittstelle mit libsodium oder Plattform-Primitiven
/// erfüllt werden (Spike S4, docs/04-technik-architektur.md Abschnitt 5.1).
library;

export 'src/aead.dart';
export 'src/aead_cryptography.dart';
export 'src/argon2.dart';
export 'src/hash.dart';
export 'src/hkdf.dart';
export 'src/key_wrap.dart';
export 'src/random.dart';
export 'src/x25519.dart';
export 'src/zeroize.dart';
