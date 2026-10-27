import 'dart:typed_data';

/// Reine Rechenschritte auf PCM im Speicher, ohne Browser-API (testbar
/// überall): Mono-Mischung, lineares Resampling, Int16 → Float32.
abstract final class Pcm {
  /// Abtastrate, die Whisper erwartet.
  static const int whisperSampleRate = 16000;

  /// Mischt mehrere Kanäle gleicher Länge durch Mittelwert zu einem Kanal.
  static Float32List mixToMono(List<Float32List> channels) {
    if (channels.isEmpty) return Float32List(0);
    if (channels.length == 1) return channels.first;
    final length = channels
        .map((c) => c.length)
        .reduce((a, b) => a < b ? a : b);
    final out = Float32List(length);
    final scale = 1 / channels.length;
    for (var i = 0; i < length; i++) {
      var sum = 0.0;
      for (final channel in channels) {
        sum += channel[i];
      }
      out[i] = sum * scale;
    }
    return out;
  }

  /// Lineares Resampling eines Blocks von [inputRate] auf [outputRate].
  /// Für Sprache und die Eingabe eines Erkennungsmodells ausreichend; die
  /// Browser-Dekodierung über `OfflineAudioContext` resampelt ohnehin selbst,
  /// dies ist der Rückfall.
  static Float32List resample(
    Float32List input, {
    required int inputRate,
    required int outputRate,
  }) {
    if (inputRate == outputRate || input.isEmpty) return input;
    final outLength = (input.length * outputRate / inputRate).round();
    final out = Float32List(outLength);
    final step = inputRate / outputRate;
    for (var i = 0; i < outLength; i++) {
      final pos = i * step;
      final idx = pos.floor();
      final frac = pos - idx;
      final a = input[idx < input.length ? idx : input.length - 1];
      final b = input[idx + 1 < input.length ? idx + 1 : input.length - 1];
      out[i] = a + (b - a) * frac;
    }
    return out;
  }

  /// Int16-PCM zu Float32 im Bereich -1 bis 1.
  static Float32List fromInt16(Int16List samples) {
    final out = Float32List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      out[i] = samples[i] / 32768;
    }
    return out;
  }

  /// Dauer eines Blocks bei [sampleRate].
  static Duration durationOf(int sampleCount, int sampleRate) =>
      Duration(microseconds: (sampleCount * 1000000 / sampleRate).round());
}
