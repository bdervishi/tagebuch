import 'dart:typed_data';

/// Quelle mit wahlfreiem Zugriff, aus der [ChunkFileReader] liest.
abstract interface class RandomAccessSource {
  /// Gesamtlänge in Byte.
  int get length;

  /// Liest bis zu [length] Bytes ab [offset]. Am Ende der Quelle darf das
  /// Ergebnis kürzer sein; der Leser wertet das als abgeschnittene Datei.
  Future<Uint8List> read(int offset, int length);
}

/// Quelle im Arbeitsspeicher. Die übergebenen Bytes werden nicht kopiert;
/// Tests können sie vor dem Lesen gezielt verändern.
class MemoryRandomAccessSource implements RandomAccessSource {
  MemoryRandomAccessSource(this._bytes);

  final Uint8List _bytes;

  @override
  int get length => _bytes.length;

  @override
  Future<Uint8List> read(int offset, int length) async {
    if (offset < 0 || length < 0) {
      throw RangeError('offset und length dürfen nicht negativ sein');
    }
    if (offset >= _bytes.length) return Uint8List(0);
    final end = offset + length > _bytes.length
        ? _bytes.length
        : offset + length;
    return Uint8List.sublistView(_bytes, offset, end);
  }
}
