import 'dart:io';
import 'dart:typed_data';

import 'format.dart';
import 'sink.dart';
import 'source.dart';

/// Senke auf einer Datei über [RandomAccessFile]. Das Längenfeld wird nach
/// dem letzten Chunk per `setPosition` gepatcht; die Datei ist während des
/// Schreibens jederzeit bis zum letzten vollständigen Datensatz lesbar
/// (Kopf mit Marker "unbekannt", Leser mit `allowTruncated: true`).
class FileChunkSink implements ChunkSink {
  /// Übernimmt eine bereits zum Schreiben geöffnete Datei.
  FileChunkSink(this._file);

  /// Öffnet [file] zum Schreiben (vorhandener Inhalt wird verworfen).
  static Future<FileChunkSink> open(File file) async =>
      FileChunkSink(await file.open(mode: FileMode.writeOnly));

  final RandomAccessFile _file;

  @override
  Future<void> write(Uint8List bytes) async {
    await _file.writeFrom(bytes);
  }

  @override
  Future<bool> patchHeaderLength(int offset, int plaintextLength) async {
    final end = await _file.position();
    await _file.setPosition(offset);
    await _file.writeFrom(ChunkFileHeader.encodeLength(plaintextLength));
    await _file.setPosition(end);
    return true;
  }

  @override
  Future<void> close() async {
    await _file.flush();
    await _file.close();
  }
}

/// Quelle auf einer Datei über [RandomAccessFile]. Zugriffe werden
/// serialisiert, weil `setPosition` und `read` sich sonst überlagern könnten.
class FileRandomAccessSource implements RandomAccessSource {
  FileRandomAccessSource._(this._file, this.length);

  /// Öffnet [file] zum Lesen; die Länge wird beim Öffnen festgehalten.
  static Future<FileRandomAccessSource> open(File file) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      return FileRandomAccessSource._(raf, await raf.length());
    } catch (_) {
      await raf.close();
      rethrow;
    }
  }

  final RandomAccessFile _file;
  Future<void> _queue = Future<void>.value();

  @override
  final int length;

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<Uint8List> read(int offset, int length) {
    if (offset < 0 || length < 0) {
      throw RangeError('offset und length dürfen nicht negativ sein');
    }
    return _serialized(() async {
      await _file.setPosition(offset);
      return _file.read(length);
    });
  }

  /// Schließt die Datei; ausstehende Lesezugriffe werden zuvor beendet.
  Future<void> close() => _serialized(() => _file.close());
}
