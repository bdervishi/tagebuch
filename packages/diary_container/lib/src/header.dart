import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';
import 'package:meta/meta.dart';

/// Wie der Container-Schlüssel entsteht.
enum ContainerKeyKind {
  /// Gerätewechsel: X25519 mit dem öffentlichen Schlüssel aus dem QR-Code.
  recipientX25519(1),

  /// Backup: Passphrase mit Argon2id.
  passphraseArgon2id(2);

  const ContainerKeyKind(this.code);
  final int code;

  static ContainerKeyKind fromCode(int code) => values.firstWhere(
    (v) => v.code == code,
    orElse: () => throw FormatException('Unbekannte Schlüsselart: $code'),
  );
}

/// Verschlüsselung des Nutzdatenstroms.
enum ContainerCipher {
  /// libsodium crypto_secretstream_xchacha20poly1305 (D6, Zielbild).
  secretstreamXchacha20(1),

  /// Chunk-AEAD wie in diary_chunkfile (Rückfall ohne libsodium).
  chunkAeadXchacha20(2);

  const ContainerCipher(this.code);
  final int code;

  static ContainerCipher fromCode(int code) => values.firstWhere(
    (v) => v.code == code,
    orElse: () =>
        throw FormatException('Unbekannte Stromverschlüsselung: $code'),
  );
}

/// Kopf des Containers (Klartext, aber als Zusatzdaten authentifiziert).
///
/// Layout: Magic `TGBX` (4) | Version u8 | Schlüsselart u8 | Cipher u8 |
/// Sitzungs-ID (16) | Schlüsselblock | Strom-Header-Länge u8 | Strom-Header.
/// Schlüsselblock je Art: X25519 = ephemerer öffentlicher Schlüssel (32);
/// Passphrase = Salt (16) | memoryKiB u32 | iterations u8 | parallelism u8.
@immutable
class ContainerHeader {
  const ContainerHeader({
    required this.keyKind,
    required this.cipher,
    required this.sessionId,
    required this.streamHeader,
    this.ephemeralPublicKey,
    this.salt,
    this.argon2Params,
    this.version = 1,
  }) : assert(sessionId.length == 16),
       assert(
         keyKind != ContainerKeyKind.recipientX25519 ||
             ephemeralPublicKey != null,
       ),
       assert(
         keyKind != ContainerKeyKind.passphraseArgon2id ||
             (salt != null && argon2Params != null),
       );

  static const magic = [0x54, 0x47, 0x42, 0x58]; // TGBX
  static const currentVersion = 1;

  final int version;
  final ContainerKeyKind keyKind;
  final ContainerCipher cipher;
  final Uint8List sessionId;
  final Uint8List? ephemeralPublicKey;
  final Uint8List? salt;
  final Argon2Params? argon2Params;

  /// Kopfdaten des Stromverfahrens (secretstream: 24 Byte).
  final Uint8List streamHeader;

  Uint8List encode() {
    final b = BytesBuilder(copy: false)
      ..add(magic)
      ..addByte(version)
      ..addByte(keyKind.code)
      ..addByte(cipher.code)
      ..add(sessionId);
    switch (keyKind) {
      case ContainerKeyKind.recipientX25519:
        if (ephemeralPublicKey!.length != 32) {
          throw const FormatException('X25519-Schlüssel muss 32 Byte haben');
        }
        b.add(ephemeralPublicKey!);
      case ContainerKeyKind.passphraseArgon2id:
        final p = argon2Params!;
        if (salt!.length != p.saltLength) {
          throw const FormatException(
            'Salt-Länge passt nicht zu den Parametern',
          );
        }
        b
          ..addByte(salt!.length)
          ..add(salt!)
          ..add(_u32(p.memoryKiB))
          ..addByte(p.iterations)
          ..addByte(p.parallelism);
    }
    if (streamHeader.length > 255) {
      throw const FormatException('Strom-Header zu lang');
    }
    b
      ..addByte(streamHeader.length)
      ..add(streamHeader);
    return b.toBytes();
  }

  /// Liest den Kopf; liefert Kopf und die Anzahl verbrauchter Bytes.
  static (ContainerHeader, int) decode(Uint8List bytes) {
    final r = _Reader(bytes);
    for (final m in magic) {
      if (r.u8() != m) {
        throw const FormatException('Kein Tagebuch-Container (Magic)');
      }
    }
    final version = r.u8();
    if (version != currentVersion) {
      throw FormatException(
        'Container-Version $version wird nicht unterstützt (erwartet $currentVersion)',
      );
    }
    final kind = ContainerKeyKind.fromCode(r.u8());
    final cipher = ContainerCipher.fromCode(r.u8());
    final sessionId = r.bytes(16);
    Uint8List? pk;
    Uint8List? salt;
    Argon2Params? params;
    switch (kind) {
      case ContainerKeyKind.recipientX25519:
        pk = r.bytes(32);
      case ContainerKeyKind.passphraseArgon2id:
        final saltLen = r.u8();
        salt = r.bytes(saltLen);
        params = Argon2Params(
          memoryKiB: r.u32(),
          iterations: r.u8(),
          parallelism: r.u8(),
          saltLength: saltLen,
        );
    }
    final shLen = r.u8();
    final sh = r.bytes(shLen);
    return (
      ContainerHeader(
        version: version,
        keyKind: kind,
        cipher: cipher,
        sessionId: sessionId,
        ephemeralPublicKey: pk,
        salt: salt,
        argon2Params: params,
        streamHeader: sh,
      ),
      r.offset,
    );
  }

  static Uint8List _u32(int v) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, v);
}

class _Reader {
  _Reader(this._b);
  final Uint8List _b;
  int offset = 0;

  int u8() {
    if (offset >= _b.length) {
      throw const FormatException('Container-Kopf unvollständig');
    }
    return _b[offset++];
  }

  int u32() {
    final v = Uint8List.fromList(bytes(4)).buffer.asByteData().getUint32(0);
    return v;
  }

  Uint8List bytes(int n) {
    if (offset + n > _b.length) {
      throw const FormatException('Container-Kopf unvollständig');
    }
    final out = Uint8List.sublistView(_b, offset, offset + n);
    offset += n;
    return out;
  }
}
