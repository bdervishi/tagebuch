import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';

import 'format.dart';
import 'sink.dart';

/// Schreibt eine Chunk-Datei (Format `TGBC` Version 1) in eine [ChunkSink].
///
/// Ablauf: Der Kopf wird beim ersten [add] oder bei [close] geschrieben, mit
/// dem Marker "unbekannt" im Längenfeld. [add] puffert bis zur Chunk-Größe
/// und schreibt volle Chunks mit `isLast = 0`; [close] schreibt den letzten
/// Chunk (`isLast = 1`, ggf. leer), patcht das Längenfeld, wenn die Senke das
/// erlaubt, schließt die Senke und nullt den Dateischlüssel.
///
/// Reihenfolge der Zufallsentnahmen (relevant für Testvektoren mit
/// `SequentialRandomSource`): Dateischlüssel (32 Byte, nur Standard-
/// Konstruktor), Kopf-Nonce (16 Byte), dann die Wrap-Nonce aus der Quelle des
/// [KeyWrap], dann je Chunk eine Nonce.
class ChunkFileWriter {
  /// Erzeugt einen zufälligen Dateischlüssel aus [random] und wrappt ihn mit
  /// [masterKey] über [keyWrap]. [keyWrap] muss dieselbe AEAD-Primitive
  /// verwenden wie [aead] (wird an der Blob-Länge geprüft).
  ChunkFileWriter(
    ChunkSink sink, {
    required Aead aead,
    required RandomSource random,
    required KeyWrap keyWrap,
    required Uint8List masterKey,
    int chunkSize = ChunkFileFormat.defaultChunkSize,
  }) : this._(
          sink,
          aead,
          random,
          keyWrap,
          masterKey,
          random.bytes(ChunkFileFormat.fileKeyLength),
          chunkSize,
        );

  /// Wie der Standard-Konstruktor, aber mit vorgegebenem Dateischlüssel
  /// (für Tests, z. B. um Chunks zwischen zwei Dateien mit gleichem Schlüssel
  /// auszutauschen). [fileKey] wird kopiert; die Kopie wird bei [close]
  /// genullt.
  ChunkFileWriter.withFileKey(
    ChunkSink sink, {
    required Aead aead,
    required RandomSource random,
    required KeyWrap keyWrap,
    required Uint8List masterKey,
    required Uint8List fileKey,
    int chunkSize = ChunkFileFormat.defaultChunkSize,
  }) : this._(sink, aead, random, keyWrap, masterKey, fileKey, chunkSize);

  ChunkFileWriter._(
    this._sink,
    this._aead,
    this._random,
    this._keyWrap,
    this._masterKey,
    Uint8List fileKey,
    this.chunkSize,
  )   : _fileKey = Uint8List.fromList(fileKey),
        _headerNonce = _random.bytes(ChunkFileFormat.headerNonceLength) {
    if (chunkSize < 1 || chunkSize > ChunkFileFormat.maxChunkSize) {
      throw ArgumentError.value(
        chunkSize,
        'chunkSize',
        'erwartet 1 bis ${ChunkFileFormat.maxChunkSize}',
      );
    }
    if (fileKey.length != ChunkFileFormat.fileKeyLength) {
      throw ArgumentError.value(
        fileKey.length,
        'fileKey',
        'erwartet ${ChunkFileFormat.fileKeyLength} Byte',
      );
    }
  }

  final ChunkSink _sink;
  final Aead _aead;
  final RandomSource _random;
  final KeyWrap _keyWrap;
  final Uint8List _masterKey;
  final Uint8List _fileKey;
  final Uint8List _headerNonce;
  final BytesBuilder _pending = BytesBuilder(copy: true);

  ChunkFileHeader? _header;
  int _chunkCount = 0;
  int _plaintextLength = 0;
  bool _busy = false;
  bool _closed = false;
  bool _lengthPatched = false;

  /// Nutzlast je Chunk.
  final int chunkSize;

  /// Bisher über [add] übergebene Bytes.
  int get plaintextLength => _plaintextLength;

  /// Bisher geschriebene Chunks (einschließlich des letzten nach [close]).
  int get chunkCount => _chunkCount;

  bool get isClosed => _closed;

  /// `true`, wenn die Senke das Längenfeld nach [close] gepatcht hat.
  bool get lengthPatched => _lengthPatched;

  /// Kopf-Nonce dieser Datei.
  Uint8List get headerNonce => Uint8List.fromList(_headerNonce);

  /// Fügt Klartext hinzu. Volle Chunks werden sofort verschlüsselt und
  /// geschrieben; der Rest bleibt bis zum nächsten [add] oder [close] im
  /// Puffer. Aufrufe dürfen sich nicht überlappen.
  Future<void> add(List<int> bytes) => _guarded(() async {
        await _ensureHeader();
        _pending.add(bytes);
        _plaintextLength += bytes.length;
        // Ein voller Chunk wird erst geschrieben, wenn danach noch Daten
        // folgen: Nur so ist bekannt, dass er nicht der letzte ist.
        if (_pending.length <= chunkSize) return;
        final data = _pending.takeBytes();
        var pos = 0;
        while (data.length - pos > chunkSize) {
          await _writeChunk(
            Uint8List.sublistView(data, pos, pos + chunkSize),
            isLast: false,
          );
          pos += chunkSize;
        }
        _pending.add(Uint8List.sublistView(data, pos));
      });

  /// Schreibt den letzten Chunk, patcht das Längenfeld, schließt die Senke
  /// und nullt den Dateischlüssel.
  Future<void> close() => _guarded(() async {
        final header = await _ensureHeader();
        try {
          await _writeChunk(_pending.takeBytes(), isLast: true);
          _lengthPatched = await _sink.patchHeaderLength(
            header.lengthFieldOffset,
            _plaintextLength,
          );
          await _sink.close();
        } finally {
          _closed = true;
          zeroize(_fileKey);
        }
      });

  Future<T> _guarded<T>(Future<T> Function() action) async {
    if (_closed) {
      throw StateError('ChunkFileWriter ist bereits geschlossen');
    }
    if (_busy) {
      throw StateError('add/close dürfen sich nicht überlappen');
    }
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  Future<ChunkFileHeader> _ensureHeader() async {
    final existing = _header;
    if (existing != null) return existing;
    final wrapped = await _keyWrap.wrap(
      masterKey: _masterKey,
      key: _fileKey,
      purpose: ChunkFileFormat.keyWrapPurpose,
    );
    if (wrapped.length != ChunkFileFormat.wrappedKeyLength(_aead.id)) {
      throw ArgumentError(
        'KeyWrap muss dieselbe AEAD-Primitive verwenden wie die Datei '
        '(${_aead.id.name}); Blob hat ${wrapped.length} Byte',
      );
    }
    final header = ChunkFileHeader(
      aeadId: _aead.id,
      chunkSize: chunkSize,
      headerNonce: _headerNonce,
      wrappedFileKey: wrapped,
    );
    await _sink.write(header.encode());
    _header = header;
    return header;
  }

  Future<void> _writeChunk(Uint8List payload, {required bool isLast}) async {
    final header = _header!;
    final index = _chunkCount;
    final nonce = _random.bytes(_aead.id.nonceLength);
    final sealed = await _aead.seal(
      key: _fileKey,
      nonce: nonce,
      plaintext: payload,
      aad: header.aad(index, isLast: isLast),
    );
    final record = Uint8List(nonce.length + sealed.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, sealed);
    await _sink.write(record);
    _chunkCount = index + 1;
  }
}
