import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as c;
import 'package:meta/meta.dart';

import 'zeroize.dart';

/// Ein X25519-Schlüsselpaar für den Gerätewechsel (D6). Der private Schlüssel
/// lebt nur so lange wie die Übertragungssitzung; Aufrufer nullen ihn mit
/// [dispose], sobald der Container importiert ist.
@immutable
class X25519KeyPair {
  const X25519KeyPair({required this.privateKey, required this.publicKey})
    : assert(privateKey.length == 32),
      assert(publicKey.length == 32);

  final Uint8List privateKey;
  final Uint8List publicKey;

  /// Nullt den privaten Schlüssel (Speicherhygiene, docs/05).
  void dispose() => zeroize(privateKey);
}

/// X25519-Schlüsselvereinbarung (RFC 7748) in reinem Dart über
/// `package:cryptography`. Auf den Zielplattformen kann libsodium
/// (`crypto_scalarmult`) dieselbe Funktion erfüllen; die Ergebnisse sind
/// identisch.
class X25519KeyAgreement {
  const X25519KeyAgreement();

  static const int keyLength = 32;

  /// Erzeugt ein zufälliges Schlüsselpaar.
  Future<X25519KeyPair> newKeyPair() async {
    final pair = await c.X25519().newKeyPair();
    return _toKeyPair(pair);
  }

  /// Leitet das Schlüsselpaar deterministisch aus einem 32-Byte-Seed ab
  /// (zum Wiederherstellen einer gespeicherten Sitzung und für Testvektoren).
  Future<X25519KeyPair> keyPairFromSeed(Uint8List seed) async {
    if (seed.length != keyLength) {
      throw ArgumentError.value(seed.length, 'seed', 'erwartet 32 Byte');
    }
    final pair = await c.X25519().newKeyPairFromSeed(seed);
    return _toKeyPair(pair);
  }

  /// Gemeinsames Geheimnis aus eigenem privatem und fremdem öffentlichem
  /// Schlüssel (32 Byte, roh; immer durch HKDF weiterverarbeiten).
  Future<Uint8List> sharedSecret({
    required Uint8List privateKey,
    required Uint8List remotePublicKey,
  }) async {
    if (privateKey.length != keyLength || remotePublicKey.length != keyLength) {
      throw ArgumentError('X25519-Schlüssel müssen 32 Byte haben');
    }
    final algorithm = c.X25519();
    final own = await algorithm.newKeyPairFromSeed(privateKey);
    final secret = await algorithm.sharedSecretKey(
      keyPair: own,
      remotePublicKey: c.SimplePublicKey(
        remotePublicKey,
        type: c.KeyPairType.x25519,
      ),
    );
    return Uint8List.fromList(await secret.extractBytes());
  }

  static Future<X25519KeyPair> _toKeyPair(c.SimpleKeyPair pair) async {
    final data = await pair.extract();
    final public = await pair.extractPublicKey();
    return X25519KeyPair(
      privateKey: Uint8List.fromList(data.bytes),
      publicKey: Uint8List.fromList(public.bytes),
    );
  }
}
