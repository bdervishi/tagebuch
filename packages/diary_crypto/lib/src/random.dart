import 'dart:math';
import 'dart:typed_data';

/// Quelle für Nonces und Schlüssel. Produktiv immer [SecureRandomSource];
/// [SequentialRandomSource] existiert nur für reproduzierbare Testvektoren.
abstract interface class RandomSource {
  Uint8List bytes(int length);
}

class SecureRandomSource implements RandomSource {
  SecureRandomSource() : _random = Random.secure();
  final Random _random;

  @override
  Uint8List bytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }
}

/// Deterministische Folge (0x00, 0x01, ...) für Testvektoren. Niemals produktiv.
class SequentialRandomSource implements RandomSource {
  SequentialRandomSource([this._next = 0]);
  int _next;

  @override
  Uint8List bytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _next & 0xff;
      _next++;
    }
    return out;
  }
}
