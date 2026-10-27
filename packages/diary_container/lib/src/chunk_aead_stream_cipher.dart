import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';

import 'stream_cipher.dart';
import 'u64.dart';

/// Referenzumsetzung der Stromverschlüsselung ohne libsodium
/// ([ContainerCipher.chunkAeadXchacha20], Kennung 2): eine Folge von
/// Nachrichten, jede mit XChaCha20-Poly1305 aus `diary_crypto` gesichert.
///
/// Byte-Layout einer gesicherten Nachricht: `tag u8 | ciphertext | mac(16)`.
/// `tag` ist 0 für eine Zwischen- und 1 für die letzte Nachricht.
///
/// * Nonce (24 Byte) = Strom-Header XOR Zähler, wobei der Zähler als
///   64-Bit-Zahl (Big Endian) in die letzten 8 Byte eingeht; der Strom-Header
///   ist zufällig und steht im Klartext-Kopf des Containers.
/// * Zusatzdaten (AAD) = Container-Kopf-Bytes || Zähler (u64 BE) || tag.
///
/// Damit scheitern Umsortieren (Zähler), Entfernen (Zähler springt),
/// Verändern (Auth-Tag), Vertauschen zwischen Containern (Kopf in der AAD)
/// und Abschneiden (die letzte Nachricht fehlt oder trägt kein Final-Tag).
/// Das entspricht dem Sicherheitsmodell von libsodium secretstream; der
/// Unterschied ist, dass secretstream den Schlüssel nach jeder Nachricht
/// weiterdreht (Rekeying), was hier bei einem einmal verwendeten
/// Containerschlüssel keinen zusätzlichen Schutz bringt.
class ChunkAeadStreamCipherFactory implements ContainerStreamCipherFactory {
  ChunkAeadStreamCipherFactory({Aead? aead, RandomSource? random})
    : _aead = aead ?? CryptographyAead.xchacha20Poly1305(),
      _random = random ?? SecureRandomSource() {
    if (_aead.id != AeadId.xchacha20Poly1305) {
      throw ArgumentError('Der Container-Strom verwendet XChaCha20-Poly1305');
    }
  }

  static const int headerLength = 24;
  static const int tagIntermediate = 0;
  static const int tagFinal = 1;

  final Aead _aead;
  final RandomSource _random;

  @override
  Future<ContainerStreamCipher> encryptor(Uint8List key) async {
    _checkKey(key);
    return _Encryptor(_aead, key, _random.bytes(headerLength));
  }

  @override
  Future<ContainerStreamDecipher> decryptor(
    Uint8List key,
    Uint8List header,
  ) async {
    _checkKey(key);
    if (header.length != headerLength) {
      throw const FormatException('Strom-Header muss 24 Byte haben');
    }
    return _Decryptor(_aead, key, header);
  }

  void _checkKey(Uint8List key) {
    if (key.length != _aead.id.keyLength) {
      throw ArgumentError.value(key.length, 'key', 'erwartet 32 Byte');
    }
  }

  static Uint8List nonceFor(Uint8List header, int counter) {
    final nonce = Uint8List.fromList(header);
    U64.xorInto(nonce, headerLength - 8, counter);
    return nonce;
  }

  static Uint8List aadFor(Uint8List? aad, int counter, int tag) =>
      Uint8List.fromList([...?aad, ...U64.encode(counter), tag]);
}

class _Encryptor implements ContainerStreamCipher {
  _Encryptor(this._aead, this._key, this.header);

  final Aead _aead;
  final Uint8List _key;
  @override
  final Uint8List header;
  int _counter = 0;
  bool _finished = false;

  @override
  Future<Uint8List> push(
    Uint8List message, {
    required bool isFinal,
    Uint8List? aad,
  }) async {
    if (_finished) {
      throw StateError('Strom ist abgeschlossen');
    }
    final tag = isFinal
        ? ChunkAeadStreamCipherFactory.tagFinal
        : ChunkAeadStreamCipherFactory.tagIntermediate;
    final sealed = await _aead.seal(
      key: _key,
      nonce: ChunkAeadStreamCipherFactory.nonceFor(header, _counter),
      plaintext: message,
      aad: ChunkAeadStreamCipherFactory.aadFor(aad, _counter, tag),
    );
    _counter++;
    if (isFinal) _finished = true;
    return Uint8List.fromList([tag, ...sealed]);
  }
}

class _Decryptor implements ContainerStreamDecipher {
  _Decryptor(this._aead, this._key, this._header);

  final Aead _aead;
  final Uint8List _key;
  final Uint8List _header;
  int _counter = 0;
  bool _finished = false;

  @override
  Future<(Uint8List, bool)> pull(Uint8List sealed, {Uint8List? aad}) async {
    if (_finished) {
      throw const AuthenticationException(
        'Daten nach der letzten Nachricht des Stroms',
      );
    }
    if (sealed.length < 1 + _aead.id.tagLength) {
      throw const AuthenticationException('Nachricht zu kurz');
    }
    final tag = sealed[0];
    if (tag != ChunkAeadStreamCipherFactory.tagIntermediate &&
        tag != ChunkAeadStreamCipherFactory.tagFinal) {
      throw const AuthenticationException('Unbekanntes Nachrichten-Tag');
    }
    final clear = await _aead.open(
      key: _key,
      nonce: ChunkAeadStreamCipherFactory.nonceFor(_header, _counter),
      sealed: Uint8List.sublistView(sealed, 1),
      aad: ChunkAeadStreamCipherFactory.aadFor(aad, _counter, tag),
    );
    _counter++;
    final isFinal = tag == ChunkAeadStreamCipherFactory.tagFinal;
    if (isFinal) _finished = true;
    return (clear, isFinal);
  }
}
