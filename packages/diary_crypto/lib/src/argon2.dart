import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as c;
import 'package:meta/meta.dart';

/// Parameter für Passphrasen (Export und Wiederherstellung, D5/D6) und den
/// PIN der App-Sperre (D23). Standard: 64 MiB, t = 3, p = 1, Salt 16 Byte.
/// Die Parameter stehen im Container-Kopf bzw. beim PIN-Hash, damit spätere
/// Anpassungen alte Dateien und Hashes nicht brechen.
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

  /// App-Sperre mit PIN (D23): bewusst moderat, weil Argon2id in reinem Dart
  /// im Browser um ein Vielfaches langsamer ist als nativ und eine Prüfung
  /// höchstens rund eine Sekunde dauern soll (dart2js `-O4` auf dem
  /// Entwicklungsrechner: 0,27 s; Telefon drei- bis fünfmal langsamer).
  /// Ein vier- bis achtstelliger PIN bleibt mit jedem Parametersatz offline
  /// ratbar; der Hash verhindert nur das Auslesen im Klartext. Die Parameter
  /// stehen beim Hash, damit sie später angehoben werden können.
  static const pin = Argon2Params(
    memoryKiB: 4096,
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
