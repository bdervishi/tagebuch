import 'dart:typed_data';

/// 64-Bit-Zahlen Big Endian als zwei 32-Bit-Hälften, weil `ByteData.setUint64`
/// unter dart2js/DDC (Web-Fassung, D16) nicht verfügbar ist. Werte bleiben
/// unter 2^53 (Dateigrößen, Zähler), also in JavaScript exakt darstellbar.
abstract final class U64 {
  static const int _two32 = 0x100000000;

  static void write(ByteData view, int offset, int value) {
    if (value < 0) throw ArgumentError.value(value, 'value', 'negativ');
    view
      ..setUint32(offset, value ~/ _two32)
      ..setUint32(offset + 4, value % _two32);
  }

  static int read(ByteData view, int offset) =>
      view.getUint32(offset) * _two32 + view.getUint32(offset + 4);

  static Uint8List encode(int value) {
    final out = Uint8List(8);
    write(ByteData.sublistView(out), 0, value);
    return out;
  }

  /// XOR von [value] in die acht Byte ab [offset].
  static void xorInto(Uint8List bytes, int offset, int value) {
    final view = ByteData.sublistView(bytes);
    view
      ..setUint32(offset, view.getUint32(offset) ^ (value ~/ _two32))
      ..setUint32(offset + 4, view.getUint32(offset + 4) ^ (value % _two32));
  }
}
