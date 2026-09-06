import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as c;

/// HKDF-SHA-256 (RFC 5869) für die Ableitung von Container-Schlüsseln aus dem
/// X25519-Geheimnis beim Gerätewechsel (D6).
class HkdfSha256 {
  const HkdfSha256();

  Future<Uint8List> derive({
    required Uint8List inputKeyMaterial,
    required Uint8List salt,
    required String info,
    int length = 32,
  }) async {
    final hkdf = c.Hkdf(hmac: c.Hmac.sha256(), outputLength: length);
    final key = await hkdf.deriveKey(
      secretKey: c.SecretKey(inputKeyMaterial),
      nonce: salt,
      info: info.codeUnits,
    );
    return Uint8List.fromList(await key.extractBytes());
  }
}
