import 'dart:typed_data';

import 'aead.dart';
import 'random.dart';

/// Envelope-Verschlüsselung (D5): Ein Datei- oder Datenbankschlüssel wird mit
/// dem Master-Key verschlüsselt ("gewrappt") abgelegt. Layout des Blobs:
/// `nonce || ciphertext || tag`. Die Zusatzdaten (`purpose`) binden den Blob an
/// seinen Verwendungszweck, damit ein DB-Schlüssel nicht als Dateischlüssel
/// missbraucht werden kann.
class KeyWrap {
  KeyWrap(this._aead, this._random);

  final Aead _aead;
  final RandomSource _random;

  Future<Uint8List> wrap({
    required Uint8List masterKey,
    required Uint8List key,
    required String purpose,
  }) async {
    final nonce = _random.bytes(_aead.id.nonceLength);
    final sealed = await _aead.seal(
      key: masterKey,
      nonce: nonce,
      plaintext: key,
      aad: Uint8List.fromList(purpose.codeUnits),
    );
    return Uint8List.fromList([...nonce, ...sealed]);
  }

  Future<Uint8List> unwrap({
    required Uint8List masterKey,
    required Uint8List wrapped,
    required String purpose,
  }) {
    final n = _aead.id.nonceLength;
    if (wrapped.length <= n) {
      throw const AuthenticationException('Gewrappter Schlüssel zu kurz');
    }
    return _aead.open(
      key: masterKey,
      nonce: Uint8List.sublistView(wrapped, 0, n),
      sealed: Uint8List.sublistView(wrapped, n),
      aad: Uint8List.fromList(purpose.codeUnits),
    );
  }
}
