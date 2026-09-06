import 'dart:typed_data';

import 'format.dart';

/// Ziel, in das [ChunkFileWriter] schreibt: sequenzielles Anhängen plus
/// einmaliges nachträgliches Setzen des Längenfelds im Kopf.
abstract interface class ChunkSink {
  /// Hängt [bytes] an das Ende an.
  Future<void> write(Uint8List bytes);

  /// Überschreibt das Längenfeld im Kopf (acht Bytes u64 BE ab Byte-Offset
  /// [offset]) mit [plaintextLength]. Liefert `false`, wenn das Ziel kein
  /// nachträgliches Schreiben erlaubt (z. B. ein reiner Datenstrom); der Kopf
  /// behält dann den Marker "unbekannt", und der Leser ermittelt die Länge
  /// aus der Dateigröße und dem letzten Chunk.
  Future<bool> patchHeaderLength(int offset, int plaintextLength);

  /// Schließt das Ziel; danach sind keine Schreibzugriffe mehr erlaubt.
  Future<void> close();
}

/// Senke im Arbeitsspeicher (Tests, Testvektoren, kleine Dateien).
class MemoryChunkSink implements ChunkSink {
  /// Mit `supportsPatching: false` verhält sich die Senke wie ein reiner
  /// Datenstrom: [patchHeaderLength] liefert `false`, der Kopf behält den
  /// Marker "unbekannt".
  MemoryChunkSink({this.supportsPatching = true});

  final bool supportsPatching;
  final BytesBuilder _builder = BytesBuilder(copy: true);
  bool _closed = false;

  /// Bisher geschriebene Bytes (Kopie).
  Uint8List get bytes => _builder.toBytes();

  /// Anzahl der bisher geschriebenen Bytes.
  int get length => _builder.length;

  bool get isClosed => _closed;

  void _checkOpen() {
    if (_closed) {
      throw StateError('MemoryChunkSink ist bereits geschlossen');
    }
  }

  @override
  Future<void> write(Uint8List bytes) async {
    _checkOpen();
    _builder.add(bytes);
  }

  @override
  Future<bool> patchHeaderLength(int offset, int plaintextLength) async {
    _checkOpen();
    if (!supportsPatching) return false;
    final all = _builder.takeBytes();
    final field = ChunkFileHeader.encodeLength(plaintextLength);
    if (offset < 0 || offset + field.length > all.length) {
      _builder.add(all);
      throw RangeError.range(offset, 0, all.length - field.length, 'offset');
    }
    all.setAll(offset, field);
    _builder.add(all);
    return true;
  }

  @override
  Future<void> close() async {
    _closed = true;
  }
}
