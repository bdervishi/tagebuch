import 'dart:typed_data';

/// Lineares Resampling 16-Bit-Mono, z. B. 24 kHz -> 16 kHz für die
/// Spracherkennung. Bewusst einfach; die Engines sind gegen leichte
/// Aliasing-Artefakte unempfindlich, und die Datei bleibt bei voller Rate.
class LinearResampler {
  LinearResampler({required this.inputRate, required this.outputRate})
    : assert(inputRate > 0 && outputRate > 0);

  final int inputRate;
  final int outputRate;
  double _phase = 0;
  int _last = 0;
  bool _hasLast = false;

  Int16List process(Int16List input) {
    if (inputRate == outputRate) return input;
    final step = inputRate / outputRate;
    final out = <int>[];
    var i = 0;
    var pos = _phase;
    // Position -1 entspricht dem letzten Sample des vorherigen Blocks.
    while (pos < input.length) {
      final idx = pos.floor();
      final frac = pos - idx;
      final a = idx < 0
          ? (_hasLast ? _last : (input.isNotEmpty ? input[0] : 0))
          : input[idx];
      final b = idx + 1 < input.length ? input[idx + 1] : a;
      out.add((a + (b - a) * frac).round().clamp(-32768, 32767));
      pos += step;
      i++;
    }
    _phase = pos - input.length;
    if (input.isNotEmpty) {
      _last = input.last;
      _hasLast = true;
    }
    assert(i == out.length);
    return Int16List.fromList(out);
  }
}
