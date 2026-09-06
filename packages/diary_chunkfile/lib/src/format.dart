import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';

import 'exceptions.dart';

/// Konstanten des Dateiformats `TGBC` Version 1 (siehe README, Abschnitt
/// "Byte-Layout").
abstract final class ChunkFileFormat {
  /// Magic-Bytes am Dateianfang: ASCII `TGBC`.
  static const List<int> magic = [0x54, 0x47, 0x42, 0x43];

  /// Formatversion, die dieses Paket schreibt und liest.
  static const int version = 1;

  /// Länge der zufälligen Kopf-Nonce in Byte.
  static const int headerNonceLength = 16;

  /// Länge des Kopf-Präfixes (Magic, Version, AEAD-Kennung, Chunk-Größe,
  /// Kopf-Nonce). Das Präfix ist Teil der Zusatzdaten (AAD) jedes Chunks.
  static const int prefixLength = 4 + 1 + 1 + 4 + headerNonceLength;

  /// Länge des festen Kopfteils bis einschließlich des u16-Längenfelds des
  /// gewrappten Schlüssels.
  static const int fixedHeaderLength = prefixLength + 2;

  /// Länge des Feldes mit der Gesamtlänge des Klartexts (u64 BE).
  static const int lengthFieldLength = 8;

  /// Länge des Dateischlüssels (DEK) in Byte.
  static const int fileKeyLength = 32;

  /// Verwendungszweck (AAD) beim Wrappen des Dateischlüssels mit `KeyWrap`.
  static const String keyWrapPurpose = 'chunkfile-v1';

  /// Standard-Nutzlast pro Chunk (32 KiB, docs/04 Abschnitt 5.1).
  static const int defaultChunkSize = 32768;

  /// Obergrenze der Chunk-Größe. Schützt den Leser vor absurden Zuteilungen
  /// aus einem manipulierten Kopf, bevor der erste Chunk authentifiziert ist.
  static const int maxChunkSize = 1 << 24;

  /// Länge der Zusatzdaten je Chunk: Kopf-Präfix, Index (u64 BE), isLast (u8).
  static const int aadLength = prefixLength + 8 + 1;

  /// Länge des gewrappten Dateischlüssels für eine AEAD-Primitive
  /// (`wrapNonce || Chiffrat(32) || Tag`).
  static int wrappedKeyLength(AeadId id) =>
      id.nonceLength + fileKeyLength + id.tagLength;

  /// Gesamtlänge des Kopfes für eine AEAD-Primitive.
  static int headerLength(AeadId id) =>
      fixedHeaderLength + wrappedKeyLength(id) + lengthFieldLength;

  /// Bytes je Datensatz, die keine Nutzlast sind (Chunk-Nonce und Tag).
  static int recordOverhead(AeadId id) => id.nonceLength + id.tagLength;
}

/// Geparster oder zu schreibender Dateikopf.
///
/// [plaintextLength] ist `null`, wenn der Kopf den Marker "unbekannt"
/// (acht Bytes 0xFF) trägt, z. B. bei einer laufenden Aufnahme oder wenn
/// die Senke kein nachträgliches Schreiben erlaubt.
final class ChunkFileHeader {
  ChunkFileHeader({
    required this.aeadId,
    required this.chunkSize,
    required Uint8List headerNonce,
    required Uint8List wrappedFileKey,
    this.plaintextLength,
  }) : headerNonce = Uint8List.fromList(headerNonce),
       wrappedFileKey = Uint8List.fromList(wrappedFileKey) {
    if (headerNonce.length != ChunkFileFormat.headerNonceLength) {
      throw ArgumentError.value(
        headerNonce.length,
        'headerNonce',
        'erwartet ${ChunkFileFormat.headerNonceLength} Byte',
      );
    }
    if (wrappedFileKey.length != ChunkFileFormat.wrappedKeyLength(aeadId)) {
      throw ArgumentError.value(
        wrappedFileKey.length,
        'wrappedFileKey',
        'erwartet ${ChunkFileFormat.wrappedKeyLength(aeadId)} Byte',
      );
    }
    if (chunkSize < 1 || chunkSize > ChunkFileFormat.maxChunkSize) {
      throw ArgumentError.value(
        chunkSize,
        'chunkSize',
        'erwartet 1 bis ${ChunkFileFormat.maxChunkSize}',
      );
    }
    final length = plaintextLength;
    if (length != null && length < 0) {
      throw ArgumentError.value(length, 'plaintextLength', 'negativ');
    }
    prefix = _encodePrefix();
  }

  /// AEAD-Primitive für Dateischlüssel-Wrapping und Chunks.
  final AeadId aeadId;

  /// Nutzlast je Chunk (alle Chunks außer dem letzten sind genau so groß).
  final int chunkSize;

  /// Zufällige Kopf-Nonce; bindet über die AAD jeden Chunk an diese Datei.
  final Uint8List headerNonce;

  /// Mit dem Master-Key gewrappter Dateischlüssel (`KeyWrap`-Blob).
  final Uint8List wrappedFileKey;

  /// Gesamtlänge des Klartexts oder `null` für "unbekannt".
  final int? plaintextLength;

  /// Kopf-Präfix (erste [ChunkFileFormat.prefixLength] Bytes des Kopfes).
  late final Uint8List prefix;

  /// Gesamtlänge des Kopfes in Byte.
  int get length =>
      ChunkFileFormat.fixedHeaderLength +
      wrappedFileKey.length +
      ChunkFileFormat.lengthFieldLength;

  /// Byte-Offset des Längenfelds (die letzten acht Bytes des Kopfes).
  int get lengthFieldOffset => length - ChunkFileFormat.lengthFieldLength;

  /// Nonce- und Tag-Bytes je Datensatz.
  int get recordOverhead => ChunkFileFormat.recordOverhead(aeadId);

  /// Länge eines vollständigen Datensatzes (Chunk mit voller Nutzlast).
  int get recordLength => recordOverhead + chunkSize;

  /// Byte-Offset des Datensatzes für Chunk [index] in der Datei.
  int chunkOffset(int index) => length + index * recordLength;

  /// Zusatzdaten (AAD) für Chunk [index]:
  /// `prefix || index als u64 BE || (isLast ? 1 : 0) als u8`.
  Uint8List aad(int index, {required bool isLast}) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'negativ');
    }
    final out = Uint8List(ChunkFileFormat.aadLength);
    out.setAll(0, prefix);
    ByteData.sublistView(out)
        .setUint64(ChunkFileFormat.prefixLength, index, Endian.big);
    out[ChunkFileFormat.prefixLength + 8] = isLast ? 1 : 0;
    return out;
  }

  /// Vollständiger Kopf als Bytes.
  Uint8List encode() {
    final out = Uint8List(length);
    final data = ByteData.sublistView(out);
    out.setAll(0, prefix);
    data.setUint16(ChunkFileFormat.prefixLength, wrappedFileKey.length);
    out.setAll(ChunkFileFormat.fixedHeaderLength, wrappedFileKey);
    out.setAll(lengthFieldOffset, encodeLength(plaintextLength));
    return out;
  }

  Uint8List _encodePrefix() {
    final out = Uint8List(ChunkFileFormat.prefixLength);
    out.setAll(0, ChunkFileFormat.magic);
    out[4] = ChunkFileFormat.version;
    out[5] = aeadId.code;
    ByteData.sublistView(out).setUint32(6, chunkSize, Endian.big);
    out.setAll(10, headerNonce);
    return out;
  }

  /// Kodiert das Längenfeld: u64 BE oder acht Bytes 0xFF für "unbekannt".
  static Uint8List encodeLength(int? plaintextLength) {
    final out = Uint8List(ChunkFileFormat.lengthFieldLength);
    if (plaintextLength == null) {
      out.fillRange(0, out.length, 0xff);
    } else {
      if (plaintextLength < 0) {
        throw ArgumentError.value(plaintextLength, 'plaintextLength');
      }
      ByteData.sublistView(out).setUint64(0, plaintextLength, Endian.big);
    }
    return out;
  }

  /// Parst einen Kopf aus [bytes]; Bytes hinter dem Kopf werden ignoriert.
  ///
  /// Wirft [ChunkFileFormatException] bei ungültigem Inhalt und
  /// [ChunkFileTruncatedException], wenn die Magic-Bytes stimmen, der Kopf
  /// aber nicht vollständig vorliegt. Mit [expectedAeadId] wird die AEAD-
  /// Kennung geprüft, bevor weitere Bytes verlangt werden.
  static ChunkFileHeader parse(Uint8List bytes, {AeadId? expectedAeadId}) {
    if (bytes.length < ChunkFileFormat.magic.length) {
      throw const ChunkFileFormatException('Datei kürzer als die Magic-Bytes');
    }
    for (var i = 0; i < ChunkFileFormat.magic.length; i++) {
      if (bytes[i] != ChunkFileFormat.magic[i]) {
        throw const ChunkFileFormatException(
          'Magic-Bytes stimmen nicht (erwartet "TGBC")',
        );
      }
    }
    if (bytes.length < ChunkFileFormat.fixedHeaderLength) {
      throw const ChunkFileTruncatedException('Kopf unvollständig');
    }
    final data = ByteData.sublistView(bytes);
    final version = bytes[4];
    if (version != ChunkFileFormat.version) {
      throw ChunkFileFormatException('Nicht unterstützte Version $version');
    }
    final AeadId aeadId;
    try {
      aeadId = AeadId.fromCode(bytes[5]);
    } on FormatException {
      throw ChunkFileFormatException('Unbekannte AEAD-Kennung ${bytes[5]}');
    }
    if (expectedAeadId != null && aeadId != expectedAeadId) {
      throw ChunkFileFormatException(
        'AEAD-Kennung ${aeadId.name} passt nicht zur übergebenen Primitive '
        '${expectedAeadId.name}',
      );
    }
    final chunkSize = data.getUint32(6, Endian.big);
    if (chunkSize < 1 || chunkSize > ChunkFileFormat.maxChunkSize) {
      throw ChunkFileFormatException('Unplausible Chunk-Größe $chunkSize');
    }
    final wrappedLength = data.getUint16(ChunkFileFormat.prefixLength);
    if (wrappedLength != ChunkFileFormat.wrappedKeyLength(aeadId)) {
      throw ChunkFileFormatException(
        'Länge des gewrappten Schlüssels $wrappedLength passt nicht zu '
        '${aeadId.name} (erwartet ${ChunkFileFormat.wrappedKeyLength(aeadId)})',
      );
    }
    final headerLength = ChunkFileFormat.headerLength(aeadId);
    if (bytes.length < headerLength) {
      throw const ChunkFileTruncatedException('Kopf unvollständig');
    }
    final wrappedStart = ChunkFileFormat.fixedHeaderLength;
    final lengthOffset = wrappedStart + wrappedLength;
    return ChunkFileHeader(
      aeadId: aeadId,
      chunkSize: chunkSize,
      headerNonce: Uint8List.sublistView(bytes, 10, 10 + 16),
      wrappedFileKey: Uint8List.sublistView(bytes, wrappedStart, lengthOffset),
      plaintextLength: decodeLength(
        Uint8List.sublistView(bytes, lengthOffset, headerLength),
      ),
    );
  }

  /// Dekodiert das Längenfeld; acht Bytes 0xFF ergeben `null` ("unbekannt").
  static int? decodeLength(Uint8List field) {
    if (field.length != ChunkFileFormat.lengthFieldLength) {
      throw ArgumentError.value(field.length, 'field', 'erwartet 8 Byte');
    }
    if (field.every((b) => b == 0xff)) return null;
    final value = ByteData.sublistView(field).getUint64(0, Endian.big);
    if (value < 0) {
      // Werte ab 2^63 sind in Dart nicht als nicht-negative int darstellbar
      // und für Audiodateien ohnehin ausgeschlossen.
      throw const ChunkFileFormatException('Klartextlänge größer als 2^63');
    }
    return value;
  }
}
