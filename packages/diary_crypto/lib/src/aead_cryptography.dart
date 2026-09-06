import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as c;

import 'aead.dart';

/// Referenzimplementierung der AEAD-Schnittstelle mit `package:cryptography`
/// (reines Dart, plattformunabhängig, für Tests und als Rückfall).
class CryptographyAead implements Aead {
  CryptographyAead.xchacha20Poly1305()
      : id = AeadId.xchacha20Poly1305,
        _algorithm = c.Xchacha20.poly1305Aead();

  CryptographyAead.aes256Gcm()
      : id = AeadId.aes256Gcm,
        _algorithm = c.AesGcm.with256bits();

  factory CryptographyAead.forId(AeadId id) => switch (id) {
        AeadId.xchacha20Poly1305 => CryptographyAead.xchacha20Poly1305(),
        AeadId.aes256Gcm => CryptographyAead.aes256Gcm(),
      };

  @override
  final AeadId id;
  final c.Cipher _algorithm;

  void _check(Uint8List key, Uint8List nonce) {
    if (key.length != id.keyLength) {
      throw ArgumentError.value(key.length, 'key', 'erwartet ${id.keyLength} Byte');
    }
    if (nonce.length != id.nonceLength) {
      throw ArgumentError.value(nonce.length, 'nonce', 'erwartet ${id.nonceLength} Byte');
    }
  }

  @override
  Future<Uint8List> seal({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List plaintext,
    Uint8List? aad,
  }) async {
    _check(key, nonce);
    final box = await _algorithm.encrypt(
      plaintext,
      secretKey: c.SecretKey(key),
      nonce: nonce,
      aad: aad ?? const <int>[],
    );
    final out = Uint8List(box.cipherText.length + box.mac.bytes.length);
    out.setAll(0, box.cipherText);
    out.setAll(box.cipherText.length, box.mac.bytes);
    return out;
  }

  @override
  Future<Uint8List> open({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List sealed,
    Uint8List? aad,
  }) async {
    _check(key, nonce);
    if (sealed.length < id.tagLength) {
      throw const AuthenticationException('Chiffrat kürzer als der Auth-Tag');
    }
    final split = sealed.length - id.tagLength;
    final box = c.SecretBox(
      Uint8List.sublistView(sealed, 0, split),
      nonce: nonce,
      mac: c.Mac(Uint8List.sublistView(sealed, split)),
    );
    try {
      final clear = await _algorithm.decrypt(
        box,
        secretKey: c.SecretKey(key),
        aad: aad ?? const <int>[],
      );
      return Uint8List.fromList(clear);
    } on c.SecretBoxAuthenticationError {
      throw const AuthenticationException();
    }
  }
}
