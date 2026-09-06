import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as c;
import 'package:meta/meta.dart';

/// Parameter für Passphrasen (nur Export und Wiederherstellung, D5/D6).
/// Standard: 64 MiB, t = 3, p = 1, Salt 16 Byte. Die Parameter stehen im
/// Container-Kopf, damit spätere Anpassungen alte Dateien nicht brechen.
@immutable
class Argon2Params {
  const Argon2Params({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    this.saltLength = 16,
    this.hashLength = 32,
  });

  /// Empfehlung aus docs/05 (Mobile-RAM-Budget).
  static const standard = Argon2Params(
    memoryKiB: 65536,
    iterations: 3,
    parallelism: 1,
  );

  /// Nur für Tests: schnell, unsicher.
  static const testing = Argon2Params(
    memoryKiB: 64,
    iterations: 1,
    parallelism: 1,
  );

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final int saltLength;
  final int hashLength;
}

/// Schlüsselableitung aus einer Passphrase.
abstract interface class PassphraseKdf {
  Future<Uint8List> derive({
    required String passphrase,
    required Uint8List salt,
    required Argon2Params params,
  });
}

/// Argon2id in reinem Dart (`package:cryptography`). Auf Mobilgeräten ist die
/// libsodium-Variante deutlich schneller; die Ergebnisse sind identisch.
class Argon2idKdf implements PassphraseKdf {
  const Argon2idKdf();

  @override
  Future<Uint8List> derive({
    required String passphrase,
    required Uint8List salt,
    required Argon2Params params,
  }) async {
    if (salt.length != params.saltLength) {
      throw ArgumentError.value(
        salt.length,
        'salt',
        'erwartet ${params.saltLength} Byte',
      );
    }
    final algorithm = c.Argon2id(
      memory: params.memoryKiB,
      parallelism: params.parallelism,
      iterations: params.iterations,
      hashLength: params.hashLength,
    );
    final key = await algorithm.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    return Uint8List.fromList(await key.extractBytes());
  }
}
