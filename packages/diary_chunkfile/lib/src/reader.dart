import 'dart:math' as math;
import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';

import 'exceptions.dart';
import 'format.dart';
import 'source.dart';

/// Liest eine Chunk-Datei (Format `TGBC` Version 1) mit wahlfreiem Zugriff.
///
/// [open] liest nur den Kopf (und bei unbekannter Länge zusätzlich den letzten
/// Datensatz), entpackt den Dateischlüssel und prüft die Struktur. Danach
/// liest [readChunk] genau einen Datensatz, ohne vorhergehende Chunks zu
/// berühren; [readRange] fasst die betroffenen Chunks zusammen.
///
/// Fehler: [ChunkFileFormatException] (Kopf/Struktur),
/// [ChunkFileTruncatedException] (Datei endet zu früh) und
/// [AuthenticationException] aus `diary_crypto` (verändertes Byte, vertauschter
/// Chunk, Chunk aus anderer Datei, falscher Master-Key).
class ChunkFileReader {
  ChunkFileReader._(
    this._source,
    this._aead,
    this._fileKey,
    this.header, {
    required this.chunkCount,
    required this.plaintextLength,
    required this.isTruncated,
  });

  /// Öffnet eine Datei. [aead] muss zur AEAD-Kennung im Kopf passen; [keyWrap]
  /// entpackt den Dateischlüssel mit [masterKey].
  ///
  /// Standardmäßig wird eine abgeschnittene Datei mit
  /// [ChunkFileTruncatedException] abgewiesen. Mit [allowTruncated] wird sie
  /// stattdessen geöffnet, [isTruncated] ist `true`, und [chunkCount] sowie
  /// [plaintextLength] beschreiben nur die vollständig vorhandenen Chunks
  /// (Wiederherstellung nach App-Abbruch während der Aufnahme).
  static Future<ChunkFileReader> open(
    RandomAccessSource source, {
    required Aead aead,
    required KeyWrap keyWrap,
    required Uint8List masterKey,
    bool allowTruncated = false,
  }) async {
    final total = source.length;
    final headerBytes = await source.read(
      0,
      math.min(total, ChunkFileFormat.headerLength(aead.id)),
    );
    final header = ChunkFileHeader.parse(headerBytes, expectedAeadId: aead.id);
    final fileKey = await keyWrap.unwrap(
      masterKey: masterKey,
      wrapped: header.wrappedFileKey,
      purpose: ChunkFileFormat.keyWrapPurpose,
    );
    if (fileKey.length != ChunkFileFormat.fileKeyLength) {
      zeroize(fileKey);
      throw const ChunkFileFormatException(
        'Entpackter Dateischlüssel hat nicht 32 Byte',
      );
    }
    try {
      final layout = await _layout(
        source,
        aead,
        fileKey,
        header,
        total,
        allowTruncated: allowTruncated,
      );
      return ChunkFileReader._(
        source,
        aead,
        fileKey,
        header,
        chunkCount: layout.chunkCount,
        plaintextLength: layout.plaintextLength,
        isTruncated: layout.isTruncated,
      );
    } catch (_) {
      zeroize(fileKey);
      rethrow;
    }
  }

  static Future<_Layout> _layout(
    RandomAccessSource source,
    Aead aead,
    Uint8List fileKey,
    ChunkFileHeader header,
    int total, {
    required bool allowTruncated,
  }) async {
    final body = total - header.length;
    final overhead = header.recordOverhead;
    final recordLength = header.recordLength;
    final chunkSize = header.chunkSize;
    final fullRecords = body ~/ recordLength;

    _Layout truncated(String reason) {
      if (!allowTruncated) throw ChunkFileTruncatedException(reason);
      return _Layout(
        chunkCount: fullRecords,
        plaintextLength: fullRecords * chunkSize,
        isTruncated: true,
      );
    }

    final declared = header.plaintextLength;
    if (declared != null) {
      // Länge bekannt: Die Dateigröße muss exakt zum Layout passen.
      if (declared > body) {
        return truncated('Datei kürzer als die im Kopf angegebene Länge');
      }
      final chunkCount = declared == 0
          ? 1
          : (declared + chunkSize - 1) ~/ chunkSize;
      final lastPayload = declared - (chunkCount - 1) * chunkSize;
      final expectedBody =
          (chunkCount - 1) * recordLength + overhead + lastPayload;
      if (body > expectedBody) {
        throw const ChunkFileFormatException(
          'Überzählige Bytes hinter dem letzten Chunk',
        );
      }
      if (body < expectedBody) {
        return truncated(
          'Datei endet vor dem letzten Chunk (${expectedBody - body} Byte '
          'fehlen)',
        );
      }
      return _Layout(
        chunkCount: chunkCount,
        plaintextLength: declared,
        isTruncated: false,
      );
    }

    // Länge unbekannt (Kopf nicht gepatcht): Layout aus der Dateigröße
    // ableiten und den letzten Datensatz prüfen.
    final remainder = body % recordLength;
    final candidateCount = remainder == 0 ? fullRecords : fullRecords + 1;
    if (candidateCount == 0) {
      return truncated('Datei enthält keinen Chunk');
    }
    final lastRecordLength = remainder == 0 ? recordLength : remainder;
    if (lastRecordLength < overhead) {
      return truncated('Letzter Datensatz ist unvollständig');
    }
    final lastPayload = lastRecordLength - overhead;
    if (lastPayload == 0 && candidateCount > 1) {
      // Ein Rest von genau Nonce + Tag hinter anderen Chunks ist entweder ein
      // mitten im Datensatz abgeschnittener Chunk oder ein nicht kanonischer
      // leerer letzter Chunk; beides wird als Abschneiden behandelt.
      return truncated('Letzter Datensatz ist unvollständig');
    }
    final lastIndex = candidateCount - 1;
    final record = await source.read(
      header.chunkOffset(lastIndex),
      lastRecordLength,
    );
    if (record.length != lastRecordLength) {
      return truncated('Letzter Datensatz ist unvollständig');
    }
    final nonce = Uint8List.sublistView(record, 0, aead.id.nonceLength);
    final sealed = Uint8List.sublistView(record, aead.id.nonceLength);
    try {
      await aead.open(
        key: fileKey,
        nonce: nonce,
        sealed: sealed,
        aad: header.aad(lastIndex, isLast: true),
      );
    } on AuthenticationException {
      if (lastPayload != chunkSize) {
        // Ein kürzerer Datensatz kann kein vollständiger Nicht-Letzter sein:
        // Er wurde mitten im Schreiben abgeschnitten (oder manipuliert, was
        // ohne Längenangabe nicht unterscheidbar ist).
        return truncated(
          'Letzter Datensatz ist unvollständig oder authentifiziert nicht',
        );
      }
      // Voller Datensatz ohne isLast: Entweder fehlen dahinter Chunks, oder
      // der Datensatz ist manipuliert.
      await aead.open(
        key: fileKey,
        nonce: nonce,
        sealed: sealed,
        aad: header.aad(lastIndex, isLast: false),
      );
      return truncated(
        'Letzter vorhandener Chunk trägt kein isLast; Chunks am Ende fehlen',
      );
    }
    return _Layout(
      chunkCount: candidateCount,
      plaintextLength: (candidateCount - 1) * chunkSize + lastPayload,
      isTruncated: false,
    );
  }

  final RandomAccessSource _source;
  final Aead _aead;
  final Uint8List _fileKey;
  bool _closed = false;

  /// Geparster Kopf (u. a. `chunkSize`, `headerNonce`, deklarierte Länge).
  final ChunkFileHeader header;

  /// Anzahl der lesbaren Chunks (bei [isTruncated] nur die vollständigen).
  final int chunkCount;

  /// Lesbare Klartextlänge in Byte.
  final int plaintextLength;

  /// `true`, wenn die Datei abgeschnitten ist und mit `allowTruncated`
  /// geöffnet wurde.
  final bool isTruncated;

  /// Nutzlast je Chunk.
  int get chunkSize => header.chunkSize;

  /// Byte-Offset des Datensatzes für Chunk [index].
  int chunkOffset(int index) => header.chunkOffset(index);

  /// Nutzlast von Chunk [index] in Byte.
  int chunkPayloadLength(int index) {
    RangeError.checkValidIndex(index, this, 'index', chunkCount);
    if (index < chunkCount - 1 || isTruncated) return chunkSize;
    return plaintextLength - index * chunkSize;
  }

  /// Entschlüsselt Chunk [index] und liest dafür genau einen Datensatz.
  Future<Uint8List> readChunk(int index) async {
    if (_closed) throw StateError('ChunkFileReader ist bereits geschlossen');
    RangeError.checkValidIndex(index, this, 'index', chunkCount);
    final payloadLength = chunkPayloadLength(index);
    final recordLength = header.recordOverhead + payloadLength;
    final record = await _source.read(chunkOffset(index), recordLength);
    if (record.length != recordLength) {
      throw ChunkFileTruncatedException('Datensatz $index ist unvollständig');
    }
    final nonceLength = _aead.id.nonceLength;
    final nonce = Uint8List.sublistView(record, 0, nonceLength);
    final sealed = Uint8List.sublistView(record, nonceLength);
    final isLast = index == chunkCount - 1 && !isTruncated;
    try {
      return await _aead.open(
        key: _fileKey,
        nonce: nonce,
        sealed: sealed,
        aad: header.aad(index, isLast: isLast),
      );
    } on AuthenticationException {
      if (!isLast || payloadLength != chunkSize) rethrow;
      // Der erwartete letzte Chunk authentifiziert nur ohne isLast: Die Datei
      // wurde hinter ihm abgeschnitten (und das Längenfeld angepasst).
      await _aead.open(
        key: _fileKey,
        nonce: nonce,
        sealed: sealed,
        aad: header.aad(index, isLast: false),
      );
      throw ChunkFileTruncatedException(
        'Chunk $index trägt kein isLast; Chunks am Ende fehlen',
      );
    }
  }

  /// Liest [length] Klartext-Bytes ab [offset] über beliebig viele Chunks.
  Future<Uint8List> readRange(int offset, int length) async {
    RangeError.checkValueInInterval(offset, 0, plaintextLength, 'offset');
    RangeError.checkValueInInterval(
      length,
      0,
      plaintextLength - offset,
      'length',
    );
    final out = Uint8List(length);
    if (length == 0) return out;
    final first = offset ~/ chunkSize;
    final last = (offset + length - 1) ~/ chunkSize;
    var written = 0;
    for (var index = first; index <= last; index++) {
      final chunk = await readChunk(index);
      final chunkStart = index * chunkSize;
      final from = math.max(offset, chunkStart) - chunkStart;
      final to =
          math.min(offset + length, chunkStart + chunk.length) - chunkStart;
      out.setRange(written, written + (to - from), chunk, from);
      written += to - from;
    }
    return out;
  }

  /// Liest den gesamten (lesbaren) Klartext.
  Future<Uint8List> readAll() async {
    final out = Uint8List(plaintextLength);
    var written = 0;
    for (var index = 0; index < chunkCount; index++) {
      final chunk = await readChunk(index);
      out.setAll(written, chunk);
      written += chunk.length;
    }
    return out;
  }

  /// Nullt den Dateischlüssel. Die Quelle bleibt Sache des Aufrufers.
  void close() {
    if (_closed) return;
    _closed = true;
    zeroize(_fileKey);
  }
}

final class _Layout {
  const _Layout({
    required this.chunkCount,
    required this.plaintextLength,
    required this.isTruncated,
  });

  final int chunkCount;
  final int plaintextLength;
  final bool isTruncated;
}
