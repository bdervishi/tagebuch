import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:diary_chunkfile/diary_chunkfile.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_keys/diary_keys.dart';

import 'indexed_db_store.dart';

/// Ergebnis von [EncryptedFileStore.write].
class WrittenFile {
  const WrittenFile({required this.fileKeyWrapped, required this.sizeBytes});

  /// Dateischlüssel, mit dem Master-Key gewrappt (identisch mit dem Blob im
  /// Dateikopf); gehört in `Recording.fileKeyWrapped`.
  final Uint8List fileKeyWrapped;

  /// Größe der verschlüsselten Datei in Byte.
  final int sizeBytes;
}

/// Audiodateien als Chunk-AEAD-Dateien (`diary_chunkfile`, AES-256-GCM,
/// 32-KiB-Chunks) im IndexedDB-Store `files` (D16, Punkt 1 und 2).
///
/// Pro Datei ein zufälliger Dateischlüssel, mit dem [DekWrapper] (Zweck
/// `chunkfile-v1`) gewrappt; der Blob steht im Dateikopf und im
/// Aufnahme-Datensatz. Entschlüsselt wird nur in den Arbeitsspeicher; auf
/// das Dateisystem gelangt nie Klartext. OPFS ist die spätere Ausbaustufe
/// für sehr große Dateien (docs/10-pwa.md Abschnitt 4).
class EncryptedFileStore {
  EncryptedFileStore(
    this._db,
    this._wrapper, {
    Aead? aead,
    RandomSource? random,
    this.chunkSize = ChunkFileFormat.defaultChunkSize,
  }) : _aead = aead ?? CryptographyAead.aes256Gcm(),
       _random = random ?? SecureRandomSource();

  final IndexedDbStore _db;
  final DekWrapper _wrapper;
  final Aead _aead;
  final RandomSource _random;
  final int chunkSize;

  /// Verschlüsselt [bytes] als Chunk-Datei und legt sie unter [fileName] ab.
  Future<WrittenFile> write(String fileName, Uint8List bytes) async {
    final fileKey = _random.bytes(ChunkFileFormat.fileKeyLength);
    try {
      final wrapped = await _wrapper.wrap(
        fileKey,
        purpose: ChunkFileFormat.keyWrapPurpose,
      );
      final sink = MemoryChunkSink();
      final writer = ChunkFileWriter.withWrappedFileKey(
        sink,
        aead: _aead,
        random: _random,
        fileKey: fileKey,
        wrappedFileKey: wrapped,
        chunkSize: chunkSize,
      );
      await writer.add(bytes);
      await writer.close();
      final encrypted = sink.bytes;
      await _db.put(IndexedDbStore.filesStore, fileName, encrypted.toJS);
      return WrittenFile(fileKeyWrapped: wrapped, sizeBytes: encrypted.length);
    } finally {
      zeroize(fileKey);
    }
  }

  /// Liest und entschlüsselt die Datei vollständig in den Speicher.
  ///
  /// [fileKeyWrapped] ist der Blob aus dem Aufnahme-Datensatz; er muss zum
  /// Kopf der Datei passen. Wirft [AuthenticationException] bei falschem
  /// Schlüssel, [ChunkFileTruncatedException] bei abgeschnittener Datei und
  /// [StateError], wenn die Datei fehlt.
  Future<Uint8List> read(String fileName, Uint8List fileKeyWrapped) async {
    final reader = await _open(fileName, fileKeyWrapped);
    try {
      return await reader.readAll();
    } finally {
      reader.close();
    }
  }

  /// Öffnet die Datei mit wahlfreiem Zugriff (für Teilbereiche).
  Future<ChunkFileReader> _open(
    String fileName,
    Uint8List fileKeyWrapped, {
    bool allowTruncated = true,
  }) async {
    final stored = await _db.get(IndexedDbStore.filesStore, fileName);
    if (stored == null) {
      throw StateError('Datei nicht vorhanden');
    }
    final bytes = (stored as JSUint8Array).toDart;
    return ChunkFileReader.openWith(
      MemoryRandomAccessSource(bytes),
      aead: _aead,
      allowTruncated: allowTruncated,
      unwrapFileKey: (headerBlob) {
        // Datensatz und Kopf tragen denselben Blob; maßgeblich ist der
        // Datensatz, weil Crypto-Shredding ihn vernichtet (D5).
        if (!_sameBytes(headerBlob, fileKeyWrapped)) {
          throw const AuthenticationException(
            'Dateischlüssel im Kopf passt nicht zum Datensatz',
          );
        }
        return _wrapper.unwrap(
          fileKeyWrapped,
          purpose: ChunkFileFormat.keyWrapPurpose,
        );
      },
    );
  }

  Future<bool> exists(String fileName) async =>
      await _db.get(IndexedDbStore.filesStore, fileName) != null;

  /// Größe der verschlüsselten Datei oder `null`, wenn sie fehlt.
  Future<int?> sizeOf(String fileName) async {
    final stored = await _db.get(IndexedDbStore.filesStore, fileName);
    return stored == null ? null : (stored as JSUint8Array).toDart.length;
  }

  Future<List<String>> fileNames() => _db.getAllKeys(IndexedDbStore.filesStore);

  Future<void> delete(String fileName) =>
      _db.delete(IndexedDbStore.filesStore, fileName);

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
