import 'dart:typed_data';

/// Kennung der AEAD-Primitive, wie sie in Dateiköpfen gespeichert wird (D4).
enum AeadId {
  /// XChaCha20-Poly1305 (IETF-Variante, 24-Byte-Nonce, 16-Byte-Tag). Referenz.
  xchacha20Poly1305(1, keyLength: 32, nonceLength: 24, tagLength: 16),

  /// AES-256-GCM (12-Byte-Nonce, 16-Byte-Tag). Option, wenn Plattform-Primitive
  /// im Player messbar schneller sind.
  aes256Gcm(2, keyLength: 32, nonceLength: 12, tagLength: 16);

  const AeadId(
    this.code, {
    required this.keyLength,
    required this.nonceLength,
    required this.tagLength,
  });

  /// Byte-Kennung im Dateikopf.
  final int code;
  final int keyLength;
  final int nonceLength;
  final int tagLength;

  static AeadId fromCode(int code) => values.firstWhere(
        (v) => v.code == code,
        orElse: () => throw FormatException('Unbekannte AEAD-Kennung: $code'),
      );
}

/// Wird geworfen, wenn ein Auth-Tag nicht stimmt (manipuliert, falscher
/// Schlüssel, falsche Zusatzdaten). Der Klartext wird in diesem Fall nie
/// herausgegeben.
class AuthenticationException implements Exception {
  const AuthenticationException([this.message = 'Authentifizierung fehlgeschlagen']);
  final String message;

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Authenticated Encryption with Associated Data.
///
/// `seal` liefert Chiffrat gefolgt vom Auth-Tag (`ciphertext || tag`);
/// `open` erwartet dasselbe Layout. Nonces werden vom Aufrufer verwaltet
/// (siehe `RandomSource`), damit Dateiformate sie selbst ablegen können.
abstract interface class Aead {
  AeadId get id;

  Future<Uint8List> seal({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List plaintext,
    Uint8List? aad,
  });

  /// Wirft [AuthenticationException], wenn Tag oder Zusatzdaten nicht passen.
  Future<Uint8List> open({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List sealed,
    Uint8List? aad,
  });
}
